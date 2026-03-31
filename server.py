import os
import shutil
import cv2
import numpy as np
from datetime import date
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import StreamingResponse
import io
import csv
from fastapi.middleware.cors import CORSMiddleware
from core.Embedding import Embedding as generate_embedding
from core.Inference import FaceMatcher
from core.SupabaseDB import SupabaseDB as DatabaseManager
# from core.SQliteDB import DatabaseManager # Deprecated (SQLite)

app = FastAPI(title="Student Attendance System API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
REG_DIR = os.path.join(DATA_DIR, "Registration")
EMB_DIR = os.path.join(DATA_DIR, "embeddings")
DB_PATH = os.path.join(DATA_DIR, "attendance.db")

os.makedirs(REG_DIR, exist_ok=True)
os.makedirs(EMB_DIR, exist_ok=True)

matcher = FaceMatcher(EMB_DIR)
db = DatabaseManager()


@app.get("/")
async def root():
    return {"message": "Student Attendance System API is running"}


# -------- Face Detection --------

@app.post("/detect")
async def detect_face(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if image is None:
        return {"detected": False}

    similarity, name, bbox, user_id, eyes_closed = matcher.match(image)

    if bbox is not None and name is not None and name != "Unknown":
        x1, y1, x2, y2 = [int(v) for v in bbox]
        student = db.get_student(str(user_id)) if user_id else None

        # Check if already marked today
        already_marked = False
        if user_id:
            today = date.today().strftime("%Y-%m-%d")
            already_marked = db.is_attendance_marked(str(user_id), today)

        return {
            "detected": True,
            "roll_no": str(user_id) if user_id else None,
            "name": str(name),
            "similarity": float(similarity),
            "bbox": [x1, y1, x2, y2],
            "class_name": student["class_name"] if student else None,
            "department": student["department"] if student else None,
            "already_marked": already_marked,
            "eyes_closed": eyes_closed
        }

    return {"detected": False, "message": "Match not found", "eyes_closed": eyes_closed}


# -------- Attendance Operations --------

@app.post("/attendance/mark")
async def mark_attendance(
    roll_no: str = Form(...),
    name: str = Form(...),
    class_name: str = Form(...),
    department: str = Form(...),
    similarity: float = Form(...),
):
    success, status = db.mark_attendance(roll_no, name, class_name, department, similarity)
    if status == "already_marked":
        return {"status": "already_marked", "message": f"{name} attendance already marked today"}
    return {"status": "success", "message": f"Attendance marked for {name}"}


# -------- Attendance History --------

@app.get("/attendance")
async def get_attendance(date: str = None, class_name: str = None, department: str = None):
    records = db.get_attendance(date_filter=date, class_filter=class_name, dept_filter=department)
    return records


@app.get("/attendance/today")
async def get_today_attendance():
    return db.get_today_attendance()


@app.get("/attendance/student/{roll_no}")
async def get_student_attendance(roll_no: str):
    return db.get_student_attendance_history(roll_no)


@app.get("/attendance/stats")
async def get_stats():
    return db.get_today_stats()


@app.get("/attendance/weekly_stats")
async def get_weekly_stats():
    return db.get_weekly_stats()


@app.delete("/attendance")
async def clear_attendance(date: str = None):
    db.clear_attendance(date_filter=date)
    return {"status": "success", "message": "Attendance cleared"}


@app.delete("/attendance/{record_id}")
async def delete_attendance_record(record_id: str):
    db.delete_attendance_record(record_id)
    return {"status": "success", "message": f"Record {record_id} removed"}


@app.get("/attendance/export")
async def export_attendance(date: str = None):
    records = db.get_attendance(date_filter=date, limit=1000)
    
    if not records:
        raise HTTPException(status_code=404, detail="No records found to export")
        
    output = io.StringIO()
    fieldnames = ["roll_no", "name", "class_name", "department", "date", "time", "similarity"]
    writer = csv.DictWriter(output, fieldnames=fieldnames, extrasaction='ignore')
    writer.writeheader()
    writer.writerows(records)
    
    # Convert string stream to bytes for download
    csv_bytes = output.getvalue().encode("utf-8-sig")
    
    filename = f"attendance_{date if date else 'all'}.csv"
    
    return StreamingResponse(
        io.BytesIO(csv_bytes),
        media_type="text/csv",
        headers={
            "Content-Disposition": f"attachment; filename={filename}",
            "Access-Control-Expose-Headers": "Content-Disposition"
        }
    )


# -------- Student Registration --------

@app.post("/students/capture")
async def capture_for_registration(
    name: str = Form(...),
    roll_no: str = Form(...),
    class_name: str = Form(...),
    department: str = Form(...),
    count: int = Form(...),
    file: UploadFile = File(...),
    email: str = Form(None),
    phone_no: str = Form(None),
):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if image is None:
        raise HTTPException(status_code=400, detail="Invalid image")

    name = name.strip()
    roll_no = roll_no.strip()
    filename = f"{roll_no}_{count}.jpg"
    cv2.imwrite(os.path.join(REG_DIR, filename), image)

    return {"status": "success", "count": count}


@app.post("/students/register")
async def finalize_registration(
    name: str = Form(...),
    roll_no: str = Form(...),
    class_name: str = Form(...),
    department: str = Form(...),
    email: str = Form(...),
    phone_no: str = Form(...),
):
    name = name.strip()
    roll_no = roll_no.strip()
    try:
        # Check how many photos were captured
        photos = [f for f in os.listdir(REG_DIR) if f.startswith(f"{roll_no}_")]
        if len(photos) < 5:
            raise HTTPException(
                status_code=400,
                detail=f"Only {len(photos)} photos captured. Need at least 5 with a visible face."
            )

        emb = generate_embedding(REG_DIR)

        person_dir = os.path.join(EMB_DIR, f"{roll_no}_{name}")
        os.makedirs(person_dir, exist_ok=True)
        np.save(os.path.join(person_dir, f"{roll_no}_{name}_embedding.npy"), emb)

        # Save to database
        db.add_student(roll_no, name, class_name, department, email=email, phone_no=phone_no)

        # Cleanup registration images
        shutil.rmtree(REG_DIR, ignore_errors=True)
        os.makedirs(REG_DIR, exist_ok=True)

        # Reload matcher
        matcher.reload()

        return {"status": "success", "message": f"Student '{name}' (Roll: {roll_no}) registered successfully!"}

    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Registration failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/students/login")
async def student_login(email: str = Form(...), phone: str = Form(...)):
    student = db.verify_student_login(email, phone)
    if student:
        return {"status": "success", "student": student}
    else:
        raise HTTPException(status_code=401, detail="Invalid Email or Phone")

@app.get("/students")
async def get_all_students():
    return db.get_all_students()


@app.delete("/students/{roll_no}")
async def delete_student(roll_no: str):
    # Remove embedding folder
    for folder in os.listdir(EMB_DIR):
        if folder.startswith(f"{roll_no}_"):
            shutil.rmtree(os.path.join(EMB_DIR, folder), ignore_errors=True)
    db.delete_student(roll_no)
    matcher.reload()
    return {"status": "success", "message": f"Student {roll_no} removed"}


if __name__ == "__main__":
    import uvicorn
    import os
    # Railway/Cloud providers provide a PORT environment variable
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
