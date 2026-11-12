import 'dart:async';
import 'dart:convert';

import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/demo_fleet.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;

const id = 'alert-tracking';

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200,
      scrollable: find.byType(Scrollable).last);
  await Scrollable.ensureVisible(tester.element(target.first), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(ValueKey(key));
  await reveal(tester, finder);
  await tester.enterText(finder, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, DemoStore store) async {
  await tester.pumpWidget(DumptrakPrototypeApp(store: store));
  await tester.tap(find.text('Alerts').last);
  await tester.pumpAndSettle();
  final manage = find.descendant(
      of: find.byKey(const ValueKey('alert-card-alert-tracking')),
      matching: find.text('Manage demo alert'));
  await reveal(tester, manage);
  await tester.tap(manage);
  await tester.pumpAndSettle();
}

void main() {
  test('lifecycle persists and resolved alerts stop counting as open', () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await store.acknowledgeAlert(id);
    expect(store.openAlerts.length, 2);
    await store.assignAlert(id, 'Ada Nwosu');
    await store.addAlertNote(id, '  Review sample tracker  ');
    final now = DateTime.utc(2026, 11, 12, 12);
    await store.resolveAlert(id, 'Reviewed in simulation', now);
    expect(store.openAlerts.length, 1);
    expect(store.resolvedAlerts.length, 1);
    expect(demoFleet(store).first.status, DemoVehicleStatus.moving);
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    final alert = loaded.alertById(id);
    expect(alert.acknowledged, isTrue);
    expect(alert.supervisor, 'Ada Nwosu');
    expect(alert.notes, ['Review sample tracker']);
    expect(alert.resolvedAt, now);
    expect(alert.resolution, 'Reviewed in simulation');
    await expectLater(loaded.addAlertNote(id, 'change'),
        throwsA(isA<FormatException>()));
    await expectLater(loaded.resolveAlert(id, 'again', now),
        throwsA(isA<FormatException>()));
    await store.reset();
    expect(store.openAlerts.length, 2);
    expect(store.resolvedAlerts, isEmpty);
    expect(store.alertById(id).notes, isEmpty);
    expect(demoFleet(store).first.status, DemoVehicleStatus.reportingGap);
  });

  test('validation, unknown IDs and failed writes preserve saved state',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final before = persistence.snapshot;
    for (final action in [
      () => store.assignAlert(id, 'not a supervisor'),
      () => store.addAlertNote(id, ' '),
      () => store.addAlertNote(id, 'x' * 501),
      () => store.resolveAlert(id, '', DateTime.now()),
      () => store.acknowledgeAlert('missing'),
    ]) {
      await expectLater(action(), throwsA(isA<FormatException>()));
    }
    persistence.failWrite = true;
    for (final action in [
      () => store.acknowledgeAlert(id),
      () => store.assignAlert(id, 'Ada Nwosu'),
      () => store.addAlertNote(id, 'sample note'),
      () => store.resolveAlert(id, 'sample closure', DateTime.now()),
    ]) {
      await expectLater(action(), throwsA(isA<PlatformException>()));
    }
    expect(persistence.snapshot, before);
    expect(store.alertById(id).acknowledged, isFalse);
    expect(store.alertById(id).notes, isEmpty);
    expect(store.openAlerts.length, 2);
    persistence.failWrite = false;
    await store.acknowledgeAlert(id);
    expect(store.alertById(id).acknowledged, isTrue);
  });

  test('legacy alerts load; invalid lifecycle data is not silently discarded',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final saved = persistence.snapshot!;
    final old = jsonDecode(saved) as Map<String, dynamic>;
    for (final alert in old['alerts']) {
      for (final key in ['acknowledged','supervisor','notes','resolvedAt','resolution']) {
        alert.remove(key);
      }
    }
    persistence.snapshot = jsonEncode(old);
    final legacy = await DemoStore.load(persistence);
    addTearDown(legacy.dispose);
    expect(legacy.openAlerts.length, 2);
    for (final (field, value) in [
      ('acknowledged', 'yes'),
      ('supervisor', 'unknown'),
      ('notes', [42]),
      ('notes', ['']),
      ('resolvedAt', 'bad'),
      ('resolvedAt', '2026-11-12T12:00:00Z'),
      ('resolution', 'without closure time'),
    ]) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      decoded['alerts'][0][field] = value;
      final raw = jsonEncode(decoded);
      persistence.snapshot = raw;
      await expectLater(
          DemoStore.load(persistence), throwsA(isA<FormatException>()));
      expect(persistence.snapshot, raw);
    }
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('alert management, history and counters at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final store = DemoStore.memory();
      addTearDown(store.dispose);
      await open(tester, store);
      await tap(tester, 'acknowledge-alert');
      expect(store.alertById(id).acknowledged, isTrue);
      await tap(tester, 'alert-supervisor');
      await tester.tap(find.text('Ada Nwosu').last);
      await tester.pumpAndSettle();
      await tap(tester, 'assign-alert');
      expect(store.alertById(id).supervisor, 'Ada Nwosu');
      await enter(tester, 'alert-note', 'Demo review completed');
      await tap(tester, 'save-alert-note');
      expect(store.alertById(id).notes, ['Demo review completed']);
      await enter(tester, 'alert-resolution', 'Closed after simulated review');
      await tap(tester, 'resolve-alert');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.openAlerts.length, 2);
      await tap(tester, 'resolve-alert');
      await tester.tap(find.text('Resolve demo alert'));
      await tester.pumpAndSettle();
      expect(store.openAlerts.length, 1);
      expect(find.byKey(const ValueKey('resolve-alert')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final history = find.byKey(const ValueKey('alert-section-History'));
      await tester.scrollUntilVisible(history, -200);
      await Scrollable.ensureVisible(tester.element(history));
      await tester.pumpAndSettle();
      await tester.tap(history);
      await tester.pumpAndSettle();
      await tap(tester, 'history-alert-$id');
      expect(find.text('Demo alert'), findsOneWidget);
      expect(find.byKey(const ValueKey('acknowledge-alert')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      final metrics = tester.widgetList<MetricCard>(find.byType(MetricCard));
      expect(metrics.firstWhere((m) => m.label == 'NEEDS ACTION').value, '1');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed note save retains input and retry adds once',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await open(tester, store);
    await enter(tester, 'alert-note', 'Retry this note');
    persistence.failWrite = true;
    await tap(tester, 'save-alert-note');
    await reveal(tester, find.textContaining('Could not save demo alert:'));
    expect(store.alertById(id).notes, isEmpty);
    persistence.failWrite = false;
    final save = find.byKey(const ValueKey('save-alert-note'));
    await tester.scrollUntilVisible(save, -200,
        scrollable: find.byType(Scrollable).last);
    await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(store.alertById(id).notes, ['Retry this note']);
  });

  testWidgets('pending alert save blocks duplicate actions and Back',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await open(tester, store);
    final acknowledge = find.byKey(const ValueKey('acknowledge-alert'));
    await reveal(tester, acknowledge);
    persistence.writeGate = Completer<void>();
    await tester.tap(acknowledge);
    await tester.pump();
    expect(tester.widget<FilledButton>(acknowledge).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Demo alert'), findsOneWidget);
    persistence.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(store.alertById(id).acknowledged, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Needs Action (2)'), -200);
    expect(store.openAlerts.length, 2);
  });
}
