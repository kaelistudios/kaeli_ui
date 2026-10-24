import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() {
  testWidgets('aviso de una línea con acción a la derecha; la acción lo cierra', (tester) async {
    var notified = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.mic)),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showKaeliNotice(
                context,
                'Cita aceptada',
                icon: Icons.check,
                action: KaeliNoticeAction(label: 'Avisar', icon: Icons.chat_outlined, onPressed: () => notified++),
              ),
              child: const Text('ir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    expect(find.text('Cita aceptada'), findsOneWidget);
    final bar = tester.getRect(find.byType(SnackBar));
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(bar.bottom, lessThanOrEqualTo(fab.top), reason: 'flota encima del botón flotante');
    expect(
      tester.getRect(find.text('Avisar')).center.dy,
      closeTo(tester.getRect(find.text('Cita aceptada')).center.dy, 4),
      reason: 'en la misma línea',
    );
    await tester.tap(find.text('Avisar'));
    await tester.pumpAndSettle();
    expect(notified, 1);
    expect(find.text('Cita aceptada'), findsNothing);
  });
}
