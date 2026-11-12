class DemoVisitCatalog {
  static const vehicles = ['DT-07', 'DT-12', 'DT-15', 'DT-18'];
  static const sites = ['Lekki Site', 'Apapa Terminal'];
  static const customers = {
    'Lekki Site': 'Lekki Development',
    'Apapa Terminal': 'Apapa Logistics',
  };

  static String customerFor(String site) {
    final customer = customers[site];
    if (customer == null) {
      throw const FormatException('Choose a sample customer site.');
    }
    return customer;
  }
}
