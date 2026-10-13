import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/widgets/first_time_tutorial_overlay.dart';

void main() {
  testWidgets('tutorial advances and saves on the final action',
      (WidgetTester tester) async {
    final targetKey = GlobalKey();
    var homeActionTriggered = false;
    var completed = false;
    final steps = [
      const FirstTimeTutorialStep(
        title: 'Welcome',
        message: 'Meet your guide.',
      ),
      FirstTimeTutorialStep(
        title: 'Levels',
        message: 'Choose a level to play.',
        targetKey: targetKey,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () => homeActionTriggered = true,
                  child: const Text('Home action'),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  key: targetKey,
                  width: 120,
                  height: 50,
                  color: Colors.blue,
                ),
              ),
              Positioned.fill(
                child: FirstTimeTutorialOverlay(
                  steps: steps,
                  onComplete: () async => completed = true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.image(const AssetImage('assets/images/npcs/guide1.png')),
        findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(find.text('Welcome'), findsNothing);
    expect(find.text('Home action'), findsOneWidget);
    await tester.tap(find.text('Home action'));
    expect(homeActionTriggered, isTrue);
  });

  testWidgets('tutorial guide can move clear of a highlighted control',
      (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    final targetKey = GlobalKey();
    final steps = [
      FirstTimeTutorialStep(
        title: 'Badges',
        message: 'See your badges.',
        targetKey: targetKey,
        guideAtTop: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  key: targetKey,
                  width: 120,
                  height: 60,
                ),
              ),
              FirstTimeTutorialOverlay(
                steps: steps,
                onComplete: () async {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.image(const AssetImage('assets/images/npcs/guide1.png')),
      findsOneWidget,
    );
    expect(find.image(const AssetImage('assets/images/npcs/npc6.png')),
        findsNothing);
    final guideRect = tester.getRect(
      find.image(const AssetImage('assets/images/npcs/guide1.png')),
    );
    expect(
      guideRect.overlaps(tester.getRect(find.byKey(targetKey))),
      isFalse,
    );
    expect(find.text('See your badges.'), findsOneWidget);
    final messageRect = tester.getRect(find.text('See your badges.'));
    expect(messageRect.top, greaterThanOrEqualTo(guideRect.bottom));
    expect(guideRect.width, greaterThanOrEqualTo(100));
    expect(guideRect.height, guideRect.width);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom-positioned guide has a landscape dialogue above it',
      (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  key: targetKey,
                  width: 120,
                  height: 60,
                ),
              ),
              FirstTimeTutorialOverlay(
                steps: [
                  FirstTimeTutorialStep(
                    title: 'Classroom Quests',
                    message: 'View quests assigned to your classroom.',
                    targetKey: targetKey,
                  ),
                ],
                onComplete: () async {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final guideRect = tester.getRect(
      find.image(const AssetImage('assets/images/npcs/guide1.png')),
    );
    final messageRect =
        tester.getRect(find.text('View quests assigned to your classroom.'));
    final targetRect = tester.getRect(find.byKey(targetKey));
    expect(messageRect.bottom, lessThanOrEqualTo(guideRect.top));
    expect(guideRect.overlaps(targetRect), isFalse);
    expect(messageRect.overlaps(targetRect), isFalse);
    expect(messageRect.width, greaterThan(messageRect.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutorial layout fits small and landscape screens',
      (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in [const Size(320, 568), const Size(812, 375)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FirstTimeTutorialOverlay(
              steps: const [
                FirstTimeTutorialStep(
                  title: 'Welcome',
                  message: 'Explore the game with NPC6.',
                ),
              ],
              onComplete: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final nextButton = tester.getRect(find.text('Finish'));
      expect(nextButton.left, greaterThanOrEqualTo(0));
      expect(nextButton.right, lessThanOrEqualTo(size.width));
      expect(nextButton.bottom, lessThanOrEqualTo(size.height));
    }
  });
}
