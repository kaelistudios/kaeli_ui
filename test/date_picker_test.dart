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

  testWidgets('0.13.0: tocar «mes año» cambia los días por las ruedas en la MISMA ventana; «Listo» vuelve al mes elegido',
      (tester) async {
    await open(tester, initial: DateTime(2024, 3, 5), last: DateTime(2030));
    expect(find.text('Marzo 2024'), findsOneWidget);
    await tester.tap(find.byKey(KaeliDatePickerDialog.monthButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'una sola ventana, sin hoja encima');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Elige mes y año'), findsOneWidget);
    expect(find.byKey(KaeliMonthYearPicker.monthWheelKey), findsOneWidget);
    expect(find.text('Aceptar'), findsNothing, reason: 'mientras, solo «Cancelar» y «Listo»');
    final month = find.byKey(KaeliMonthYearPicker.monthWheelKey);
    final extent = tester.getSize(month).height / 5;
    await tester.drag(month, Offset(0, -extent * 2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KaeliMonthYearPicker.doneKey));
    await tester.pumpAndSettle();
    expect(find.text('Mayo 2024'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget, reason: 'vuelven los días y sus botones');
    // «Cancelar» de las ruedas vuelve a los días sin cambiar el mes.
    await tester.tap(find.byKey(KaeliDatePickerDialog.monthButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KaeliMonthYearPicker.cancelKey));
    await tester.pumpAndSettle();
    expect(find.text('Mayo 2024'), findsOneWidget);
  });

  // 0.14.0: la semana empieza en lunes en todos los idiomas; en español, «X» para el miércoles.
  Future<List<String>> weekdayRow(WidgetTester tester, Locale locale, {int? firstDayOfWeek}) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: [locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => firstDayOfWeek == null
                ? showKaeliDatePicker(context, openAt: DateTime(2026, 10, 1), first: DateTime(2026), last: DateTime(2027))
                : showKaeliDatePicker(
                    context,
                    openAt: DateTime(2026, 10, 1),
                    first: DateTime(2026),
                    last: DateTime(2027),
                    firstDayOfWeek: firstDayOfWeek,
                  ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final grid = find.byType(GridView);
    final texts = tester.widgetList<Text>(find.descendant(of: grid, matching: find.byType(Text))).take(7);
    return [for (final t in texts) t.data!];
  }

  testWidgets('0.14.0: lunes primero en español (con «X») y en inglés; domingo si se pide', (tester) async {
    expect(await weekdayRow(tester, const Locale('es', 'US')), ['L', 'M', 'X', 'J', 'V', 'S', 'D']);
    expect(await weekdayRow(tester, const Locale('en', 'US')), ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    expect(await weekdayRow(tester, const Locale('en', 'US'), firstDayOfWeek: DateTime.sunday), ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
  });
}
