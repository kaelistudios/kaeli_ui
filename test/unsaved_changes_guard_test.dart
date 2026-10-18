// KaeliUnsavedChangesGuard y KaeliDirtyTracker: salir con cambios pregunta «¿Descartar cambios?».
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

/// Formulario que usa KaeliDirtyTracker con un controlador fuera de un Form.
class _Edit extends StatefulWidget {
  const _Edit();

  @override
  State<_Edit> createState() => _EditState();
}

class _EditState extends State<_Edit> with KaeliDirtyTracker<_Edit> {
  final _name = TextEditingController(text: 'Casa Colibrí');
  var _tags = <String>{'playa'};

  @override
  Object? dirtySnapshot() => (_name.text, _tags);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KaeliUnsavedChangesGuard(
    isDirty: () => hasUnsavedChanges,
    listenable: _name,
    child: Scaffold(
      appBar: AppBar(title: const Text('Editar')),
      body: Column(
        children: [
          TextField(key: const Key('name'), controller: _name),
          TextButton(
            key: const Key('tag'),
            onPressed: () => setState(() => _tags = {..._tags, 'piscina'}),
            child: const Text('Etiqueta'),
          ),
        ],
      ),
      bottomNavigationBar: KaeliFormBottomBar(
        child: FilledButton(
          key: const Key('save'),
          onPressed: () {
            setState(markSaved);
            kaeliPopAfterSave(context);
          },
          child: const Text('Guardar'),
        ),
      ),
    ),
  );
}

/// Formulario con Form + TextFormField y `ValueNotifier<bool>` como aviso de cambios.
class _NotifierEdit extends StatefulWidget {
  const _NotifierEdit();

  @override
  State<_NotifierEdit> createState() => _NotifierEditState();
}

class _NotifierEditState extends State<_NotifierEdit> {
  final _dirty = ValueNotifier(false);

  @override
  void dispose() {
    _dirty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KaeliUnsavedChangesGuard(
    listenable: _dirty,
    child: Scaffold(
      appBar: AppBar(title: const Text('Editar')),
      body: TextFormField(key: const Key('name'), onChanged: (_) => _dirty.value = true),
    ),
  );
}

Future<void> _open(WidgetTester tester, Widget page, {Locale locale = const Locale('es'), KaeliUiStrings? strings}) async {
  await pumpKaeliApp(tester, Opener(page: (_) => page), locale: locale, strings: strings);
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin cambios vuelve sin preguntar', (tester) async {
    await _open(tester, const _Edit());
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsNothing);
    expect(find.byKey(const Key('open')), findsOneWidget);
  });

  testWidgets('con cambios pregunta: «Seguir editando» se queda, «Descartar» vuelve', (tester) async {
    await _open(tester, const _Edit());
    await tester.enterText(find.byKey(const Key('name')), 'Casa Colibrí 2');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('name')), findsOneWidget);
    expect(find.text('Casa Colibrí 2'), findsOneWidget);

    // Atrás del sistema (Android) también pregunta.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('name')), findsNothing);
    expect(find.byKey(const Key('open')), findsOneWidget);
  });

  testWidgets('volver a dejar el valor original ya no pregunta', (tester) async {
    await _open(tester, const _Edit());
    await tester.enterText(find.byKey(const Key('name')), 'Otra');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name')), 'Casa Colibrí');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsNothing);
    expect(find.byKey(const Key('open')), findsOneWidget);
  });

  testWidgets('un cambio que no es de texto (conjunto) también cuenta', (tester) async {
    await _open(tester, const _Edit());
    await tester.tap(find.byKey(const Key('tag')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsOneWidget);
  });

  testWidgets('después de guardar vuelve sin preguntar', (tester) async {
    await _open(tester, const _Edit());
    await tester.enterText(find.byKey(const Key('name')), 'Casa Nueva');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save')));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsNothing);
    expect(find.byKey(const Key('open')), findsOneWidget);
  });

  testWidgets('con cambios el gesto de volver de iPhone no sale', (tester) async {
    await onPlatform(TargetPlatform.iOS, () async {
      await _open(tester, const _Edit());
      await tester.enterText(find.byKey(const Key('name')), 'Otra');
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(5, 300), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('name')), findsOneWidget);
    });
  });

  testWidgets('ValueListenable<bool> como aviso de cambios', (tester) async {
    await _open(tester, const _NotifierEdit());
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open')), findsOneWidget, reason: 'sin cambios sale');

    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('name')), 'x');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar cambios?'), findsOneWidget);
    await tester.tap(find.byKey(KaeliUnsavedChangesGuard.discardKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open')), findsOneWidget);
  });

  testWidgets('confirmDiscard propio reemplaza el diálogo', (tester) async {
    var asked = 0;
    await _open(
      tester,
      KaeliUnsavedChangesGuard(
        dirty: true,
        confirmDiscard: (_) async {
          asked++;
          return true;
        },
        child: Scaffold(appBar: AppBar(title: const Text('Editar'))),
      ),
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(find.byKey(const Key('open')), findsOneWidget);
  });

  test('kaeliSnapshotEquals compara por contenido', () {
    expect(kaeliSnapshotEquals([1, {'a': {2}}], [1, {'a': {2}}]), isTrue);
    expect(kaeliSnapshotEquals([1, 2], [1, 3]), isFalse);
    expect(kaeliSnapshotEquals({'a': 1}, {'b': 1}), isFalse);
    expect(kaeliSnapshotEquals(('x', 1), ('x', 1)), isTrue);
  });
}
