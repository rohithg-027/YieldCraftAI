import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yieldcraft_app/widgets/custom_cards.dart';
import 'package:yieldcraft_app/widgets/empty_state_view.dart';
import 'package:yieldcraft_app/widgets/loading_indicator.dart';

void main() {
  testWidgets('StatMetricCard renders label and value correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatMetricCard(
            title: 'Available Nitrogen',
            value: '85.4 kg/ha',
            icon: Icons.eco,
          ),
        ),
      ),
    );

    expect(find.text('Available Nitrogen'), findsOneWidget);
    expect(find.text('85.4 kg/ha'), findsOneWidget);
    expect(find.byIcon(Icons.eco), findsOneWidget);
  });

  testWidgets('EmptyStateView renders title, description and button', (WidgetTester tester) async {
    bool clicked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            icon: Icons.agriculture,
            title: 'No Farms Found',
            description: 'Please create a farm to get started.',
            buttonText: 'Add New Farm',
            onButtonPressed: () {
              clicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('No Farms Found'), findsOneWidget);
    expect(find.text('Please create a farm to get started.'), findsOneWidget);
    expect(find.text('Add New Farm'), findsOneWidget);

    await tester.tap(find.text('Add New Farm'));
    expect(clicked, isTrue);
  });

  testWidgets('LoadingIndicator renders status message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(message: 'Synthesizing agronomic intelligence...'),
        ),
      ),
    );

    expect(find.text('Synthesizing agronomic intelligence...'), findsOneWidget);
  });
}
