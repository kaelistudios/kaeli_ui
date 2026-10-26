// KaeliBadge (0.10.0): el número del ícono sigue a los avisos sin leer; al abrir la app y al volver se limpian las
// notificaciones ya vistas; 0 = sin número; sin sesión, 0.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

class _Fake extends KaeliBadgePlatform {
  final calls = <String>[];

  @override
  Future<void> set(int count) async => calls.add('set $count');

  @override
  Future<void> clearDelivered() async => calls.add('clear');
}

Widget _app(int unread, {bool enabled = true}) => Directionality(
  textDirection: TextDirection.ltr,
  child: KaeliBadgeSync(unread: unread, enabled: enabled, child: const SizedBox()),
);

void main() {
  late _Fake fake;
  setUp(() => KaeliBadge.platform = fake = _Fake());

  testWidgets('al abrir: limpia y pone el número; al cambiar el número, lo pone', (tester) async {
    await tester.pumpWidget(_app(2));
    expect(fake.calls, ['clear', 'set 2']);
    await tester.pumpWidget(_app(0));
    expect(fake.calls.last, 'set 0');
    await tester.pumpWidget(_app(0));
    expect(fake.calls, ['clear', 'set 2', 'set 0'], reason: 'sin cambios no vuelve a llamar');
  });

  testWidgets('al volver a la app: limpia y vuelve a poner el número', (tester) async {
    await tester.pumpWidget(_app(3));
    fake.calls.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(fake.calls, ['clear', 'set 3']);
  });

  testWidgets('sin sesión (enabled: false): 0 y no limpia', (tester) async {
    await tester.pumpWidget(_app(5, enabled: false));
    expect(fake.calls, ['set 0']);
  });

  test('nunca negativo; el push lleva el conteo real o nada', () async {
    await KaeliBadge.set(-1);
    expect(fake.calls, ['set 0']);
    expect(KaeliBadge.pushBadgeFor(4), 4);
    expect(KaeliBadge.pushBadgeFor(-2), 0);
    expect(KaeliBadge.pushBadgeFor(null), isNull);
  });
}
