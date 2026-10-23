import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

/// Navegador con páginas (como go_router): inicio y una pantalla encima hecha con [kaeliPage].
class _App extends StatefulWidget {
  const _App({required this.second});
  final Widget second;
  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  bool open = true;
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Navigator(
      pages: [
        kaeliPage<void>(
          key: const ValueKey('home'),
          child: const Scaffold(body: Text('inicio')),
        ),
        if (open)
          kaeliPage<void>(key: const ValueKey('second'), child: widget.second),
      ],
      onDidRemovePage: (page) => setState(() => open = false),
    ),
  );
}

Future<void> swipeBack(WidgetTester tester) async {
  await tester.timedDragFrom(
    const Offset(4, 300),
    const Offset(700, 0),
    const Duration(milliseconds: 300),
  );
  await tester.pumpAndSettle();
}

void main() {
  final iPhone = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets('kaeliPage: en iPhone se vuelve deslizando desde el borde', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _App(second: Scaffold(body: Text('detalle'))),
    );
    expect(find.text('detalle'), findsOneWidget);
    await swipeBack(tester);
    expect(find.text('detalle'), findsNothing);
    expect(find.text('inicio'), findsOneWidget);
  }, variant: iPhone);

  testWidgets('kaeliPage: con cambios sin guardar el gesto no sale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _App(
        second: KaeliUnsavedChangesGuard(
          dirty: true,
          child: Scaffold(body: Text('formulario')),
        ),
      ),
    );
    await swipeBack(tester);
    expect(find.text('formulario'), findsOneWidget);
  }, variant: iPhone);
}
