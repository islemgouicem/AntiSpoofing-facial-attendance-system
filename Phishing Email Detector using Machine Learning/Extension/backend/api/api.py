"""
api.py — PhishGuard local FastAPI server
────────────────────────────────────────
Run from the folder that CONTAINS this file:

    cd path/to/your/extension_or_api_folder
    uvicorn api:app --reload --port 8000 --host 127.0.0.1
"""

import os
import re
import html
import string
import unicodedata
import pickle
import joblib
import numpy as np
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from scipy.sparse import hstack, csr_matrix
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import MinMaxScaler
import warnings
warnings.filterwarnings("ignore")

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE_DIR   = Path(__file__).resolve().parent
MODEL_DIR  = BASE_DIR.parent / "models"


model_path = MODEL_DIR / "best_model.pkl"

if not model_path.exists():
    raise FileNotFoundError(
        f"best_model.pkl not found at {model_path}\n"
        "Make sure the 'models/' folder is next to api.py."
    )

# ── Load artifacts saved during Phase 3 & 4 ──────────────────────────────────
# The vectorizers and scaler MUST be the same objects fitted on train —
# loading them here guarantees no re-fitting happens at inference time.

def _load(path: Path, label: str):
    if not path.exists():
        raise FileNotFoundError(f"{label} not found at {path}")
    with open(path, "rb") as f:
        return pickle.load(f)

# If you serialised them separately with joblib/pickle during Phase 3, load them:
word_tfidf: TfidfVectorizer = _load(MODEL_DIR / "word_tfidf.pkl",  "word TF-IDF vectorizer")
char_tfidf: TfidfVectorizer = _load(MODEL_DIR / "char_tfidf.pkl",  "char TF-IDF vectorizer")
scaler:     MinMaxScaler    = _load(MODEL_DIR / "hc_scaler.pkl",   "handcrafted scaler")

bundle = _load(model_path, "best model")
model  = bundle["model"]
model_name = bundle["name"]

print(f"[PhishGuard] Loaded model: {model_name}")

# ── Text-cleaning (mirrors Phase 1 exactly) ───────────────────────────────────
URL_RE     = re.compile(r"(https?://\S+|www\.\S+)", re.IGNORECASE)
EMAIL_RE   = re.compile(r"\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b")
NUM_RE     = re.compile(r"\b\d+(?:[.,:/-]\d+)*\b")
HTML_TAG   = re.compile(r"<[^>]+>")
CTRL_CHAR  = re.compile(r"[\x00-\x1f\x7f-\x9f]")

def clean_text(text: str) -> str:
    text = str(text)
    text = html.unescape(text)
    text = HTML_TAG.sub(" ", text)
    text = unicodedata.normalize("NFKC", text)
    text = CTRL_CHAR.sub(" ", text)
    text = text.lower()
    text = URL_RE.sub(" <url> ", text)
    text = EMAIL_RE.sub(" <email> ", text)
    text = NUM_RE.sub(" <num> ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text

# ── Handcrafted feature extraction (mirrors Phase 3.1 – 3.3) ─────────────────
URGENCY_WORDS = {
    "urgent","immediately","expire","expires","expiry","deadline",
    "act now","limited time","today","now","asap","hurry","last chance",
    "final notice","important notice","attention","alert","warning"
}
FINANCIAL_WORDS = {
    "free","money","cash","prize","winner","million","billion",
    "reward","bonus","profit","investment","lottery","claim","won",
    "earn","income","dollar","€","£","payment","transfer","fund"
}
ACTION_WORDS = {
    "click","verify","confirm","update","login","log in","sign in",
    "submit","enter","provide","download","install","open","access",
    "register","activate","validate","reactivate"
}
THREAT_WORDS = {
    "suspend","suspended","terminate","terminated","illegal","blocked",
    "risk","fraud","hacked","unauthorized","violation","penalty",
    "deactivate","restricted","compromised","breach"
}

def _count_lexicon(text: str, lexicon: set) -> int:
    t = text.lower()
    return sum(t.count(term) for term in lexicon)

def _caps_ratio(text: str) -> float:
    alpha = [c for c in text if c.isalpha()]
    if not alpha:
        return 0.0
    return sum(1 for c in alpha if c.isupper()) / len(alpha)

def _ttr(text: str) -> float:
    words = text.split()
    return len(set(words)) / len(words) if words else 0.0

def _sentence_count(text: str) -> int:
    sents = re.split(r"[.!?]+", text.strip())
    return max(1, len([s for s in sents if s.strip()]))

def extract_handcrafted(clean: str, raw: str) -> np.ndarray:
    word_count  = max(len(clean.split()), 1)

    url_count   = clean.count("<url>")
    email_count = clean.count("<email>")
    num_count   = clean.count("<num>")

    # 3.1 structural
    avg_word_len = (
        np.mean([len(w) for w in clean.split()]) if clean.split() else 0
    )
    excl = raw.count("!")
    ques = raw.count("?")
    punct = sum(1 for c in raw if c in string.punctuation)

    struct = [
        url_count,
        email_count,
        num_count,
        word_count,
        len(clean),       # char_count  ← was already there, just double-check order
        url_count / word_count,
        num_count / word_count,
        avg_word_len,
        excl,
        ques,
        punct,
    ]

    # 3.2 urgency / sentiment
    urgency_count   = _count_lexicon(clean, URGENCY_WORDS)
    financial_count = _count_lexicon(clean, FINANCIAL_WORDS)
    action_count    = _count_lexicon(clean, ACTION_WORDS)
    threat_count    = _count_lexicon(clean, THREAT_WORDS)
    caps_ratio      = _caps_ratio(raw)
    urgency_density = urgency_count / word_count

    urgency = [urgency_count, financial_count, action_count,
               threat_count, caps_ratio, urgency_density]

    # 3.3 stylometric
    sent_count      = _sentence_count(clean)
    ph_total        = url_count + email_count + num_count
    digit_ratio     = sum(c.isdigit() for c in raw) / max(len(raw), 1)

    style = [
        _ttr(clean),
        sent_count,
        word_count / sent_count,
        ph_total / word_count,
        digit_ratio,
    ]

    return np.array(struct + urgency + style, dtype=float).reshape(1, -1)


def build_feature_matrix(raw: str):
    """Full Phase-3 pipeline for a single email → sparse feature matrix."""
    clean = clean_text(raw)

    hc_raw    = extract_handcrafted(clean, raw)
    hc_scaled = scaler.transform(hc_raw)             # MinMaxScaler fitted on train

    X_word = word_tfidf.transform([clean])            # (1, 5000)
    X_char = char_tfidf.transform([clean])            # (1, 3000)

    X_full = hstack([csr_matrix(hc_scaled), X_word, X_char])
    return X_full, clean

# ── FastAPI app ───────────────────────────────────────────────────────────────
app = FastAPI(title="PhishGuard API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://mail.google.com",
        "https://outlook.cloud.microsoft",
        "https://outlook.office.com",
        "https://outlook.office365.com",
        "chrome-extension://*",
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type"],
)

# ── Request / Response schemas ────────────────────────────────────────────────
class Email(BaseModel):
    text: str

class Prediction(BaseModel):
    label: int          # 0 = safe, 1 = phishing
    verdict: str        # "safe" | "phishing"
    confidence: float   # probability of phishing  (0.0 – 1.0)
    model: str

# ── Endpoints ─────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"status": "PhishGuard API running", "model": model_name}

@app.get("/health")
def health():
    return {"ok": True}


@app.post("/predict")
def predict(email: Email):
    text = email.text.strip()
    if not text:
        raise HTTPException(status_code=422, detail="Email text is empty.")

    try:
        X, _ = build_feature_matrix(text)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Feature extraction failed: {exc}")

    # Compute probability
    if hasattr(model, "predict_proba"):
        prob_phishing = float(model.predict_proba(X)[0, 1])
    elif hasattr(model, "decision_function"):
        score = float(model.decision_function(X)[0])
        prob_phishing = 1 / (1 + np.exp(-score))
    else:
        prob_phishing = float(model.predict(X)[0])

    # Convert to 0/1 like your second version
    prediction = int(prob_phishing <= 0.5)
    print(f"[PhishGuard] Prediction: {prediction} (prob_phishing={prob_phishing:.4f})")
    return {"prediction": prediction}
