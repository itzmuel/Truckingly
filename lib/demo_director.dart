enum DemoPresentationMode {
  autoplay('Autoplay', 'The presentation advances on its own.'),
  guided('Guided', 'Move through each presentation step yourself.'),
  explore('Explore', 'Load the scenario, then use the app freely.');

  const DemoPresentationMode(this.label, this.description);

  final String label;
  final String description;
}

class DemoPresentationStep {
  const DemoPresentationStep({
    required this.title,
    required this.screen,
    required this.narration,
  });

  final String title;
  final String screen;
  final String narration;

  static const sequence = <DemoPresentationStep>[
    DemoPresentationStep(
      title: 'Operations overview',
      screen: 'Home',
      narration:
          'Start with the shared operational picture: active trips, vehicles in transit, completions, and situations needing attention.',
    ),
    DemoPresentationStep(
      title: 'Trip activity',
      screen: 'Trips',
      narration:
          'Review assigned sample trips and open a trip to inspect its timeline. Continuing advances one eligible sample trip by a single stage.',
    ),
    DemoPresentationStep(
      title: 'Fleet map',
      screen: 'Map',
      narration:
          'Vehicle markers use simulated trip stages in a schematic view; this is not live GPS.',
    ),
    DemoPresentationStep(
      title: 'Situation management',
      screen: 'Alerts',
      narration:
          'Inspect the sample situations. Continuing acknowledges the selected scenario alert; it does not resolve or repair the underlying issue.',
    ),
    DemoPresentationStep(
      title: 'Operational reports',
      screen: 'Reports',
      narration:
          'Finish with analytics derived from the same saved demo trips, alerts, and explicitly recorded visit events.',
    ),
  ];

  static const presentationLengths = <int>[3, 5, 8];

  static Duration stepDuration(int minutes) {
    if (!presentationLengths.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes', 'Choose 3, 5, or 8.');
    }
    return Duration(seconds: minutes * 60 ~/ sequence.length);
  }
}
