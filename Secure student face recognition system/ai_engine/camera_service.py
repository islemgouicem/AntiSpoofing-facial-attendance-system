"""Thread-safe camera service using OpenCV."""

import threading
import cv2


class CameraService:
    def __init__(self):
        self._cap = None
        self._frame = None
        self._lock = threading.Lock()
        self._running = False
        self._thread = None

    @property
    def is_running(self) -> bool:
        return self._running

    def start(self, camera_id: int = 0) -> bool:
        if self._running:
            return True
        # Use DirectShow backend on Windows for much faster startup
        self._cap = cv2.VideoCapture(camera_id, cv2.CAP_DSHOW)
        if not self._cap.isOpened():
            return False
        self._cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self._cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self._running = True
        self._thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._thread.start()
        return True

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)
        if self._cap:
            self._cap.release()
            self._cap = None
        self._frame = None

    def get_frame(self):
        with self._lock:
            return self._frame.copy() if self._frame is not None else None

    def _capture_loop(self):
        while self._running and self._cap and self._cap.isOpened():
            ret, frame = self._cap.read()
            if ret:
                frame = cv2.flip(frame, 1)
                with self._lock:
                    self._frame = frame
            else:
                break
        self._running = False
