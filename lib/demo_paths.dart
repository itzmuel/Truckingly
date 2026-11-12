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
    this.targetStatus,
  });

  final DemoPathAudience role;
  final String screen;
  final String title;
  final String action;
  final String description;
  final String? targetStatus;
}

class DemoPathGenerator {
  static List<DemoPathStep> generate({
    required DemoPathAudience audience,
    required DemoScenario scenario,
  }) {
    if (audience == DemoPathAudience.allPersonnel) {
      return List.unmodifiable(_allPersonnel(scenario));
    }
    return List.unmodifiable(switch (audience) {
      DemoPathAudience.administrator => _administrator,
      DemoPathAudience.dispatcher => _dispatcher(scenario),
      DemoPathAudience.driver => _driver(scenario),
      DemoPathAudience.supervisor => _supervisor,
      DemoPathAudience.allPersonnel => const <DemoPathStep>[],
    });
  }

  static List<DemoPathStep> _allPersonnel(DemoScenario scenario) {
    final scenarioTrip = scenario == DemoScenario.vehicleIncident;
    final createTrip = scenario == DemoScenario.normal;
    return [
      DemoPathStep(
        role: DemoPathAudience.dispatcher,
        screen: 'Home',
        title: 'Dispatcher handoff',
        action: 'inspect-home',
        description: scenarioTrip
            ? 'Continue with the same exception trip and incident alert.'
            : 'Continue with the selected shared trip and its scenario context.',
      ),
      if (createTrip) ...[
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Create the shared demonstration trip',
          action: 'create-trip',
          description:
              'Create one sample trip that the Dispatcher and Driver will share.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Review shared trip assignment',
          action: 'inspect-created-trip',
          description:
              'Inspect the same trip that will be handed to the Driver.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Update shared trip assignment',
          action: 'edit-trip',
          description:
              'Change the sample assignment before dispatch and preserve this trip for the Driver.',
        ),
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Dispatch shared trip to origin',
          action: 'progress-trip',
          targetStatus: 'In transit',
          description:
              'Advance the shared trip only to In transit, leaving the remaining journey for the Driver.',
        ),
      ] else ...[
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: scenarioTrip
              ? 'Inspect the incident trip'
              : 'Inspect the delayed delivery',
          action: scenarioTrip ? 'inspect-exception' : 'inspect-trip',
          description: scenarioTrip
              ? 'Open the scenario alert’s referenced Exception trip; do not create or advance a different trip.'
              : 'Open the in-transit trip referenced by the delivery-delay scenario.',
        ),
      ],
      const DemoPathStep(
        role: DemoPathAudience.dispatcher,
        screen: 'Map',
        title: 'Coordinate the shared vehicle',
        action: 'inspect-map',
        description:
            'Inspect the vehicle assigned to the selected shared or scenario trip.',
      ),
      if (!scenarioTrip)
        const DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Alerts',
          title: 'Acknowledge the open sample alert',
          action: 'acknowledge-alert',
          description:
              'Acknowledge without resolving so the Supervisor can continue the same alert lifecycle.',
        ),
      const DemoPathStep(
        role: DemoPathAudience.dispatcher,
        screen: 'Reports',
        title: 'Review dispatch results',
        action: 'inspect-reports',
        description: 'Review shared operational totals and trip analytics.',
      ),
      if (scenario == DemoScenario.delayedDelivery) ...[
        const DemoPathStep(
          role: DemoPathAudience.supervisor,
          screen: 'Home',
          title: 'Supervisor reviews the delay response',
          action: 'inspect-home',
          description:
              'Review the delay alert after Dispatcher acknowledgment and before the Driver completes the journey.',
        ),
        ..._supervisor,
      ],
      DemoPathStep(
        role: DemoPathAudience.driver,
        screen: 'Home',
        title: 'Driver handoff',
        action: 'inspect-home',
        description: createTrip
            ? 'Continue the same trip at In transit; the Dispatcher left the remaining journey for the Driver.'
            : scenarioTrip
                ? 'Review the same Exception trip without advancing it.'
                : 'Continue the same delayed trip after the Supervisor records a simulated response; this does not prove that the real-world delay has ended.',
      ),
      DemoPathStep(
        role: DemoPathAudience.driver,
        screen: 'Trips',
        title: scenarioTrip ? 'Review exception state' : 'Continue assigned trip',
        action: scenarioTrip ? 'inspect-exception' : 'inspect-trip',
        description: scenarioTrip
            ? 'Inspect the same Exception trip referenced by the vehicle incident.'
            : 'Open the exact trip selected by the Dispatcher and use its current saved status.',
      ),
      if (!scenarioTrip)
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Trips',
          title: 'Advance the shared trip to arrival',
          action: 'progress-trip',
          targetStatus: 'Arrived',
          description:
              'Continue the same trip from its saved stage to Arrived before recording the site visit.',
        ),
      const DemoPathStep(
        role: DemoPathAudience.driver,
        screen: 'Map',
        title: 'Review assigned vehicle',
        action: 'inspect-map',
        description: 'Inspect the vehicle linked to the shared trip.',
      ),
      if (!scenarioTrip)
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'More',
          title: 'Record customer-site visit',
          action: 'record-visit',
          description:
              'Record arrival and departure through the existing visit flow while the trip remains active.',
        ),
      if (!scenarioTrip)
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Trips',
          title: 'Complete the remaining journey',
          action: 'progress-trip',
          targetStatus: 'Completed',
          description:
              'Complete the same trip after the recorded site visit, without replaying completed stages.',
        ),
      if (scenario != DemoScenario.delayedDelivery)
        const DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Alerts',
          title: 'Review alert without changing it',
          action: 'inspect-alert',
          description:
              'View the same scenario alert without acknowledging, assigning, or resolving it.',
        ),
      const DemoPathStep(
        role: DemoPathAudience.driver,
        screen: 'Reports',
        title: 'Review journey results',
        action: 'inspect-reports',
        description:
            'Review completion and any explicitly recorded site visit data.',
      ),
      if (scenario != DemoScenario.delayedDelivery) ..._supervisor,
      ..._administrator,
    ];
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

  static List<DemoPathStep> _dispatcher(DemoScenario scenario) {
    if (scenario == DemoScenario.vehicleIncident) {
      return const [
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Home',
          title: 'Review incident operations',
          action: 'inspect-home',
          description: 'Review the vehicle incident and attention indicators.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Inspect the incident trip',
          action: 'inspect-exception',
          description:
              'Inspect the same Exception trip referenced by the vehicle incident. No unrelated trip is created.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Map',
          title: 'Inspect the affected vehicle',
          action: 'inspect-map',
          description: 'Review the vehicle linked to the Exception trip.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Alerts',
          title: 'Acknowledge the incident alert',
          action: 'acknowledge-alert',
          description:
              'Acknowledge the incident alert without treating it as resolved.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Reports',
          title: 'Review incident totals',
          action: 'inspect-reports',
          description: 'Review the selected incident scenario in reports.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Home',
          title: 'Return to operations',
          action: 'inspect-home',
          description: 'Return to the updated overview.',
        ),
      ];
    }
    if (scenario == DemoScenario.delayedDelivery) {
      return const [
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Home',
          title: 'Review dispatch overview',
          action: 'inspect-home',
          description: 'Review the active delay scenario.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Trips',
          title: 'Inspect delayed trip',
          action: 'inspect-trip',
          description:
              'Open the in-transit trip referenced by the delay scenario.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Map',
          title: 'Coordinate the delayed vehicle',
          action: 'inspect-map',
          description: 'Inspect the vehicle assigned to the delayed trip.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Alerts',
          title: 'Acknowledge the delay alert',
          action: 'acknowledge-alert',
          description:
              'Acknowledge the selected delay alert without resolving it.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Reports',
          title: 'Review dispatch results',
          action: 'inspect-reports',
          description: 'Review shared operational totals and trip analytics.',
        ),
        DemoPathStep(
          role: DemoPathAudience.dispatcher,
          screen: 'Home',
          title: 'Return to operations',
          action: 'inspect-home',
          description: 'Return to the updated overview.',
        ),
      ];
    }
    return [
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
      const DemoPathStep(
        role: DemoPathAudience.dispatcher,
        screen: 'Trips',
        title: 'Dispatch trip to In transit',
        action: 'progress-trip',
        targetStatus: 'In transit',
        description:
            'Advance the selected trip to In transit, leaving later stages to the Driver.',
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
  }

  static List<DemoPathStep> _driver(DemoScenario scenario) {
    if (scenario == DemoScenario.vehicleIncident) {
      return const [
        DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Home',
          title: 'Review Driver overview',
          action: 'inspect-home',
          description:
              'Review current operations without changing the incident.',
        ),
        DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Trips',
          title: 'Review incident trip',
          action: 'inspect-exception',
          description:
              'Inspect the same Exception trip. The Driver does not advance it.',
        ),
        DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Map',
          title: 'Review affected vehicle',
          action: 'inspect-map',
          description: 'Inspect the vehicle linked to the Exception trip.',
        ),
        DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Alerts',
          title: 'Review alert details',
          action: 'inspect-alert',
          description:
              'View the incident alert without acknowledging or resolving it.',
        ),
        DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Reports',
          title: 'Review incident report',
          action: 'inspect-visits-report',
          description: 'Review reports without recording a delivery visit.',
        ),
        DemoPathStep(
          role: DemoPathAudience.driver,
          screen: 'Home',
          title: 'Return to operations',
          action: 'inspect-home',
          description: 'Return to the shared operational overview.',
        ),
      ];
    }
    return [
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
        description: 'Open the eligible assigned trip and review its timeline.',
      ),
      const DemoPathStep(
        role: DemoPathAudience.driver,
        screen: 'Trips',
        title: 'Advance the assigned journey to arrival',
        action: 'progress-trip',
        targetStatus: 'Arrived',
        description:
            'Advance from the trip’s current saved status to Arrived before recording the site visit.',
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
            'Use the existing demo visit controls to record sample arrival and departure.',
      ),
      const DemoPathStep(
        role: DemoPathAudience.driver,
        screen: 'Trips',
        title: 'Complete the assigned journey',
        action: 'progress-trip',
        targetStatus: 'Completed',
        description:
            'Complete the same trip after its customer-site visit; never replay completed stages.',
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
  }

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
          'Confirm the dashboard reflects the saved local alert state before the next personnel handoff.',
    ),
  ];
}
