import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

const _brands = [
  'Avon',
  'Farmasi',
  'Ésika',
  'Unique / Yanbal',
  'Natura',
  'Zermat',
  'Cyzone',
  'Mary Kay',
  'Oriflame',
  'Jafra',
];
final _options = [for (final b in _brands) KaeliSearchOption(b, b)];

const _field = Key('brand');
const _filler = Key('filler');

class _Host extends StatefulWidget {
  const _Host({this.allowNew = true, this.clearOnSelect = true, this.onTaken, this.brands = _brands});

  final List<String> brands;
  final bool allowNew;
  final bool clearOnSelect;
  final ValueChanged<KaeliSearchOption<String>>? onTaken;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final added = <String>[];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KaeliSearchField<String>(
          fieldKey: _field,
          label: 'Marca',
          // Como haría la app: las que se agregaron como nuevas también son opciones (así no se repiten).
          options: [
            for (final b in widget.brands) KaeliSearchOption(b, b),
            for (final a in added)
              if (!widget.brands.contains(a)) KaeliSearchOption(a, a),
          ],
          maxResults: 5,
          clearOnSelect: widget.clearOnSelect,
          isTaken: (b) => added.contains(b),
          onTaken: widget.onTaken,
          onSelected: (o) => setState(() => added.add(o.value)),
          onAddNew: widget.allowNew ? (text) => setState(() => added.add(text)) : null,
        ),
        for (final a in added) Text('agregada: $a'),
        const SizedBox(key: _filler, height: 1200),
      ],
    ),
  );
}

void main() {
  group('búsqueda', () {
    test('sin importar tildes, mayúsculas ni signos', () {
      expect(kaeliSearchFold('Ésika'), 'esika');
      expect(kaeliSearchFold('Unique / Yanbal'), 'uniqueyanbal');
      expect(kaeliSearchOptions('esika', _options).first.label, 'Ésika');
      expect(kaeliSearchOptions('ZERMAT', _options).single.label, 'Zermat');
    });

    test('encuentra por una parte del nombre o por otros nombres', () {
      expect(kaeliSearchOptions('yanbal', _options).first.label, 'Unique / Yanbal');
      final banks = [
        const KaeliSearchOption('bdb', 'Banco de Bogotá', keywords: ['BdB']),
      ];
      expect(kaeliSearchOptions('bdb', banks).single.value, 'bdb');
    });

    test('perdona un error de letra desde 5 letras, ninguno en palabras cortas', () {
      expect(kaeliSearchOptions('Farmasy', _options).first.label, 'Farmasi');
      expect(kaeliSearchOptions('Farms', _options).first.label, 'Farmasi');
      expect(kaeliSearchOptions('Avin', _options), isEmpty);
    });

    test('primero los que empiezan igual; en empate, el orden de la lista', () {
      final r = kaeliSearchOptions('a', _options);
      expect(r.first.label, 'Avon');
      expect(kaeliSearchOptions('', _options, limit: 3).map((o) => o.label), ['Avon', 'Farmasi', 'Ésika']);
    });

    test('lo escrito se reconoce como una conocida, con su nombre oficial', () {
      expect(kaeliMatchOption('farmasy', _options)?.label, 'Farmasi');
      expect(kaeliMatchOption('yanbal', _options)?.label, 'Unique / Yanbal');
      expect(kaeliMatchOption('Mi marca', _options), isNull);
    });

    test('si se parece igual a dos, no adivina', () {
      final twins = [const KaeliSearchOption('a', 'Marcela'), const KaeliSearchOption('b', 'Marcelo')];
      expect(kaeliMatchOption('Marcele', twins), isNull);
      expect(kaeliMatchOption('Marcelo', twins)?.value, 'b');
    });

    test('0.22.1: kaeliClosestOptions da la parecida, o las dos si empatan, y nada con solo el principio', () {
      expect(kaeliClosestOptions('Farmasy', _options).map((o) => o.label), ['Farmasi']);
      final twins = [const KaeliSearchOption('a', 'Marcela'), const KaeliSearchOption('b', 'Marcelo')];
      expect(kaeliClosestOptions('Marcele', twins).map((o) => o.value), ['a', 'b']);
      expect(kaeliClosestOptions('Nat', _options), isEmpty);
      expect(kaeliClosestOptions('Mi marca', _options), isEmpty);
    });

    test('perdona errores de letra también en una parte del nombre', () {
      expect(kaeliMatchOption('Yanbak', _options)?.label, 'Unique / Yanbal');
    });
  });

  group('campo', () {
    testWidgets('con solo tocar el campo se abre la lista, sin escribir', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      expect(find.text('Avon'), findsNothing);
      await tester.tap(find.byKey(_field));
      await tester.pumpAndSettle();
      expect(find.text('Avon'), findsOneWidget);
      expect(find.text('Natura'), findsOneWidget);
      expect(find.text('Zermat'), findsNothing, reason: 'maxResults: 5');
      expect(find.byKey(KaeliSearchField.addNewKey), findsNothing);
    });

    testWidgets('tocar una opción la elige aunque el teclado esté abierto, y ya no vuelve a salir', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.pumpAndSettle();
      final press = await tester.startGesture(tester.getCenter(find.text('Farmasi')));
      await tester.pump();
      expect(fieldFocused(), isTrue, reason: 'al poner el dedo en la fila, el teclado sigue abierto');
      expect(find.text('Farmasi'), findsOneWidget);
      await press.up();
      await tester.pumpAndSettle();
      expect(find.text('agregada: Farmasi'), findsOneWidget);
      expect(find.text('Avon'), findsNothing, reason: 'la lista se cierra al elegir');
      await tester.tap(find.byKey(_field));
      await tester.pumpAndSettle();
      expect(find.text('Farmasi'), findsNothing);
      expect(find.text('Zermat'), findsOneWidget, reason: 'sube la siguiente');
    });

    testWidgets('al escribir filtra y ofrece agregar lo que no está', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'Mi Marca');
      await tester.pumpAndSettle();
      expect(find.text('Avon'), findsNothing);
      expect(find.text('Agregar «Mi Marca»'), findsOneWidget);
      await tester.tap(find.byKey(KaeliSearchField.addNewKey));
      await tester.pumpAndSettle();
      expect(find.text('agregada: Mi Marca'), findsOneWidget);
    });

    testWidgets('0.22.1: si se parece a una conocida, la fila es la conocida (arriba), sin «Agregar»', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'Farmasy');
      await tester.pumpAndSettle();
      expect(find.byKey(KaeliSearchField.addNewKey), findsNothing, reason: 'no dice «Agregar «Farmasy»»');
      expect(find.textContaining('Farmasy'), findsOneWidget, reason: 'solo en el campo');
      final rows = tester.widgetList<Text>(find.descendant(of: find.byType(InkWell), matching: find.byType(Text)));
      expect(rows.first.data, 'Farmasi', reason: 'la parecida va arriba');
      await tester.tap(find.text('Farmasi'));
      await tester.pumpAndSettle();
      expect(find.text('agregada: Farmasi'), findsOneWidget, reason: 'lo que dice la fila es lo que se agrega');
    });

    testWidgets('0.22.1: si se parece igual a dos, salen las dos y no adivina', (tester) async {
      await pumpKaeliApp(tester, const _Host(brands: ['Avon', 'Marcela', 'Marcelo']));
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'Marcele');
      await tester.pumpAndSettle();
      expect(find.text('Marcela'), findsOneWidget);
      expect(find.text('Marcelo'), findsOneWidget);
      expect(find.byKey(KaeliSearchField.addNewKey), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining('agregada:'), findsNothing, reason: 'Enter no adivina ni agrega «Marcele»');
      expect(find.text('Marcela'), findsOneWidget, reason: 'la lista sigue para elegir');
    });

    testWidgets('0.22.1: «Agregar» sigue apareciendo mientras se escribe el principio de una conocida', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'Nat');
      await tester.pumpAndSettle();
      expect(find.text('Natura'), findsOneWidget);
      expect(find.text('Agregar «Nat»'), findsOneWidget);
    });

    testWidgets('si lo escrito se parece a una conocida, se agrega la conocida', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'farmasy');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('agregada: Farmasi'), findsOneWidget);
    });

    testWidgets('una ya agregada no se repite: avisa', (tester) async {
      KaeliSearchOption<String>? repeated;
      await pumpKaeliApp(tester, _Host(onTaken: (o) => repeated = o));
      await tester.tap(find.byKey(_field));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avon'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'avon');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repeated?.value, 'Avon');
      expect(find.text('agregada: Avon'), findsOneWidget);
    });

    testWidgets('sin «agregar», muestra que no hay coincidencias', (tester) async {
      await pumpKaeliApp(tester, const _Host(allowNew: false));
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'xyz');
      await tester.pumpAndSettle();
      expect(find.byKey(KaeliSearchField.noResultsKey), findsOneWidget);
      expect(find.text('No hay coincidencias'), findsOneWidget);
    });

    testWidgets('para elegir un solo valor, el campo queda con el nombre elegido', (tester) async {
      await pumpKaeliApp(tester, const _Host(clearOnSelect: false));
      await tester.tap(find.byKey(_field));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Natura'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(_field)).controller!.text, 'Natura');
    });

    for (final (locale, add) in [
      ('es', 'Agregar «Nova»'),
      ('en', 'Add “Nova”'),
      ('fr', 'Ajouter « Nova »'),
      ('pt', 'Adicionar “Nova”'),
    ]) {
      testWidgets('textos en el idioma de la app ($locale)', (tester) async {
        await pumpKaeliApp(tester, const _Host(), locale: Locale(locale));
        await tester.tap(find.byKey(_field));
        await tester.enterText(find.byKey(_field), 'Nova');
        await tester.pumpAndSettle();
        expect(find.text(add), findsOneWidget);
      });
    }

    testWidgets('desplazar la pantalla no cierra la lista; tocar fuera sí', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.pumpAndSettle();
      expect(find.text('Avon'), findsOneWidget);
      // Arrastrar desde fuera del campo y de la lista.
      final outside = tester.getTopLeft(find.byKey(_filler)) + const Offset(20, 40);
      expect(outside.dy, lessThan(600), reason: 'el punto se ve en la pantalla');
      await tester.dragFrom(outside, const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(find.text('Avon'), findsOneWidget, reason: 'la lista sigue abierta (el teclado se puede cerrar)');
      await tester.tapAt(tester.getTopLeft(find.byKey(_filler)) + const Offset(20, 40));
      await tester.pumpAndSettle();
      expect(find.text('Avon'), findsNothing);
    });

    testWidgets('una agregada como nueva tampoco se repite', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'Mi Marca');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'mi marca');
      await tester.pumpAndSettle();
      expect(find.byKey(KaeliSearchField.addNewKey), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('agregada: Mi Marca'), findsOneWidget);
      expect(find.text('«Mi Marca» ya está agregada'), findsOneWidget, reason: 'aviso por defecto');
    });

    testWidgets('al escribir una ya agregada, la lista lo dice (no «No hay coincidencias»)', (tester) async {
      await pumpKaeliApp(tester, const _Host());
      await tester.tap(find.byKey(_field));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avon'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'Avon');
      await tester.pumpAndSettle();
      expect(find.byKey(KaeliSearchField.noResultsKey), findsNothing);
      expect(find.byKey(KaeliSearchField.takenKey), findsOneWidget);
      expect(find.text('«Avon» ya está agregada'), findsOneWidget);
    });
  });
}
