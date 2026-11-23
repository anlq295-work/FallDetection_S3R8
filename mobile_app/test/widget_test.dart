import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/core/models.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/services/hearth_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Hearth launches in Vietnamese by default and switches to EN / FR', (tester) async {
    final ctrl = HearthController();
    await ctrl.load();

    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();

    expect(find.text('Hearth'), findsOneWidget);
    expect(find.text('Gửi mã đăng nhập cho tôi'), findsOneWidget);

    await ctrl.setLanguage(AppLanguage.en);
    await tester.pumpAndSettle();
    expect(find.text('Send me a sign-in code'), findsOneWidget);

    await ctrl.setLanguage(AppLanguage.fr);
    await tester.pumpAndSettle();
    expect(find.text('M’envoyer un code de connexion'), findsOneWidget);
  });

  testWidgets('Hearth S6 Home and S7 Fall Alert render cleanly on compact phone', (tester) async {
    final ctrl = HearthController();
    await ctrl.load();
    await ctrl.signIn(email: 'anna.ruiz@mail.com', returningUser: true);

    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nhà của'), findsOneWidget);

    ctrl.triggerFallAlert(simulated: true);
    await tester.pumpAndSettle();

    expect(find.text('Tôi đang xử lý'), findsOneWidget);
    await tester.tap(find.text('Tôi đang xử lý'));
    await tester.pumpAndSettle();
    expect(find.text('Đánh dấu đã xử lý xong'), findsOneWidget);
  });

  testWidgets('Hearth renders cleanly on Tablet 2-pane and Desktop 3-column layouts', (tester) async {
    final ctrl = HearthController();
    await ctrl.load();
    await ctrl.signIn(email: 'anna.ruiz@mail.com', returningUser: true);

    // Tablet / Foldable 2-pane
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nhà của'), findsOneWidget);

    // Desktop 3-column + NavRail
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();
    expect(find.text('Hoạt động hôm nay'), findsOneWidget);
  });
}
