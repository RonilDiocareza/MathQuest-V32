import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirstTimeTutorialStep {
  const FirstTimeTutorialStep({
    required this.title,
    required this.message,
    this.targetKey,
    this.guideAtTop = false,
    this.guideAssetPath = 'assets/images/npcs/guide1.png',
  });

  final String title;
  final String message;
  final GlobalKey? targetKey;
  final bool guideAtTop;
  final String guideAssetPath;
}

class FirstTimeTutorialOverlay extends StatefulWidget {
  const FirstTimeTutorialOverlay({
    required this.steps,
    required this.onComplete,
    this.onStepChanged,
    super.key,
  }) : assert(steps.length > 0);

  final List<FirstTimeTutorialStep> steps;
  final Future<void> Function() onComplete;
  final Future<void> Function(int index)? onStepChanged;

  @override
  State<FirstTimeTutorialOverlay> createState() =>
      _FirstTimeTutorialOverlayState();
}

class _FirstTimeTutorialOverlayState extends State<FirstTimeTutorialOverlay> {
  final GlobalKey _overlayBoundsKey = GlobalKey();
  int _stepIndex = 0;
  bool _isSaving = false;
  bool _isCompleted = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _advance() async {
    if (_isSaving) return;

    if (_stepIndex == widget.steps.length - 1) {
      setState(() {
        _isSaving = true;
        _saveError = null;
      });
      try {
        await widget.onComplete();
        if (!mounted) return;
        setState(() => _isCompleted = true);
      } catch (error, stackTrace) {
        debugPrint(
          '[FirstTimeTutorialOverlay] Finish save callback failed: '
          'type=${error.runtimeType}, message=$error.',
        );
        if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          setState(() {
            _isSaving = false;
            _saveError = 'Could not save your progress. Please try again.';
          });
        }
      }
      return;
    }

    final nextIndex = _stepIndex + 1;
    try {
      await widget.onStepChanged?.call(nextIndex);
      if (!mounted) return;
      setState(() {
        _stepIndex = nextIndex;
        _saveError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to focus tutorial feature: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Rect? _targetRect() {
    final targetContext = widget.steps[_stepIndex].targetKey?.currentContext;
    final overlayContext = _overlayBoundsKey.currentContext;
    final targetObject = targetContext?.findRenderObject();
    final overlayObject = overlayContext?.findRenderObject();
    if (targetObject is! RenderBox ||
        overlayObject is! RenderBox ||
        !targetObject.hasSize ||
        !overlayObject.hasSize) {
      return null;
    }

    final topLeft = targetObject.localToGlobal(Offset.zero);
    final overlayTopLeft = overlayObject.localToGlobal(Offset.zero);
    return (topLeft - overlayTopLeft & targetObject.size).inflate(5);
  }

  double _overlapArea(Rect first, Rect second) {
    final intersection = first.intersect(second);
    return intersection.isEmpty ? 0 : intersection.width * intersection.height;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return const SizedBox.shrink();

    final step = widget.steps[_stepIndex];
    final targetRect = _targetRect();

    return LayoutBuilder(
      key: _overlayBoundsKey,
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final isWide = maxWidth > maxHeight;
        final characterWidth = math.min(
          math.max(maxWidth * (isWide ? 0.30 : 0.42), 90.0),
          isWide ? 230.0 : 180.0,
        );
        final guideSize = math.min(
          characterWidth,
          maxHeight * (isWide ? 0.30 : 0.24),
        );
        final safeInsets = MediaQuery.paddingOf(context);
        final groupWidth = math.min(maxWidth - 24, 820.0);
        final dialogueHeight = math.min(maxHeight * 0.32, 190.0);
        final groupHeight = guideSize + 8 + dialogueHeight;
        final groupLeft = (maxWidth - groupWidth) / 2;
        final top = safeInsets.top + 12;
        final bottom = math.max(
          top,
          maxHeight - safeInsets.bottom - groupHeight - 12,
        );
        final topGroupRect = Rect.fromLTWH(
          groupLeft,
          top,
          groupWidth,
          groupHeight,
        );
        final bottomGroupRect = Rect.fromLTWH(
          groupLeft,
          bottom,
          groupWidth,
          groupHeight,
        );
        final topOverlap =
            targetRect == null ? 0.0 : _overlapArea(topGroupRect, targetRect);
        final bottomOverlap = targetRect == null
            ? 0.0
            : _overlapArea(bottomGroupRect, targetRect);
        final placeAtTop = topOverlap < bottomOverlap ||
            (topOverlap == bottomOverlap && step.guideAtTop);
        final groupTop = placeAtTop ? top : bottom;
        final guideComesFirst = placeAtTop;

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _TutorialScrimPainter(targetRect: targetRect),
                size: Size.infinite,
              ),
            ),
            if (targetRect != null)
              Positioned.fromRect(
                rect: targetRect,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFFFD65A), width: 4),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xCCFFD65A),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: groupTop,
              left: groupLeft,
              width: groupWidth,
              height: groupHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (guideComesFirst) ...[
                    _buildGuide(guideSize),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: dialogueHeight,
                      width: groupWidth,
                      child: _buildDialogue(step, maxHeight),
                    ),
                  ] else ...[
                    SizedBox(
                      height: dialogueHeight,
                      width: groupWidth,
                      child: _buildDialogue(step, maxHeight),
                    ),
                    const SizedBox(height: 8),
                    _buildGuide(guideSize),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuide(double size) => ClipRect(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            widget.steps[_stepIndex].guideAssetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      );

  Widget _buildDialogue(FirstTimeTutorialStep step, double availableHeight) {
    final isFinalStep = _stepIndex == widget.steps.length - 1;

    return Container(
      constraints:
          BoxConstraints(maxHeight: math.min(availableHeight * 0.32, 190)),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A3620), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3C2A1C),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_stepIndex + 1}/${widget.steps.length}',
                style: const TextStyle(
                  color: Color(0xFF76563D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                step.message,
                style: const TextStyle(
                  color: Color(0xFF3C2A1C),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 4),
            Text(
              _saveError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSaving ? null : _advance,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 34),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                backgroundColor: const Color(0xFF8F5C2D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isFinalStep ? 'Finish' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialScrimPainter extends CustomPainter {
  const _TutorialScrimPainter({required this.targetRect});

  final Rect? targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final screenPath = Path()..addRect(Offset.zero & size);
    final scrimPath = targetRect == null
        ? screenPath
        : Path.combine(
            PathOperation.difference,
            screenPath,
            Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  targetRect!,
                  const Radius.circular(15),
                ),
              ),
          );
    canvas.drawPath(
      scrimPath,
      Paint()..color = const Color(0xB8000000),
    );
  }

  @override
  bool shouldRepaint(_TutorialScrimPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect;
}
