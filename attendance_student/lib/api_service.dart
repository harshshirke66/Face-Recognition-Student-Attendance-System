import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://face-recognition-student-attendance-system-production.up.railway.app';

  static Future<List<dynamic>> fetchTodayAttendance() async {
    final response = await http.get(Uri.parse('$baseUrl/attendance/today'));
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

  static Future<Map<String, dynamic>?> studentLogin(String email, String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/students/login'),
      body: {'email': email, 'phone': phone},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
