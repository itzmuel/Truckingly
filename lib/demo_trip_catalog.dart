class DemoTripCatalog {
  static const projects = ['Lekki development', 'Apapa logistics'];
  static const origins = ['Ikeja Quarry', 'Ogun Yard'];
  static const destinations = ['Lekki Site', 'Apapa Terminal'];
  static const drivers = ['Ayo Bello', 'Chidi Okafor', 'Tunde Adeyemi'];
  static const vehicles = ['DT-07', 'DT-12', 'DT-15', 'DT-18'];
  static const materials = ['Granite aggregate', 'Laterite', 'Sand'];
}

class DemoTripDraft {
  const DemoTripDraft({
    required this.project,
    required this.origin,
    required this.destination,
    required this.driver,
    required this.vehicle,
    required this.material,
  });

  final String project;
  final String origin;
  final String destination;
  final String driver;
  final String vehicle;
  final String material;

  void validate() {
    for (final (label, value, options) in [
      ('project', project, DemoTripCatalog.projects),
      ('origin', origin, DemoTripCatalog.origins),
      ('destination', destination, DemoTripCatalog.destinations),
      ('driver', driver, DemoTripCatalog.drivers),
      ('vehicle', vehicle, DemoTripCatalog.vehicles),
      ('material', material, DemoTripCatalog.materials),
    ]) {
      if (!options.contains(value)) {
        throw FormatException('Choose a valid sample $label.');
      }
    }
    if (origin == destination) {
      throw const FormatException('Origin and destination must differ.');
    }
  }
}
