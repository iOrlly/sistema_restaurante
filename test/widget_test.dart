// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:controle_restaurante/screens/home_screen.dart';

void main() {
  testWidgets('App initial screen loads', (WidgetTester tester) async {
    // Build the home screen with a fake report loader to avoid database access.
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          relatorioLoader: (_) async => {
            'faturamento': 0.0,
            'itens_vendidos': 0,
            'itens_produzidos': 0,
            'percentual_desperdicio': 0.0,
            'status': 'Bom',
            'total_funcionarios': 0,
            'eficiencia_por_funcionario': 0.0,
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the home screen UI renders.
    expect(find.text('Controle Restaurante'), findsOneWidget);
    expect(find.text('Registrar Venda'), findsOneWidget);
    expect(find.text('Registrar Produção'), findsOneWidget);
  });
}
