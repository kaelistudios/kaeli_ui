// KaeliKeyboardObserver y KaeliTabDismiss: el teclado no queda pegado al cambiar de pantalla o de pestaña.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

/// Dos pestañas, cada una con su navegador y su observador (como `StatefulShellRoute.indexedStack` de go_router).
class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  var _index = 0;
  final _observers = [KaeliKeyboardObserver(), KaeliKeyboardObserver()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        for (final i in [0, 1])
          Navigator(
            observers: [_observers[i]],
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => Scaffold(body: TextField(key: Key('field$i'))),
            ),
          ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: KaeliTabDismiss.wrap(
        (i) => setState(() => _index = i),
      ),
      destinations: const [
        NavigationDestination(
          key: Key('tab0'),
          icon: Icon(Icons.list),
          label: 'Lista',
        ),
        NavigationDestination(
          key: Key('tab1'),
          icon: Icon(Icons.settings),
          label: 'Ajustes',
        ),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'al volver con el teclado abierto (flecha o atrás del sistema), el teclado se cierra',
    (tester) async {
      await pumpKaeliApp(tester, Opener(page: (_) => const TestForm()));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byKey(const Key('single')));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open')), findsOneWidget);
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      // Botón atrás de Android (o volver del sistema).
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byKey(const Key('multi')));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open')), findsOneWidget);
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );

  testWidgets(
    'al abrir una pantalla o un diálogo con el teclado abierto, el teclado se cierra',
    (tester) async {
      await pumpKaeliApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const TextField(key: Key('single')),
                TextButton(
                  key: const Key('dialog'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(title: Text('Hola')),
                  ),
                  child: const Text('Diálogo'),
                ),
                TextButton(
                  key: const Key('push'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('Otra')),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byKey(const Key('single')));
      await tester.pump();
      // Sin pasar por «tocar fuera»: se abre desde el código.
      tester.widget<TextButton>(find.byKey(const Key('dialog'))).onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Hola'), findsOneWidget);
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      Navigator.of(tester.element(find.text('Hola'))).pop();
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byKey(const Key('single')));
      await tester.pump();
      tester.widget<TextButton>(find.byKey(const Key('push'))).onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Otra'), findsOneWidget);
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );

  testWidgets(
    'al reemplazar una pantalla con el teclado abierto, el teclado se cierra',
    (tester) async {
      await pumpKaeliApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextField(
              key: const Key('single'),
              onSubmitted: (_) => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Nueva')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byKey(const Key('single')));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Nueva'), findsOneWidget);
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );

  testWidgets('el gesto de volver de iPhone cierra el teclado apenas empieza', (
    tester,
  ) async {
    await onPlatform(TargetPlatform.iOS, () async {
      // Sin «tocar fuera», para comprobar que lo cierra el observador (al empezar el gesto) y no el toque.
      await pumpKaeliApp(
        tester,
        Opener(page: (_) => const TestForm()),
        dismissOnTapOutside: false,
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byKey(const Key('single')));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(fieldFocused(), isFalse, reason: 'cerrado a mitad del gesto');
      expect(tester.testTextInput.isVisible, isFalse);
      await gesture.moveBy(const Offset(500, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open')), findsOneWidget);
    });
  });

  testWidgets(
    'KaeliKeyboardObserver cierra el teclado en cada aviso del navegador',
    (tester) async {
      await pumpKaeliApp(tester, const TestForm());
      final observer = KaeliKeyboardObserver();
      final route = ModalRoute.of(tester.element(find.byType(TestForm)))!;
      final calls = <String, void Function()>{
        'didPush': () => observer.didPush(route, null),
        'didPop': () => observer.didPop(route, null),
        'didRemove': () => observer.didRemove(route, null),
        'didReplace': () => observer.didReplace(newRoute: route),
        'didStartUserGesture': () => observer.didStartUserGesture(route, null),
      };
      for (final MapEntry(key: name, value: call) in calls.entries) {
        await tester.showKeyboard(find.byKey(const Key('single')));
        await tester.pump();
        expect(tester.testTextInput.isVisible, isTrue, reason: name);
        call();
        await tester.pump();
        expect(fieldFocused(), isFalse, reason: name);
        expect(tester.testTextInput.isVisible, isFalse, reason: name);
      }
    },
  );

  testWidgets(
    'cambiar de pestaña con el teclado abierto lo cierra (KaeliTabDismiss.wrap)',
    (tester) async {
      await pumpKaeliApp(tester, const _Tabs(), dismissOnTapOutside: false);
      await tester.showKeyboard(find.byKey(const Key('field0')));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.byKey(const Key('tab1')));
      await tester.pumpAndSettle();
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      // Al volver a la pestaña, el campo sigue ahí pero sin el teclado.
      await tester.tap(find.byKey(const Key('tab0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('field0')), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );

  testWidgets(
    'KaeliTabDismiss.goBranch cierra el teclado y pide la primera pantalla al tocar la pestaña actual',
    (tester) async {
      await pumpKaeliApp(tester, const TestForm());
      final calls = <(int, bool)>[];
      void goBranch(int index, {bool initialLocation = false}) =>
          calls.add((index, initialLocation));

      await tester.showKeyboard(find.byKey(const Key('single')));
      await tester.pump();
      KaeliTabDismiss.goBranch(1, goBranch, currentIndex: 0);
      await tester.pump();
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      KaeliTabDismiss.goBranch(1, goBranch, currentIndex: 1);
      expect(calls, [(1, false), (1, true)]);
    },
  );
}
