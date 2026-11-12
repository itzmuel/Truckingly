import 'package:dumptrak_mobile_prototype/demo_paths.dart';
import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates different paths for each personnel perspective', () {
    final administrator = DemoPathGenerator.generate(
      audience: DemoPathAudience.administrator,
      scenario: DemoScenario.normal,
    );
    final dispatcher = DemoPathGenerator.generate(
      audience: DemoPathAudience.dispatcher,
      scenario: DemoScenario.normal,
    );
    final driver = DemoPathGenerator.generate(
      audience: DemoPathAudience.driver,
      scenario: DemoScenario.normal,
    );
    final supervisor = DemoPathGenerator.generate(
      audience: DemoPathAudience.supervisor,
      scenario: DemoScenario.normal,
    );

    expect(administrator.any((step) => step.action == 'inspect-intelligence'),
        isTrue);
    expect(dispatcher.any((step) => step.action == 'create-trip'), isTrue);
    expect(
        dispatcher.where((step) => step.action == 'progress-trip').length, 1);
    expect(
      dispatcher
          .singleWhere((step) => step.action == 'progress-trip')
          .targetStatus,
      'In transit',
    );
    expect(driver.any((step) => step.action == 'record-visit'), isTrue);
    final driverProgress =
        driver.where((step) => step.action == 'progress-trip').toList();
    expect(driverProgress.map((step) => step.targetStatus),
        ['Arrived', 'Completed']);
    expect(
        supervisor.any((step) => step.action == 'investigate-alert'), isTrue);
    expect(supervisor.any((step) => step.action == 'filter-alerts'), isTrue);
    expect(supervisor.any((step) => step.action == 'resolve-alert'), isTrue);
  });

  test('incident paths inspect exceptions instead of advancing them', () {
    for (final audience in DemoPathAudience.values
        .where((audience) => audience != DemoPathAudience.administrator)) {
      final path = DemoPathGenerator.generate(
        audience: audience,
        scenario: DemoScenario.vehicleIncident,
      );
      if (audience != DemoPathAudience.supervisor) {
        expect(path.any((step) => step.action == 'inspect-exception'), isTrue);
      }
      expect(path.any((step) => step.action == 'progress-trip'), isFalse);
    }
  });

  test('Full Enterprise scenario handoffs preserve a single relevant trip', () {
    for (final scenario in DemoScenario.values) {
      final path = DemoPathGenerator.generate(
        audience: DemoPathAudience.allPersonnel,
        scenario: scenario,
      );
      final dispatcherSteps = path
          .where((step) => step.role == DemoPathAudience.dispatcher)
          .toList();
      final driverSteps =
          path.where((step) => step.role == DemoPathAudience.driver).toList();
      final dispatchProgress = dispatcherSteps
          .where((step) => step.action == 'progress-trip')
          .toList();
      final driverProgress =
          driverSteps.where((step) => step.action == 'progress-trip').toList();

      if (scenario == DemoScenario.normal) {
        expect(dispatcherSteps.any((step) => step.action == 'create-trip'),
            isTrue);
        expect(dispatchProgress.single.targetStatus, 'In transit');
        expect(driverProgress.map((step) => step.targetStatus),
            ['Arrived', 'Completed']);
      } else if (scenario == DemoScenario.delayedDelivery) {
        expect(dispatcherSteps.any((step) => step.action == 'create-trip'),
            isFalse);
        expect(dispatcherSteps.any((step) => step.action == 'inspect-trip'),
            isTrue);
        expect(driverProgress.map((step) => step.targetStatus),
            ['Arrived', 'Completed']);
      } else {
        expect(dispatcherSteps.any((step) => step.action == 'create-trip'),
            isFalse);
        expect(
            dispatcherSteps.any((step) => step.action == 'inspect-exception'),
            isTrue);
        expect(driverSteps.any((step) => step.action == 'inspect-exception'),
            isTrue);
        expect(dispatchProgress, isEmpty);
        expect(driverProgress, isEmpty);
        expect(
            driverSteps.any((step) => step.action == 'record-visit'), isFalse);
      }
    }
  });

  test('All Personnel combines paths in the requested role order', () {
    final path = DemoPathGenerator.generate(
      audience: DemoPathAudience.allPersonnel,
      scenario: DemoScenario.normal,
    );
    final roles = path.map((step) => step.role).toSet();

    expect(roles, {
      DemoPathAudience.administrator,
      DemoPathAudience.dispatcher,
      DemoPathAudience.driver,
      DemoPathAudience.supervisor,
    });
    expect(path.first.role, DemoPathAudience.administrator);
    expect(
      path.indexWhere((step) => step.role == DemoPathAudience.dispatcher),
      greaterThan(path.lastIndexWhere(
          (step) => step.role == DemoPathAudience.administrator)),
    );
    expect(
      path.indexWhere((step) => step.role == DemoPathAudience.driver),
      greaterThan(path
          .lastIndexWhere((step) => step.role == DemoPathAudience.dispatcher)),
    );
    expect(
      path.indexWhere((step) => step.role == DemoPathAudience.supervisor),
      greaterThan(
          path.lastIndexWhere((step) => step.role == DemoPathAudience.driver)),
    );
  });
}
