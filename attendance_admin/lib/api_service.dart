import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<List<dynamic>> fetchTodayAttendance() async {
    final response = await http.get(Uri.parse('$baseUrl/attendance/today'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchStats() async {
    final response = await http.get(Uri.parse('$baseUrl/attendance/stats'));
    if (response.statusCode == 200) return json.decode(response.body);
    return {'total_students': 0, 'present': 0, 'absent': 0};
  }

  static Future<List<dynamic>> fetchWeeklyStats() async {
    final response = await http.get(Uri.parse('$baseUrl/attendance/weekly_stats'));
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  static Future<List<dynamic>> fetchAttendanceByDate(String date) async {
    final response = await http.get(Uri.parse('$baseUrl/attendance?date=$date'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> fetchStudentAttendance(String rollNo) async {
    final response = await http.get(Uri.parse('$baseUrl/attendance/student/$rollNo'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> detectFace(List<int> bytes) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/detect'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'frame.jpg'));
    
    var response = await request.send();
    if (response.statusCode == 200) {
      var body = await response.stream.bytesToString();
      return json.decode(body);
    }
    return {'detected': false};
  }

  static Future<bool> markAttendance(Map<String, dynamic> data) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/attendance/mark'));
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    
    var response = await request.send();
    return response.statusCode == 200;
  }

  static Future<bool> captureStudentSample(Map<String, String> data, List<int> bytes) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/students/capture'));
    data.forEach((key, value) {
      request.fields[key] = value;
    });
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'snap.jpg'));
    
    var response = await request.send();
    return response.statusCode == 200;
  }

  static Future<bool> registerStudent(Map<String, String> data) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/students/register'));
    data.forEach((key, value) {
      request.fields[key] = value;
    });
    
    var response = await request.send();
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> fetchAllStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/students'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  static Future<bool> deleteStudent(String rollNo) async {
    final response = await http.delete(Uri.parse('$baseUrl/students/$rollNo'));
    return response.statusCode == 200;
  }

  static Future<bool> deleteAttendance(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/attendance/$id'));
    return response.statusCode == 200;
  }
}
