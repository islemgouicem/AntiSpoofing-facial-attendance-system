"""Anti-spoofing liveness detection service."""

import os
import sys
import cv2
import numpy as np

# Add antispoffing directory so its internal imports (src.*) resolve correctly.
if not getattr(sys, 'frozen', False):
    _BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    _PROJECT_DIR = os.path.dirname(_BASE_DIR)
    _ANTISPOOF_DIR = os.path.join(_PROJECT_DIR, "antispoffing")
    if _ANTISPOOF_DIR not in sys.path:
        sys.path.insert(0, _ANTISPOOF_DIR)

from src.anti_spoof_predict import AntiSpoofPredict
from src.generate_patches import CropImage
from src.utility import parse_model_name


class AntiSpoofService:
    def __init__(self, model_dir: str, device_id: int = 0):
        self.model_dir = model_dir
        self._predictor = AntiSpoofPredict(device_id)
        self._cropper = CropImage()

    def check(self, frame) -> bool:
        """Return True if the face is real, False if spoof or error."""
        try:
            h, w = frame.shape[:2]
            new_w = int(h * 3 / 4)
            image = cv2.resize(frame, (new_w, h))

            image_bbox = self._predictor.get_bbox(image)
            prediction = np.zeros((1, 3))

            for model_name in os.listdir(self.model_dir):
                h_input, w_input, model_type, scale = parse_model_name(model_name)
                param = {
                    "org_img": image,
                    "bbox": image_bbox,
                    "scale": scale,
                    "out_w": w_input,
                    "out_h": h_input,
                    "crop": scale is not None,
                }
                img = self._cropper.crop(**param)
                prediction += self._predictor.predict(
                    img, os.path.join(self.model_dir, model_name)
                )

            label = int(np.argmax(prediction))
            return label == 1
        except Exception as e:
            print(f"[AntiSpoof] error: {e}")
            return False
