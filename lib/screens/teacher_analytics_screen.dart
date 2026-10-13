import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_progress_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/math_background.dart';
import 'home_screen.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen>
    with WidgetsBindingObserver {
  List<StudentAnalytics> students = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final progressFuture = UserProgressService.getCurrentUserProgress();
    final preferencesFuture = SharedPreferences.getInstance();
    final progress = await progressFuture;
    final prefs = await preferencesFuture;
    if (!mounted) return;
    final studentName = prefs.getString('current_user_name') ??
        prefs.getString('user_name') ??
        'Student 1';

    const totalLevels = 60; // 3 levels × 20 sublevels
    final levelProgress = (progress.completedCount / totalLevels) * 100;

    setState(() {
      students = [
        StudentAnalytics(
          name: studentName,
          levelProgress: levelProgress.toStringAsFixed(1),
          questAttempts: progress.questAttempts,
          levelsCompleted: progress.completedCount,
          totalLevels: totalLevels,
        ),
      ];
    });
  }

  void _goBackToHome() {
    final navigator = Navigator.of(context);
    var homeExists = false;

    navigator.popUntil((route) {
      if (route is HomeScreen) {
        homeExists = true;
        return true;
      }
      return false;
    });

    if (!homeExists) {
      navigator.pushAndRemoveUntil(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'My Progress',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ui.Color.fromARGB(255, 0, 0, 0)),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (students.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No student data available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Column(
                                children: students.map((student) {
                                  return _buildStudentCard(student);
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                 const SizedBox(height: 16),
Center(
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _goBackToHome,
      borderRadius: BorderRadius.circular(12),
      child: CustomButton(
        text: 'Back',
        onPressed: _goBackToHome,
      ),
    ),
  ),
),
const SizedBox(height: 16),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentAnalytics student) {
    double progressPercent = double.parse(student.levelProgress);
    Color progressColor = progressPercent >= 75
        ? Colors.green
        : progressPercent >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1D0AD),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Name Header
          Row(
            children: [
              const Icon(Icons.person, size: 30, color: Colors.black87),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Level Progress Section
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Levels Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${student.levelProgress}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercent / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${student.levelsCompleted}/${student.totalLevels} levels completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Classroom Quest Attempts Section
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.quiz,
                  size: 30,
                  color: Colors.blue,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Classroom Quest Attempts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${student.questAttempts} attempt${student.questAttempts != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Summary Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                title: 'Status',
                value: progressPercent >= 75
                    ? '✓ Excellent'
                    : progressPercent >= 50
                        ? '⚠ Good'
                        : '✗ Needs Improvement',
                color: progressColor,
              ),
              _buildStatCard(
                title: 'Activity',
                value: student.questAttempts > 0 ? '✓ Active' : '✗ Inactive',
                color: student.questAttempts > 0 ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      {required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StudentAnalytics {
  final String name;
  final String levelProgress;
  final int questAttempts;
  final int levelsCompleted;
  final int totalLevels;

  StudentAnalytics({
    required this.name,
    required this.levelProgress,
    required this.questAttempts,
    required this.levelsCompleted,
    required this.totalLevels,
  });
}
