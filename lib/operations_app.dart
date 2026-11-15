part of 'main.dart';

class DemoStartup extends StatefulWidget {
  const DemoStartup({super.key, this.persistence});

  final DemoPersistence? persistence;

  @override
  State<DemoStartup> createState() => _DemoStartupState();
}

class _DemoStartupState extends State<DemoStartup> {
  late final DemoPersistence _persistence =
      widget.persistence ?? LocalDemoPersistence();
  DemoStore? _store;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool restore = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = restore
          ? await DemoStore.restore(_persistence)
          : await DemoStore.load(_persistence);
      if (!mounted) {
        store.dispose();
        return;
      }
      setState(() => _store = store);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_store != null) return DumptrakPrototypeApp(store: _store);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _busy
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading saved demo…'),
                      ],
                    )
                  : Builder(
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Saved demo could not be loaded',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Text(_error ?? 'Local storage is unavailable.'),
                          const SizedBox(height: 12),
                          const Text(
                            'Your saved demo has not been replaced. Retry, or explicitly restore the sample data.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry loading'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final reset = await _confirmDemoReset(context);
                              if (reset && mounted) {
                                await _load(restore: true);
                              }
                            },
                            child: const Text('Restore sample data'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDemoReset(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset simulated data?'),
        content: const Text(
          'This replaces all saved demo changes on this device with the original sample records. No production data is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Demo'),
          ),
        ],
      ),
    ) ??
    false;

class DumptrakPrototypeApp extends StatelessWidget {
  const DumptrakPrototypeApp({super.key, this.store});

  final DemoStore? store;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: Brightness.dark,
      surface: _surface,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dumptrak Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceRaised,
          selectedColor: _blue,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
        ),
      ),
      home: OperationsShell(store: store),
    );
  }
}
