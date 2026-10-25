import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

import 'helpers.dart';

/// Formulario con un teléfono, un botón «Guardar» y lo último que entregó el campo.
class _PhoneForm extends StatefulWidget {
  const _PhoneForm({
    this.initialValue,
    this.defaultCountry,
    this.preferredCountry,
    this.pinned = const [],
    this.isRequired = false,
  });

  final String? initialValue;
  final String? defaultCountry;
  final String? preferredCountry;
  final List<String> pinned;
  final bool isRequired;

  @override
  State<_PhoneForm> createState() => _PhoneFormState();
}

String? lastChanged;
String? lastCountry;
String? lastSaved;
bool? lastValid;

class _PhoneFormState extends State<_PhoneForm> {
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: KaeliForm(
      formKey: _form,
      child: KaeliFormList(
        children: [
          KaeliPhoneField(
            initialValue: widget.initialValue,
            defaultCountry: widget.defaultCountry,
            preferredCountry: widget.preferredCountry,
            onCountryChanged: (iso) => lastCountry = iso,
            pinnedCountries: widget.pinned,
            isRequired: widget.isRequired,
            decoration: InputDecoration(
              label: widget.isRequired ? const KaeliRequiredLabel('Teléfono') : const Text('Teléfono'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => lastChanged = v,
            onSaved: (v) => lastSaved = v,
          ),
          TextButton(
            key: const Key('save'),
            onPressed: () {
              lastValid = kaeliValidateForm(_form);
              if (lastValid!) _form.currentState!.save();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

String selectorLabel(WidgetTester tester) => tester.getSemantics(find.byKey(KaeliPhoneField.countryKey)).label;

Finder dialText(String dial) => find.descendant(of: find.byKey(KaeliPhoneField.countryKey), matching: find.text(dial));

void main() {
  setUp(() {
    lastChanged = lastSaved = null;
    lastValid = null;
  });

  group('lógica', () {
    test('país desde el número (incluye +1 y +7 por código de área)', () {
      expect(kaeliCountryFromPhone('+50660895761')?.iso, 'CR');
      expect(kaeliCountryFromPhone('0052 55 1234 5678')?.iso, 'MX');
      expect(kaeliCountryFromPhone('+18095551234')?.iso, 'DO');
      expect(kaeliCountryFromPhone('+14165551234')?.iso, 'CA');
      expect(kaeliCountryFromPhone('+12125551234')?.iso, 'US');
      expect(kaeliCountryFromPhone('+77011234567')?.iso, 'KZ');
      expect(kaeliCountryFromPhone('+74951234567')?.iso, 'RU');
      expect(kaeliCountryFromPhone('60895761'), isNull);
    });

    test('E.164: largo por país y 0 de larga distancia', () {
      final cr = kaeliPhoneCountryOf('CR')!;
      final fr = kaeliPhoneCountryOf('fr')!;
      expect(kaeliToE164('6089-5761', cr), '+50660895761');
      expect(kaeliToE164('6089 576', cr), isNull);
      expect(kaeliToE164('06 12 34 56 78', fr), '+33612345678');
      expect(kaeliToE164('+52 55 1234 5678', cr), '+525512345678', reason: 'con código, se respeta');
      expect(kaeliToE164('', cr), isNull);
    });

    test('separar un número guardado', () {
      final s = kaeliSplitPhone('+50660895761');
      expect(s.country?.iso, 'CR');
      expect(s.national, '6089 5761');
      expect(kaeliSplitPhone('+525512345678').national, '55 1234 5678');
      expect(kaeliSplitPhone(null).country, isNull);
    });

    test('buscar por nombre (sin acentos, en el idioma y en inglés), por ISO y por código', () {
      expect(kaeliSearchPhoneCountries('mexico', 'es').map((c) => c.iso), contains('MX'));
      expect(kaeliSearchPhoneCountries('Brasil', 'pt').map((c) => c.iso), ['BR']);
      expect(kaeliSearchPhoneCountries('germany', 'es').map((c) => c.iso), ['DE']);
      expect(kaeliSearchPhoneCountries('cr', 'es').map((c) => c.iso), contains('CR'));
      expect(kaeliSearchPhoneCountries('+506', 'es').map((c) => c.iso), ['CR']);
      expect(kaeliSearchPhoneCountries('506', 'es').map((c) => c.iso), ['CR']);
      expect(kaeliSearchPhoneCountries('zzzz', 'es'), isEmpty);
    });

    test('la lista no repite países y tiene nombre en los 4 idiomas', () {
      final isos = kaeliPhoneCountries.map((c) => c.iso).toList();
      expect(isos.toSet().length, isos.length);
      expect(kaeliPhoneCountries.length, greaterThan(200));
      for (final c in kaeliPhoneCountries) {
        expect(c.names.length, 4, reason: c.iso);
        expect(c.min, lessThanOrEqualTo(c.max), reason: c.iso);
      }
      expect(kaeliPhoneCountryOf('CR')!.flag, '🇨🇷');
    });
  });

  group('preselección', () {
    testWidgets('el país del número guardado', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpKaeliApp(tester, const _PhoneForm(initialValue: '+50660895761', defaultCountry: 'US'));
      expect(dialText('+506'), findsOneWidget);
      expect(find.text('6089 5761'), findsOneWidget);
    });

    testWidgets('sin número: la región del teléfono', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpKaeliApp(tester, const _PhoneForm(defaultCountry: 'CR'));
      expect(dialText('+52'), findsOneWidget);
    });

    testWidgets('número nuevo con preferredCountry (el del negocio): ese, antes que la región (0.11.0)', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpKaeliApp(tester, const _PhoneForm(preferredCountry: 'CR', defaultCountry: 'US'));
      expect(dialText('+506'), findsOneWidget);
    });

    testWidgets('con número guardado, el del número aunque haya preferredCountry', (tester) async {
      await pumpKaeliApp(tester, const _PhoneForm(initialValue: '+525512345678', preferredCountry: 'CR'));
      expect(dialText('+52'), findsOneWidget);
    });

    testWidgets('sin región conocida: el país por defecto de la app', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpKaeliApp(tester, const _PhoneForm(defaultCountry: 'CR'));
      expect(dialText('+506'), findsOneWidget);
    });
  });

  group('campo', () {
    setUp(() {});

    Future<void> pumpCR(WidgetTester tester, {Widget? form, Locale locale = const Locale('es')}) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpKaeliApp(tester, form ?? const _PhoneForm(defaultCountry: 'CR'), locale: locale);
    }

    testWidgets('selector y número lado a lado, con la misma altura', (tester) async {
      await pumpCR(tester);
      final selector = tester.getRect(
        find.descendant(of: find.byKey(KaeliPhoneField.countryKey), matching: find.byType(InputDecorator)),
      );
      final number = tester.getRect(
        find.descendant(of: find.byKey(KaeliPhoneField.numberKey), matching: find.byType(InputDecorator)),
      );
      expect(selector.height, number.height);
      expect(selector.top, number.top);
      expect(selector.right, lessThan(number.left));
      expect(find.text('🇨🇷'), findsOneWidget);
    });

    testWidgets('escribir el número entrega E.164', (tester) async {
      await pumpCR(tester);
      await tester.enterText(find.byKey(KaeliPhoneField.numberKey), '6089 576');
      expect(lastChanged, isNull, reason: 'todavía no es válido');
      await tester.enterText(find.byKey(KaeliPhoneField.numberKey), '6089 5761');
      expect(lastChanged, '+50660895761');
      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();
      expect(lastValid, isTrue);
      expect(lastSaved, '+50660895761');
    });

    testWidgets('pegar un número con + cambia el país solo', (tester) async {
      await pumpCR(tester);
      await tester.enterText(find.byKey(KaeliPhoneField.numberKey), '+52 55 1234 5678');
      await tester.pump();
      expect(dialText('+52'), findsOneWidget);
      expect(find.text('55 1234 5678'), findsOneWidget);
      expect(lastChanged, '+525512345678');
      expect(lastCountry, 'MX', reason: 'avisa el cambio de país (0.11.0)');
    });

    testWidgets('validación: largo y obligatorio, con KaeliForm y kaeliValidateForm', (tester) async {
      await pumpCR(tester, form: const _PhoneForm(defaultCountry: 'CR', isRequired: true));
      expect(find.byType(KaeliRequiredLabel), findsOneWidget);
      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();
      expect(lastValid, isFalse);
      expect(find.text('Escribe un número de teléfono'), findsOneWidget);
      expect(focusedEditableText()?.controller.text, '', reason: 'kaeliValidateForm enfoca el número');

      await tester.enterText(find.byKey(KaeliPhoneField.numberKey), '608');
      await tester.pump();
      expect(find.text('Número no válido'), findsOneWidget, reason: 'KaeliForm vuelve a revisar al escribir');
      await tester.enterText(find.byKey(KaeliPhoneField.numberKey), '6089 5761');
      await tester.pump();
      expect(find.text('Número no válido'), findsNothing, reason: 'el error se quita al corregir');
    });

    testWidgets('hoja de países: fijados arriba, buscar por nombre y por código, sin resultados', (tester) async {
      await pumpCR(
        tester,
        form: const _PhoneForm(defaultCountry: 'CR', pinned: ['MX', 'US']),
      );
      await tester.tap(find.byKey(KaeliPhoneField.countryKey));
      await tester.pumpAndSettle();
      expect(find.text('Código de país'), findsOneWidget);
      final mx = tester.getRect(find.byKey(const Key('kaeliPhone.pinned.MX')));
      final us = tester.getRect(find.byKey(const Key('kaeliPhone.pinned.US')));
      expect(mx.top, lessThan(us.top));

      await tester.enterText(find.byKey(KaeliPhoneField.searchKey), 'españa');
      await tester.pump();
      expect(find.byKey(KaeliPhoneField.countryTileKey('ES')), findsOneWidget);

      await tester.enterText(find.byKey(KaeliPhoneField.searchKey), '+57');
      await tester.pump();
      expect(find.byKey(KaeliPhoneField.countryTileKey('CO')), findsOneWidget);

      await tester.enterText(find.byKey(KaeliPhoneField.searchKey), 'xyzw');
      await tester.pump();
      expect(find.text('Ningún país coincide con la búsqueda'), findsOneWidget);

      await tester.enterText(find.byKey(KaeliPhoneField.searchKey), '506');
      await tester.pump();
      await tester.tap(find.byKey(KaeliPhoneField.countryTileKey('CR')));
      await tester.pumpAndSettle();
      expect(dialText('+506'), findsOneWidget);
    });

    testWidgets('cambiar de país recalcula el valor', (tester) async {
      await pumpCR(tester);
      await tester.enterText(find.byKey(KaeliPhoneField.numberKey), '55 1234 5678');
      expect(lastChanged, isNull, reason: '10 cifras no son un número de Costa Rica');
      await tester.tap(find.byKey(KaeliPhoneField.countryKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(KaeliPhoneField.searchKey), '52');
      await tester.pump();
      lastCountry = null;
      await tester.tap(find.byKey(KaeliPhoneField.countryTileKey('MX')));
      await tester.pumpAndSettle();
      expect(lastChanged, '+525512345678');
      expect(lastCountry, 'MX');
    });

    testWidgets('el lector de pantalla anuncia «País: Costa Rica, +506»', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCR(tester);
      expect(selectorLabel(tester), 'País: Costa Rica, +506');
      handle.dispose();
    });

    for (final (locale, country, search, invalid, label, name) in [
      ('es', 'País', 'Buscar país o código', 'Número no válido', 'País: Alemania, +49', 'Alemania'),
      ('en', 'Country', 'Search country or code', 'Invalid number', 'Country: Germany, +49', 'Germany'),
      ('fr', 'Pays', 'Rechercher un pays ou un indicatif', 'Numéro non valide', 'Pays : Allemagne, +49', 'Allemagne'),
      ('pt', 'País', 'Buscar país ou código', 'Número inválido', 'País: Alemanha, +49', 'Alemanha'),
    ]) {
      testWidgets('textos y nombres de países en $locale', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpCR(
          tester,
          form: const _PhoneForm(defaultCountry: 'DE'),
          locale: Locale(locale),
        );
        expect(find.text(country), findsOneWidget);
        expect(selectorLabel(tester), label);
        await tester.enterText(find.byKey(KaeliPhoneField.numberKey), '12');
        await tester.tap(find.byKey(const Key('save')));
        await tester.pumpAndSettle();
        expect(find.text(invalid), findsOneWidget);
        await tester.tap(find.byKey(KaeliPhoneField.countryKey));
        await tester.pumpAndSettle();
        expect(find.text(search), findsOneWidget);
        await tester.enterText(find.byKey(KaeliPhoneField.searchKey), name);
        await tester.pump();
        expect(
          find.descendant(of: find.byKey(KaeliPhoneField.countryTileKey('DE')), matching: find.text(name)),
          findsOneWidget,
        );
        handle.dispose();
      });
    }

    testWidgets('textos propios', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpKaeliApp(
        tester,
        const Scaffold(
          body: KaeliPhoneField(
            defaultCountry: 'CR',
            strings: KaeliPhoneStrings(country: 'Código'),
          ),
        ),
      );
      expect(find.text('Código'), findsOneWidget);
    });
  });
}
