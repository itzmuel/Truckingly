part of 'main.dart';

extension _OperationsPartnerIntelligenceView on _OperationsShellState {
  Widget _partnerPage({required bool isSettlement}) {
    final service = isSettlement ? 'Settlement' : 'FleetOps';
    return _pageScroll([
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _setPresentationActionState(
            () => _morePage = null,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('More'),
        ),
      ),
      _pageHeading(
        'ADAPTIQ $service',
        isSettlement
            ? 'Work Offers to subcontractors and evidence of delivered work.'
            : 'Your fleet movement over the last 24 hours, measured from trackers.',
      ),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isSettlement
                      ? Icons.storefront_outlined
                      : Icons.directions_car_filled_outlined,
                  color: _blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSettlement ? 'Work Offers' : 'Movement',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSettlement) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE58A),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFCE7100), width: 4),
                  ),
                ),
                child: const Text(
                  'DEMO — NOT LEGALLY BINDING — NO FUNDS WILL MOVE',
                  style: TextStyle(
                    color: Color(0xFF302000),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Work Offers are not connected in this prototype. In the live system, your Settlement administrator registers ADAPTIQ-Dumptrak as a source through Work Offers administration. Nothing needs to change in Dumptrak.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              _partnerStatus('Last answer from Settlement', 'None yet'),
              _partnerStatus('Completion reports waiting to be sent', '0'),
              _partnerStatus(
                  'Held until a supervisor confirms the tonnes', '0'),
              _partnerStatus('Refused by Settlement', '0'),
              const SizedBox(height: 8),
              const Text(
                'Sample counts only, not live queue totals. In the live system, offer a trip as work from the trip itself.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
            ] else ...[
              const Text(
                'Reporting window · Last 24 hours',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vehicle · Movements · Time moving · Last movement',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              const EmptyState(
                icon: Icons.route_outlined,
                title: 'Movement data unavailable',
                detail:
                    'No tracker or FleetOps service is connected. Missing records do not mean vehicles have not moved.',
              ),
              const SizedBox(height: 12),
              const Text(
                'When connected, open a vehicle to review each movement in the reporting window.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading(title: 'GEUTech sign-in'),
            const SizedBox(height: 12),
            Text(
              'ADAPTIQ $service uses GEUTech sign-in. In the live app, password users link their identity once: GEUTech verifies who you are, then Dumptrak asks for your password to confirm the link. After linking, sign in with GEUTech.',
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Not linked in this prototype. No credentials are requested or stored.',
              style: TextStyle(color: _amber, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: ValueKey('link-geutech-$service'),
              onPressed: () => _showIdentityLinkInfo(service),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Link my GEUTech sign-in',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _partnerStatus(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _showIdentityLinkInfo(String service) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('GEUTech linking is not connected'),
        content: Text(
          'This prototype cannot link your $service account. The production identity configuration and approved sign-in flow are needed. No account was linked and no credentials were requested.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _intelligencePage() {
    return _pageScroll([
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _setPresentationActionState(
            () => _morePage = null,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('More'),
        ),
      ),
      _pageHeading(
        'Intelligence workspace',
        'Fleet analytics, trends and reporting over the last $_intelligenceDays days.',
      ),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      KeyedSubtree(
        key: _presentationActive &&
                _presentationCurrentStep.action == 'inspect-intelligence'
            ? _presentationPrimaryTargetKey
            : null,
        child: DropdownButtonFormField<int>(
          key: const ValueKey('intelligence-period'),
          initialValue: _intelligenceDays,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Period (required)'),
          items: [
            for (final days in [7, 30, 90])
              DropdownMenuItem(value: days, child: Text('Last $days days')),
          ],
          onChanged: (days) {
            if (days != null) {
              _setPresentationActionState(() => _intelligenceDays = days);
            }
          },
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'The period findings are listed for. Changing it updates the prototype view only.',
        style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 20),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: 'Fleet condition'),
            const SizedBox(height: 8),
            Text(
              'Last $_intelligenceDays days · Coverage determines what may be concluded.',
              key: const ValueKey('intelligence-coverage-period'),
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Not evaluated',
              style: TextStyle(color: _amber, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'No fleet evidence is connected. A fleet condition score cannot be shown; missing evaluations do not mean the fleet is operating normally.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title: 'Vehicles requiring attention'),
            SizedBox(height: 8),
            Text(
              'Ranking requires the existing server evaluation.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              'Not available',
              style: TextStyle(color: _amber, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'No completed evaluation is available for fuel, maintenance, utilization or telemetry confidence. Connect the evaluation service before showing a ranked vehicle list.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: 'Evaluation service'),
            const SizedBox(height: 12),
            _intelligenceUnavailable('evaluation'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: 'Analytic findings'),
            const SizedBox(height: 8),
            const Text(
              'Evidence for reporting and optimization. These never raise alerts and never appear in alert counts.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            _intelligenceUnavailable('analytic findings'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title: 'Before drawing conclusions'),
            SizedBox(height: 10),
            Text(
              'Thresholds are provisional and have not been calibrated against operating data. Treat findings as indicative, not established fact.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => _setPresentationActionState(() {
          _tab = 3;
          _morePage = null;
          _alertSection = 'Needs action';
        }),
        icon: const Icon(Icons.notifications_none_rounded),
        label: const Text('View situations needing action'),
      ),
    ]);
  }

  Widget _intelligenceUnavailable(String service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C58).withValues(alpha: 0.1),
        border:
            Border.all(color: const Color(0xFFFF5C58).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5C58)),
          const SizedBox(height: 8),
          Text(
            'The $service service is not connected in this prototype.',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: ValueKey('intelligence-retry-$service'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cannot retry $service: no API is configured. No live request was made.',
                ),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
