import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:dumptrak_mobile_prototype/reports_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Reports opens from More and returns to the tools menu',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsPage), findsOneWidget);
    expect(find.text('Presentation prototype'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'More'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsPage), findsNothing);
    expect(find.text('Tools and account'), findsOneWidget);
  });

  testWidgets('date pickers allow inclusive single day and cancel safely',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: ReportsPage(onBack: () {})),
    ));
    final before =
        tester.widget<Text>(find.byKey(const ValueKey('report-period'))).data;
    await tester.tap(find.byKey(const ValueKey('report-from')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('report-period'))).data,
        before);

    await tester.tap(find.byKey(const ValueKey('report-to')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final period =
        tester.widget<Text>(find.byKey(const ValueKey('report-period'))).data!;
    final dates = period.split(' · ').first.split(' to ');
    expect(dates[0], dates[1]);
    await tester.scrollUntilVisible(
      find.text('Daily sample counts · 1 day'),
      350,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Daily sample counts · 1 day')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily sample counts · 1 day'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report scope flows into provenance and export is explicit',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: ReportsPage(onBack: () {})),
    ));
    final filter = find.byKey(const ValueKey('report-assets'));
    await tester.scrollUntilVisible(filter, 200);
    await Scrollable.ensureVisible(tester.element(filter), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vehicles only').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Data quality and provenance'), 400);
    await tester.scrollUntilVisible(find.text('No evidence read'), 200);
    expect(find.text('No evidence read'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Vehicles only'), 150);
    expect(find.text('Vehicles only'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('report-export')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('report-export')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Excel export is unavailable'), findsOneWidget);
  });

  testWidgets('other report sections never present unconnected results',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ReportsPage(onBack: () {})),
    ));
    for (final section in [
      'Maintenance',
      'Fleet assets and instruments',
      'Guided questions'
    ]) {
      await tester.tap(find.byKey(ValueKey('report-section-$section')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('This report is not connected'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-assets')), findsNothing);
    }
  });
}
