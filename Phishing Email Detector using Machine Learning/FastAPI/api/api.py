"""
api.py — PhishGuard local FastAPI server
────────────────────────────────────────
Run from the folder that CONTAINS this file:

    cd path/to/your/extension_or_api_folder
    uvicorn api:app --reload --port 8000 --host 127.0.0.1
"""

import os
from pathlib import Path
from fastapi import FastAPI
from pydantic import BaseModel
import re
import joblib
from fastapi.middleware.cors import CORSMiddleware
