import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

const _brands = ['Avon', 'Farmasi', 'Ésika', 'Unique / Yanbal', 'Natura', 'Zermat', 'Cyzone', 'Mary Kay', 'Oriflame', 'Jafra'];
final _options = [for (final b in _brands) KaeliSearchOption(b, b)];

const _field = Key('brand');

class _Host extends StatefulWidget {
  const _Host({this.allowNew = true, this.clearOnSelect = true, this.onTaken});

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
          options: _options,
          maxResults: 5,
          clearOnSelect: widget.clearOnSelect,
          isTaken: (b) => added.contains(b),
          onTaken: widget.onTaken,
          onSelected: (o) => setState(() => added.add(o.value)),
          onAddNew: widget.allowNew ? (text) => setState(() => added.add(text)) : null,
        ),
        for (final a in added) Text('agregada: $a'),
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
      final banks = [const KaeliSearchOption('bdb', 'Banco de Bogotá', keywords: ['BdB'])];
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
      await tester.tap(find.text('Farmasi'));
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

    testWidgets('textos en el idioma de la app', (tester) async {
      await pumpKaeliApp(tester, const _Host(), locale: const Locale('pt'));
      await tester.tap(find.byKey(_field));
      await tester.enterText(find.byKey(_field), 'Nova');
      await tester.pumpAndSettle();
      expect(find.text('Adicionar “Nova”'), findsOneWidget);
    });
  });
}
