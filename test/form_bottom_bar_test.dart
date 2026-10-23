// KaeliFormBottomBar (regla 0.2.0): «Guardar» se queda en su lugar con el teclado abierto y el formulario se
// desplaza para que el campo que se escribe se vea (también por encima de la barra «Listo» en iPhone).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

Widget _form({bool scaffold = false}) {
  final body = [
    for (var i = 0; i < 8; i++) const SizedBox(height: 60),
    const TextField(key: Key('multi'), maxLines: null),
    const TextField(key: Key('single')),
  ];
  final save = FilledButton(
    key: const Key('save'),
    onPressed: () {},
    child: const Text('Guardar'),
  );
  if (scaffold) {
    return KaeliFormScaffold(
      appBar: AppBar(title: const Text('Formulario')),
      body: ListView(children: body),
      bottomAction: save,
    );
  }
  return Scaffold(
    appBar: AppBar(title: const Text('Formulario')),
    body: ListView(children: body),
    bottomNavigationBar: KaeliFormBottomBar(showDivider: true, child: save),
  );
}

void _setScreen(WidgetTester tester, {double keyboard = 0}) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: 34);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

void main() {
  for (final scaffold in [false, true]) {
    final name = scaffold ? 'KaeliFormScaffold' : 'KaeliFormBottomBar';

    testWidgets('$name: «Guardar» no sube con el teclado y el campo se ve', (
      tester,
    ) async {
      _setScreen(tester);
      await pumpKaeliApp(tester, _form(scaffold: scaffold));
      final before = tester.getRect(find.byKey(const Key('save')));
      await tester.showKeyboard(find.byKey(const Key('single')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 340);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('save'))),
        before,
        reason: 'se queda en su lugar',
      );
      expect(
        tester.getRect(find.byKey(const Key('single'))).bottom,
        lessThanOrEqualTo(800 - 340),
        reason: 'el campo que se escribe queda encima del teclado',
      );
    });

    testWidgets('$name: sin teclado respeta la zona segura de abajo', (
      tester,
    ) async {
      _setScreen(tester);
      await pumpKaeliApp(tester, _form(scaffold: scaffold));
      final save = tester.getRect(find.byKey(const Key('save')));
      expect(save.bottom, lessThanOrEqualTo(800 - 34));
    });
  }

  testWidgets(
    'en iPhone el campo queda también por encima de la barra «Listo»',
    (tester) async {
      await onPlatform(TargetPlatform.iOS, () async {
        _setScreen(tester);
        await pumpKaeliApp(tester, _form());
        await tester.tap(find.byKey(const Key('multi')));
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byKey(KaeliKeyboard.barKey));
        expect(bar.bottom, 500);
        expect(
          tester.getRect(find.byKey(const Key('multi'))).bottom,
          lessThanOrEqualTo(bar.top),
        );
        expect(
          tester.getRect(find.byKey(const Key('save'))).top,
          greaterThan(bar.bottom),
          reason: 'el botón no sube',
        );
      });
    },
  );
}
