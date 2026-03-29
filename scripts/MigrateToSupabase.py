import sqlite3
import os
import sys

# Add the project root to sys.path to resolve 'core' module
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.SupabaseDB import SupabaseDB
from dotenv import load_dotenv

load_dotenv()

def migrate():
    SQLITE_DB = os.path.join("data", "attendance.db")
    if not os.path.exists(SQLITE_DB):
        print("SQLite Database not found at data/attendance.db")
        return

    print("--- Starting Migration to Supabase ---")
    
    # 1. Connect to Local SQLite
    conn = sqlite3.connect(SQLITE_DB)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # 2. Connect to Supabase
    try:
        sb = SupabaseDB()
    except Exception as e:
        print(f"Error connecting to Supabase: {e}")
        return

    # 3. Migrate Students
    print("Migrating Students...")
    cursor.execute("SELECT * FROM students")
    for row in cursor.fetchall():
        sb.add_student(
            roll_no=row["roll_no"], 
            name=row["name"], 
            class_name=row["class_name"], 
            department=row["department"]
        )
    
    # 4. Migrate Attendance
    print("Migrating Attendance Records...")
    cursor.execute("SELECT * FROM attendance")
    for row in cursor.fetchall():
        data = {
            "roll_no": row["roll_no"],
            "name": row["name"],
            "class_name": row["class_name"],
            "department": row["department"],
            "similarity": row["similarity"],
            "date": row["date"],
            "time": row["time"]
        }
        try:
            sb.client.table("attendance").insert(data).execute()
        except:
            pass # Skips if duplicate or error

    print("--- Migration Finished Successfully ---")
    conn.close()

if __name__ == "__main__":
    migrate()
