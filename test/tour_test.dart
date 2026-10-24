import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

const _pages = [
  KaeliTourPage(icon: Icons.edit_note, title: 'Uno', body: 'Primera página'),
  KaeliTourPage(icon: Icons.ios_share, title: 'Dos', body: 'Segunda página'),
  KaeliTourPage(icon: Icons.star, title: 'Tres', body: 'Tercera página'),
];

/// Pantalla que abre el tutorial una vez al tocar «abrir» y cuenta cuántas veces lo mostró.
class _TourHome extends StatelessWidget {
  const _TourHome({required this.onShown, this.storageKey = KaeliTourMemory.defaultKey});

  final ValueChanged<bool> onShown;
  final String storageKey;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const Key('open'),
        onPressed: () async => onShown(await showKaeliTourOnce(context, pages: _pages, key: storageKey)),
        child: const Text('Inicio'),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openTour(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('«Siguiente» avanza y «Empezar» en la última página cierra el tutorial', (tester) async {
    final shown = <bool>[];
    await pumpKaeliApp(tester, _TourHome(onShown: shown.add));
    await openTour(tester);
    expect(find.text('Uno'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    await tester.tap(find.byKey(KaeliTour.nextKey));
    await tester.pumpAndSettle();
    expect(find.text('Dos'), findsOneWidget);
    await tester.tap(find.byKey(KaeliTour.nextKey));
    await tester.pumpAndSettle();
    expect(find.text('Tres'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
    // En la última página «Saltar» se oculta: el botón principal ya termina.
    expect(find.text('Saltar').hitTestable(), findsNothing);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(find.byType(KaeliTour), findsNothing);
    expect(shown, [true]);
  });

  testWidgets('«Saltar» cierra el tutorial desde la primera página', (tester) async {
    await pumpKaeliApp(tester, _TourHome(onShown: (_) {}));
    await openTour(tester);
    await tester.tap(find.byKey(KaeliTour.skipKey));
    await tester.pumpAndSettle();
    expect(find.byType(KaeliTour), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('deslizar también cambia de página', (tester) async {
    await pumpKaeliApp(tester, _TourHome(onShown: (_) {}));
    await openTour(tester);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Dos'), findsOneWidget);
  });

  testWidgets('solo sale una vez por teléfono (y queda visto aunque se cierre a la mitad)', (tester) async {
    final shown = <bool>[];
    await pumpKaeliApp(tester, _TourHome(onShown: shown.add));
    await openTour(tester);
    await tester.tap(find.byKey(KaeliTour.skipKey));
    await tester.pumpAndSettle();
    await openTour(tester);
    expect(find.byType(KaeliTour), findsNothing);
    expect(shown, [true, false]);
    expect(await KaeliTourMemory.seen(), isTrue);
  });

  testWidgets('con la clave vieja de una app (ej. «settings.onboardingSeen») no vuelve a salir', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.onboardingSeen': true});
    final shown = <bool>[];
    await pumpKaeliApp(tester, _TourHome(onShown: shown.add, storageKey: 'settings.onboardingSeen'));
    await openTour(tester);
    expect(find.byType(KaeliTour), findsNothing);
    expect(shown, [false]);
  });

  testWidgets('showKaeliTour lo abre siempre (Ajustes → «Ver el tutorial»)', (tester) async {
    await KaeliTourMemory.markSeen();
    await pumpKaeliApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showKaeliTour(context, pages: _pages),
            child: const Text('Ver'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Uno'), findsOneWidget);
  });

  for (final (locale, skip, next, start) in [
    ('es', 'Saltar', 'Siguiente', 'Empezar'),
    ('en', 'Skip', 'Next', 'Get started'),
    ('fr', 'Passer', 'Suivant', 'Commencer'),
    ('pt', 'Pular', 'Próximo', 'Começar'),
  ]) {
    testWidgets('botones en $locale', (tester) async {
      await pumpKaeliApp(
        tester,
        KaeliTour(pages: _pages.sublist(0, 2), onFinished: () {}),
        locale: Locale(locale),
      );
      expect(find.text(skip), findsOneWidget);
      expect(find.text(next), findsOneWidget);
      await tester.tap(find.byKey(KaeliTour.nextKey));
      await tester.pumpAndSettle();
      expect(find.text(start), findsOneWidget);
    });
  }

  testWidgets('textos propios y diseño de página propio', (tester) async {
    await pumpKaeliApp(
      tester,
      KaeliTour(
        pages: _pages,
        onFinished: () {},
        strings: const KaeliTourStrings(skip: 'Omitir'),
        pageBuilder: (context, page) => Text('Propia: ${page.title}'),
      ),
    );
    expect(find.text('Omitir'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget, reason: 'lo que no se pasa sale de los textos incluidos');
    expect(find.text('Propia: Uno'), findsOneWidget);
  });

  testWidgets('el lector de pantalla oye «Página 1 de 3»', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKaeliApp(tester, KaeliTour(pages: _pages, onFinished: () {}));
    expect(find.bySemanticsLabel(RegExp('Página 1 de 3')), findsOneWidget);
    handle.dispose();
  });
}
