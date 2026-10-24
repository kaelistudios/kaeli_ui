import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Set<int> disabled = const {}}) async {
    var value = <int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => KaeliWeekdayPicker(
              value: value,
              onChanged: (v) => set(() => value = v),
              initials: (d) => 'LMMJVSD'[d - 1],
              names: (d) => 'dia$d',
              weekdaysLabel: 'Lunes a viernes',
              allLabel: 'Todos',
              disabled: disabled,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('siete círculos iguales; tocar marca sin ✓ ni cambiar de tamaño', (tester) async {
    await pump(tester);
    final sizes = [for (var d = 1; d <= 7; d++) tester.getSize(find.bySemanticsLabel('dia$d'))];
    expect(sizes.toSet(), hasLength(1));
    await tester.tap(find.bySemanticsLabel('dia3'));
    await tester.pump();
    expect(tester.getSemantics(find.bySemanticsLabel('dia3')), isSemantics(isSelected: true));
    expect(tester.getSize(find.bySemanticsLabel('dia3')), sizes.first);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('atajos con borde: «Todos» sin los desactivados', (tester) async {
    await pump(tester, disabled: {2});
    expect(find.widgetWithText(OutlinedButton, 'Lunes a viernes'), findsOneWidget);
    await tester.tap(find.text('Todos'));
    await tester.pump();
    for (final d in [1, 3, 4, 5, 6, 7]) {
      expect(tester.getSemantics(find.bySemanticsLabel('dia$d')), isSemantics(isSelected: true));
    }
    expect(tester.getSemantics(find.bySemanticsLabel('dia2')), isSemantics(isSelected: false));
  });
}
