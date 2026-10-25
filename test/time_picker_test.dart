import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() {
  testWidgets('hora con ruedas: ✓ devuelve la hora; ✕ devuelve null', (tester) async {
    TimeOfDay? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                got = await showKaeliTimePicker(context, initial: const TimeOfDay(hour: 8, minute: 7)),
            child: const Text('ir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(got, const TimeOfDay(hour: 8, minute: 5), reason: 'redondeado al intervalo de 5 minutos');
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(got, isNull);
  });

  testWidgets('letra al 200 % en pantalla pequeña: la rueda se achica (al menos 3 filas) y la hoja cabe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    TimeOfDay? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => got = await showKaeliTimePicker(
              context,
              initial: const TimeOfDay(hour: 12, minute: 7),
              minuteInterval: 1,
            ),
            child: const Text('ir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(CupertinoDatePicker)).height, greaterThanOrEqualTo(96));
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(got, const TimeOfDay(hour: 12, minute: 7), reason: 'de 1 en 1, sin redondear');
  });
}
