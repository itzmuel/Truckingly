import 'demo_store.dart';

enum DemoPathAudience {
  administrator('Administrator'),
  dispatcher('Dispatcher'),
  driver('Driver'),
  supervisor('Supervisor'),
  allPersonnel('All Personnel');

  const DemoPathAudience(this.label);

  final String label;
}

class DemoPathStep {
  const DemoPathStep({
    required this.role,
    required this.screen,
    required this.title,
    required this.action,
    required this.description,
  });

  final DemoPathAudience role;
  final String screen;
  final String title;
  final String action;
  final String description;
}

class DemoPathGenerator {
  static List<DemoPathStep> generate({
    required DemoPathAudience audience,
    required DemoScenario scenario,
  }) {
    final roles = audience == DemoPathAudience.allPersonnel
        ? const [
            DemoPathAudience.administrator,
            DemoPathAudience.dispatcher,
            DemoPathAudience.driver,
            DemoPathAudience.supervisor,
          ]
        : [audience];
    return List.unmodifiable([
      for (final role in roles)
        ...switch (role) {
          DemoPathAudience.administrator => _administrator,
          DemoPathAudience.dispatcher => _dispatcher(scenario),
          DemoPathAudience.driver => _driver(scenario),
          DemoPathAudience.supervisor => _supervisor,
          DemoPathAudience.allPersonnel => const <DemoPathStep>[],
        },
    ]);
  }

  static const _administrator = <DemoPathStep>[
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Home',
      title: 'Operations overview',
      action: 'inspect-home',
      description: 'Review operational totals and attention indicators.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Trips',
      title: 'Trip statuses and timelines',
      action: 'inspect-trips',
      description: 'Compare trip statuses and inspect a journey timeline.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Map',
      title: 'Fleet and assigned trip',
      action: 'inspect-map',
      description: 'Review simulated vehicle details and its assigned trip.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Alerts',
      title: 'Situation history',
      action: 'inspect-alert-history',
      description: 'Review prior detections and closed-situation filters.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Reports',
      title: 'Operational reports',
      action: 'inspect-reports',
      description:
          'Review analytics, trip status, vehicle workload, alert totals, and recorded visits.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Intelligence',
      title: 'Intelligence periods',
      action: 'inspect-intelligence',
      description:
          'Compare the available 7-, 30-, and 90-day sample views; no live data is connected.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Compliance',
      title: 'Compliance and documents',
      action: 'inspect-compliance',
      description: 'Review the available prototype sections and their status.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Settlement',
      title: 'Settlement workspace',
      action: 'inspect-settlement',
      description: 'Review the disconnected, non-binding demo workspace.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'FleetOps',
      title: 'FleetOps workspace',
      action: 'inspect-fleetops',
      description:
          'Review the tracker integration preview; no service is connected.',
    ),
    DemoPathStep(
      role: DemoPathAudience.administrator,
      screen: 'Home',
      title: 'Return to operations',
      action: 'inspect-home',
      description: 'Return to the updated operational overview.',
    ),
  ];

  static List<DemoPathStep> _dispatcher(DemoScenario scenario) => [
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Home',
          title: 'Dispatch overview',
          action: 'inspect-home',
          description: 'Review active trips and outstanding situations.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Create a demo trip',
          action: 'create-trip',
          description:
              'Use the trip wizard with available sample project, route, driver, vehicle, and material options.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Review trip assignment',
          action: 'inspect-created-trip',
          description: 'Review the created trip and its planned assignment.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Edit sample assignment',
          action: 'edit-trip',
          description:
              'Use the existing trip wizard to update the planned driver and vehicle assignment.',
        ),
        if (scenario == DemoScenario.vehicleIncident)
          const DemoPathStep(
            role: DemoPathAudience.dispatcher,
            screen: 'Trips',
            title: 'Inspect exception trip',
            action: 'inspect-exception',
            description:
                'The incident trip remains in Exception; this route does not advance it.',
          )
        else
          for (final status in Trip.journey.skip(0).skip(1))
            DemoPathStep(
              role: DemoPathAudience.dispatcher,
              screen: 'Trips',
              title: 'Advance trip to $status',
              action: 'progress-trip',
              description:
                  'Advance the same trip to its next supported journey stage.',
            ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Map',
          title: 'Coordinate with the fleet',
          action: 'inspect-map',
          description: 'Inspect the assigned vehicle and linked trip.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Alerts',
          title: 'Acknowledge a relevant alert',
          action: 'acknowledge-alert',
          description:
              'Acknowledge the selected open sample alert when it needs action; acknowledgment does not resolve it.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Reports',
          title: 'Review dispatch results',
          action: 'inspect-reports',
          description: 'Review operational totals and trip/vehicle analytics.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Home',
          title: 'Review updated overview',
          action: 'inspect-home',
          description: 'Check the shared dashboard after local demo changes.',
        ),
      ];

  static List<DemoPathStep> _driver(DemoScenario scenario) => [
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Home',
          title: 'Driver overview',
          action: 'inspect-home',
          description: 'Review current sample operations.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Trips',
          title: 'Assigned journey',
          action: 'inspect-trip',
          description:
              'Open the eligible assigned trip and review its timeline.',
        ),
        if (scenario == DemoScenario.vehicleIncident)
          const DemoPathStep(
            role: DemoPathAudience.driver,
            screen: 'Trips',
            title: 'Review exception state',
            action: 'inspect-exception',
            description:
                'An exception trip cannot advance; inspect the status and timeline only.',
          )
        else
          for (final status in const ['Approaching', 'Arrived', 'Completed'])
            DemoPathStep(
              role: DemoPathAudience.driver,
              screen: 'Trips',
              title: 'Advance the journey to $status',
              action: 'progress-trip',
              description:
                  'Advance the same sample trip to its next supported stage; this is not live dispatch.',
            ),
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Map',
          title: 'Assigned vehicle',
          action: 'inspect-map',
          description: 'Review the vehicle profile and linked sample trip.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'More',
          title: 'Record customer-site visit',
          action: 'record-visit',
          description:
              'Use the existing demo visit controls to record sample arrival and departure events.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Alerts',
          title: 'Review alert details',
          action: 'inspect-alert',
          description:
              'View the relevant sample alert without acknowledging, assigning, or resolving it.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Reports',
          title: 'Review recorded visit',
          action: 'inspect-visits-report',
          description:
              'Review explicitly recorded visits; the report does not create arrival/departure events.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Home',
          title: 'Review journey outcome',
          action: 'inspect-home',
          description: 'Return to the shared operational overview.',
        ),
      ];

  static const _supervisor = <DemoPathStep>[
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Home',
      title: 'Situation overview',
      action: 'inspect-home',
      description: 'Review the attention queue and current sample trips.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Alerts',
      title: 'Filter the situation queue',
      action: 'filter-alerts',
      description:
          'Use the available sample situation kind to narrow the open alert queue.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Alerts',
      title: 'Filter and investigate',
      action: 'inspect-alert',
      description: 'Review the selected scenario alert and its trip reference.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Alerts',
      title: 'Acknowledge, assign, and note',
      action: 'investigate-alert',
      description:
          'Acknowledge the alert, assign a sample supervisor, and add an investigation note.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Map',
      title: 'Inspect affected vehicle',
      action: 'inspect-map',
      description: 'Review the vehicle profile and assigned trip.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Trips',
      title: 'Review trip timeline',
      action: 'inspect-trip',
      description: 'Inspect the affected trip status and event history.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Alerts',
      title: 'Resolve and review history',
      action: 'resolve-alert',
      description:
          'Resolve the sample alert with a clear demo reason, then inspect its history entry.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Reports',
      title: 'Review operational impact',
      action: 'inspect-reports',
      description: 'Review updated alert, trip, and vehicle analytics.',
    ),
    DemoPathStep(
      role: DemoPathAudience.supervisor,
      screen: 'Home',
      title: 'Verify attention totals',
      action: 'inspect-home',
      description:
          'Confirm the dashboard reflects the saved local alert state.',
    ),
  ];
}
