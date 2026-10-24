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
    expect(find.byType(RadioListTile<int>), findsNWidgets(4));
    expect(find.byIcon(Icons.place), findsNWidgets(4));
    await tester.tap(find.text('Opción 3'));
    await tester.pumpAndSettle();
    expect(value, 3);

    expect(KaeliChoice.segmented(const [KaeliOption(1, 'Un texto bastante largo'), KaeliOption(2, 'Otro')]), isFalse);
    expect(KaeliChoice.segmented(const [KaeliOption(1, 'Sí'), KaeliOption(2, 'No')], textScale: 2), isFalse);
  });
}
