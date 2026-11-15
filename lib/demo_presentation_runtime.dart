part of 'main.dart';

extension _DemoPresentationRuntime on _OperationsShellState {
  Future<void> _completePresentationStep() => _presentationPlayback.advance();

  Future<void> _performPresentationAction(
    GlobalKey target,
    String label,
    int generation, {
    Future<void> Function()? onActivate,
    ScrollController? scrollController,
  }) async {
    bool canContinue() =>
        mounted &&
        _presentationActive &&
        generation == _presentationTouchGeneration;
    if (!canContinue()) return;
    await DemoTouchPointer.showAndActivate(
      context,
      target,
      label: label,
      onActivate: onActivate,
      scrollController: scrollController,
      shouldContinue: canContinue,
    );
    if (!canContinue()) return;
  }

  Future<void> _waitForDemoSave(int generation) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (_demo.saving &&
        mounted &&
        _presentationActive &&
        generation == _presentationTouchGeneration &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (_demo.saving &&
        mounted &&
        _presentationActive &&
        generation == _presentationTouchGeneration) {
      throw StateError('The demo save did not finish in time.');
    }
  }

  bool _presentationCanContinue(int generation) =>
      mounted &&
      _presentationActive &&
      generation == _presentationTouchGeneration;

  Future<void> _waitForPresentationState(
    bool Function() isReady,
    int generation, {
    String description = 'The presentation control did not become available.',
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!isReady() &&
        _presentationCanContinue(generation) &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (_presentationCanContinue(generation) && !isReady()) {
      throw StateError(description);
    }
  }

  void _setPresentationPlaying(bool playing) {
    _presentationPlayback.setPlaying(playing);
  }

  void _jumpPresentationTo(int index) {
    _presentationPlayback.jumpTo(index);
  }

  void _stopPresentation() {
    _presentationPlayback.stop();
    _setPresentationActionState(() {
      _tab = 0;
      _morePage = null;
    });
  }
}
