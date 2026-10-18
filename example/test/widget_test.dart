// Prueba del ejemplo: lista → formulario → aviso de cambios → guardar; cambiar de pestaña cierra el teclado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';
import 'package:kaeli_ui_example/main.dart';

void main() {
  testWidgets('editar una propiedad: aviso al salir con cambios y «Guardar» la actualiza', (tester) async {
    await tester.pumpWidget(const ExampleApp(locale: Locale('es')));
    await tester.tap(find.byKey(const Key('list.item0')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('form.price')), '900');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('form.save')));
    await tester.pumpAndSettle();
    expect(find.text('900.00 por noche'), findsOneWidget);
  });

  testWidgets('cambiar de pestaña con el teclado abierto lo cierra', (tester) async {
    await tester.pumpWidget(const ExampleApp(locale: Locale('es')));
    await tester.showKeyboard(find.byKey(const Key('list.search')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tab.notes')));
    await tester.pumpAndSettle();
    expect(focusedEditableText(), isNull);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
