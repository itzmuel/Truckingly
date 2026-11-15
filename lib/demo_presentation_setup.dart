part of 'main.dart';

extension _DemoPresentationSetup on _OperationsShellState {
  Future<void> _loadGuidedScenario() async {
    final scenario = _scenarioChoice;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Load ${scenario.label}?'),
        content: const Text(
          'This replaces the saved demo trips and alerts on this device with the selected sample scenario. This cannot be undone. Reset Demo restores the original samples. No production data is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-load-guided-scenario'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load scenario'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _saveDemo(() async {
      await _demo.loadScenario(scenario);
      if (!mounted) return;
      _setPresentationActionState(() {
        _scenarioChoice = scenario;
        _selectedTripStatus = 'All statuses';
        _alertSection = 'Needs action';
        _situationKind = 'All kinds';
        _historyOutcome = 'All closed situations';
        _intelligenceDays = 30;
        _tab = 0;
        _morePage = null;
      });
    }, '${scenario.label} loaded and saved on this device.');
  }

  Future<void> _startPresentation() async {
    final scenario = _scenarioChoice;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${scenario.label}?'),
        content: const Text(
          'Starting replaces the saved demo trips, alerts, and visit events on this device with this fixed sample scenario. This cannot be undone. No production data is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-start-presentation'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start presentation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _presentationPlayback.stop();
    await _saveDemo(() async {
      await _demo.loadScenario(scenario);
      if (!mounted) return;
      _setPresentationActionState(() {
        if (_presentationRole != DemoPathAudience.allPersonnel) {
          _demoRole = _DemoRole.values.firstWhere(
            (role) => role.label == _presentationRole.label,
          );
        }
        _presentationSteps = DemoPathGenerator.generate(
          audience: _presentationRole,
          scenario: scenario,
        );
        _selectedTripStatus = 'All statuses';
        _alertSection = 'Needs action';
        _situationKind = 'All kinds';
        _historyOutcome = 'All closed situations';
        _intelligenceDays = 30;
        _presentationTripCode = null;
        _presentationReportSection = null;
        _presentationAlertTargetSection = null;
        _tab = _presentationMode == DemoPresentationMode.explore ? 0 : 4;
        _morePage = _presentationMode == DemoPresentationMode.explore
            ? null
            : 'Presentation';
      });
      _presentationPlayback.start(
        mode: _presentationMode,
        lengthMinutes: _presentationLength,
        stepCount: _presentationSteps.length,
        runStep: _demonstratePresentationStep,
      );
    }, '${scenario.label} presentation started with locally saved sample data.');
  }

  void _openWalkthroughScreen(String screen) {
    final destination = switch (screen) {
      'Home' => (0, null),
      'Trips' => (1, null),
      'Map' => (2, null),
      'Alerts' => (3, null),
      'Reports' => (4, 'Reports'),
      _ => throw StateError('Unknown walkthrough screen: $screen'),
    };
    _setPresentationActionState(() {
      _tab = destination.$1;
      _morePage = destination.$2;
      if (screen == 'Trips') _selectedTripStatus = 'All statuses';
      if (screen == 'Alerts') _alertSection = 'Needs action';
    });
  }

  Widget _guidedScenarios() {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(title: 'Guided scenarios'),
          const SizedBox(height: 8),
          const Text(
            'Choose a fixed sample walkthrough. Loading it replaces saved demo changes on this device; Reset Demo restores the original samples.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DemoScenario>(
            key: ValueKey('guided-scenario-${_scenarioChoice.name}'),
            initialValue: _scenarioChoice,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Scenario'),
            items: [
              for (final scenario in DemoScenario.values)
                DropdownMenuItem(
                  value: scenario,
                  child: Text(scenario.label),
                ),
            ],
            onChanged: _demo.saving
                ? null
                : (scenario) {
                    if (scenario != null) {
                      _setPresentationActionState(
                        () => _scenarioChoice = scenario,
                      );
                    }
                  },
          ),
          const SizedBox(height: 8),
          Text(
            _scenarioChoice.summary,
            key: const ValueKey('guided-scenario-summary'),
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('load-guided-scenario'),
            onPressed: _demo.saving ? null : _loadGuidedScenario,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Load ${_scenarioChoice.label}'),
          ),
          const SizedBox(height: 8),
          for (var index = 0;
              index < _scenarioChoice.walkthrough.length;
              index++)
            ListTile(
              key: ValueKey('walkthrough-step-$index'),
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                child:
                    Text('${index + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(_scenarioChoice.walkthrough[index].screen),
              subtitle: Text(_scenarioChoice.walkthrough[index].instruction),
              trailing: TextButton(
                onPressed: () => _openWalkthroughScreen(
                  _scenarioChoice.walkthrough[index].screen,
                ),
                child: const Text('Open'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _walkthroughPage() {
    final route = DemoPathGenerator.generate(
      audience: _presentationRole,
      scenario: _scenarioChoice,
    );
    return _pageScroll([
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _setPresentationActionState(() {
            _tab = 0;
            _morePage = null;
          }),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Home'),
        ),
      ),
      _pageHeading('Stakeholder walkthrough', 'A guided, simulated demo'),
      const DemoNotice(),
      const SizedBox(height: 16),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading(title: 'Demo Director'),
            const SizedBox(height: 8),
            const Text(
              'Choose how to present the sample operation. Starting replaces saved demo records only after confirmation.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DemoPresentationMode>(
              key: ValueKey('presentation-mode-${_presentationMode.name}'),
              initialValue: _presentationMode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Presentation mode'),
              items: [
                for (final mode in DemoPresentationMode.values)
                  DropdownMenuItem(value: mode, child: Text(mode.label)),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  _setPresentationActionState(
                    () => _presentationMode = mode,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _presentationMode.description,
              key: const ValueKey('presentation-mode-description'),
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DemoPathAudience>(
              key: const ValueKey('presentation-role-switcher'),
              initialValue: _presentationRole,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Personnel perspective'),
              items: [
                for (final role in DemoPathAudience.values)
                  DropdownMenuItem(value: role, child: Text(role.label)),
              ],
              onChanged: (role) {
                if (role != null) {
                  _setPresentationActionState(
                    () => _presentationRole = role,
                  );
                }
              },
            ),
            ExpansionTile(
              key: ValueKey(
                'presentation-route-${_presentationRole.name}-${_scenarioChoice.name}',
              ),
              tilePadding: EdgeInsets.zero,
              title: Text('Preview route · ${route.length} steps'),
              subtitle: Text(
                _presentationRole == DemoPathAudience.allPersonnel
                    ? 'Administrator → Dispatcher → Driver → Supervisor'
                    : '${_presentationRole.label} · ${_scenarioChoice.label}',
              ),
              children: [
                for (var index = 0; index < route.length; index++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 13,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    title: Text(
                      route[index].title,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${route[index].role.label} · ${route[index].screen}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            if (_presentationMode == DemoPresentationMode.autoplay) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('presentation-length-$_presentationLength'),
                initialValue: _presentationLength,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Presentation length'),
                items: [
                  for (final minutes
                      in DemoPresentationStep.presentationLengths)
                    DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes minutes'),
                    ),
                ],
                onChanged: (minutes) {
                  if (minutes != null) {
                    _setPresentationActionState(
                      () => _presentationLength = minutes,
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('start-presentation'),
              onPressed: _demo.saving ? null : _startPresentation,
              icon: Icon(_presentationMode == DemoPresentationMode.explore
                  ? Icons.explore_outlined
                  : Icons.play_arrow_rounded),
              label: Text(
                _presentationMode == DemoPresentationMode.explore
                    ? 'Explore ${_scenarioChoice.label}'
                    : 'Start ${_presentationMode.label.toLowerCase()}',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _guidedScenarios(),
    ]);
  }
}
