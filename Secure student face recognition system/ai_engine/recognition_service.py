"""Face recognition service using the face_recognition library."""

import os
import pickle
import face_recognition
import numpy as np


class RecognitionService:
    def __init__(self, db_dir: str):
        self.db_dir = db_dir
        os.makedirs(db_dir, exist_ok=True)
        self._embeddings_cache: dict[str, np.ndarray] = {}
        self._load_embeddings()

    def _load_embeddings(self):
        self._embeddings_cache.clear()
        for filename in sorted(os.listdir(self.db_dir)):
            if filename.endswith(".pickle"):
                name = filename[:-7]
                path = os.path.join(self.db_dir, filename)
                with open(path, "rb") as f:
                    self._embeddings_cache[name] = pickle.load(f)

    def recognize(self, frame):
        """Recognize a face. Returns (name, confidence) or None."""
        encodings = face_recognition.face_encodings(frame)
        if len(encodings) == 0:
            return None

        unknown_encoding = encodings[0]
        if not self._embeddings_cache:
            return ("unknown_person", 0.0)

        names = list(self._embeddings_cache.keys())
        known = list(self._embeddings_cache.values())
        distances = face_recognition.face_distance(known, unknown_encoding)
        min_idx = int(np.argmin(distances))
        min_dist = float(distances[min_idx])

        if min_dist < 0.6:
            return (names[min_idx], round(1.0 - min_dist, 3))
        return ("unknown_person", 0.0)

    def register(self, frame, name: str) -> bool:
        encodings = face_recognition.face_encodings(frame)
        if len(encodings) == 0:
            return False
        embedding = encodings[0]
        path = os.path.join(self.db_dir, f"{name}.pickle")
        with open(path, "wb") as f:
            pickle.dump(embedding, f)
        self._embeddings_cache[name] = embedding
        return True

    def list_students(self) -> list[str]:
        return list(self._embeddings_cache.keys())

    def delete_student(self, name: str) -> bool:
        path = os.path.join(self.db_dir, f"{name}.pickle")
        if os.path.exists(path):
            os.remove(path)
            self._embeddings_cache.pop(name, None)
            return True
        return False
