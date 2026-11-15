import 'dart:async';

import 'package:dumptrak_mobile_prototype/demo_director.dart';
import 'package:dumptrak_mobile_prototype/demo_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
