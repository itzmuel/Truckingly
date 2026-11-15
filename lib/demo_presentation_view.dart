part of 'main.dart';

extension _DemoPresentationView on _OperationsShellState {
  String _presentationTimeLabel() => _presentation.playback.timeLabel;

  String _presentationNarration(DemoPathStep step) {
    final focus = switch (step.role) {
      DemoPathAudience.administrator =>
        'Administrator Ada Nwosu oversees fleet-wide activity.',
      DemoPathAudience.dispatcher =>
        'Dispatcher Samuel Onyenwe coordinates trip assignments.',
      DemoPathAudience.supervisor =>
        'Supervisor Femi Adewale investigates operational situations.',
      DemoPathAudience.driver =>
        'Driver Ayo Bello follows an assigned journey.',
      DemoPathAudience.allPersonnel => 'All Personnel tour.',
    };
    return '$focus ${step.description} Perspective is a demo lens, not access control.';
  }

  Widget _presentationRoleHandoff(DemoPathStep step) {
    final playback = _presentation.playback;
    if (playback.stepIndex == 0) return const SizedBox.shrink();
    final previous = _presentation.steps[playback.stepIndex - 1];
    if (previous.role == step.role) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('presentation-role-transition'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2233),
        border: Border.all(color: _blue.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: _blue, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Role handoff · ${previous.role.label} → ${step.role.label}',
              style: const TextStyle(
                color: _blue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presentationSummary() {
    final playback = _presentation.playback;
    final completed = playback.completedActions;
    final outcomeLabel = switch (playback.outcome) {
      DemoPresentationOutcome.completed => 'Completed',
      DemoPresentationOutcome.completedWithSkips => 'Completed with skipped steps',
      DemoPresentationOutcome.failed => 'Failed',
      null => 'In progress',
    };
    final handledAlerts = completed.where((index) {
      final action = _presentation.steps[index].action;
      return action == 'acknowledge-alert' || action == 'resolve-alert';
    }).length;
    final reviewedReports = completed.where((index) {
      final action = _presentation.steps[index].action;
      return action == 'inspect-reports' ||
          action == 'inspect-visits' ||
          action == 'inspect-visits-report';
    }).length;
    return Container(
      key: const ValueKey('presentation-journey-summary'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF10251D),
        border: Border.all(color: _green.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            outcomeLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: playback.outcome == DemoPresentationOutcome.completed
                  ? _green
                  : const Color(0xFFFFA000),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${completed.length} of ${_presentation.steps.length} steps completed'
            ' · ${playback.skippedActions.length} skipped'
            ' · $handledAlerts alert${handledAlerts == 1 ? '' : 's'} handled'
            ' · $reviewedReports report${reviewedReports == 1 ? '' : 's'} reviewed',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _presentationScreenContent() {
    final screen = _presentationCurrentStep.screen;
    final content = switch (screen) {
      'Home' => _homePage(),
      'Trips' => _tripsPage(),
      'Map' => _mapPage(),
      'Alerts' => _alertsPage(),
      'Reports' => ReportsPage(
          key: _presentationReportsPageKey,
          onBack: () {
            if (_presentationStep > 0) {
              _jumpPresentationTo(_presentationStep - 1);
            } else {
              _stopPresentation();
            }
          },
          trips: _demo.trips,
          alerts: _demo.alerts,
          visits: _demo.visits,
          presentationSectionKey: _presentation.reportSection != null &&
                  _presentation.reportSection != 'Customer visits'
              ? _presentationPrimaryTargetKey
              : null,
          presentationSection: _presentation.reportSection,
          presentationCustomerVisitsKey:
              _presentation.reportSection == 'Customer visits'
                  ? _presentationPrimaryTargetKey
                  : null,
          scrollController: _presentationReportsScrollController,
        ),
      'More' => _morePageView(),
      'Intelligence' => _intelligencePage(),
      'Compliance' => _moreDetailPage(titleOverride: 'Compliance & documents'),
      'Settlement' => _partnerPage(isSettlement: true),
      'FleetOps' => _partnerPage(isSettlement: false),
      _ => throw StateError('Unknown presentation screen: $screen'),
    };
    return KeyedSubtree(key: _presentationPageTargetKey, child: content);
  }

  Widget _presentationPage() {
    final step = _presentation.steps[_presentationStep];
    final lastStep = _presentationStep == _presentation.steps.length - 1;
    final playback = _presentation.playback;
    final hasPresentationError = playback.actionError != null;
    final showOutcome = playback.outcome != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.present_to_all_rounded,
                        color: _blue, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_presentation.mode.label} · ${step.role.label}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('stop-presentation'),
                      tooltip: 'Stop presentation',
                      onPressed: _stopPresentation,
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                LinearProgressIndicator(
                  value: (_presentationStep + 1) / _presentation.steps.length,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'STEP ${_presentationStep + 1} OF ${_presentation.steps.length} · ${step.screen.toUpperCase()}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (_presentation.mode == DemoPresentationMode.autoplay)
                      Text(
                        _presentationTimeLabel(),
                        key: const ValueKey('presentation-countdown'),
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _presentationRoleHandoff(step),
                Text(
                  step.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _presentationNarration(step),
                  style:
                      const TextStyle(color: _muted, fontSize: 12, height: 1.4),
                ),
                if (playback.observational) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Reviewing a previous step · simulated actions are paused.',
                    key: ValueKey('presentation-observational'),
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (hasPresentationError) ...[
                  const SizedBox(height: 8),
                  Container(
                    key: const ValueKey('presentation-action-error'),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF321A16),
                      border: Border.all(color: const Color(0xFFFFA000)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'This action failed. Autoplay is paused. Check for partial local changes before retrying.',
                          style: TextStyle(
                            color: Color(0xFFFFA000),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Details: ${playback.actionError}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              key: const ValueKey('presentation-action-retry'),
                              onPressed: () {
                                playback.retryFailedAction();
                              },
                              child: const Text('Retry'),
                            ),
                            TextButton(
                              key: const ValueKey('presentation-action-skip'),
                              onPressed: playback.skipFailedAction,
                              child: const Text('Skip'),
                            ),
                            TextButton(
                              key: const ValueKey('presentation-action-stop'),
                              onPressed: _stopPresentation,
                              child: const Text('Stop'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (_presentationActionInProgress) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demonstrating with simulated actions…',
                          key: ValueKey('presentation-action-progress'),
                          style: TextStyle(
                              color: _blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ] else if (_completedPresentationActions
                    .contains(_presentationStep)) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 15, color: _green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demonstration complete · changes saved locally',
                          key: ValueKey('presentation-action-complete'),
                          style: TextStyle(
                              color: _green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
                if (showOutcome) _presentationSummary(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('presentation-previous'),
                      tooltip: 'Previous step',
                      onPressed: _presentationStep > 0 && !hasPresentationError
                          ? () => _jumpPresentationTo(_presentationStep - 1)
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    if (_presentation.mode == DemoPresentationMode.autoplay)
                      IconButton.filled(
                        key: ValueKey(_presentationPlaying
                            ? 'presentation-pause'
                            : 'presentation-resume'),
                        tooltip: _presentationPlaying ? 'Pause' : 'Resume',
                        onPressed: hasPresentationError
                            ? null
                            : () => _setPresentationPlaying(!_presentationPlaying),
                        icon: Icon(_presentationPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                      )
                    else
                      const Icon(Icons.touch_app_outlined,
                          size: 20, color: _muted),
                    const Spacer(),
                    if (_presentation.mode == DemoPresentationMode.autoplay &&
                        lastStep)
                      TextButton.icon(
                        key: const ValueKey('replay-presentation'),
                        onPressed: hasPresentationError ? null : _startPresentation,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Replay'),
                      )
                    else if (_presentation.mode ==
                            DemoPresentationMode.guided &&
                        lastStep)
                      FilledButton(
                        key: const ValueKey('finish-presentation'),
                        onPressed: _stopPresentation,
                        child: const Text('Finish'),
                      )
                    else
                      FilledButton.icon(
                        key: const ValueKey('presentation-next'),
                        onPressed: _presentationActionInProgress ||
                                hasPresentationError
                            ? null
                            : _completePresentationStep,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next step'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _presentationScreenContent()),
      ],
    );
  }
}
