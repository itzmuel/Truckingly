import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'demo_director.dart';

typedef DemoPresentationStepRunner = Future<void> Function(int step);

enum DemoPresentationOutcome {
  completed,
  completedWithSkips,
  failed,
}

class DemoPresentationController extends ChangeNotifier {
  static const minimumStepDuration = Duration(seconds: 8);

  DemoPresentationMode _mode = DemoPresentationMode.guided;
  int _stepIndex = 0;
  int _stepCount = 0;
  int _furthestStepIndex = 0;
  int _secondsRemaining = 0;
  int _generation = 0;
  bool _active = false;
  bool _playing = false;
  bool _actionInProgress = false;
  bool _observational = false;
  DemoPresentationOutcome? _outcome;
  Object? _actionError;
  StackTrace? _actionErrorStackTrace;
  int? _failedStep;
  List<Duration> _stepDurations = const [];
  final Set<int> _completedActions = {};
  final Set<int> _skippedActions = {};
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
  bool get observational => _observational;
  DemoPresentationOutcome? get outcome => _outcome;
  bool get finishedSuccessfully =>
      _outcome == DemoPresentationOutcome.completed;
  Object? get actionError => _actionError;
  StackTrace? get actionErrorStackTrace => _actionErrorStackTrace;
  Set<int> get completedActions => Set.unmodifiable(_completedActions);
  Set<int> get skippedActions => Set.unmodifiable(_skippedActions);

  Duration get stepDuration =>
      _stepDurations.isEmpty ? Duration.zero : _stepDurations[_stepIndex];

  String get timeLabel {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static List<Duration> allocateStepDurations({
    required Duration totalDuration,
    required List<int> weights,
    Duration minimumDuration = minimumStepDuration,
  }) {
    if (weights.isEmpty || weights.any((weight) => weight <= 0)) {
      throw ArgumentError.value(weights, 'weights', 'Must be positive.');
    }
    final totalSeconds = totalDuration.inSeconds;
    final minimumSeconds = minimumDuration.inSeconds;
    if (minimumSeconds < 0 || totalSeconds < minimumSeconds * weights.length) {
      throw ArgumentError(
        'The total duration must provide at least $minimumSeconds seconds '
        'for each of ${weights.length} steps.',
      );
    }
    final remainingSeconds = totalSeconds - minimumSeconds * weights.length;
    final totalWeight = weights.fold<int>(0, (total, weight) => total + weight);
    var allocatedSeconds = 0;
    return List<Duration>.generate(weights.length, (index) {
      final extraSeconds = index == weights.length - 1
          ? remainingSeconds - allocatedSeconds
          : remainingSeconds * weights[index] ~/ totalWeight;
      allocatedSeconds += extraSeconds;
      return Duration(seconds: minimumSeconds + extraSeconds);
    }, growable: false);
  }

  void start({
    required DemoPresentationMode mode,
    required int lengthMinutes,
    required int stepCount,
    required DemoPresentationStepRunner runStep,
    List<int>? stepWeights,
  }) {
    if (stepCount <= 0) {
      throw ArgumentError.value(stepCount, 'stepCount', 'Must be positive.');
    }
    if (lengthMinutes <= 0) {
      throw ArgumentError.value(lengthMinutes, 'lengthMinutes', 'Must be positive.');
    }
    final weights = stepWeights ?? List<int>.filled(stepCount, 1);
    if (weights.length != stepCount) {
      throw ArgumentError.value(
        weights,
        'stepWeights',
        'Must have one weight per step.',
      );
    }
    _timer?.cancel();
    _generation++;
    _mode = mode;
    _stepIndex = 0;
    _stepCount = stepCount;
    _furthestStepIndex = 0;
    _stepDurations = allocateStepDurations(
      totalDuration: Duration(minutes: lengthMinutes),
      weights: weights,
    );
    _secondsRemaining = _stepDurations.first.inSeconds;
    _active = mode != DemoPresentationMode.explore;
    _playing = mode == DemoPresentationMode.autoplay;
    _actionInProgress = false;
    _observational = false;
    _outcome = null;
    _actionError = null;
    _actionErrorStackTrace = null;
    _failedStep = null;
    _completedActions.clear();
    _skippedActions.clear();
    _runStep = runStep;
    notifyListeners();
    if (_playing) _armTimer();
    scheduleCurrentStep();
  }

  Future<void> advance() async {
    if (_actionInProgress || !_active || _actionError != null) return;
    final completedStep = _stepIndex;
    if (completedStep >= _stepCount - 1) return;
    _timer?.cancel();
    if (!_observational && !_completedActions.contains(completedStep)) {
      await _runAction(completedStep);
      if (!_active ||
          _actionError != null ||
          !_completedActions.contains(completedStep)) {
        return;
      }
    }
    _moveToStep(completedStep + 1);
  }

  void setPlaying(bool playing) {
    if (!_active ||
        _mode != DemoPresentationMode.autoplay ||
        _actionError != null) {
      return;
    }
    _timer?.cancel();
    _playing = playing;
    notifyListeners();
    if (playing) _armTimer();
  }

  void jumpTo(int index) {
    if (index < 0 ||
        index >= _stepCount ||
        index == _stepIndex ||
        _actionError != null) {
      return;
    }
    _timer?.cancel();
    _generation++;
    _actionInProgress = false;
    _stepIndex = index;
    _furthestStepIndex = index > _furthestStepIndex ? index : _furthestStepIndex;
    _observational = index < _furthestStepIndex;
    _secondsRemaining = _stepDurations[index].inSeconds;
    if (_mode == DemoPresentationMode.autoplay && index == _stepCount - 1) {
      _playing = false;
    }
    notifyListeners();
    if (_playing) _armTimer();
    scheduleCurrentStep();
  }

  Future<void> retryFailedAction() async {
    final step = _failedStep;
    if (!_active || step == null || step != _stepIndex) return;
    _clearActionError();
    await _runAction(step);
  }

  void skipFailedAction() {
    final step = _failedStep;
    if (!_active || step == null || step != _stepIndex) return;
    _skippedActions.add(step);
    _clearActionError();
    if (step < _stepCount - 1) {
      _furthestStepIndex = step + 1 > _furthestStepIndex
          ? step + 1
          : _furthestStepIndex;
      _moveToStep(step + 1);
    } else {
      _updateOutcome();
      notifyListeners();
    }
  }

  void stop() {
    _timer?.cancel();
    _generation++;
    _active = false;
    _playing = false;
    _actionInProgress = false;
    _clearActionError(notify: false);
    notifyListeners();
  }

  bool canContinue(int generation) => _active && generation == _generation;

  void completeAction(int step, int generation) {
    if (!canContinue(generation)) return;
    _completedActions.add(step);
    _updateOutcome();
    notifyListeners();
  }

  void scheduleCurrentStep() => _scheduleStep(_stepIndex);

  void _moveToStep(int index) {
    _stepIndex = index;
    _furthestStepIndex = index > _furthestStepIndex ? index : _furthestStepIndex;
    _observational = index < _furthestStepIndex;
    _secondsRemaining = _stepDurations[index].inSeconds;
    notifyListeners();
    if (_playing) _armTimer();
    scheduleCurrentStep();
  }

  void _clearActionError({bool notify = true}) {
    _actionError = null;
    _actionErrorStackTrace = null;
    _failedStep = null;
    _outcome = null;
    if (notify) notifyListeners();
  }

  void _updateOutcome() {
    if (_actionError != null || _stepCount == 0) {
      _outcome = _actionError == null ? null : DemoPresentationOutcome.failed;
      return;
    }
    final accountedFor = _completedActions.length + _skippedActions.length;
    if (_stepIndex != _stepCount - 1 || accountedFor != _stepCount) {
      _outcome = null;
      return;
    }
    _outcome = _skippedActions.isEmpty
        ? DemoPresentationOutcome.completed
        : DemoPresentationOutcome.completedWithSkips;
  }

  Future<void> _runAction(int step) async {
    final runner = _runStep;
    if (!_active ||
        _mode == DemoPresentationMode.explore ||
        _observational ||
        _actionInProgress ||
        _actionError != null ||
        _completedActions.contains(step) ||
        runner == null) {
      return;
    }
    final generation = _generation;
    _actionInProgress = true;
    notifyListeners();
    try {
      await runner(step);
    } catch (error, stackTrace) {
      if (canContinue(generation)) {
        _timer?.cancel();
        _playing = false;
        _actionError = error;
        _actionErrorStackTrace = stackTrace;
        _failedStep = step;
        _outcome = DemoPresentationOutcome.failed;
      }
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
          _observational ||
          _actionError != null ||
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
        if (_completedActions.contains(_stepIndex)) {
          _updateOutcome();
        } else {
          _actionError = StateError(
            'The final presentation action did not complete before its time expired.',
          );
          _actionErrorStackTrace = StackTrace.current;
          _failedStep = _stepIndex;
          _outcome = DemoPresentationOutcome.failed;
        }
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
