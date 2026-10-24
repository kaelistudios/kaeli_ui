import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() {
  testWidgets('kaeliValidateForm + KaeliFormList: va al primer campo con error y lo enfoca', (tester) async {
    final form = GlobalKey<FormState>();
    final controllers = List.generate(30, (i) => TextEditingController(text: i == 25 ? '' : 'ok'));
    var valid = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: form,
            child: KaeliFormList(
              children: [
                for (final (i, c) in controllers.indexed)
                  TextFormField(
                    key: Key('f$i'),
                    controller: c,
                    validator: (v) => (v ?? '').isEmpty ? 'Falta el $i' : null,
                  ),
              ],
            ),
          ),
          bottomNavigationBar: ElevatedButton(
            onPressed: () => valid = kaeliValidateForm(form),
            child: const Text('Guardar'),
          ),
        ),
      ),
    );
    expect(find.text('Falta el 25'), findsNothing);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(valid, isFalse);
    expect(find.text('Falta el 25').hitTestable(), findsOneWidget);
    final field = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const Key('f25')), matching: find.byType(EditableText)),
    );
    expect(field.focusNode.hasFocus, isTrue);

    controllers[25].text = 'ya';
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(valid, isTrue);
  });

  testWidgets('KaeliRequiredLabel: asterisco y «obligatorio» para el lector', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextField(decoration: InputDecoration(label: KaeliRequiredLabel('Nombre'))),
        ),
      ),
    );
    expect(find.textContaining('Nombre *', findRichText: true), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Nombre, required')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('con ListView los campos de abajo no se validan (por eso KaeliFormList)', (tester) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: form,
            child: ListView(
              children: [for (var i = 0; i < 40; i++) TextFormField(validator: (v) => i == 39 ? 'Falta' : null)],
            ),
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isTrue);
  });
}
