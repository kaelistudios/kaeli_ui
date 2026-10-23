// KaeliKeyboard: tocar fuera, deslizar y barra «Listo».
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

void main() {
  testWidgets(
    'tocar fuera de un campo cierra el teclado; tocar otro campo o un botón sigue funcionando',
    (tester) async {
      var pressed = 0;
      await pumpKaeliApp(tester, TestForm(onButton: () => pressed++));

      await tester.tap(find.byKey(const Key('single')));
      await tester.pump();
      expect(fieldFocused(), isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // Otro campo: el foco pasa al otro (no se cierra en medio).
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();
      expect(fieldFocused(), isTrue);

      // Fuera (el título): se cierra.
      await tester.tap(find.text('Formulario'));
      await tester.pumpAndSettle();
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      // Un botón con el teclado abierto: cierra el teclado Y hace lo suyo.
      await tester.tap(find.byKey(const Key('single')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('button')));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(fieldFocused(), isFalse);
    },
  );

  testWidgets(
    'con dismissOnTapOutside: false, tocar fuera no cierra el teclado',
    (tester) async {
      await pumpKaeliApp(tester, const TestForm(), dismissOnTapOutside: false);
      await tester.tap(find.byKey(const Key('single')));
      await tester.pump();
      await tester.tap(find.text('Formulario'));
      await tester.pumpAndSettle();
      expect(fieldFocused(), isTrue);
    },
  );

  testWidgets('deslizar una lista cierra el teclado', (tester) async {
    await pumpKaeliApp(tester, const TestForm());
    await tester.tap(find.byKey(const Key('single')));
    await tester.pump();
    expect(fieldFocused(), isTrue);

    // Arrastrar EMPEZANDO sobre otro campo (así no cuenta como «tocar fuera»): lo cierra el desplazamiento.
    await tester.dragFrom(
      tester.getCenter(find.byKey(const Key('other'))),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(fieldFocused(), isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('deslizar un SingleChildScrollView también cierra el teclado', (
    tester,
  ) async {
    await pumpKaeliApp(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              TextField(key: Key('single')),
              TextField(key: Key('other')),
              SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('single')));
    await tester.pump();
    await tester.dragFrom(
      tester.getCenter(find.byKey(const Key('other'))),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(fieldFocused(), isFalse);
  });

  testWidgets('KaeliKeyboard.dismiss y dismissKeyboard cierran el teclado', (
    tester,
  ) async {
    await pumpKaeliApp(tester, const TestForm());
    await tester.showKeyboard(find.byKey(const Key('single')));
    await tester.pump();
    dismissKeyboard();
    await tester.pump();
    expect(fieldFocused(), isFalse);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.showKeyboard(find.byKey(const Key('multi')));
    await tester.pump();
    KaeliKeyboard.dismiss(tester.element(find.byType(TestForm)));
    await tester.pump();
    expect(fieldFocused(), isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  group('barra «Listo» sobre el teclado', () {
    testWidgets(
      'en iPhone aparece en campos de varias líneas, numéricos y de teléfono; «Listo» cierra el teclado',
      (tester) async {
        await onPlatform(TargetPlatform.iOS, () async {
          await pumpKaeliApp(tester, const TestForm());
          expect(find.byKey(KaeliKeyboard.barKey), findsNothing);

          // Una línea: el teclado tiene su propia tecla para cerrarse.
          await tester.tap(find.byKey(const Key('single')));
          await tester.pumpAndSettle();
          expect(find.byKey(KaeliKeyboard.barKey), findsNothing);

          for (final key in ['multi', 'number', 'phone']) {
            await tester.tap(find.byKey(Key(key)));
            await tester.pumpAndSettle();
            expect(
              find.byKey(KaeliKeyboard.barKey),
              findsOneWidget,
              reason: key,
            );
            expect(find.text('Listo'), findsOneWidget);
          }

          await tester.tap(find.byKey(KaeliKeyboard.doneKey));
          await tester.pumpAndSettle();
          expect(fieldFocused(), isFalse);
          expect(tester.testTextInput.isVisible, isFalse);
          expect(find.byKey(KaeliKeyboard.barKey), findsNothing);
        });
      },
    );

    testWidgets('en iPad también aparece y en inglés dice «Done»', (
      tester,
    ) async {
      await onPlatform(TargetPlatform.iOS, () async {
        tester.view.physicalSize = const Size(1024, 1366);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpKaeliApp(
          tester,
          const TestForm(),
          locale: const Locale('en'),
        );
        await tester.tap(find.byKey(const Key('number')));
        await tester.pumpAndSettle();
        expect(find.text('Done'), findsOneWidget);
      });
    });

    testWidgets(
      'en Android no aparece (su teclado numérico tiene tecla para cerrarse)',
      (tester) async {
        await onPlatform(TargetPlatform.android, () async {
          await pumpKaeliApp(tester, const TestForm());
          for (final key in ['multi', 'number', 'phone']) {
            await tester.tap(find.byKey(Key(key)));
            await tester.pumpAndSettle();
            expect(find.byKey(KaeliKeyboard.barKey), findsNothing, reason: key);
          }
        });
      },
    );

    testWidgets('queda justo encima del teclado y se suma a viewInsets', (
      tester,
    ) async {
      await onPlatform(TargetPlatform.iOS, () async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.reset);
        await pumpKaeliApp(tester, const TestForm());
        await tester.tap(find.byKey(const Key('multi')));
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byKey(KaeliKeyboard.barKey));
        expect(bar.bottom, 500, reason: 'justo encima del teclado');
        final insets = MediaQuery.viewInsetsOf(
          tester.element(find.byType(TestForm)),
        );
        expect(insets.bottom, 300 + bar.height);
      });
    });

    testWidgets('con doneBar: false no aparece', (tester) async {
      await onPlatform(TargetPlatform.iOS, () async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                KaeliKeyboard(doneBar: false, child: child!),
            home: const TestForm(),
          ),
        );
        await tester.tap(find.byKey(const Key('multi')));
        await tester.pumpAndSettle();
        expect(find.byKey(KaeliKeyboard.barKey), findsNothing);
      });
    });
  });

  test('needsKeyboardDoneBar: varias líneas, números y teléfono sí; texto de una línea no', () {
    EditableText field({int? maxLines = 1, TextInputType? type}) =>
        EditableText(
          controller: TextEditingController(),
          focusNode: FocusNode(),
          style: const TextStyle(),
          cursorColor: const Color.fromARGB(0, 0, 0, 0),
          backgroundCursorColor: const Color.fromARGB(0, 0, 0, 0),
          maxLines: maxLines,
          keyboardType: type,
        );
    expect(needsKeyboardDoneBar(field()), isFalse);
    expect(
      needsKeyboardDoneBar(field(type: TextInputType.emailAddress)),
      isFalse,
    );
    expect(needsKeyboardDoneBar(field(maxLines: null)), isTrue);
    expect(needsKeyboardDoneBar(field(maxLines: 4)), isTrue);
    expect(needsKeyboardDoneBar(field(type: TextInputType.number)), isTrue);
    expect(
      needsKeyboardDoneBar(
        field(type: const TextInputType.numberWithOptions(decimal: true)),
      ),
      isTrue,
    );
    expect(needsKeyboardDoneBar(field(type: TextInputType.phone)), isTrue);
  });
}
