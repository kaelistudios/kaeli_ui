// KaeliMonthYearPicker: ruedas de mes y año, «Cancelar» y «Listo» (0.13.0), meses en el idioma de la app y rango.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

/// Pantalla con un botón que abre el selector y guarda lo elegido.
class _Host extends StatefulWidget {
  const _Host({required this.initial, this.first, this.last});

  final DateTime initial;
  final DateTime? first;
  final DateTime? last;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  DateTime? picked;
  bool closed = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            key: const Key('open'),
            onPressed: () async {
              final r = await showKaeliMonthYearPicker(
                context,
                initial: widget.initial,
                first: widget.first,
                last: widget.last,
                title: 'Mes',
              );
              setState(() {
                picked = r;
                closed = true;
              });
            },
            child: const Text('Abrir'),
          ),
          if (closed) Text(picked == null ? 'nada' : '${picked!.year}-${picked!.month}', key: const Key('result')),
        ],
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester, Widget host, {Locale locale = const Locale('es')}) async {
  await pumpKaeliApp(tester, host, locale: locale);
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

String _result(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('result'))).data!;

void main() {
  testWidgets('abre en el mes y año dados, con los meses en español', (tester) async {
    await _open(tester, _Host(initial: DateTime(2026, 10, 23)));
    expect(find.text('Octubre'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    // 0.13.0: título y botones de texto (no ✕ y ✓).
    expect(find.text('Mes'), findsOneWidget, reason: 'título propio');
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('sin título propio: «Elige mes y año»; 5 opciones visibles y ruedas del mismo alto', (tester) async {
    await pumpKaeliApp(
      tester,
      Scaffold(
        body: KaeliMonthYearPicker(initial: DateTime(2026, 10), onCancel: () {}, onConfirm: (_) {}),
      ),
    );
    expect(find.text('Elige mes y año'), findsOneWidget);
    final m = tester.getSize(find.byKey(KaeliMonthYearPicker.monthWheelKey));
    final y = tester.getSize(find.byKey(KaeliMonthYearPicker.yearWheelKey));
    expect(m.height, y.height);
    expect(m.width / y.width, closeTo(5 / 4, 0.05));
  });

  testWidgets('girar las ruedas y «Listo» devuelve el primer día del mes elegido', (tester) async {
    await _open(tester, _Host(initial: DateTime(2026, 10, 23)));
    final month = find.byKey(KaeliMonthYearPicker.monthWheelKey);
    final year = find.byKey(KaeliMonthYearPicker.yearWheelKey);
    final extent = tester.getSize(month).height / 5;
    await tester.drag(month, Offset(0, extent * 2));
    await tester.pumpAndSettle();
    await tester.drag(year, Offset(0, -extent));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KaeliMonthYearPicker.doneKey));
    await tester.pumpAndSettle();
    expect(_result(tester), '2027-8');
  });

  testWidgets('«Cancelar» cierra sin elegir', (tester) async {
    await _open(tester, _Host(initial: DateTime(2026, 10)));
    await tester.tap(find.byKey(KaeliMonthYearPicker.cancelKey));
    await tester.pumpAndSettle();
    expect(_result(tester), 'nada');
  });

  testWidgets('no deja salir del rango', (tester) async {
    await _open(tester, _Host(initial: DateTime(2026, 10), first: DateTime(2026, 9), last: DateTime(2026, 11)));
    final month = find.byKey(KaeliMonthYearPicker.monthWheelKey);
    final extent = tester.getSize(month).height / 5;
    await tester.drag(month, Offset(0, extent * 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KaeliMonthYearPicker.doneKey));
    await tester.pumpAndSettle();
    expect(_result(tester), '2026-9');
  });

  for (final (code, october, cancel) in [
    ('en', 'October', 'Cancel'),
    ('fr', 'Octobre', 'Annuler'),
    ('pt', 'Outubro', 'Cancelar'),
  ]) {
    testWidgets('meses y botones en $code', (tester) async {
      await _open(tester, _Host(initial: DateTime(2026, 10)), locale: Locale(code));
      expect(find.text(october), findsOneWidget);
      expect(find.text(cancel), findsOneWidget);
    });
  }

  test('rango por defecto: 5 años atrás y 10 adelante, siempre con el mes inicial', () {
    final now = DateTime(2026, 10, 23);
    expect(KaeliMonthYearPicker.defaultRange(DateTime(2026, 10), now), (DateTime(2021), DateTime(2036, 12)));
    expect(KaeliMonthYearPicker.defaultRange(DateTime(2010, 3), now).$1, DateTime(2010, 3));
  });
}
