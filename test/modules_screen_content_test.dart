import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/screens/modules_screen.dart';
import 'package:flutter_mathquest/worksheet_lesson_data.dart';

void main() {
  testWidgets('all reference worksheets appear in module order with lessons',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);

    await tester.pumpWidget(const MaterialApp(home: ModulesScreen()));
    await tester.pumpAndSettle();

    expect(worksheetTitles, hasLength(67));
    expect(
      worksheetTitles.take(3),
      [
        'Adding Similar Fractions',
        'Subtracting Similar Fractions',
        'Adding and Subtracting Mixed Numbers',
      ],
    );
    expect(worksheetTitles.last, 'Dividing Integers');

    for (var moduleIndex = 0;
        moduleIndex < worksheetModuleIds.length;
        moduleIndex++) {
      final moduleTitle = worksheetModuleNames[moduleIndex];
      await tester.scrollUntilVisible(
        find.text(moduleTitle),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(moduleTitle));
      await tester.pumpAndSettle();

      final moduleLessons = worksheetLessons
          .where((lesson) => lesson.moduleId == worksheetModuleIds[moduleIndex])
          .toList();
      expect(moduleLessons, isNotEmpty);
      for (final lesson in moduleLessons) {
        expect(find.text(lesson.title), findsOneWidget);
      }
      expect(find.text('Worked Example'), findsWidgets);
      expect(find.text('Practice'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
    }
  });
}
