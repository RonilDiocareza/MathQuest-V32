import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/math_background.dart';

class ClassroomQuestScreen extends StatefulWidget {
  const ClassroomQuestScreen({super.key});

  @override
  State<ClassroomQuestScreen> createState() => _ClassroomQuestScreenState();
}

class _ClassroomQuestScreenState extends State<ClassroomQuestScreen> {
  late TextEditingController _answerController;
  final GlobalKey _answerFieldKey = GlobalKey();
  double _answerFieldOffset = 0;
  Timer? _timer;
  int _remainingSeconds = 60;
  int _attempts = 0;
  bool _isSubmitted = false;
  bool _isTimeUp = false;
  bool _isTimeoutDialogShowing = false;
  String? _feedbackMessage;
  int _currentLevel = 0;

  static const int _totalTime = 60;
  static const List<Map<String, Object>> _levels = [
    {
      'equation': '1/4 + 2/4 = ?',
      'prompt': 'Give your answer as a fraction.',
      'answer': '3/4',
    },
    {
      'equation': '3/5 - 1/5 = ?',
      'prompt': 'Give your answer as a fraction.',
      'answer': '2/5',
    },
    {
      'equation': '1/2 + 1/4 = ?',
      'prompt': 'Give your answer as a simplified fraction.',
      'answer': '3/4',
    },
  ];

  Map<String, Object> get _currentProblem => _levels[_currentLevel];
  bool get _isLastLevel => _currentLevel == _levels.length - 1;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalTime;
      _attempts = 0;
      _isSubmitted = false;
      _isTimeUp = false;
      _feedbackMessage = null;
      _answerController.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (mounted && !_isTimeUp && !_isTimeoutDialogShowing) {
          setState(() {
            _remainingSeconds = 0;
            _isTimeUp = true;
          });
          unawaited(_showTimeUpDialog());
        }
        return;
      }
      if (mounted) {
        setState(() {
          _remainingSeconds -= 1;
        });
      }
    });
  }

  Future<void> _showTimeUpDialog() async {
    if (_isTimeoutDialogShowing || !mounted) return;
    _isTimeoutDialogShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text("Time's Up!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _startTimer();
                },
                child: const Text('Try Again'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    } finally {
      _isTimeoutDialogShowing = false;
    }
  }

  void _submitAnswer() {
    if (_isTimeUp || _isSubmitted) {
      return;
    }

    if (_answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an answer first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userAnswer = _parseFraction(_answerController.text);
    if (userAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid fraction, mixed number, or integer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _attempts += 1;
    });

    // Save attempt to SharedPreferences
    _saveAttempt();

    final correctAnswer = _parseFraction(_currentProblem['answer'] as String)!;
    if (userAnswer == correctAnswer) {
      _timer?.cancel();
      if (_isLastLevel) {
        setState(() {
          _isSubmitted = true;
          _feedbackMessage =
              'Great job! You completed all levels in $_attempts attempt(s).';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All levels complete! Attempts: $_attempts'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _currentLevel += 1;
          _feedbackMessage = 'Correct! Starting level ${_currentLevel + 1}.';
          _answerController.clear();
          _isSubmitted = false;
          _isTimeUp = false;
          _remainingSeconds = _totalTime;
          _attempts = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correct! Level ${_currentLevel + 1} ready.'),
            backgroundColor: Colors.green,
          ),
        );

        _startTimer();
      }
    } else {
      setState(() {
        _feedbackMessage = 'Wrong answer. Attempts: $_attempts';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wrong answer. Attempts: $_attempts'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAttempt() async {
    await UserProgressService.incrementQuestAttempts();
  }

  (int, int)? _parseFraction(String value) {
    final answer = value.trim();
    final mixedNumberMatch =
        RegExp(r'^(\d+)\s+(\d+)\/(\d+)$').firstMatch(answer);
    final fractionMatch = RegExp(r'^(\d+)\/(\d+)$').firstMatch(answer);
    final integerMatch = RegExp(r'^\d+$').firstMatch(answer);

    late final int numerator;
    late final int denominator;
    if (mixedNumberMatch != null) {
      final whole = int.parse(mixedNumberMatch.group(1)!);
      final remainder = int.parse(mixedNumberMatch.group(2)!);
      denominator = int.parse(mixedNumberMatch.group(3)!);
      if (denominator == 0 || remainder >= denominator) return null;
      numerator = whole * denominator + remainder;
    } else if (fractionMatch != null) {
      numerator = int.parse(fractionMatch.group(1)!);
      denominator = int.parse(fractionMatch.group(2)!);
      if (denominator == 0) return null;
    } else if (integerMatch != null) {
      numerator = int.parse(answer);
      denominator = 1;
    } else {
      return null;
    }

    var divisor = numerator;
    var remainder = denominator;
    while (remainder != 0) {
      final next = divisor % remainder;
      divisor = remainder;
      remainder = next;
    }
    return (numerator ~/ divisor, denominator ~/ divisor);
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final answerFieldObject =
        _answerFieldKey.currentContext?.findRenderObject();
    var answerFieldOffset = 0.0;
    if (keyboardInset > 0 &&
        answerFieldObject is RenderBox &&
        answerFieldObject.hasSize) {
      final keyboardTop = MediaQuery.sizeOf(context).height - keyboardInset;
      final answerFieldBottom =
          answerFieldObject.localToGlobal(Offset.zero).dy +
              answerFieldObject.size.height -
              _answerFieldOffset;
      final requiredOffset = keyboardTop - answerFieldBottom - 12;
      answerFieldOffset = requiredOffset < 0 ? requiredOffset : 0;
    }
    _answerFieldOffset = answerFieldOffset;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MathBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // HEADER
                            Row(
                              children: [
                                const SizedBox(width: 48),
                                const Expanded(
                                  child: Text(
                                    'Classroom Quest',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // 🔥 ORANGE CARD (NUMBER WIDTH CONTROL HERE)
                            Center(
                              child: Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(maxWidth: 350),
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1D0AD),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Math Problem',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Level ${_currentLevel + 1} of ${_levels.length}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Solve this fraction problem:',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(height: 15),
                                          Text(
                                            _currentProblem['equation']
                                                as String,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(_currentProblem['prompt']
                                              as String),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Time Remaining',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatTime(_remainingSeconds),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Attempts',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$_attempts',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (_feedbackMessage != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  _feedbackMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 30),

                            const Text(
                              'Your Answer',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Transform.translate(
                              offset: Offset(0, answerFieldOffset),
                              child: Center(
                                child: CustomTextField(
                                  key: _answerFieldKey,
                                  hint: 'Enter answer...',
                                  controller: _answerController,
                                  keyboardType: TextInputType.text,
                                  height: 60,
                                  width: 200,
                                  enabled: !_isTimeUp && !_isSubmitted,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Center(
                              child: SizedBox(
                                width: 200,
                                child: CustomButton(
                                  text: _isSubmitted
                                      ? '✅ Submitted!'
                                      : 'Submit Answer',
                                  onPressed: (_isSubmitted || _isTimeUp)
                                      ? null
                                      : _submitAnswer,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Center(
                              child: SizedBox(
                                width: 200,
                                child: CustomButton(
                                  text: 'Back',
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
