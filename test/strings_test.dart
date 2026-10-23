// Textos de kaeli_ui en los 4 idiomas y textos propios de cada app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

Widget _dirtyPage() => KaeliUnsavedChangesGuard(
  dirty: true,
  child: Scaffold(
    appBar: AppBar(title: const Text('Editar')),
    body: const TextField(key: Key('number'), keyboardType: TextInputType.number),
  ),
);

Future<void> _openAndBack(WidgetTester tester, {required Locale locale, KaeliUiStrings? strings, Widget? page}) async {
  await pumpKaeliApp(
    tester,
    Opener(page: (_) => page ?? _dirtyPage()),
    locale: locale,
    strings: strings,
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  for (final (code, title, discard, keep) in [
    ('es', '¿Descartar cambios?', 'Descartar', 'Seguir editando'),
    ('en', 'Discard changes?', 'Discard', 'Keep editing'),
    ('fr', 'Abandonner les modifications ?', 'Abandonner', 'Continuer'),
    ('pt', 'Descartar alterações?', 'Descartar', 'Continuar editando'),
  ]) {
    testWidgets('aviso de cambios en $code', (tester) async {
      await _openAndBack(tester, locale: Locale(code));
      expect(find.text(title), findsOneWidget);
      expect(find.text(discard), findsOneWidget);
      expect(find.text(keep), findsOneWidget);
    });
  }

  for (final (code, done) in [('fr', 'OK'), ('pt', 'OK')]) {
    testWidgets('barra «Listo» en $code', (tester) async {
      await onPlatform(TargetPlatform.iOS, () async {
        await pumpKaeliApp(tester, _dirtyPage(), locale: Locale(code));
        await tester.tap(find.byKey(const Key('number')));
        await tester.pumpAndSettle();
        expect(find.descendant(of: find.byKey(KaeliKeyboard.doneKey), matching: find.text(done)), findsOneWidget);
      });
    });
  }

  test('idioma sin textos propios: inglés', () {
    expect(KaeliUiStrings.resolve('de').done, 'Done');
    expect(KaeliUiStrings.resolve(null).discardTitle, 'Discard changes?');
  });

  testWidgets('textos propios en KaeliKeyboard: cambian solo los indicados', (tester) async {
    await _openAndBack(
      tester,
      locale: const Locale('es'),
      strings: const KaeliUiStrings(discardTitle: '¿Salir sin guardar?', discard: 'Salir'),
    );
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);
    expect(find.text('Salir'), findsOneWidget);
    expect(find.text('Seguir editando'), findsOneWidget, reason: 'lo demás sigue en el idioma actual');
  });

  testWidgets('textos propios en el guardián van encima de los de KaeliKeyboard', (tester) async {
    await _openAndBack(
      tester,
      locale: const Locale('pt'),
      strings: const KaeliUiStrings(discard: 'Sair'),
      page: KaeliUnsavedChangesGuard(
        dirty: true,
        strings: const KaeliUiStrings(keepEditing: 'Ficar'),
        child: Scaffold(appBar: AppBar(title: const Text('Editar'))),
      ),
    );
    expect(find.text('Sair'), findsOneWidget);
    expect(find.text('Ficar'), findsOneWidget);
    expect(find.text('Descartar alterações?'), findsOneWidget);
  });

  testWidgets('texto propio de la barra «Listo»', (tester) async {
    await onPlatform(TargetPlatform.iOS, () async {
      await pumpKaeliApp(tester, _dirtyPage(), strings: const KaeliUiStrings(done: 'Cerrar'));
      await tester.tap(find.byKey(const Key('number')));
      await tester.pumpAndSettle();
      expect(find.text('Cerrar'), findsOneWidget);
    });
  });
}
