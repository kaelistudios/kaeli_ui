// KaeliMonthYearPicker: ruedas de mes y año, ✕ y ✓, meses en el idioma de la app y rango.
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
          if (closed)
            Text(
              picked == null ? 'nada' : '${picked!.year}-${picked!.month}',
              key: const Key('result'),
            ),
        ],
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  Widget host, {
  Locale locale = const Locale('es'),
}) async {
  await pumpKaeliApp(tester, host, locale: locale);
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

String _result(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('result'))).data!;

void main() {
  testWidgets('abre en el mes y año dados, con los meses en español', (
    tester,
  ) async {
    await _open(tester, _Host(initial: DateTime(2026, 10, 23)));
    expect(find.text('Octubre'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.byTooltip('Cancelar'), findsOneWidget);
    expect(find.byTooltip('Aceptar'), findsOneWidget);
  });

  testWidgets('girar las ruedas y ✓ devuelve el primer día del mes elegido', (
    tester,
  ) async {
    await _open(tester, _Host(initial: DateTime(2026, 10, 23)));
    final month = find.byKey(KaeliMonthYearPicker.monthWheelKey);
    final year = find.byKey(KaeliMonthYearPicker.yearWheelKey);
    final extent = tester.getSize(month).height / 5;
    await tester.drag(month, Offset(0, extent * 2));
    await tester.pumpAndSettle();
    await tester.drag(year, Offset(0, -extent));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aceptar'));
    await tester.pumpAndSettle();
    expect(_result(tester), '2027-8');
  });

  testWidgets('✕ cierra sin elegir', (tester) async {
    await _open(tester, _Host(initial: DateTime(2026, 10)));
    await tester.tap(find.byTooltip('Cancelar'));
    await tester.pumpAndSettle();
    expect(_result(tester), 'nada');
  });

  testWidgets('no deja salir del rango', (tester) async {
    await _open(
      tester,
      _Host(
        initial: DateTime(2026, 10),
        first: DateTime(2026, 9),
        last: DateTime(2026, 11),
      ),
    );
    final month = find.byKey(KaeliMonthYearPicker.monthWheelKey);
    final extent = tester.getSize(month).height / 5;
    await tester.drag(month, Offset(0, extent * 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aceptar'));
    await tester.pumpAndSettle();
    expect(_result(tester), '2026-9');
  });

  for (final (code, october, cancel) in [
    ('en', 'October', 'Cancel'),
    ('fr', 'Octobre', 'Annuler'),
    ('pt', 'Outubro', 'Cancelar'),
  ]) {
    testWidgets('meses y botones en $code', (tester) async {
      await _open(
        tester,
        _Host(initial: DateTime(2026, 10)),
        locale: Locale(code),
      );
      expect(find.text(october), findsOneWidget);
      expect(find.byTooltip(cancel), findsOneWidget);
    });
  }

  test(
    'rango por defecto: 5 años atrás y 10 adelante, siempre con el mes inicial',
    () {
      final now = DateTime(2026, 10, 23);
      expect(KaeliMonthYearPicker.defaultRange(DateTime(2026, 10), now), (
        DateTime(2021),
        DateTime(2036, 12),
      ));
      expect(
        KaeliMonthYearPicker.defaultRange(DateTime(2010, 3), now).$1,
        DateTime(2010, 3),
      );
    },
  );
}
