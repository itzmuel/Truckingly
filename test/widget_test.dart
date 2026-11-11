import 'package:flutter/material.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the mobile operations overview', (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());

    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
    expect(find.text('ACTIVE TRIPS'), findsOneWidget);
  });

  testWidgets('adds a local demo trip from the trip form', (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());

    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create trip'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'DT-21');
    await tester.enterText(fields.at(1), 'Yard');
    await tester.enterText(fields.at(2), 'Site');
    await tester.enterText(fields.at(3), 'Granite');
    await tester.tap(find.text('Add demo trip'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Yard → Site'), findsOneWidget);
    expect(find.textContaining('DT-21'), findsOneWidget);
  });
}
