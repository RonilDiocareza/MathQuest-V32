import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/math_background.dart';
import '../worksheet_lesson_data.dart';

class ModuleLessonScreen extends StatelessWidget {
  final Map<String, String> module;

  const ModuleLessonScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final lessons = worksheetLessons
        .where((lesson) => lesson.moduleId == module['id'])
        .toList(growable: false);

    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        module['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final lesson in lessons)
                          _LessonPanel(
                            title: lesson.title,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.objective,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(lesson.explanation),
                                const SizedBox(height: 12),
                                const Text(
                                  'Worked Example',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B3B5A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lesson.example,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B3B5A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(lesson.solution),
                                const SizedBox(height: 12),
                                const Text(
                                  'Practice',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B3B5A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(lesson.practice),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'Back to Modules',
                          width: double.infinity,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: CustomButton(
                    text: 'Back',
                    width: double.infinity,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _LessonPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3D5AA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2B3B5A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFF5F6670),
              fontSize: 15,
              height: 1.4,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
