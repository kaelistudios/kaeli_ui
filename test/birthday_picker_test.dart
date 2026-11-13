import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

final _today = DateTime(2026, 11, 13);

/// Un botón que abre el selector y guarda lo elegido con [onResult].
Future<void> _open(
  WidgetTester tester, {
  KaeliBirthday? initial,
  Locale locale = const Locale('es'),
  required void Function(KaeliBirthday?) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('es'), Locale('en'), Locale('fr'), Locale('pt')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onResult(await showKaeliBirthdayPicker(context, initial: initial, today: _today)),
          child: const Text('ir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ir'));
  await tester.pumpAndSettle();
}

/// Gira la rueda [key] [rows] filas (positivo: hacia abajo de la lista, es decir, el valor siguiente).
Future<void> _spin(WidgetTester tester, Key key, int rows) async {
  final wheel = find.byKey(key);
  final extent = tester.widget<CupertinoPicker>(wheel).itemExtent;
  await tester.drag(wheel, Offset(0, -extent * rows));
  await tester.pumpAndSettle();
}

Future<void> _done(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(KaeliBirthdayPicker.doneKey));
  await tester.tap(find.byKey(KaeliBirthdayPicker.doneKey));
  await tester.pumpAndSettle();
}

void main() {
  test('KaeliBirthday: == y hashCode; días del mes', () {
    expect(const KaeliBirthday(month: 2, day: 29), const KaeliBirthday(month: 2, day: 29));
    expect(const KaeliBirthday(month: 2, day: 29).hashCode, const KaeliBirthday(month: 2, day: 29).hashCode);
    expect(const KaeliBirthday(month: 2, day: 29), isNot(const KaeliBirthday(month: 2, day: 29, year: 2024)));
    expect(KaeliBirthday.daysIn(2, null), 29);
    expect(KaeliBirthday.daysIn(2, 2024), 29);
    expect(KaeliBirthday.daysIn(2, 2026), 28);
    expect(KaeliBirthday.daysIn(4, 2026), 30);
  });

  testWidgets('sin initial: abre en hoy y «Sin año», con «Cumpleaños», «Cancelar» y «Listo»', (tester) async {
    KaeliBirthday? got;
    await _open(tester, onResult: (b) => got = b);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Cumpleaños'), findsOneWidget);
    expect(find.text('Sin año'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
    await _done(tester);
    expect(got, const KaeliBirthday(month: 11, day: 13));
  });

  testWidgets('cancelar devuelve null', (tester) async {
    KaeliBirthday? got = const KaeliBirthday(month: 1, day: 1);
    await _open(tester, onResult: (b) => got = b);
    await tester.tap(find.byKey(KaeliBirthdayPicker.cancelKey));
    await tester.pumpAndSettle();
    expect(got, isNull);
  });

  testWidgets('elegir día, mes y año', (tester) async {
    KaeliBirthday? got;
    await _open(tester, onResult: (b) => got = b);
    await _spin(tester, KaeliBirthdayPicker.dayWheelKey, 2); // 15
    await _spin(tester, KaeliBirthdayPicker.monthWheelKey, -1); // octubre
    await _spin(tester, KaeliBirthdayPicker.yearWheelKey, 3); // Sin año → 2026 → 2025 → 2024
    await _done(tester);
    expect(got, const KaeliBirthday(month: 10, day: 15, year: 2024));
  });

  testWidgets('con initial: abre en su valor', (tester) async {
    KaeliBirthday? got;
    await _open(tester, initial: const KaeliBirthday(month: 6, day: 3, year: 1985), onResult: (b) => got = b);
    expect(find.text('1985'), findsOneWidget);
    expect(find.text('Junio'), findsOneWidget);
    await _done(tester);
    expect(got, const KaeliBirthday(month: 6, day: 3, year: 1985));
  });

  testWidgets('29 de febrero: se puede sin año o con bisiesto; con 2026 baja a 28', (tester) async {
    KaeliBirthday? got;
    await _open(tester, initial: const KaeliBirthday(month: 2, day: 29), onResult: (b) => got = b);
    await _done(tester);
    expect(got, const KaeliBirthday(month: 2, day: 29));

    await _open(tester, initial: const KaeliBirthday(month: 2, day: 29, year: 2024), onResult: (b) => got = b);
    await _done(tester);
    expect(got, const KaeliBirthday(month: 2, day: 29, year: 2024));

    await _open(tester, initial: const KaeliBirthday(month: 2, day: 29), onResult: (b) => got = b);
    await _spin(tester, KaeliBirthdayPicker.yearWheelKey, 1); // 2026, no bisiesto
    await _done(tester);
    expect(got, const KaeliBirthday(month: 2, day: 28, year: 2026));
  });

  testWidgets('31 de marzo → abril: baja a 30', (tester) async {
    KaeliBirthday? got;
    await _open(tester, initial: const KaeliBirthday(month: 3, day: 31), onResult: (b) => got = b);
    await _spin(tester, KaeliBirthdayPicker.monthWheelKey, 1);
    await _done(tester);
    expect(got, const KaeliBirthday(month: 4, day: 30));
  });

  for (final (code, title, noYear, cancel, done, month) in [
    ('fr', 'Anniversaire', 'Sans année', 'Annuler', 'OK', 'Novembre'),
    ('pt', 'Aniversário', 'Sem ano', 'Cancelar', 'Pronto', 'Novembro'),
    ('en', 'Birthday', 'No year', 'Cancel', 'Done', 'November'),
  ]) {
    testWidgets('textos en $code', (tester) async {
      await _open(tester, locale: Locale(code), onResult: (_) {});
      expect(find.text(title), findsOneWidget);
      expect(find.text(noYear), findsOneWidget);
      expect(find.text(cancel), findsOneWidget);
      expect(find.text(done), findsOneWidget);
      expect(find.text(month), findsOneWidget);
    });
  }

  testWidgets('letra al 200 % en pantalla pequeña: cabe (al menos 3 filas) y «Listo» funciona', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    KaeliBirthday? got;
    await _open(tester, locale: const Locale('pt'), onResult: (b) => got = b);
    expect(tester.takeException(), isNull);
    final day = find.byKey(KaeliBirthdayPicker.dayWheelKey);
    final rows = tester.getSize(day).height / tester.widget<CupertinoPicker>(day).itemExtent;
    expect(rows, greaterThanOrEqualTo(3));
    await _done(tester);
    expect(tester.takeException(), isNull);
    expect(got, const KaeliBirthday(month: 11, day: 13));
  });
}
