import 'dart:async';

import 'package:dumptrak_mobile_prototype/demo_director.dart';
import 'package:dumptrak_mobile_prototype/demo_paths.dart';
import 'package:dumptrak_mobile_prototype/demo_presentation_controller.dart';
import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weighted autoplay durations keep a minimum and total session length',
      () {
    final durations = DemoPresentationController.allocateStepDurations(
      totalDuration: const Duration(minutes: 2),
      weights: [1, 3, 2],
    );

    expect(durations, [
      const Duration(seconds: 24),
      const Duration(seconds: 56),
      const Duration(seconds: 40),
    ]);
    expect(durations.reduce((total, duration) => total + duration),
        const Duration(minutes: 2));
    expect(
        durations.every((duration) =>
            duration >= DemoPresentationController.minimumStepDuration),
        isTrue);
    expect(
      () => DemoPresentationController.allocateStepDurations(
        totalDuration: const Duration(minutes: 3),
        weights: List<int>.filled(35, 1),
      ),
      throwsArgumentError,
    );
  });

  testWidgets('guided playback runs steps once and advances after completion',
      (tester) async {
    final controller = DemoPresentationController();
    addTearDown(controller.dispose);
    final ranSteps = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, child) => Text(
            '${controller.stepIndex}:${controller.completedActions.length}',
          ),
        ),
      ),
    );
    controller.start(
      mode: DemoPresentationMode.guided,
      lengthMinutes: 3,
      stepCount: 2,
      runStep: (step) async {
        ranSteps.add(step);
        controller.completeAction(step, controller.generation);
      },
    );
    await tester.pump();
    await tester.pump();

    expect(ranSteps, [0]);
    expect(controller.completedActions, {0});
    await controller.advance();
    await tester.pump();
    await tester.pump();

    expect(controller.stepIndex, 1);
    expect(ranSteps, [0, 1]);
    expect(controller.completedActions, {0, 1});
  });

  testWidgets('stopping invalidates an in-flight playback action',
      (tester) async {
    final controller = DemoPresentationController();
    addTearDown(controller.dispose);
    final actionStarted = Completer<void>();
    final finishAction = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, child) => Text('${controller.stepIndex}'),
        ),
      ),
    );
    controller.start(
      mode: DemoPresentationMode.guided,
      lengthMinutes: 3,
      stepCount: 2,
      runStep: (step) async {
        final generation = controller.generation;
        actionStarted.complete();
        await finishAction.future;
        controller.completeAction(step, generation);
      },
    );
    await tester.pump();
    await actionStarted.future;

    controller.stop();
    finishAction.complete();
    await tester.pump();
    await tester.pump();

    expect(controller.active, isFalse);
    expect(controller.completedActions, isEmpty);
    expect(controller.stepIndex, 0);
  });

  testWidgets('playback catches action errors and offers an explicit retry',
      (tester) async {
    final controller = DemoPresentationController();
    addTearDown(controller.dispose);
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, child) => Text(
            '${controller.actionError}:${controller.playing}',
          ),
        ),
      ),
    );

    controller.start(
      mode: DemoPresentationMode.autoplay,
      lengthMinutes: 1,
      stepCount: 1,
      runStep: (step) async {
        attempts++;
        if (attempts == 1) throw RangeError('sample action failed');
        controller.completeAction(step, controller.generation);
      },
    );
    await tester.pump();
    await tester.pump();

    expect(controller.actionError, isA<RangeError>());
    expect(controller.actionError.toString(), contains('sample action failed'));
    expect(controller.playing, isFalse);
    expect(controller.actionInProgress, isFalse);
    expect(tester.takeException(), isNull);

    await controller.retryFailedAction();
    await tester.pump();
    expect(attempts, 2);
    expect(controller.actionError, isNull);
    expect(controller.completedActions, {0});
    expect(controller.playing, isFalse);
  });

  testWidgets('skipping a failed action advances and records the skipped step',
      (tester) async {
    final controller = DemoPresentationController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, child) => Text('${controller.stepIndex}'),
        ),
      ),
    );
    controller.start(
      mode: DemoPresentationMode.guided,
      lengthMinutes: 1,
      stepCount: 2,
      runStep: (step) async {
        if (step == 0) throw StateError('cannot run step');
        controller.completeAction(step, controller.generation);
      },
    );
    await tester.pump();
    await tester.pump();
    expect(controller.actionError, isA<StateError>());

    controller.skipFailedAction();
    await tester.pump();
    await tester.pump();

    expect(controller.stepIndex, 1);
    expect(controller.skippedActions, {0});
    expect(controller.completedActions, {1});
    expect(controller.actionError, isNull);
  });

  testWidgets('backward jumps are observational for unfinished actions',
      (tester) async {
    final controller = DemoPresentationController();
    addTearDown(controller.dispose);
    final ranSteps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, child) => Text('${controller.stepIndex}'),
        ),
      ),
    );
    controller.start(
      mode: DemoPresentationMode.guided,
      lengthMinutes: 1,
      stepCount: 3,
      runStep: (step) async {
        ranSteps.add(step);
        controller.completeAction(step, controller.generation);
      },
    );
    await tester.pump();
    await tester.pump();
    controller.jumpTo(2);
    await tester.pump();
    await tester.pump();
    controller.jumpTo(1);
    await tester.pump();
    await tester.pump();

    expect(controller.observational, isTrue);
    expect(ranSteps, [0, 2]);
    await controller.advance();
    await tester.pump();
    await tester.pump();
    expect(controller.stepIndex, 2);
    expect(controller.observational, isFalse);
    expect(ranSteps, [0, 2]);
  });

  testWidgets('Full Enterprise autoplay completes each route using its timer',
      (tester) async {
    for (final scenario in DemoScenario.values) {
      final controller = DemoPresentationController();
      addTearDown(controller.dispose);
      final route = DemoPathGenerator.generate(
        audience: DemoPathAudience.allPersonnel,
        scenario: scenario,
      );
      final ranSteps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: controller,
            builder: (context, child) => Text(
              '${controller.stepIndex}:${controller.completedActions.length}',
            ),
          ),
        ),
      );
      controller.start(
        mode: DemoPresentationMode.autoplay,
        lengthMinutes: 8,
        stepCount: route.length,
        stepWeights: route.map((step) => step.durationWeight).toList(),
        runStep: (step) async {
          ranSteps.add(step);
          controller.completeAction(step, controller.generation);
        },
      );
      await tester.pump();
      await tester.pump();

      for (var index = 0;
          index < route.length + 2 && controller.playing;
          index++) {
        await tester.pump(Duration(seconds: controller.secondsRemaining));
        await tester.pump();
        await tester.pump();
      }

      expect(controller.actionError, isNull, reason: scenario.name);
      expect(controller.playing, isFalse, reason: scenario.name);
      expect(
          controller.completedActions,
          Set<int>.from(
            List<int>.generate(route.length, (index) => index),
          ),
          reason: scenario.name);
      expect(ranSteps, List<int>.generate(route.length, (index) => index),
          reason: scenario.name);
      expect(tester.takeException(), isNull, reason: scenario.name);
    }
  });
}
