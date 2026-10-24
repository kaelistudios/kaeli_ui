import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() {
  Future<DateTime?> open(WidgetTester tester, {DateTime? initial, DateTime? openAt, required DateTime last}) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showKaeliDatePicker(
                context,
                initial: initial,
                openAt: openAt,
                first: DateTime(1990),
                last: last,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('abre en el mes pedido, sin fechas futuras y con Cancelar/Aceptar iguales', (tester) async {
    await open(tester, openAt: DateTime(2020, 6, 1), last: DateTime(2020, 6, 15));
    expect(find.text('Junio 2020'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget); // no «ACEPTAR»
    // El 20 de junio es después de «last»: no se puede tocar.
    await tester.tap(find.text('20'));
    await tester.pump();
    final ok = tester.widget<TextButton>(find.ancestor(of: find.text('Aceptar'), matching: find.byType(TextButton)));
    expect(ok.onPressed, isNull);
    await tester.tap(find.text('10'));
    await tester.pump();
    final ok2 = tester.widget<TextButton>(find.ancestor(of: find.text('Aceptar'), matching: find.byType(TextButton)));
    expect(ok2.onPressed, isNotNull);
  });

  testWidgets('tocar «mes año» abre las ruedas', (tester) async {
    await open(tester, initial: DateTime(2024, 3, 5), last: DateTime(2030));
    expect(find.text('Marzo 2024'), findsOneWidget);
    await tester.tap(find.byKey(KaeliDatePickerDialog.monthButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(KaeliMonthYearPicker.monthWheelKey), findsOneWidget);
  });
}
