# 🎓 EDU_GUARD - AI Biometric Attendance Suite 🛡️

**EDU_GUARD Obsidian** is a state-of-the-art, high-performance student attendance and management platform. Powered by **InsightFace (Buffalo_L)** and **FastAPI**, it delivers sub-second facial recognition, real-time visual analytics, and cloud-synchronized data integrity via **Supabase**.

---

## 🌌 The Obsidian Experience
*   **True-Black UI**: A premium, high-contrast dark mode designed for professional OLED displays.
*   **Unified Shared Viewport**: Stable hardware-management using a single, persistent camera stream across all modules.
*   **Visual Analytics**: Real-time insights into institutional engagement with glowing interactive charts and stats.
*   **Session Persistence**: Institutional-grade login caching ensures administrators stay logged in throughout their shift.
*   **Manual Confirmation**: Scanner HUD requires manual "Mark as Present" triggers for 100% data accuracy.

---

## 🛠️ Tech Stack
*   **AI Engine**: InsightFace (Buffalo_L), ONNX Runtime, OpenCV.
*   **Backend**: FastAPI (Python), Uvicorn.
*   **Database**: Supabase (Postgres Cloud).
*   **Frontend**: Flutter (Web), Google Fonts, Animate Do, Lucide Icons.

---

## 📥 Getting Started

### 1. Database Setup (Supabase)
1.  Create a new project on [Supabase](https://supabase.com).
2.  Run the SQL commands from `SUPABASE_SCHEMA.sql` in your Supabase SQL Editor to initialize the `students` and `attendance` tables.
3.  Copy your **SUPABASE_URL** and **SUPABASE_KEY** from the Project Settings -> API.

### 2. Backend Initialization
```bash
# Clone the repository
git clone https://github.com/harshshirke66/Face-Recognition-Student-Attendance-System.git
cd Face-Recognition-Student-Attendance-System

# Create virtual environment
python -m venv venv
# Activate on Windows: .\venv\Scripts\activate
# Activate on Linux/Mac: source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Pre-download AI models (One-time warmup)
python warmup.py
```

### 3. Frontend Installation
```bash
# Navigate to the Admin Portal
cd attendance_admin
flutter pub get

# Navigate to the Student Dashboard (Optional)
cd ../attendance_student
flutter pub get
```

---

## 🚦 How to Run

### 1. Start the AI Server
```bash
python server.py
# Server will run at http://localhost:8000
```

### 2. Launch the Admin Portal
```bash
cd attendance_admin
flutter run -d chrome --web-port 8080
```

---

## 📂 Project Structure
```
.
├── core/                # AI & Database Hub (Embedding, Inference, Supabase)
├── attendance_admin/    # Flutter Dashboard (Scanner, Directory, Insights)
├── attendance_student/  # Flutter Student View (Personal Records)
├── server.py            # FastAPI Entry Point
├── warmup.py            # Model-Caching Service
├── SUPABASE_SCHEMA.sql  # Database Initialization Script
└── requirements.txt     # Production Dependencies
```

---

## 🔐 Security & Persistence
*   **Secrets**: All API keys and environment variables are strictly managed via `.env` files and shielded from Git tracking.
*   **Integrity**: The system strictly ignores "Unknown" faces for attendance markers, requiring manual administrative overrides for unregistered guests.

---

## 🛡️ License
Built for educational excellence and institutional security.
