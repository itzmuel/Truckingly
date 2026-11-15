import 'package:dumptrak_mobile_prototype/demo_touch_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long touch labels stay within narrow overlay bounds',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final targetKey = GlobalKey();
    const label = 'Review Customer visits report';
    var activated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: SizedBox(
                  key: targetKey,
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final activation = DemoTouchPointer.showAndActivate(
      tester.element(find.byKey(targetKey)),
      targetKey,
      label: label,
      onActivate: () async {
        activated = true;
      },
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 500));

    final mark = find.ancestor(
      of: find.text(label),
      matching: find.byType(Column),
    );
    expect(mark, findsOneWidget);
    final markRect = tester.getRect(mark);
    expect(markRect.left, greaterThanOrEqualTo(0));
    expect(markRect.right, lessThanOrEqualTo(360));
    expect(markRect.top, greaterThanOrEqualTo(0));
    expect(markRect.bottom, lessThanOrEqualTo(640));
    final targetCenter = tester.getRect(find.byKey(targetKey)).center;
    final markerCenter =
        tester.getRect(find.byIcon(Icons.touch_app_rounded)).center;
    expect((markerCenter - targetCenter).distance, lessThan(40));

    await tester.pump(const Duration(seconds: 2));
    await activation;
    expect(activated, isTrue);
    expect(tester.takeException(), isNull);
  });
}
