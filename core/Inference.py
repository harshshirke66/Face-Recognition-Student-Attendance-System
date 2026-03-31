import os
import numpy as np
from insightface.app import FaceAnalysis

# -------- Load Buffalo Engine ONCE --------
app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
app.prepare(ctx_id=0, det_size=(640, 640))

# Cosine similarity - Higher is more identical
MATCH_THRESHOLD = 0.40
EAR_THRESHOLD = 0.18 

def calculate_ear(landmarks):
    def get_group_ear(group):
        min_p = np.min(group, axis=0)
        max_p = np.max(group, axis=0)
        width = max_p[0] - min_p[0]
        height = max_p[1] - min_p[1]
        return height / (width + 1e-6)
    return float((get_group_ear(landmarks[36:42]) + get_group_ear(landmarks[42:48])) / 2.0)

def calculate_yaw(landmarks):
    nose_x = landmarks[30][0]
    return float(abs(nose_x - np.min(landmarks[:, 0])) / (abs(np.max(landmarks[:, 0]) - nose_x) + 1e-6))

def load_embeddings(root_dir):
    User_ID, names, embeddings = [], [], []
    if not os.path.exists(root_dir): return [], None, []
    
    for person in os.listdir(root_dir):
        person_dir = os.path.join(root_dir, person)
        if not os.path.isdir(person_dir): continue
        parts = person.split("_", 1)
        if len(parts) != 2: continue
        
        for file in os.listdir(person_dir):
            if file.endswith(".npy"):
                try:
                    # Flatten ensures it works even if dimensions are nested
                    emb = np.load(os.path.join(person_dir, file), allow_pickle=True).flatten().astype(np.float32)
                    if emb.shape[0] == 512:
                        emb = emb / (np.linalg.norm(emb) + 1e-8)
                        embeddings.append(emb)
                        names.append(parts[1])
                        User_ID.append(parts[0])
                    else:
                        print(f"[WARN] Incompatible file size {emb.size} for {parts[1]}. Removing or Re-registering recommended.")
                except Exception as e:
                    print(f"[ERROR] Failed to load {file}: {e}")
                    
    if not embeddings: return [], None, []
    return names, np.vstack(embeddings), User_ID


class FaceMatcher:
    def __init__(self, emb_root):
        self.emb_root = emb_root
        self.reload()

    def reload(self):
        self.names, self.db_embs, self.User_IDs = load_embeddings(self.emb_root)

    def match(self, frame):
        if frame is None: return None, None, None, None, False
        try:
            # AUTO-RELOAD: If no records, try to reload once
            if not self.names or self.db_embs is None:
                self.reload()

            # Use original full-resolution detection for better accuracy locally
            faces = app.get(frame)
            if not faces: return None, None, None, None, False
            
            face = faces[0]
            liveness_detected = False
            landmarks = getattr(face, 'landmark_3d_68', None)
            if landmarks is not None:
                liveness_detected = calculate_ear(landmarks) < EAR_THRESHOLD or calculate_yaw(landmarks) > 1.3
            
            test_emb = face.normed_embedding.flatten().astype(np.float32)
            test_emb = test_emb / (np.linalg.norm(test_emb) + 1e-8)
            bbox = face.bbox.astype(int).tolist()

            if self.db_embs is None or len(self.names) == 0:
                return 0.1, "No compatible records", bbox, None, False

            # Similarity - Shape (N,)
            sims = np.dot(self.db_embs, test_emb)
            best_idx = int(np.argmax(sims))
            similarity = float(sims[best_idx])

            if similarity < MATCH_THRESHOLD:
                return similarity, "Unknown", bbox, None, liveness_detected

            return similarity, self.names[best_idx], bbox, self.User_IDs[best_idx], liveness_detected

        except Exception as e:
            print(f"[ERROR] Inference error: {e}")
            return None, None, None, None, False
