part of 'main.dart';

extension _OperationsMoreView on _OperationsShellState {
  Widget _morePageView() {
    const items = <_MoreItem>[
      _MoreItem(
        'Compliance & documents',
        'Chain-of-custody records and generated PDFs',
        Icons.verified_user_outlined,
      ),
      _MoreItem(
        'Reports',
        'Customer visits, fleet activity and exports',
        Icons.bar_chart_rounded,
      ),
      _MoreItem(
        'Intelligence',
        'Fleet condition, trends and data quality',
        Icons.insights_rounded,
      ),
      _MoreItem(
        'Settlement',
        'Work offers and completion evidence',
        Icons.account_balance_wallet_outlined,
      ),
      _MoreItem(
        'FleetOps',
        'Vehicle movement and tracker activity',
        Icons.directions_car_filled_outlined,
      ),
    ];

    return _pageScroll([
      _pageHeading('More', 'Tools and account'),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      for (final item in items) ...[
        Card(
          key: ValueKey('more-item-${item.title}'),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            leading: Icon(item.icon, color: _blue),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                item.description,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
            onTap: () => _setPresentationActionState(
              () => _morePage = item.title,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      const Text(
        'ACCOUNT',
        style: TextStyle(
          color: _muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('DEMO ACCOUNT PERSPECTIVE',
                style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 10),
            Text(_demoRole.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_demoRole.organization, style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            DropdownButtonFormField<_DemoRole>(
              key: const ValueKey('demo-role-switcher'),
              initialValue: _demoRole,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Switch demo role'),
              items: [
                for (final role in _DemoRole.values)
                  DropdownMenuItem(value: role, child: Text(role.label)),
              ],
              onChanged: (role) {
                if (role != null) {
                  _setPresentationActionState(() => _demoRole = role);
                }
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Display-only sample perspective. No permissions, account access, or actions are changed.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'GEUTech sign-in linking is not connected in this prototype.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _demoControls(),
    ], controller: _presentationMoreScrollController);
  }

  Widget _moreDetailPage({String? titleOverride}) {
    final title = titleOverride ?? _morePage!;
    if (title == 'Walkthrough') return _walkthroughPage();
    if (title == 'Reports') {
      return ReportsPage(
        onBack: () => _setPresentationActionState(() => _morePage = null),
        trips: _demo.trips,
        alerts: _demo.alerts,
        visits: _demo.visits,
      );
    }
    if (title == 'Intelligence') return _intelligencePage();
    if (title == 'Settlement' || title == 'FleetOps') {
      return _partnerPage(isSettlement: title == 'Settlement');
    }
    const previews = <String, _SectionPreview>{
      'Compliance & documents': _SectionPreview(
        Icons.verified_user_outlined,
        'Keep chain-of-custody records and generated trip documents together.',
        'No compliance records in this demo.',
      ),
    };
    final detail = previews[title] ??
        const _SectionPreview(
          Icons.info_outline_rounded,
          'This section is not available in the prototype.',
          'Sample presentation only',
        );

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
      const SizedBox(height: 8),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(detail.icon, size: 30, color: _blue),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              detail.summary,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(detail.status, style: const TextStyle(color: _muted)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sample presentation only · Connect the existing application to load live records.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ]);
  }
}
