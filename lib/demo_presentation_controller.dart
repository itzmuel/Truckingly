import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'demo_director.dart';

typedef DemoPresentationStepRunner = Future<void> Function(int step);

class DemoPresentationController extends ChangeNotifier {
  DemoPresentationMode _mode = DemoPresentationMode.guided;
  int _stepIndex = 0;
  int _stepCount = 0;
  int _secondsRemaining = 0;
  int _generation = 0;
  bool _active = false;
  bool _playing = false;
  bool _actionInProgress = false;
  Duration _stepDuration = Duration.zero;
  final Set<int> _completedActions = {};
  Timer? _timer;
  DemoPresentationStepRunner? _runStep;

  DemoPresentationMode get mode => _mode;
  int get stepIndex => _stepIndex;
  int get stepCount => _stepCount;
  int get secondsRemaining => _secondsRemaining;
  int get generation => _generation;
  bool get active => _active;
  bool get playing => _playing;
  bool get actionInProgress => _actionInProgress;
  Set<int> get completedActions => Set.unmodifiable(_completedActions);

  Duration get stepDuration => _stepDuration;

  String get timeLabel {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void start({
    required DemoPresentationMode mode,
    required int lengthMinutes,
    required int stepCount,
    required DemoPresentationStepRunner runStep,
  }) {
    if (stepCount <= 0) {
      throw ArgumentError.value(stepCount, 'stepCount', 'Must be positive.');
    }
    _timer?.cancel();
    _generation++;
    _mode = mode;
    _stepIndex = 0;
    _stepCount = stepCount;
    _stepDuration = Duration(seconds: lengthMinutes * 60 ~/ stepCount);
    _secondsRemaining = _stepDuration.inSeconds;
    _active = mode != DemoPresentationMode.explore;
    _playing = mode == DemoPresentationMode.autoplay;
    _actionInProgress = false;
    _completedActions.clear();
    _runStep = runStep;
    notifyListeners();
    if (_playing) _armTimer();
    scheduleCurrentStep();
  }

  Future<void> advance() async {
    if (_actionInProgress || !_active) return;
    final completedStep = _stepIndex;
    if (completedStep >= _stepCount - 1) return;
    _timer?.cancel();
    if (!_completedActions.contains(completedStep)) {
      await _runAction(completedStep);
      if (!_active || !_completedActions.contains(completedStep)) return;
    }
    _stepIndex++;
    _secondsRemaining = _stepDuration.inSeconds;
    notifyListeners();
    if (_playing) _armTimer();
    scheduleCurrentStep();
  }

  void setPlaying(bool playing) {
    if (!_active || _mode != DemoPresentationMode.autoplay) return;
    _timer?.cancel();
    _playing = playing;
    notifyListeners();
    if (playing) _armTimer();
  }

  void jumpTo(int index) {
    if (index < 0 || index >= _stepCount) return;
    _timer?.cancel();
    _generation++;
    _actionInProgress = false;
    _stepIndex = index;
    _secondsRemaining = _stepDuration.inSeconds;
    if (_mode == DemoPresentationMode.autoplay && index == _stepCount - 1) {
      _playing = false;
    }
    notifyListeners();
    if (_playing) _armTimer();
    scheduleCurrentStep();
  }

  void stop() {
    _timer?.cancel();
    _generation++;
    _active = false;
    _playing = false;
    _actionInProgress = false;
    notifyListeners();
  }

  bool canContinue(int generation) => _active && generation == _generation;

  void completeAction(int step, int generation) {
    if (!canContinue(generation)) return;
    _completedActions.add(step);
    notifyListeners();
  }

  void scheduleCurrentStep() => _scheduleStep(_stepIndex);

  Future<void> _runAction(int step) async {
    final runner = _runStep;
    if (!_active ||
        _mode == DemoPresentationMode.explore ||
        _actionInProgress ||
        _completedActions.contains(step) ||
        runner == null) {
      return;
    }
    final generation = _generation;
    _actionInProgress = true;
    notifyListeners();
    try {
      await runner(step);
    } finally {
      if (canContinue(generation)) {
        _actionInProgress = false;
        notifyListeners();
      }
    }
  }

  void _scheduleStep(int step) {
    if (_runStep == null) return;
    final generation = _generation;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!canContinue(generation) ||
          _mode == DemoPresentationMode.explore ||
          step != _stepIndex) {
        return;
      }
      unawaited(_runAction(step));
    });
  }

  void _armTimer() {
    _timer?.cancel();
    if (!_active || !_playing || _mode != DemoPresentationMode.autoplay) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_active || !_playing) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        notifyListeners();
        return;
      }
      if (_actionInProgress) return;
      timer.cancel();
      if (_stepIndex >= _stepCount - 1) {
        _secondsRemaining = 0;
        _playing = false;
        notifyListeners();
        return;
      }
      unawaited(advance());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
