# <img src="https://img.shields.io/badge/EDU__GUARD-OBSIDIAN-00d4ff?style=for-the-badge&labelColor=000000&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0iIzAwZDRmZiIgZD0iTTEyIDJMMyA3djVjMCA1LjU1IDMuODQgMTAuNzQgOSAxMiA1LjE2LTEuMjYgOS02LjQ1IDktMTJWN2wtOS01eiIvPjwvc3ZnPg==" alt="EDU_GUARD OBSIDIAN" />

<div align="center">

```
███████╗██████╗ ██╗   ██╗     ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗
██╔════╝██╔══██╗██║   ██║    ██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗
█████╗  ██║  ██║██║   ██║    ██║  ███╗██║   ██║███████║██████╔╝██║  ██║
██╔══╝  ██║  ██║██║   ██║    ██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║
███████╗██████╔╝╚██████╔╝    ╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
╚══════╝╚═════╝  ╚═════╝      ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
```

**AI Biometric Attendance Suite — Obsidian Edition**

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![ONNX](https://img.shields.io/badge/ONNX_Runtime-005CED?style=flat-square&logo=onnx&logoColor=white)](https://onnxruntime.ai)
[![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?style=flat-square&logo=opencv&logoColor=white)](https://opencv.org)

> *Sub-second facial recognition. Real-time visual analytics. Institutional-grade security.*

</div>

---

## 🌌 The Obsidian Experience

<table>
<tr>
<td width="50%">

### 🖥️ True-Black UI
Premium, high-contrast dark mode engineered for professional OLED displays — every pixel crafted for clarity and depth.

### 📡 Unified Shared Viewport
Stable hardware management through a single, persistent camera stream shared seamlessly across all modules.

</td>
<td width="50%">

### 📊 Visual Analytics
Real-time institutional engagement insights — glowing interactive charts and live statistics at a glance.

### 🔒 Session Persistence
Institutional-grade login caching keeps administrators authenticated throughout their entire shift without interruption.

</td>
</tr>
<tr>
<td width="50%">

### ✋ Manual Confirmation
Scanner HUD demands manual **"Mark as Present"** triggers — delivering 100% data accuracy with zero false positives.

</td>
<td width="50%">

### 🧠 AI Engine
Powered by **InsightFace (Buffalo_L)** — one of the most accurate open-source face recognition models available.

</td>
</tr>
</table>

---

## 🛠️ Tech Stack

<div align="center">

| Layer | Technology | Role |
|:---:|:---:|:---|
| 🤖 **AI Engine** | InsightFace (Buffalo_L) · ONNX Runtime · OpenCV | Face embedding, inference & capture |
| ⚡ **Backend** | FastAPI · Uvicorn (Python) | High-performance async REST API |
| 🗄️ **Database** | Supabase (PostgreSQL Cloud) | Cloud-sync, real-time data integrity |
| 🎨 **Frontend** | Flutter Web · Google Fonts · Lucide Icons | Cross-platform admin & student portals |

</div>

---

## 📥 Getting Started

### Step 1 — Database Setup (Supabase)

```
1. Create a new project on https://supabase.com
2. Open the SQL Editor → run SUPABASE_SCHEMA.sql
3. Copy your credentials from Project Settings → API
```

> 💡 This initializes the `students` and `attendance` tables with all required schema.

---

### Step 2 — Backend Initialization

```bash
# Clone the repository
git clone https://github.com/harshshirke66/Face-Recognition-Student-Attendance-System.git
cd Face-Recognition-Student-Attendance-System

# Create & activate virtual environment
python -m venv venv

# Windows
.\venv\Scripts\activate

# Linux / macOS
source venv/bin/activate

# Install all dependencies
pip install -r requirements.txt

# Pre-download & cache AI models (one-time warmup)
python warmup.py
```

---

### Step 3 — Frontend Installation

```bash
# Admin Portal
cd attendance_admin
flutter pub get

# Student Dashboard (optional)
cd ../attendance_student
flutter pub get
```

---

## 🚦 Running the System

### 1 — Start the AI Server

```bash
python server.py
# → http://localhost:8000
```

### 2 — Launch the Admin Portal

```bash
cd attendance_admin
flutter run -d chrome --web-port 8080
```

---

## 📂 Project Structure

```
Face-Recognition-Student-Attendance-System/
│
├── 🧠 core/                   # AI & Database Hub
│   └── Embedding · Inference · Supabase integration
│
├── 🖥️  attendance_admin/       # Flutter Admin Dashboard
│   └── Scanner · Directory · Insights modules
│
├── 👤 attendance_student/      # Flutter Student View
│   └── Personal attendance records
│
├── ⚡ server.py                # FastAPI entry point
├── 🔥 warmup.py               # Model-caching service
├── 🗄️  SUPABASE_SCHEMA.sql     # Database initialization script
└── 📦 requirements.txt        # Production dependencies
```

---

## 🔐 Security & Integrity

<table>
<tr>
<td>

**🔑 Secret Management**
All API keys and environment variables are strictly managed via `.env` files — shielded from version control and never committed to Git.

</td>
<td>

**🛡️ Face Integrity**
The system strictly ignores **"Unknown"** faces during attendance marking. Unregistered individuals require explicit manual administrative override.

</td>
</tr>
</table>

---

## 🛡️ License

<div align="center">

Built for **educational excellence** and **institutional security**.

*EDU_GUARD Obsidian — precision attendance, powered by AI.*

</div>
