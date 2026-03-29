# 🎓 EduGuard - Smart AI Attendance System 🛡️

EduGuard is a professional-grade, enterprise-ready student attendance system that leverages **Deep Learning (InsightFace)** and **FastAPI** to provide real-time facial recognition, **Multi-Modal Liveness Detection**, and **Cloud Synchronization (Supabase)**.

## 🚀 Key Features

- **🛡️ Multi-Modal Liveness Protection**: High-security anti-spoofing that detects **Blinks** and **Head Movements (Yaw)** to prevent photo/video spoofing.
- **☁️ Supabase Cloud Integration**: Real-time identification and attendance logging synchronized to the cloud.
- **🔄 Smart Identification**: High-fidelity facial vector matching (50 samples per student) for sub-second recognition.
- **📄 CSV Attendance Export**: Export daily or historical attendance records to Excel-ready CSV files with a single click.
- **📊 Real-time Dashboard**: Dynamic stats tracking showing today's attendance, department-wise breakdowns, and live scan feeds.
- **⚡ Pro UI/UX**: Premium, high-contrast dashboard built with **React**, **Tailwind CSS**, and **Framer Motion**.

## 🛠️ Tech Stack

- **Backend**: FastAPI (Python), InsightFace (AI Engine), OpenCV, Supabase.
- **Frontend**: React (Vite), Tailwind CSS, Framer Motion, Lucide Icons.
- **Database**: Supabase (PostgreSQL Cloud).

---

## 📥 Getting Started

### 1. Prerequisites
- **Python 3.10+** (Recommend 3.11 for performance).
- **Node.js** (v18+).
- **Supabase Account** (Create a project and get your URL/Key).

### 2. Environment Setup
Create a `.env` file in the project root with the following:
```env
SUPABASE_URL=your_project_url
SUPABASE_KEY=your_anon_key
```

### 3. Backend Installation
```bash
# Create and activate virtual environment
python -m venv face_env
source face_env/bin/activate  # Windows: .\face_env\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 4. Frontend Installation
```bash
cd frontend
npm install
```

---

## 🚦 How to Run

1. **Start Backend**: `python server.py` (Starts at `http://localhost:8000`)
2. **Start Frontend**: `cd frontend && npm run dev` (Starts at `http://localhost:5173`)

---

## 📂 Project Structure
```
Face_Recognition_System-main/
├── core/               # AI Engine & Logic
│   ├── Embedding.py    # Facial Vector Generation
│   ├── Inference.py    # Face Matching & Liveness Check
│   └── SupabaseDB.py   # Cloud Database Hub
├── data/               # Local data & Snapshot Cache
├── frontend/           # React App (Tailwind UI)
├── server.py           # FastAPI REST Endpoints
└── requirements.txt    # Python Dependencies
```

## 🔐 Security Note
The system uses **EAR (Eye Aspect Ratio)** and **Yaw Estimation** to ensure that only a physically present human can mark attendance. Users are required to **Blink** or **Turn their head** side-to-side to unlock the attendance button.

---

## ⚠️ Troubleshooting
- **No Face Found**: Enhance lighting or ensure the camera is at eye level.
- **Liveness Stuck**: Perform a deliberate slow blink or move your head clearly left-to-right to trigger verification.
- **Supabase Error**: Check your `.env` formatting and network connection.
