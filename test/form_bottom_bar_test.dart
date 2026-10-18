// KaeliFormBottomBar: «Guardar» se ve con el teclado abierto (y por encima de la barra «Listo» en iPhone).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

Widget _form({bool scaffold = false}) {
  const body = [TextField(key: Key('multi'), maxLines: null), TextField(key: Key('single'))];
  final save = FilledButton(key: const Key('save'), onPressed: () {}, child: const Text('Guardar'));
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

    testWidgets('$name: «Guardar» queda encima del teclado', (tester) async {
      _setScreen(tester);
      await pumpKaeliApp(tester, _form(scaffold: scaffold));
      await tester.showKeyboard(find.byKey(const Key('single')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 340);
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('save'));
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(800 - 340), reason: 'encima del teclado');
    });

    testWidgets('$name: sin teclado respeta la zona segura de abajo', (tester) async {
      _setScreen(tester);
      await pumpKaeliApp(tester, _form(scaffold: scaffold));
      final save = tester.getRect(find.byKey(const Key('save')));
      expect(save.bottom, lessThanOrEqualTo(800 - 34));
    });
  }

  testWidgets('en iPhone «Guardar» sube también por encima de la barra «Listo»', (tester) async {
    await onPlatform(TargetPlatform.iOS, () async {
      _setScreen(tester, keyboard: 300);
      await pumpKaeliApp(tester, _form());
      await tester.tap(find.byKey(const Key('multi')));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byKey(KaeliKeyboard.barKey));
      expect(bar.bottom, 500);
      final save = find.byKey(const Key('save'));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(bar.top), reason: '«Guardar» no queda detrás de la barra');
      expect(save.hitTestable(), findsOneWidget);
    });
  });
}
