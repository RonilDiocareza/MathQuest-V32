import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/main.dart';
import 'package:flutter_mathquest/screens/home_screen.dart';
import 'package:flutter_mathquest/screens/landing_screen.dart';
import 'package:flutter_mathquest/screens/login_screen.dart';

void main() {
  testWidgets('app opens on login before authentication', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(LandingScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landing screen adapts to phone, tablet, and wide layouts',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in [
      const Size(320, 568),
      const Size(768, 1024),
      const Size(1510, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        const MaterialApp(home: LandingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Play'), findsOneWidget);
      expect(find.text('About Us'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final label in ['Play', 'About Us']) {
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
    }
  });

  testWidgets('Play opens the existing Home Screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('Home icon returns to the post-login landing screen',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final icon = find.byKey(const ValueKey('home-navigation'));
    expect(icon, findsOneWidget);
    final iconRect = tester.getRect(icon);
    final logoRect = tester
        .getRect(find.image(const AssetImage('assets/images/Icon/Icon2.png')));
    final profileRect = tester
        .getRect(find.image(const AssetImage('assets/images/player/boy.png')));
    expect(iconRect.center.dy, closeTo(logoRect.center.dy, 1));
    expect(iconRect.right, lessThan(logoRect.left));
    expect(logoRect.right, lessThan(profileRect.left));

    await tester.tap(icon);
    await tester.pumpAndSettle();

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('About Us'), findsOneWidget);
  });

  testWidgets('About Us explains the game and Back returns to landing',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('About Us'));
    await tester.pumpAndSettle();

    expect(find.text('About MathQuest'), findsNWidgets(2));
    expect(find.text('Purpose of the Game'), findsOneWidget);
    expect(find.text('Who Is the Game For?'), findsOneWidget);
    expect(find.text('How to Use MathQuest'), findsOneWidget);
    expect(
      find.textContaining('Grade 7 students'),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.textContaining('Review scores and learning progress'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('about-back')));
    await tester.pumpAndSettle();

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('About Us'), findsOneWidget);
    expect(find.byType(AboutUsScreen), findsNothing);
  });
}
