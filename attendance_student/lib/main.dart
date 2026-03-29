import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';

void main() {
  runApp(const StudentAppRoot());
}

class StudentAppRoot extends StatelessWidget {
  const StudentAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDU_GUARD Student',
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
      home: const StudentApp(),
    );
  }
}

class StudentApp extends StatefulWidget {
  const StudentApp({super.key});

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _student;
  List<dynamic> _history = [];
  bool _isLoading = false;
  
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  void _login() async {
    if (_emailCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    final result = await ApiService.studentLogin(_emailCtrl.text, _phoneCtrl.text);
    
    if (result != null && result['status'] == 'success') {
      final history = await ApiService.fetchStudentAttendance(result['student']['roll_no']);
      if (mounted) {
        setState(() {
          _student = result['student'];
          _history = history;
          _isLoggedIn = true;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ACCESS_DENIED: PROFILES_MISMATCH')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoggedIn ? _buildDashboard() : _buildLogin(),
    );
  }

  Widget _buildLogin() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.03),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
              ),
              child: const Icon(LucideIcons.userX, size: 80, color: Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 48),
          Text('EDU_GUARD_PORTAL', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
          Text('BIOMETRIC ARCHIVE ACCESS', style: GoogleFonts.inter(fontSize: 8, color: Colors.white24, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 64),
          SizedBox(
            width: 400,
            child: Column(
              children: [
                _NoirInput(controller: _emailCtrl, label: 'AUTH_EMAIL_ID', icon: LucideIcons.mail),
                _NoirInput(controller: _phoneCtrl, label: 'SECURE_NODE_PHONE', icon: LucideIcons.phone),
                const SizedBox(height: 32),
                _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF10B981))
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('DECRYPT_RECORDS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF000000),
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SYNCED_IDENTITY:', style: TextStyle(fontSize: 8, color: Color(0xFF10B981), letterSpacing: 2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(_student!['name'], style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('ROLL_ID: ${_student!['roll_no']}', style: const TextStyle(fontSize: 12, color: Colors.white24)),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => setState(() => _isLoggedIn = false),
              icon: const Icon(LucideIcons.power, color: Colors.white12),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildObsidianStat('ID_STATUS', 'VERIFIED')),
                    const SizedBox(width: 24),
                    Expanded(child: _buildObsidianStat('RECORDS_COUNT', '${_history.length}')),
                  ],
                ),
                const SizedBox(height: 48),
                _buildObsidianCalendar(),
                const SizedBox(height: 48),
                Text('VERIFICATION_ARCHIVE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 2)),
                const SizedBox(height: 24),
                _buildHistoryList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObsidianStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF10B981), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildObsidianCalendar() {
    final Map<DateTime, List> events = {};
    for (var log in _history) {
      try {
        final date = DateTime.parse(log['date']);
        events[DateTime(date.year, date.month, date.day)] = ['Present'];
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          formatButtonVisible: false,
          leftChevronIcon: const Icon(LucideIcons.chevronLeft, color: Colors.white24, size: 16),
          rightChevronIcon: const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 16),
        ),
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: Colors.white60, fontSize: 13),
          weekendTextStyle: TextStyle(color: Colors.white12, fontSize: 13),
          todayDecoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
        ),
        eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return const Center(child: Text('NO_RECORDS_INDEXED', style: TextStyle(color: Colors.white12, fontSize: 10, letterSpacing: 2)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final log = _history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF010101), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Row(
            children: [
              const Icon(LucideIcons.check, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${log['time']} • ${(log['class_name'] ?? '').toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.white24, letterSpacing: 1)),
                  ],
                ),
              ),
              Text('MATCH: ${(log['similarity'] * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ],
          ),
        );
      },
    );
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
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: Colors.white24),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1.5),
          filled: true, fillColor: Colors.black,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
        ),
      ),
    );
  }
}
