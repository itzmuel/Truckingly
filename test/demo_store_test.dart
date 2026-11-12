import 'dart:async';
import 'dart:convert';

import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestPersistence extends MemoryDemoPersistence {
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? writeGate;

  @override
  Future<String?> read() async {
    if (failRead) throw PlatformException(code: 'read_failed');
    return super.read();
  }

  @override
  Future<void> write(String snapshot) async {
    if (writeGate != null) await writeGate!.future;
    if (failWrite) throw PlatformException(code: 'write_failed');
    await super.write(snapshot);
  }
}

void main() {
  final instant = DateTime.utc(2026, 11, 12, 12);

  test('seed metrics and references are consistent and lists immutable',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    expect(store.activeTrips.length, 2);
    expect(store.inTransit, 1);
    expect(store.completedOn(instant), 0);
    expect(store.alerts.length, 2);
    for (final alert in store.alerts) {
      expect(store.trips.any((trip) => trip.code == alert.tripCode), isTrue);
    }
    expect(() => store.trips.clear(), throwsUnsupportedError);
    expect(persistence.snapshot, isNotNull);
  });

  test('simulation survives reload and confirmed reset restores full seed',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await store.advance(instant);
    expect(store.trips.first.status, 'Approaching');
    expect(store.trips.last.status, 'In transit');
    final reloaded = await DemoStore.load(persistence);
    addTearDown(reloaded.dispose);
    expect(reloaded.trips.first.status, 'Approaching');
    expect(reloaded.trips.last.status, 'In transit');
    while (reloaded.canAdvance) {
      await reloaded.advance(instant);
    }
    expect(reloaded.activeTrips, isEmpty);
    expect(reloaded.completedOn(instant), 2);
    expect(reloaded.alerts.length, 2);
    expect(
      () => reloaded.advance(instant),
      throwsStateError,
    );
    final completedSnapshot = await DemoStore.load(persistence);
    addTearDown(completedSnapshot.dispose);
    expect(completedSnapshot.completedOn(instant), 2);
    await reloaded.reset();
    final reset = await DemoStore.load(persistence);
    addTearDown(reset.dispose);
    expect(reset.activeTrips.length, 2);
    expect(reset.inTransit, 1);
    expect(reset.completedOn(instant), 0);
    expect(reset.trips.every((trip) => trip.completedAt == null), isTrue);
  });

  test('completed today uses Lagos date across UTC midnight', () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final completion = DateTime.utc(2026, 11, 11, 23, 30);
    while (store.canAdvance) {
      await store.advance(completion);
    }
    expect(store.completedOn(DateTime.utc(2026, 11, 12, 12)), 2);
    expect(store.completedOn(DateTime.utc(2026, 11, 11, 12)), 0);
  });

  test('failed save and reset do not publish partial data', () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final original = persistence.snapshot;
    persistence.failWrite = true;
    await expectLater(store.advance(instant), throwsA(isA<PlatformException>()));
    expect(store.trips.first.status, 'In transit');
    expect(persistence.snapshot, original);
    expect(store.saving, isFalse);
    persistence.failWrite = false;
    await store.advance(instant);
    persistence.failWrite = true;
    await expectLater(store.reset(), throwsA(isA<PlatformException>()));
    expect(store.trips.first.status, 'Approaching');
    persistence.failWrite = false;
    await store.reset();
    expect(store.trips.first.status, 'In transit');
  });

  test('pending save prevents double advance and notifies when finished',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);
    persistence.writeGate = Completer<void>();
    final save = store.advance(instant);
    expect(store.saving, isTrue);
    expect(store.trips.first.status, 'In transit');
    await expectLater(store.advance(instant), throwsStateError);
    persistence.writeGate!.complete();
    await save;
    expect(store.saving, isFalse);
    expect(store.trips.first.status, 'Approaching');
    expect(notifications, 2);
  });

  test('read failure is explicit and does not replace saved data', () async {
    final persistence = TestPersistence()..snapshot = 'keep this';
    persistence.failRead = true;
    await expectLater(
        DemoStore.load(persistence), throwsA(isA<PlatformException>()));
    expect(persistence.snapshot, 'keep this');
  });

  test('corrupt or unsupported snapshots require explicit restoration',
      () async {
    final persistence = TestPersistence();
    for (final raw in [
      '{broken',
      '{"version":2,"trips":[],"alerts":[]}',
      '{"version":1,"trips":[42],"alerts":[]}',
    ]) {
      persistence.snapshot = raw;
      await expectLater(
          DemoStore.load(persistence), throwsA(isA<FormatException>()));
      expect(persistence.snapshot, raw);
    }
    final restored = await DemoStore.restore(persistence);
    addTearDown(restored.dispose);
    expect(restored.activeTrips.length, 2);
  });

  test('invalid statuses, progress, timestamps and references are rejected',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final valid = persistence.snapshot!;
    for (final field in [
      ('status', 'Teleporting'),
      ('progress', -1),
      ('progress', 2),
      ('completedAt', 'not-a-date'),
      ('completedAt', '2026-11-12T12:00:00'),
      ('status', 'Completed'),
    ]) {
      final decoded = jsonDecode(valid) as Map<String, dynamic>;
      decoded['trips'][0][field.$1] = field.$2;
      persistence.snapshot = jsonEncode(decoded);
      await expectLater(
          DemoStore.load(persistence), throwsA(isA<FormatException>()));
    }
    final decoded = jsonDecode(valid) as Map<String, dynamic>;
    decoded['alerts'][0]['tripCode'] = 'missing-trip';
    persistence.snapshot = jsonEncode(decoded);
    await expectLater(
        DemoStore.load(persistence), throwsA(isA<FormatException>()));
    decoded['alerts'][0]['tripCode'] = 'TR-2048';
    decoded['trips'].add(decoded['trips'][0]);
    persistence.snapshot = jsonEncode(decoded);
    await expectLater(
        DemoStore.load(persistence), throwsA(isA<FormatException>()));
  });
}
