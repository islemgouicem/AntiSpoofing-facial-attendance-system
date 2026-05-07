# AI388 — Computer and Network Security  Projects 


###  Table of Contents
- [Team Members](#team-members)
- [Demo Videos](#demo-videos)
- [P001 — Secure Student Face Recognition System](#p001--secure-student-face-recognition-system)
  - [Key Features & Benefits](#key-features--benefits-p001)
  - [Technologies Used](#technologies-used-p001)
  - [Pipeline](#pipeline-p001)
  - [Folder Structure](#folder-structure-p001)
  - [How to Run](#how-to-run-p001)
- [S005 — Phishing Email Detector Using Machine Learning](#s005--phishing-email-detector-using-machine-learning)
  - [Key Features & Benefits](#key-features--benefits-s005)
  - [Technologies Used](#technologies-used-s005)
  - [Pipeline](#pipeline-s005)
  - [Folder Structure](#folder-structure-s005)
  - [How to Run](#how-to-run-s005)
- [Contributing](#Contributing)


---

### TEAM 44 - G07 members:

This project was carried out by the following students:

- **AHMED FOUATIH Hamza Faiz** — *Team Leader*  
- **GADIRI Amina**  
- **GOUICEM Islem**  
- **AMEDDAH Mohamed**  
- **CHERGUI Mohamed Bahae Eddine**

---

### Demo videos link:

- **P001 — Secure student face recognition system:** [![Watch Video](https://img.youtube.com/vi/YOUR_VIDEO_ID/0.jpg)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)
- **S005 — Phishing Email Detector using Machine Learning:** 
  [![Watch Video](https://img.youtube.com/vi/0KgpARxQnfQ/0.jpg)](https://youtu.be/0KgpARxQnfQ)

---

## P001 — Secure student face recognition system

Adopts deep learning to build an intelligent face recognition system for students — usable for attendance tracking or authentication. The system includes anti-spoofing protection so a malicious actor cannot bypass it using a photo or crafted mask.

**Demo video:** https://youtuve.51cjqnckq

### Key Features & Benefits 

- Real-time face recognition for student authentication  
- Anti-spoofing detection (prevents fake face attacks)  
- FastAPI backend for high-performance inference  
- Modular architecture (separate services for camera, recognition, and security)  
- Flutter desktop application for user-friendly attendance system  
- Scalable design for future smart campus integration  

### Technologies Used 

- Python (core backend + AI logic)  
- FastAPI (REST API server)  
- OpenCV (camera processing)  
- Deep Learning (face recognition + spoof detection models)  
- NumPy (numerical processing)  
- Flutter (desktop UI application)  
- Uvicorn (server runtime for FastAPI)  


### Pipeline

![Face Recognition Pipeline](Secure%20student%20face%20recognition%20system/pipeline.png)



### Folder structure

The Folder is organized into distinct components for ai_engine, antispoffing, and the attendance desktop app .

```
Secure student face recognition system/
├── ai_engine/                                     # FastAPI backend (face recognition server)
│   ├── ai_engine.spec                             # Build/spec file (PyInstaller or packaging config)
│   ├── server.py                                  # Main FastAPI entry point (API routes, server startup)
│   ├── camera_service.py                          # Handles camera input stream + frame capture
│   ├── recognition_service.py                     # Face recognition logic (embeddings + matching)
│   ├── anti_spoof_service.py                      # Calls anti-spoof system to detect fake faces
│   └── requirements.txt                           # Python dependencies for AI engine
├── antispoffing/                                  # Anti-spoofing system (security layer)
│   ├── db/                                        # Database files (logs, stored data, metadata)
│   ├── resources/                                 # Models, pretrained weights, datasets
│   ├── src/                                       # Core anti-spoofing source code
│   ├── log.txt                                    # Runtime logs (debugging / tracking)
│   ├── main.py                                    # Main entry point for anti-spoof system
│   ├── test.py                                    # Testing script for model validation
│   ├── util.py                                    # Utility functions (image processing, helpers)
│   └── requirements.txt                           # Dependencies for anti-spoof module

│   └── src/
│       ├── data_io/                               # Dataset loading + preprocessing pipeline
│       ├── model_lib/                             # Deep learning models for spoof detection
│       ├── __pycache__/                           # Python cache (auto-generated)
│       ├── anti_spoof_predict.py                  # Inference script (real vs fake prediction)
│       ├── generate_patches.py                    # Extracts face patches from images/videos
│       └── utility.py                             # Helper functions (transformations, tools)
├── attendance_app/                                # Flutter desktop application (UI)
│   ├── lib/                                       # Main Flutter source code
│   │   ├── data/                                  # Data layer (API calls, models)
│   │   ├── domain/                                # Business logic layer (use cases)
│   │   ├── presentation/                          # UI screens and widgets
│   │   └── providers/                             # State management (Riverpod/Provider)
```



### How to run

#### Windows

```PowerShell
# Terminal 1 — AI engine
> cd "Secure student face recognition system"
> .venv\Scripts\activate
> cd ai_engine
> python -m uvicorn server:app --host 127.0.0.1 --port 8000

# Terminal 2 — Flutter app
> cd attendance_app\lib
> flutter run -d windows
```
#### Linux / macOS
```bash
# Terminal 1 — AI engine
cd "Secure student face recognition system"
source .venv/bin/activate
cd ai_engine
python -m uvicorn server:app --host 127.0.0.1 --port 8000

# Terminal 2 — Flutter app
cd attendance_app/lib
flutter run -d linux
```

---

## S005 — Phishing email detector using machine learning

Detects phishing emails using machine learning and text-based features. Extracts indicators such as suspicious URLs, keywords, and email structure, then trains and evaluates classification models. A small interface demonstrates phishing probability prediction.

**Demo video:**   https://youtu.be/0KgpARxQnfQ
[![Watch Video](https://img.youtube.com/vi/0KgpARxQnfQ/0.jpg)](https://youtu.be/0KgpARxQnfQ)


### Key Features & Benefits 

- ML-based phishing email classification  
- Feature extraction from email content (URLs, keywords, structure)  
- FastAPI backend for real-time predictions  
- Browser extension integration (PhishGuard)  
- Offline-trained models for fast inference
- Modular design (analysis, backend, frontend separation)  

### Technologies Used 

- Python (ML + backend development)
- Scikit-learn (classification models)
- FastAPI (backend API)
- Pandas & NumPy (data processing)
- Node.js (frontend tooling)
- JavaScript (browser extension frontend)
- Uvicorn (API server)


### Pipeline

![Phishing Email Detector pipeline](Phishing%20Email%20Detector%20using%20Machine%20Learning/pipeline.png)

### Folder structure

The repository is organized into distinct components for analysis, model storage, and the browser extension.
```
Phishing Email Detector using Machine Learning/
    ├── Analysis/ 
    │   ├── CNS_project.ipynb              # Jupyter Notebook for ML model development and analysis
    │   │── emails.csv                     # Raw dataset of emails
    │   └── data/
    │       ├── processed/                 # Cleaned and processed datasets
    │       │   ├── X_test_full.npz
    │       │   ├── ... 
    │   └── reports/                       # json files for reports of each phase
    │       ├── cleaning_report.json
    │       ├── ...    
    │   └── models/                        # pkl files for backend deployments
    │       ├── best_model.pkl
    │       ├── ...   
    ├── Extension/                         # Browser extension (PhishGuard)
    │   ├── backend/                       # FastAPI server for email classification
    │   │   ├── api/
    │   │   │   └── api.py                 # Main FastAPI application logic
    │   │   └── requirements.txt           # Python dependencies for the backend
    │   └── frontend/                      # Browser extension frontend assets (Nodejs + react)
    │       ├── assets/
    │       └── public/                    # Other extension files (e.g., manifest.json)
    │       ├── src/

```


### How to run

```PowerShell
# Terminal 1 — Backend side
> cd "Phishing Email Detector using Machine Learning\Extension\backend\api"
> uvicorn api:app --reload --port 8000 --host 127.0.0.1

```
Load the browser extension into your preferred browser.

1.  Open Chrome and navigate to `chrome://extensions`.
2.  Enable "Developer mode" by toggling the switch in the top right corner.
3.  Click the "Load unpacked" button.
4.  Navigate to and select the `Phishing Email Detector using Machine Learning/Extension/frontend/dist` directory from your cloned repository.


## Contributing Guidelines

We welcome contributions to enhance the Phishing Email Detector or Secure student face recognition system! To contribute, please follow these steps:

1.  **Fork** the repository to your GitHub account.
2.  **Clone** your forked repository: `git clone https://github.com/YourUsername/AI388_CNS_projects.git`
3.  **Create a new branch** for your feature or bug fix: `git checkout -b feature/your-feature-name` or `bugfix/issue-description`.
4.  **Implement your changes** and ensure they adhere to the existing code styles and conventions.
5.  **Test your changes** thoroughly to prevent regressions.
6.  **Commit your changes** with a clear, concise, and descriptive commit message.
7.  **Push your branch** to your forked repository.
8.  **Open a Pull Request** to the `main` branch of the original repository. Please provide a detailed description of your changes and why they are necessary.
