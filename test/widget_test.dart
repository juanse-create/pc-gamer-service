import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La aplicacion muestra su nombre', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('PC Gamer Service'))),
      ),
    );

    expect(find.text('PC Gamer Service'), findsOneWidget);
  });
}
