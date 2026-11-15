part of 'main.dart';

extension _OperationsShellLayout on _OperationsShellState {
  Widget _pageScroll(
    List<Widget> children, {
    ScrollController? controller,
  }) {
    return ListView(
      key: ValueKey(
        'page-${_presentationActive ? _presentationStep : '$_tab-${_morePage ?? 'main'}'}',
      ),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: children,
    );
  }

  Widget _pageHeading(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
