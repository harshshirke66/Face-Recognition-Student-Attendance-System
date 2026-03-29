import os
import cv2
import numpy as np
from insightface.app import FaceAnalysis

# Buffalo_L for 512-D embeddings
app = FaceAnalysis(name='buffalo_l')
app.prepare(ctx_id=0, det_size=(640, 640))

def Embedding(img_or_path):
    """
    Generate face embedding using Buffalo_L.
    Supports both a single image (array) or a directory path (string).
    """
    try:
        if isinstance(img_or_path, str) and os.path.isdir(img_or_path):
            embeddings = []
            for file in os.listdir(img_or_path):
                # Only process actual images
                if not file.lower().endswith(('.jpg', '.jpeg', '.png')):
                    continue
                                    
                path = os.path.join(img_or_path, file)
                img = cv2.imread(path)
                
                # Verify we actually loaded an image (array)
                if img is not None and hasattr(img, 'shape'):
                    faces = app.get(img)
                    if faces:
                        embeddings.append(faces[0].normed_embedding.flatten())
            
            if not embeddings:
                return None
            return np.mean(embeddings, axis=0).astype(np.float32)
            
        elif hasattr(img_or_path, 'shape'):
            # Single image mode (Numpy array)
            faces = app.get(img_or_path)
            if not faces:
                return None
            return faces[0].normed_embedding.flatten().astype(np.float32)
        
        else:
            print(f"[WARN] Invalid input to Embedding: {type(img_or_path)}")
            return None

    except Exception as e:
        print(f"[ERROR] Embedding generation failed: {e}")
        return None