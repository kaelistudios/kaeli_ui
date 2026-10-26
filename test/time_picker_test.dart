import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

/// Un botón que abre el selector y guarda lo elegido en [got].
Future<void> _open(
  WidgetTester tester, {
  required TimeOfDay initial,
  int minuteInterval = 5,
  bool twentyFour = false,
  required void Function(TimeOfDay?) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // El reloj del teléfono (12 o 24 horas).
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: twentyFour),
        child: child!,
      ),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              onResult(await showKaeliTimePicker(context, initial: initial, minuteInterval: minuteInterval)),
          child: const Text('ir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el mismo estilo que el calendario: título «Elige la hora», «Cancelar» y «Listo»', (tester) async {
    TimeOfDay? got = const TimeOfDay(hour: 0, minute: 0);
    await _open(tester, initial: const TimeOfDay(hour: 8, minute: 7), onResult: (t) => got = t);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Elige la hora'), findsOneWidget);
    expect(find.byKey(KaeliTimePicker.periodWheelKey), findsOneWidget, reason: 'reloj de 12 horas: a. m./p. m.');
    await tester.tap(find.byKey(KaeliTimePicker.doneKey));
    await tester.pumpAndSettle();
    expect(got, const TimeOfDay(hour: 8, minute: 5), reason: 'redondeado al intervalo de 5 minutos');
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KaeliTimePicker.cancelKey));
    await tester.pumpAndSettle();
    expect(got, isNull);
  });

  testWidgets('girar las ruedas: 16:35 con el reloj de 24 horas y minutos de 1 en 1', (tester) async {
    TimeOfDay? got;
    await _open(
      tester,
      initial: const TimeOfDay(hour: 15, minute: 30),
      minuteInterval: 1,
      twentyFour: true,
      onResult: (t) => got = t,
    );
    expect(find.byKey(KaeliTimePicker.periodWheelKey), findsNothing);
    final hour = find.byKey(KaeliTimePicker.hourWheelKey);
    final minute = find.byKey(KaeliTimePicker.minuteWheelKey);
    final extent = tester.widget<CupertinoPicker>(hour).itemExtent;
    await tester.drag(hour, Offset(0, -extent));
    await tester.pumpAndSettle();
    await tester.drag(minute, Offset(0, -extent * 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KaeliTimePicker.doneKey));
    await tester.pumpAndSettle();
    expect(got, const TimeOfDay(hour: 16, minute: 35));
  });

  testWidgets('p. m. con el reloj de 12 horas', (tester) async {
    TimeOfDay? got;
    await _open(tester, initial: const TimeOfDay(hour: 9, minute: 0), onResult: (t) => got = t);
    final period = find.byKey(KaeliTimePicker.periodWheelKey);
    final extent = tester.widget<CupertinoPicker>(period).itemExtent;
    await tester.drag(period, Offset(0, -extent));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(KaeliTimePicker.doneKey));
    await tester.pumpAndSettle();
    expect(got, const TimeOfDay(hour: 21, minute: 0));
  });

  testWidgets('letra al 200 % en pantalla pequeña: cabe (al menos 3 filas) y «Listo» funciona', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    TimeOfDay? got;
    await _open(tester, initial: const TimeOfDay(hour: 12, minute: 7), minuteInterval: 1, onResult: (t) => got = t);
    expect(tester.takeException(), isNull);
    final hour = find.byKey(KaeliTimePicker.hourWheelKey);
    final rows = tester.getSize(hour).height / tester.widget<CupertinoPicker>(hour).itemExtent;
    expect(rows, greaterThanOrEqualTo(3));
    await tester.ensureVisible(find.byKey(KaeliTimePicker.doneKey));
    await tester.tap(find.byKey(KaeliTimePicker.doneKey));
    await tester.pumpAndSettle();
    expect(got, const TimeOfDay(hour: 12, minute: 7));
  });
}
