"""
api.py — PhishGuard local FastAPI server
────────────────────────────────────────
Run from the folder that CONTAINS this file:

    cd path/to/your/extension_or_api_folder
    uvicorn api:app --reload --port 8000 --host 127.0.0.1

Make sure model.pkl and vectorizer.pkl are at:
    ../model/model.pkl
    ../model/vectorizer.pkl
  OR edit MODEL_DIR below to match your actual paths.
"""

import os
from pathlib import Path
from fastapi import FastAPI
from pydantic import BaseModel
import re
import joblib
from fastapi.middleware.cors import CORSMiddleware

# ── Model paths ──────────────────────────────────────────────────────
# Path is relative to THIS file's location, not where you run uvicorn from.
BASE_DIR   = Path(__file__).resolve().parent
MODEL_DIR  = BASE_DIR.parent / "model"          # adjust if needed

model_path = MODEL_DIR / "model.pkl"
vec_path   = MODEL_DIR / "vectorizer.pkl"

if not model_path.exists():
    raise FileNotFoundError(
        f"model.pkl not found at {model_path}\n"
        f"Edit MODEL_DIR in api.py to point to the correct folder."
    )

model      = joblib.load(model_path)
vectorizer = joblib.load(vec_path)
print(f"✅ Model loaded from {model_path}")

# ── Preprocessing ────────────────────────────────────────────────────
def preprocess_text(text: str) -> str:
    text = re.sub(r"http\S+", "", text)
    text = re.sub(r"[^\w\s]", "", text)
    text = text.lower()
    text = re.sub(r"\s+", " ", text).strip()
    return text

# ── App ──────────────────────────────────────────────────────────────
app = FastAPI(title="PhishGuard API")

# IMPORTANT: allow_credentials=True is INCOMPATIBLE with allow_origins=["*"]
# Use explicit origins instead.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://mail.google.com",
        "https://outlook.cloud.microsoft",
        "https://outlook.office.com",
        "https://outlook.office365.com",
        "chrome-extension://*",   # catches any extension origin
    ],
    allow_credentials=False,      # must be False when origins includes wildcards/chrome-ext
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type"],
)

class Email(BaseModel):
    text: str

@app.get("/")
def root():
    return {"status": "PhishGuard API running"}

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/predict")
def predict(email: Email):
    processed  = preprocess_text(email.text)
    vect       = vectorizer.transform([processed])
    prediction = int(model.predict(vect)[0])
    return {"prediction": prediction}