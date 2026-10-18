import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

/// App mínima con kaeli_ui integrado como lo haría una app de Kaeli (README, pasos 1 y 2).
Future<void> pumpKaeliApp(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale('es'),
  KaeliUiStrings? strings,
  bool dismissOnTapOutside = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('es'), Locale('en'), Locale('fr'), Locale('pt')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) =>
          KaeliKeyboard(strings: strings, dismissOnTapOutside: dismissOnTapOutside, child: child!),
      navigatorObservers: [KaeliKeyboardObserver()],
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

/// ¿Algún campo de texto tiene el foco?
bool fieldFocused() => focusedEditableText() != null;

/// Formulario de prueba con campos de cada tipo y un botón.
class TestForm extends StatelessWidget {
  const TestForm({super.key, this.onButton});

  final VoidCallback? onButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Formulario')),
    body: ListView(
      key: const Key('list'),
      children: [
        const TextField(key: Key('single')),
        const TextField(key: Key('other')),
        const TextField(key: Key('multi'), maxLines: null),
        const TextField(key: Key('number'), keyboardType: TextInputType.number),
        const TextField(key: Key('phone'), keyboardType: TextInputType.phone),
        TextButton(key: const Key('button'), onPressed: onButton, child: const Text('Botón')),
        const SizedBox(height: 2000, child: Text('Relleno')),
      ],
    ),
  );
}

/// Pantalla con un botón que abre [page] encima.
class Opener extends StatelessWidget {
  const Opener({super.key, required this.page});

  final WidgetBuilder page;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const Key('open'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: page)),
        child: const Text('Abrir'),
      ),
    ),
  );
}

/// Corre [body] como si fuera [platform] y deja todo como estaba.
Future<void> onPlatform(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}
