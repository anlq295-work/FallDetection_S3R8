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

  testWidgets('Hearth launches in VI with Pre-release2.0.1, enforces required fields, and switches EN/FR', (tester) async {
    final ctrl = HearthController();
    await ctrl.load();

    // Ensure ZERO hardcoded fake names or contacts exist on fresh install
    expect(ctrl.personName, isEmpty);
    expect(ctrl.contacts, isEmpty);
    expect(ctrl.rooms, isEmpty);

    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();

    expect(find.text('Hearth'), findsOneWidget);
    expect(find.text(kAppReleaseLabel), findsOneWidget);
    expect(find.text('Gửi mã đăng nhập cho tôi'), findsOneWidget);

    // Tapping submit with blank required fields shows validation error
    await tester.ensureVisible(find.text('Gửi mã đăng nhập cho tôi'));
    await tester.tap(find.text('Gửi mã đăng nhập cho tôi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('bắt buộc'), findsWidgets);

    await ctrl.setLanguage(AppLanguage.en);
    await tester.pumpAndSettle();
    expect(find.text('Send me a sign-in code'), findsOneWidget);

    await ctrl.setLanguage(AppLanguage.fr);
    await tester.pumpAndSettle();
    expect(find.text('M’envoyer un code de connexion'), findsOneWidget);
  });

  testWidgets('Simultaneous multi-channel Fall Alert S7 works cleanly on compact phone', (tester) async {
    final ctrl = HearthController();
    await ctrl.load();
    await ctrl.signIn(
      email: 'carer@example.com',
      carerName: 'Hùng',
      personName: 'Ông Nam',
      personPhone: '0909111222',
      skipDirectToHome: true,
    );
    await ctrl.addContact('Chị Hoa', '0908333444');
    await ctrl.addOrUpdateRoom(
      HearthRoom(
        id: 'r1',
        name: 'Phòng tắm',
        type: RoomType.bathroom,
        status: RoomStatus.occupied,
        lastMovementAt: DateTime.now(),
        sensorId: 'S3R8',
        lastCheckedAt: DateTime.now(),
      ),
    );

    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();

    expect(find.text('Nhà của Ông Nam'), findsOneWidget);
    // Confirm no hardcoded demo contacts exist
    expect(find.textContaining('Anh Minh'), findsNothing);
    expect(find.textContaining('Bà Lan'), findsNothing);

    // Default dispatch mode is Simultaneous
    expect(ctrl.dispatchMode, AlertDispatchMode.simultaneous);

    ctrl.triggerFallAlert(roomId: 'r1', simulated: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('ĐỒNG THỜI'), findsOneWidget);
    expect(find.textContaining('Chị Hoa'), findsOneWidget);

    await tester.tap(find.text('Tôi đang xử lý (Nhận trách nhiệm)'));
    await tester.pumpAndSettle();
    expect(find.text('Đánh dấu đã xử lý xong'), findsOneWidget);
  });

  testWidgets('Hearth renders cleanly on Tablet 2-pane and Desktop layouts without hardcoded names', (tester) async {
    final ctrl = HearthController();
    await ctrl.load();
    await ctrl.signIn(
      email: 'carer@example.com',
      carerName: 'Linh',
      personName: '',
      skipDirectToHome: true,
    );
    await ctrl.addOrUpdateRoom(
      HearthRoom(
        id: 'r1',
        name: 'Phòng khách',
        type: RoomType.livingRoom,
        status: RoomStatus.occupied,
        lastMovementAt: DateTime.now(),
        sensorId: 'S3R8',
        lastCheckedAt: DateTime.now(),
      ),
    );

    // Tablet 2-pane
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();

    // Neutral fallback title when personName is empty — never "Nhà của Bà Lan"!
    expect(find.text('Ngôi nhà của bạn'), findsOneWidget);
    expect(find.textContaining('Bà Lan'), findsNothing);

    // Desktop layout
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(HearthApp(controller: ctrl));
    await tester.pumpAndSettle();
    expect(find.text('Hoạt động hôm nay'), findsOneWidget);
  });
}
