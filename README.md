# Secure Student Face Recognition System

Welcome to the Secure Student Face Recognition System 👋

This project is a modular attendance and authentication system that combines face recognition with anti-spoofing checks, so it can reject fake attempts such as photos, videos, or masks.

## What it does ✨

- Detects real faces and blocks spoof attempts with an anti-spoofing ensemble.
- Extracts face embeddings and matches them against enrolled students.
- Supports attendance workflows through a clean service-based architecture.

## Project Layout 📦

- `ai_engine/` — Core inference services, camera handling, recognition, and API orchestration.
- `antispoffing/` — Anti-spoofing models, utilities, and resources.
- `attendance_app/` — Flutter app for demos, face registration, and attendance marking.

## Included Models 🧠

- Anti-spoof weights: `antispoffing/resources/anti_spoof_models/2.7_80x80_MiniFASNetV2.pth` and `4_0_0_80x80_MiniFASNetV1SE.pth`.
- Face detector: `antispoffing/resources/detection_model/deploy.prototxt` and `Widerface-RetinaFace.caffemodel`.

## Quick Start (Windows) 🚀

1. Create and activate a Python virtual environment:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Install Python dependencies for the AI engine and anti-spoofing components:

```powershell
pip install -r ai_engine/requirements.txt
pip install -r antispoffing/requirements.txt
```

3. Start the AI engine server. This handles camera capture and exposes recognition/attendance endpoints:

```powershell
python ai_engine/server.py
```

4. Run anti-spoofing tools or tests:

```powershell
python antispoffing/main.py
```

## Helpful Notes 💡

- Face registration, encoding, and matching logic live in `ai_engine/recognition_service.py`.
- Anti-spoofing model inference and patch utilities live in `antispoffing/src/` and are orchestrated by `antispoffing/main.py`.
- The Flutter app in `attendance_app/` demonstrates how the system registers students and marks attendance via the AI engine endpoints.
- If you plan to retrain models or run experiments, consult `antispoffing/src/generate_patches.py` and `antispoffing/src/anti_spoof_predict.py`.

## Contributing 🤝

Contributions are welcome. Open an issue first to discuss larger changes. When submitting a pull request, include a short summary and any setup or test steps.

## License 📄

This project was developed for an academic course. Check bundled third-party models and libraries for their licenses.

Made by Team 44 for the AI388 course.
