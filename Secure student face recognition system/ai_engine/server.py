"""Face Recognition Attendance System — AI Engine Server.

Run:  python server.py
Or:   uvicorn server:app --host 127.0.0.1 --port 8000
"""

import os
import sys
import time
import threading
from contextlib import asynccontextmanager
import psutil

import cv2
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response, StreamingResponse

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
if getattr(sys, 'frozen', False):
    # PyInstaller frozen mode (ai_engine.exe)
    # The executable is inside AttendanceSystem_Test/ai_engine.exe
    BASE_DIR = os.path.dirname(sys.executable)
    DB_DIR = os.path.join(BASE_DIR, "db")
    MODEL_DIR = os.path.join(BASE_DIR, "models")
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    PROJECT_DIR = os.path.dirname(BASE_DIR)
    ANTISPOOF_DIR = os.path.join(PROJECT_DIR, "antispoffing")
    DB_DIR = os.path.join(ANTISPOOF_DIR, "db")
    MODEL_DIR = os.path.join(ANTISPOOF_DIR, "resources", "anti_spoof_models")

    # Ensure antispoffing importable
    if ANTISPOOF_DIR not in sys.path:
        sys.path.insert(0, ANTISPOOF_DIR)

from camera_service import CameraService
from recognition_service import RecognitionService
from anti_spoof_service import AntiSpoofService

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------
camera = CameraService()
recognizer = RecognitionService(db_dir=DB_DIR)
anti_spoof = AntiSpoofService(model_dir=MODEL_DIR)


# ---------------------------------------------------------------------------
# Lifecycle and Termination
# ---------------------------------------------------------------------------
def monitor_parent(parent_pid: int):
    """Exit the process if the parent process dies."""
    try:
        parent = psutil.Process(parent_pid)
        while True:
            if not parent.is_running():
                print(f"[AI Engine] Parent process {parent_pid} terminated. Exiting...")
                os._exit(0)
            time.sleep(2)
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        print(f"[AI Engine] Parent process {parent_pid} not found. Exiting...")
        os._exit(1)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Optional: logic to start monitoring here if needed
    yield
    camera.stop()


app = FastAPI(title="Face Attendance AI Engine", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------
@app.get("/health")
async def health():
    return {"status": "ok", "camera_active": camera.is_running}


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------
@app.post("/camera/start")
async def camera_start(camera_id: int = Query(0)):
    if not camera.start(camera_id):
        raise HTTPException(500, "Failed to start camera")
    return {"status": "started"}


@app.post("/camera/stop")
async def camera_stop():
    camera.stop()
    return {"status": "stopped"}


@app.get("/camera/frame")
async def camera_frame():
    frame = camera.get_frame()
    if frame is None:
        raise HTTPException(503, "No frame available")
    _, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
    return Response(content=buf.tobytes(), media_type="image/jpeg")


def _mjpeg_generator():
    while camera.is_running:
        frame = camera.get_frame()
        if frame is not None:
            _, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 75])
            yield (
                b"--frame\r\nContent-Type: image/jpeg\r\n\r\n"
                + buf.tobytes()
                + b"\r\n"
            )
        time.sleep(0.033)


@app.get("/stream")
async def video_stream():
    if not camera.is_running:
        raise HTTPException(503, "Camera not running")
    return StreamingResponse(
        _mjpeg_generator(),
        media_type="multipart/x-mixed-replace; boundary=frame",
    )


# ---------------------------------------------------------------------------
# Recognition
# ---------------------------------------------------------------------------
@app.post("/recognize")
async def recognize():
    frame = camera.get_frame()
    if frame is None:
        raise HTTPException(503, "No frame available")

    is_real = anti_spoof.check(frame)
    if not is_real:
        return {"recognized": False, "reason": "spoof_detected"}

    result = recognizer.recognize(frame)
    if result is None:
        return {"recognized": False, "reason": "no_face_found"}

    name, confidence = result
    if name == "unknown_person":
        return {"recognized": False, "reason": "unknown_person"}

    return {"recognized": True, "name": name, "confidence": confidence}


# ---------------------------------------------------------------------------
# Registration & Student management
# ---------------------------------------------------------------------------
@app.post("/register")
async def register(name: str = Query(...)):
    frame = camera.get_frame()
    if frame is None:
        raise HTTPException(503, "No frame available")
    if not recognizer.register(frame, name):
        raise HTTPException(400, "No face detected in frame")
    return {"status": "registered", "name": name}


@app.get("/students")
async def list_students():
    return {"students": recognizer.list_students()}


@app.delete("/students/{name}")
async def delete_student(name: str):
    if not recognizer.delete_student(name):
        raise HTTPException(404, "Student not found")
    return {"status": "deleted", "name": name}


# ---------------------------------------------------------------------------
# Entry-point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    import argparse

    parser = argparse.ArgumentParser(description="AI Attendance Engine")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--parent-pid", type=int, help="PID of the parent process to monitor")
    args = parser.parse_args()

    if args.parent_pid:
        print(f"[AI Engine] Monitoring parent PID: {args.parent_pid}")
        threading.Thread(target=monitor_parent, args=(args.parent_pid,), daemon=True).start()

    uvicorn.run(app, host=args.host, port=args.port)
