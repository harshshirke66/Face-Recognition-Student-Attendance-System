import os
from datetime import datetime, date
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

class SupabaseDB:
    def __init__(self):
        url: str = os.environ.get("SUPABASE_URL")
        key: str = os.environ.get("SUPABASE_KEY")
        if not url or not key:
            raise ValueError("SUPABASE_URL and SUPABASE_KEY must be set in environment variables")
        self.client: Client = create_client(url, key)

    # ---- Students ----

    def add_student(self, roll_no, name, class_name, department, email=None, phone_no=None):
        try:
            data = {
                "roll_no": roll_no,
                "name": name,
                "class_name": class_name,
                "department": department,
                "email": email,
                "phone_no": phone_no,
                "enrolled_at": datetime.now().isoformat()
            }
            # upsert based on roll_no
            self.client.table("students").upsert(data, on_conflict="roll_no").execute()
            return True
        except Exception as e:
            print(f"[ERROR] add_student: {e}")
            return False

    def get_all_students(self):
        try:
            response = self.client.table("students").select("*").order("class_name").order("roll_no").execute()
            return response.data
        except Exception as e:
            print(f"[ERROR] get_all_students: {e}")
            return []

    def get_student(self, roll_no):
        try:
            response = self.client.table("students").select("*").eq("roll_no", roll_no).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"[ERROR] get_student: {e}")
            return None

    def get_student_by_email(self, email):
        try:
            response = self.client.table("students").select("*").eq("email", email).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"[ERROR] get_student_by_email: {e}")
            return None

    def verify_student_login(self, email, phone):
        try:
            response = self.client.table("students").select("*").eq("email", email).eq("phone_no", phone).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"[ERROR] verify_student_login: {e}")
            return None

    def delete_student(self, roll_no):
        try:
            # Delete attendance first (if not cascading)
            self.client.table("attendance").delete().eq("roll_no", roll_no).execute()
            self.client.table("students").delete().eq("roll_no", roll_no).execute()
            return True
        except Exception as e:
            print(f"[ERROR] delete_student: {e}")
            return False

    def is_attendance_marked(self, roll_no, date_str):
        try:
            res = self.client.table("attendance").select("id").eq("roll_no", roll_no).eq("date", date_str).execute()
            return len(res.data) > 0
        except Exception as e:
            print(f"[ERROR] is_attendance_marked: {e}")
            return False

    # ---- Attendance ----

    def mark_attendance(self, roll_no, name, class_name, department, similarity):
        today = date.today().strftime("%Y-%m-%d")
        now = datetime.now().strftime("%H:%M:%S")

        try:
            # Prevent duplicate attendance for same student on same day
            check = self.client.table("attendance").select("id").eq("roll_no", roll_no).eq("date", today).execute()
            if check.data:
                return False, "already_marked"

            data = {
                "roll_no": roll_no,
                "name": name,
                "class_name": class_name,
                "department": department,
                "similarity": similarity,
                "date": today,
                "time": now
            }
            self.client.table("attendance").insert(data).execute()
            return True, "marked"
        except Exception as e:
            print(f"[ERROR] mark_attendance: {e}")
            return False, "error"

    def get_attendance(self, date_filter=None, class_filter=None, dept_filter=None, limit=100):
        try:
            query = self.client.table("attendance").select("*")
            if date_filter:
                query = query.eq("date", date_filter)
            if class_filter:
                query = query.eq("class_name", class_filter)
            if dept_filter:
                query = query.eq("department", dept_filter)
            
            response = query.order("timestamp", desc=True).limit(limit).execute()
            return response.data
        except Exception as e:
            print(f"[ERROR] get_attendance: {e}")
            return []

    def get_today_attendance(self):
        today = date.today().strftime("%Y-%m-%d")
        return self.get_attendance(date_filter=today)

    def get_today_stats(self):
        today = date.today().strftime("%Y-%m-%d")
        try:
            total_res = self.client.table("students").select("roll_no", count="exact").execute()
            total = total_res.count if total_res.count is not None else 0

            present_res = self.client.table("attendance").select("id", count="exact").eq("date", today).execute()
            present = present_res.count if present_res.count is not None else 0

            return {
                "total_students": total,
                "present": present,
                "absent": total - present,
                "date": today
            }
        except Exception as e:
            print(f"[ERROR] get_today_stats: {e}")
            return {"error": str(e)}

    def get_weekly_stats(self):
        try:
            # We want stats for last 7 dates
            from datetime import timedelta
            end_date = date.today()
            start_date = end_date - timedelta(days=6)
            
            res = self.client.table("attendance").select("date", "roll_no").gte("date", start_date.strftime("%Y-%m-%d")).execute()
            data = res.data or []
            
            # Aggregate counts per day
            stats = {}
            for i in range(7):
                d = (start_date + timedelta(days=i)).strftime("%Y-%m-%d")
                stats[d] = 0
                
            for record in data:
                d = record['date']
                if d in stats:
                    stats[d] += 1
            
            # Format for charts
            chart_data = []
            for d in sorted(stats.keys()):
                chart_data.append({"date": d, "present": stats[d]})
            return chart_data
        except Exception as e:
            print(f"[ERROR] get_weekly_stats: {e}")
            return []

    def delete_attendance_record(self, record_id):
        try:
            self.client.table("attendance").delete().eq("id", record_id).execute()
            return True
        except Exception as e:
            print(f"[ERROR] delete_attendance_record: {e}")
            return False

    def clear_attendance(self, date_filter=None):
        try:
            query = self.client.table("attendance").delete()
            if date_filter:
                query = query.eq("date", date_filter)
            else:
                # To delete all rows safely in Supabase, you might need a different approach or a filter that matches all
                query = query.neq("id", -1) 
            query.execute()
            return True
        except Exception as e:
            print(f"[ERROR] clear_attendance: {e}")
            return False

    def get_student_attendance_history(self, roll_no):
        try:
            response = self.client.table("attendance").select("*").eq("roll_no", roll_no).order("date", desc=True).execute()
            return response.data
        except Exception as e:
            print(f"[ERROR] get_student_attendance_history: {e}")
            return []

    def close(self):
        # Supabase client doesn't need explicit closing in the same way as sqlite3
        pass
