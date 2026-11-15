part of 'main.dart';

class DemoPresentationSession {
  final DemoPresentationController playback = DemoPresentationController();

  DemoScenario scenario = DemoScenario.normal;
  DemoPresentationMode mode = DemoPresentationMode.guided;
  DemoPathAudience audience = DemoPathAudience.dispatcher;
  int lengthMinutes = 5;
  List<DemoPathStep> steps = const [];
  String? tripCode;
  String? reportSection;
  String? alertTargetSection;
}
