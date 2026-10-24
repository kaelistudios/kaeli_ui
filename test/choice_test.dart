import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double textScale = 1}) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets('2 o 3 opciones cortas: control segmentado; al tocar cambia', (tester) async {
    var value = 'a';
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KaeliChoice<String>(
          value: value,
          options: const [KaeliOption('a', 'Uno'), KaeliOption('b', 'Dos')],
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    await tester.tap(find.text('Dos'));
    await tester.pumpAndSettle();
    expect(value, 'b');
  });

  testWidgets('4 o más, textos largos o letra muy grande: lista vertical con círculo', (tester) async {
    var value = 1;
    final many = [for (var i = 1; i <= 4; i++) KaeliOption(i, 'Opción $i', icon: Icons.place)];
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) =>
            KaeliChoice<int>(value: value, options: many, onChanged: (v) => setState(() => value = v)),
      ),
    );
    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.byType(RadioListTile<Object?>), findsNWidgets(4));
    expect(find.byIcon(Icons.place), findsNWidgets(4));
    await tester.tap(find.text('Opción 3'));
    await tester.pumpAndSettle();
    expect(value, 3);

    expect(KaeliChoice.segmented(const [KaeliOption(1, 'Un texto bastante largo'), KaeliOption(2, 'Otro')]), isFalse);
    expect(KaeliChoice.segmented(const [KaeliOption(1, 'Sí'), KaeliOption(2, 'No')], textScale: 2), isFalse);
  });

  testWidgets('layout fijo: segmentado aunque la letra sea grande', (tester) async {
    await pump(
      tester,
      KaeliChoice<int>(
        value: 1,
        layout: KaeliChoiceLayout.segmented,
        options: const [KaeliOption(1, 'Día'), KaeliOption(2, 'Semana'), KaeliOption(3, 'Mes')],
        onChanged: (_) {},
      ),
      textScale: 2,
    );
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
  });

  testWidgets('tarjetas con ícono: elegir una', (tester) async {
    String? value;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KaeliChoice<String>(
          layout: KaeliChoiceLayout.cards,
          value: value,
          options: const [
            KaeliOption('c1', 'Consultorio 1', icon: Icons.place, subtitle: 'Centro'),
            KaeliOption('h', 'A domicilio', icon: Icons.home),
          ],
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    expect(find.byType(KaeliChoiceCard), findsNWidgets(2));
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    await tester.tap(find.text('A domicilio'));
    await tester.pumpAndSettle();
    expect(value, 'h');
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.bySemanticsLabel('Consultorio 1, Centro'), findsOneWidget);
  });

  testWidgets('lista con «Otra» al final: muestra el campo al elegirla', (tester) async {
    int? value = 24;
    var other = false;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KaeliChoice<int>(
          value: other ? null : value,
          options: const [KaeliOption(12, '12 h'), KaeliOption(24, '24 h')],
          onChanged: (v) => setState(() {
            value = v;
            other = false;
          }),
          other: KaeliChoiceOther(
            label: 'Otra',
            selected: other,
            onSelected: () => setState(() => other = true),
            field: const TextField(key: Key('other')),
          ),
        ),
      ),
    );
    // Con «Otra» nunca va segmentado, aunque sean 2 opciones cortas.
    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.byKey(const Key('other')), findsNothing);
    await tester.tap(find.text('Otra'));
    await tester.pumpAndSettle();
    expect(other, isTrue);
    expect(find.byKey(const Key('other')), findsOneWidget);
    await tester.tap(find.text('12 h'));
    await tester.pumpAndSettle();
    expect((value, other), (12, false));
    expect(find.byKey(const Key('other')), findsNothing);
  });

  testWidgets('varias con tarjetas: marcar y desmarcar', (tester) async {
    var values = <int>{1};
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KaeliMultiChoice<int>(
          values: values,
          options: const [
            KaeliOption(1, 'Lenguaje', icon: Icons.mic),
            KaeliOption(2, 'Física', icon: Icons.accessibility),
          ],
          onChanged: (v) => setState(() => values = v),
          footer: const [KaeliChoiceCard(label: '+ Agregar otra', selected: false, showIndicator: false)],
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Física'));
    await tester.pumpAndSettle();
    expect(values, {1, 2});
    await tester.tap(find.text('Lenguaje'));
    await tester.pumpAndSettle();
    expect(values, {2});
    expect(find.text('+ Agregar otra'), findsOneWidget);
  });

  testWidgets('tarjetas al 200 %: sin desbordes', (tester) async {
    await pump(
      tester,
      KaeliChoice<int>(
        layout: KaeliChoiceLayout.cards,
        value: 1,
        options: const [
          KaeliOption(1, 'Consultorio principal de la avenida', icon: Icons.place, subtitle: 'Calle larga 123, piso 4'),
        ],
        onChanged: (_) {},
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
