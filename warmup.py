import insightface
from insightface.app import FaceAnalysis
import os

def warmup():
    print("[INFO] Initializing Buffalo_L Model Download/Warmup...")
    try:
        # This will trigger the download of models to the server's cache (~/.insightface/models)
        app = FaceAnalysis(name='buffalo_s', root='~/.insightface')
        app.prepare(ctx_id=-1, det_size=(640, 640))
        print("[SUCCESS] Models downloaded and initialized successfully.")
    except Exception as e:
        print(f"[ERROR] Warmup failed: {e}")

if __name__ == "__main__":
    warmup()
