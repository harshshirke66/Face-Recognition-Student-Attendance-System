import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error getting cameras: $e');
    _cameras = [];
  }
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDU_GUARD Obsidian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
          surface: const Color(0xFF010101),
        ),
        useMaterial3: true,
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isAdminLoggedIn = false;
  final TextEditingController _adminEmail = TextEditingController();
  final TextEditingController _adminPass = TextEditingController();
  
  String _activeTab = 'dashboard';
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _logs = [];
  List<dynamic> _students = [];
  Map<String, dynamic> _stats = {'total_students': 0, 'present': 0, 'absent': 0};
  List<dynamic> _weeklyStats = [];
  bool _isLoadingAnalytics = false;
  
  Map<String, dynamic>? _lastDetection;
  bool _isEnrolling = false;
  bool _isCameraReady = false;
  
  CameraController? _cameraController;
  Timer? _detectionTimer;
  Timer? _logTimer;

  // Enrollment fields
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _rollCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  int _capturedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPersistentLogin();
    _initCamera();
    _fetchLogs();
    _fetchStudents();
    _fetchAnalytics();
    _logTimer = Timer.periodic(const Duration(seconds: 5), (_) {
       if (DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
          _fetchLogs();
          _fetchAnalytics();
       }
    });
    _detectionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isAdminLoggedIn && _activeTab == 'dashboard' && _isCameraReady && !_isEnrolling) {
        _performAutoScan();
      }
    });
  }

  Future<void> _checkPersistentLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('admin_logged_in') ?? false) {
      setState(() => _isAdminLoggedIn = true);
    }
  }

  Future<void> _fetchLogs() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final logs = await ApiService.fetchAttendanceByDate(dateStr);
    if (mounted) setState(() => _logs = logs);
  }

  Future<void> _fetchStudents() async {
    final students = await ApiService.fetchAllStudents();
    if (mounted) setState(() => _students = students);
  }

  Future<void> _fetchAnalytics() async {
    if (_weeklyStats.isEmpty) setState(() => _isLoadingAnalytics = true);
    try {
      final stats = await ApiService.fetchStats();
      final weekly = await ApiService.fetchWeeklyStats();
      if (mounted) setState(() { _stats = stats; _weeklyStats = weekly; _isLoadingAnalytics = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingAnalytics = false);
    }
  }

  Future<void> _deleteStudent(String rollNo) async {
    bool ok = await ApiService.deleteStudent(rollNo);
    if (ok) { _fetchStudents(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RECORD_PURGED'))); }
  }

  Future<void> _deleteLog(dynamic logID) async {
    if (logID == null) return;
    bool ok = await ApiService.deleteAttendance(logID.toString());
    if (ok) { _fetchLogs(); _fetchAnalytics(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LOG_CLEARED'))); }
  }

  Future<void> _initCamera() async {
    if (_cameras.isEmpty) return;
    if (_cameraController != null) await _cameraController!.dispose();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.high, enableAudio: false);
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Camera Fail: $e');
    }
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    if (_adminEmail.text == 'admin@gmail.com' && _adminPass.text == 'admin123') { 
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_logged_in', true);
      setState(() => _isAdminLoggedIn = true); 
    }
    else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SECURE_ACCESS_DENIED'))); }
  }

  Future<void> _logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_logged_in', false);
    setState(() => _isAdminLoggedIn = false);
  }

  Future<void> _performAutoScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final result = await ApiService.detectFace(bytes.toList());
      if (mounted) {
        if (result['detected'] == true) { setState(() => _lastDetection = result); }
        else { setState(() => _lastDetection = null); }
      }
    } catch (e) { debugPrint('Scan error: $e'); }
  }

  Future<void> _markSelectedAsPresent() async {
    if (_lastDetection == null || _lastDetection!['name'] == 'Unknown') return;
    bool success = await ApiService.markAttendance({
      'roll_no': _lastDetection!['roll_no'],
      'name': _lastDetection!['name'],
      'class_name': _lastDetection!['class_name'] ?? 'B-101',
      'department': _lastDetection!['department'] ?? 'CS/IT',
      'similarity': _lastDetection!['similarity'],
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF10B981), content: Text('ID: ${_lastDetection!['name']} • MARKED', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))));
      setState(() => _lastDetection = null);
      if (DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
        _fetchLogs();
        _fetchAnalytics();
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.black,
              surface: Color(0xFF010101),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchLogs();
    }
  }

  Future<void> _startEnrollment() async {
    if (_nameCtrl.text.isEmpty || _rollCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID_DATA_INCOMPLETE'))); return; }
    setState(() => _isEnrolling = true);
    try {
      for (int i = 1; i <= 10; i++) {
        final XFile image = await _cameraController!.takePicture();
        final bytes = await image.readAsBytes();
        await ApiService.captureStudentSample({'name': _nameCtrl.text, 'roll_no': _rollCtrl.text, 'class_name': 'B-101', 'department': 'CS/IT', 'email': _emailCtrl.text, 'phone_no': _phoneCtrl.text, 'count': i.toString()}, bytes.toList());
        if (mounted) setState(() => _capturedCount = i);
        if (i < 10) await Future.delayed(const Duration(milliseconds: 300));
      }
      await ApiService.registerStudent({'name': _nameCtrl.text, 'roll_no': _rollCtrl.text, 'class_name': 'B-101', 'department': 'CS/IT', 'email': _emailCtrl.text, 'phone_no': _phoneCtrl.text});
      if (mounted) { setState(() { _isEnrolling = false; _capturedCount = 0; _nameCtrl.clear(); _rollCtrl.clear(); _emailCtrl.clear(); _phoneCtrl.clear(); }); _fetchStudents(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID_REG_FINALIZED'))); }
    } catch (e) { if (mounted) setState(() => _isEnrolling = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isAdminLoggedIn ? _buildAdminLogin() : Row(
        children: [
          _buildObsidianSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildAdminLogin() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(child: const Icon(LucideIcons.shieldCheck, size: 80, color: Color(0xFF10B981))),
          const SizedBox(height: 32),
          Text('EDU_GUARD_ADMIN', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
          const SizedBox(height: 64),
          SizedBox(
            width: 400,
            child: Column(
              children: [
                _NoirInput(controller: _adminEmail, label: 'AUTH_ADMIN_ID', icon: LucideIcons.user),
                _NoirInput(controller: _adminPass, label: 'SECURE_PIN', icon: LucideIcons.lock),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loginAdmin,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('DECRYPT_DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObsidianSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(color: Color(0xFF010101), border: Border(right: BorderSide(color: Colors.white10))),
      child: Column(
        children: [
          const SizedBox(height: 60),
          FadeInDown(child: const Icon(LucideIcons.fingerprint, size: 40, color: Color(0xFF10B981))),
          const SizedBox(height: 12),
          Text('EDU_GUARD v1', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.white38)),
          const SizedBox(height: 60),
          _sidebarItem('dashboard', LucideIcons.scan, 'LIVE_ID'),
          _sidebarItem('register', LucideIcons.userPlus, 'ENROLL_HUB'),
          _sidebarItem('insights', LucideIcons.barChart3, 'INSIGHTS'),
          _sidebarItem('directory', LucideIcons.users, 'DIRECTORY'),
          _sidebarItem('attendance', LucideIcons.table, 'ATTENDANCE'),
          const Spacer(),
          IconButton(onPressed: _logoutAdmin, icon: const Icon(LucideIcons.power, color: Colors.white12)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sidebarItem(String tab, IconData icon, String label) {
    bool active = _activeTab == tab;
    return InkWell(
      onTap: () { setState(() { _activeTab = tab; _lastDetection = null; }); if (tab == 'directory') _fetchStudents(); if (tab == 'attendance') _fetchLogs(); if (tab == 'insights') _fetchAnalytics(); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(color: active ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: active ? const Color(0xFF10B981) : Colors.white60, size: 18),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: active ? Colors.white : Colors.white60, fontWeight: active ? FontWeight.bold : FontWeight.normal, letterSpacing: 1), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_activeTab == 'insights') return _buildAnalyticsView();
    if (_activeTab == 'directory') return _buildDirectoryView();
    if (_activeTab == 'attendance') return _buildLogsView();
    
    return Container(
      padding: const EdgeInsets.all(40),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_activeTab == 'dashboard' ? 'ID_SCANNER_CORE' : 'STUDENT_ONBOARDING', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _initCamera, icon: const Icon(LucideIcons.refreshCcw, size: 12), label: const Text('SYNC_SENSOR', style: TextStyle(fontSize: 10, color: Colors.white60))),
                ]),
                const SizedBox(height: 40),
                Expanded(child: _buildSharedCamera()),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(flex: 1, child: _activeTab == 'dashboard' ? _buildScannerHUD() : _buildEnrollHUD()),
        ],
      ),
    );
  }

  Widget _buildSharedCamera() {
    return Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
          _buildHUDOverlay(),
        ],
      ),
    );
  }

  Widget _buildHUDOverlay() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const _HUDElem(text: 'SYS_ON'), _HUDElem(text: 'BIOMETRIC_RDY', color: const Color(0xFF10B981))]),
          const Spacer(),
          Container(width: 300, height: 300, decoration: BoxDecoration(border: Border.all(color: Colors.white12, width: 0.5), borderRadius: BorderRadius.circular(16))),
          const Spacer(),
          const _HUDElem(text: 'SECURE_CHANNEL_ACTIVE'),
        ],
      ),
    );
  }

  Widget _buildScannerHUD() {
    bool detected = _lastDetection != null && _lastDetection!['detected'] == true;
    bool isUnknown = detected && _lastDetection!['name'] == 'Unknown';
    bool hasMatch = detected && !isUnknown;
    bool alreadyMarked = hasMatch && _lastDetection!['already_marked'] == true;
    
    return Column(
      children: [
        FadeInRight(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
            child: Column(
              children: [
                const Text('MATCH_RESULT', style: TextStyle(fontSize: 8, color: Colors.white60, letterSpacing: 2)),
                const SizedBox(height: 32),
                Icon(detected ? (isUnknown ? LucideIcons.userX : LucideIcons.userCheck) : LucideIcons.scan, size: 48, color: detected ? (isUnknown ? Colors.redAccent : (alreadyMarked ? Colors.amber : const Color(0xFF10B981))) : Colors.white24),
                const SizedBox(height: 24),
                Text(detected ? _lastDetection!['name'] : 'SEARCHING...', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.bold)),
                if (detected) ...[
                  if (!isUnknown) Text('ROLL: ${_lastDetection!['roll_no']}', style: const TextStyle(color: Colors.white60, fontSize: 12)) else const Text('NOT_IN_REGISTRY', style: TextStyle(color: Colors.redAccent, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 48),
                  if (!isUnknown) ...[
                     alreadyMarked ? _buildAlreadyMarked() : _buildMarkButton(),
                  ] else ...[
                     const Text('ACCESS_DENIED', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                  ],
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => setState(() => _lastDetection = null), child: const Text('DISMISS', style: TextStyle(color: Colors.white60, fontSize: 10))),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildQuickLog()),
      ],
    );
  }

  Widget _buildMarkButton() {
    return ElevatedButton(
      onPressed: _markSelectedAsPresent,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: const Text('MARK_AS_PRESENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildAlreadyMarked() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withValues(alpha: 0.2))),
      child: const Center(child: Text('ALREADY MARKED TODAY', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
    );
  }

  Widget _buildQuickLog() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF010101).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: ListView.builder(
        itemCount: _logs.length > 5 ? 5 : _logs.length,
        itemBuilder: (context, index) {
          final l = _logs[index];
          return ListTile(contentPadding: EdgeInsets.zero, title: Text(l['name'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white)), subtitle: Text(l['time'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white60)), trailing: const Icon(LucideIcons.check, size: 12, color: Color(0xFF10B981)));
        },
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIVE_INSIGHTS', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          Row(
            children: [
              _statCard('TOTAL_STUDENTS', _stats['total_students'].toString(), LucideIcons.users, const Color(0xFF10B981)),
              _statCard('PRESENT_TODAY', _stats['present'].toString(), LucideIcons.checkCircle, Colors.blueAccent),
              _statCard('ABSENT_TODAY', _stats['absent'].toString(), LucideIcons.userX, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildLineChart()),
                const SizedBox(width: 40),
                Expanded(flex: 1, child: _buildPieChart()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 24),
            Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 8, color: Colors.white60, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_isLoadingAnalytics) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    List<dynamic> statsToUse = _weeklyStats.isEmpty ? List.generate(7, (i) => {'date': '', 'present': 0}) : _weeklyStats;
    List<FlSpot> spots = [];
    for (int i = 0; i < statsToUse.length; i++) {
        spots.add(FlSpot(i.toDouble(), (statsToUse[i]['present'] as int).toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY_ENGAGEMENT', style: TextStyle(fontSize: 8, color: Colors.white60, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF10B981),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withValues(alpha: 0.1)),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    double total = (_stats['total_students'] as int).toDouble();
    double present = (_stats['present'] as int).toDouble();
    if (total == 0) total = 1;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          const Text('TODAY_DISTRIBUTION', style: TextStyle(fontSize: 8, color: Colors.white60, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Expanded(
            child: PieChart(PieChartData(
              sectionsSpace: 8,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(color: const Color(0xFF10B981), value: present, title: 'PRES', radius: 10, titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                PieChartSectionData(color: Colors.white24, value: total - present, title: 'ABSENT', radius: 10, titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white60)),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollHUD() {
    return FadeInRight(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
          child: Column(
            children: [
              const Text('STDN_DETAILS', style: TextStyle(fontSize: 8, color: Colors.white60, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _NoirInput(controller: _nameCtrl, label: 'PRFL_NAME', icon: LucideIcons.user),
              _NoirInput(controller: _rollCtrl, label: 'STDN_ROLL', icon: LucideIcons.hash),
              _NoirInput(controller: _emailCtrl, label: 'AUTH_EMAIL', icon: LucideIcons.mail),
              _NoirInput(controller: _phoneCtrl, label: 'AUTH_PHONE', icon: LucideIcons.phone),
              const SizedBox(height: 16),
              _isEnrolling
                ? Column(children: [LinearProgressIndicator(value: _capturedCount / 10, backgroundColor: Colors.white10, color: const Color(0xFF10B981)), const SizedBox(height: 12), Text('SAMPLING: $_capturedCount/10', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981)))])
                : ElevatedButton(onPressed: _startEnrollment, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('REGISTER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryView() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: FadeIn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STUDENT_DIRECTORY', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.bold)), ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.download), label: const Text('EXPORT'))]),
            const SizedBox(height: 48),
            Expanded(
              child: ListView.separated(
                itemCount: _students.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 32),
                itemBuilder: (context, index) {
                  final s = _students[index];
                  return Row(children: [CircleAvatar(backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1), child: const Icon(LucideIcons.user, size: 16, color: Color(0xFF10B981))), const SizedBox(width: 24), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)), Text('ID: ${s['roll_no']} • ${s['email']}', style: const TextStyle(color: Colors.white60, fontSize: 11))])), IconButton(onPressed: () => _deleteStudent(s['roll_no']), icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18))]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsView() {
    final displayDate = DateFormat('dd MMM yyyy').format(_selectedDate);
    return Container(
      padding: const EdgeInsets.all(40),
      child: FadeIn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('STUDENT ATTENDANCE', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.bold)),
                 Row(
                   children: [
                     ElevatedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(LucideIcons.calendar),
                        label: Text(displayDate),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                     ),
                     const SizedBox(width: 12),
                     ElevatedButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.download), label: const Text('EXPORT')),
                   ],
                 )
              ],
            ),
            const SizedBox(height: 48),
            Expanded(
              child: _logs.isEmpty 
              ? Center(child: Text('NO RECORDS FOR $displayDate', style: const TextStyle(color: Colors.white38, letterSpacing: 2)))
              : ListView.separated(
                itemCount: _logs.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 32),
                itemBuilder: (context, index) {
                  final l = _logs[index];
                  return Row(children: [const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981), size: 16), const SizedBox(width: 24), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)), Text('ID: ${l['roll_no']} • ${l['class_name']}', style: const TextStyle(color: Colors.white60, fontSize: 11))])), Row(children: [Text(l['time'] ?? '', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 16), IconButton(onPressed: () => _deleteLog(l['id']), icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16))])]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HUDElem extends StatelessWidget {
  final String text;
  final Color? color;
  const _HUDElem({required this.text, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: color?.withValues(alpha: 0.3) ?? Colors.white38), borderRadius: BorderRadius.circular(4)), child: Text(text, style: TextStyle(fontSize: 7, letterSpacing: 2, color: color ?? Colors.white38)));
  }
}

class _NoirInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _NoirInput({required this.controller, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(prefixIcon: Icon(icon, size: 14, color: Colors.white60), labelText: label, labelStyle: const TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 1.5), filled: true, fillColor: const Color(0xFF000000), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981)))),
      ),
    );
  }
}
