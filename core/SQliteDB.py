import sqlite3
from datetime import datetime, date


class DatabaseManager:

    def __init__(self, path):
        self.path = path
        self.connection = sqlite3.connect(path, check_same_thread=False)
        self.connection.row_factory = sqlite3.Row
        self.cursor = self.connection.cursor()
        self._create_tables()

    def _create_tables(self):
        # Students table
        self.cursor.execute("""
        CREATE TABLE IF NOT EXISTS students (
            roll_no TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            class_name TEXT NOT NULL,
            department TEXT NOT NULL,
            enrolled_at DATETIME DEFAULT (datetime('now','localtime'))
        )
        """)

        # Attendance records table
        self.cursor.execute("""
        CREATE TABLE IF NOT EXISTS attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            roll_no TEXT NOT NULL,
            name TEXT NOT NULL,
            class_name TEXT NOT NULL,
            department TEXT NOT NULL,
            similarity REAL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            timestamp DATETIME DEFAULT (datetime('now','localtime')),
            FOREIGN KEY (roll_no) REFERENCES students(roll_no)
        )
        """)

        self.connection.commit()

    # ---- Students ----

    def add_student(self, roll_no, name, class_name, department):
        try:
            self.cursor.execute(
                "INSERT OR REPLACE INTO students (roll_no, name, class_name, department) VALUES (?, ?, ?, ?)",
                (roll_no, name, class_name, department)
            )
            self.connection.commit()
            return True
        except Exception as e:
            print(f"[ERROR] add_student: {e}")
            return False

    def get_all_students(self):
        self.cursor.execute("SELECT * FROM students ORDER BY class_name, roll_no")
        return [dict(r) for r in self.cursor.fetchall()]

    def get_student(self, roll_no):
        self.cursor.execute("SELECT * FROM students WHERE roll_no=?", (roll_no,))
        row = self.cursor.fetchone()
        return dict(row) if row else None

    def delete_student(self, roll_no):
        self.cursor.execute("DELETE FROM students WHERE roll_no=?", (roll_no,))
        self.cursor.execute("DELETE FROM attendance WHERE roll_no=?", (roll_no,))
        self.connection.commit()

    # ---- Attendance ----

    def mark_attendance(self, roll_no, name, class_name, department, similarity):
        today = date.today().strftime("%Y-%m-%d")
        now = datetime.now().strftime("%H:%M:%S")

        # Prevent duplicate attendance for same student on same day
        self.cursor.execute(
            "SELECT id FROM attendance WHERE roll_no=? AND date=?",
            (roll_no, today)
        )
        existing = self.cursor.fetchone()
        if existing:
            return False, "already_marked"

        self.cursor.execute(
            "INSERT INTO attendance (roll_no, name, class_name, department, similarity, date, time) VALUES (?,?,?,?,?,?,?)",
            (roll_no, name, class_name, department, similarity, today, now)
        )
        self.connection.commit()
        return True, "marked"

    def get_attendance(self, date_filter=None, class_filter=None, dept_filter=None, limit=100):
        query = "SELECT * FROM attendance WHERE 1=1"
        params = []
        if date_filter:
            query += " AND date=?"
            params.append(date_filter)
        if class_filter:
            query += " AND class_name=?"
            params.append(class_filter)
        if dept_filter:
            query += " AND department=?"
            params.append(dept_filter)
        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)
        self.cursor.execute(query, params)
        return [dict(r) for r in self.cursor.fetchall()]

    def get_today_attendance(self):
        today = date.today().strftime("%Y-%m-%d")
        self.cursor.execute(
            "SELECT * FROM attendance WHERE date=? ORDER BY timestamp DESC",
            (today,)
        )
        return [dict(r) for r in self.cursor.fetchall()]

    def get_today_stats(self):
        today = date.today().strftime("%Y-%m-%d")
        self.cursor.execute("SELECT COUNT(*) as total FROM students")
        total = self.cursor.fetchone()["total"]

        self.cursor.execute("SELECT COUNT(*) as present FROM attendance WHERE date=?", (today,))
        present = self.cursor.fetchone()["present"]

        return {
            "total_students": total,
            "present": present,
            "absent": total - present,
            "date": today
        }

    def get_student_attendance_summary(self, roll_no):
        self.cursor.execute(
            "SELECT COUNT(*) as days FROM attendance WHERE roll_no=?",
            (roll_no,)
        )
        days = self.cursor.fetchone()["days"]
        return {"roll_no": roll_no, "total_days_present": days}

    def clear_attendance(self, date_filter=None):
        if date_filter:
            self.cursor.execute("DELETE FROM attendance WHERE date=?", (date_filter,))
        else:
            self.cursor.execute("DELETE FROM attendance")
        self.connection.commit()

    def close(self):
        self.connection.close()