// Pruebas de KaeliAnalytics (medición de uso, kaeli-tools/docs/ANALITICA.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

class _FakeSink implements KaeliAnalyticsSink {
  final sent = <(String, Map<String, Object>)>[];
  var starts = 0;
  var stops = 0;
  var clears = 0;
  var fail = false;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> send(String event, Map<String, Object> properties) async {
    if (fail) throw Exception('sin conexión');
    sent.add((event, properties));
  }

  @override
  Future<void> stop({bool clear = false}) async {
    stops++;
    if (clear) clears++;
  }
}

void main() {
  late _FakeSink sink;
  setUp(() {
    KaeliAnalytics.resetForTesting();
    sink = _FakeSink();
    KaeliAnalytics.configure(sink: sink, events: {'first_open', 'setup_done', 'paywall_seen'});
  });

  test('apagada hasta que el servidor la encienda', () async {
    await KaeliAnalytics.track('setup_done');
    expect(sink.sent, isEmpty);
    expect(sink.starts, 0);
    await KaeliAnalytics.update(remote: true);
    await KaeliAnalytics.track('setup_done');
    expect(sink.starts, 1);
    expect(sink.sent.single.$1, 'setup_done');
  });

  test('la persona la apaga en Ajustes: no manda nada y borra lo guardado', () async {
    await KaeliAnalytics.update(remote: true);
    await KaeliAnalytics.update(userAllows: false);
    await KaeliAnalytics.track('setup_done');
    expect(sink.sent, isEmpty);
    expect(sink.clears, 1);
    await KaeliAnalytics.update(userAllows: true);
    await KaeliAnalytics.track('setup_done');
    expect(sink.sent, hasLength(1));
  });

  test('un evento que no está aprobado es un error en las pruebas', () async {
    await KaeliAnalytics.update(remote: true);
    await expectLater(KaeliAnalytics.track('otra_cosa'), throwsA(isA<AssertionError>()));
  });

  test('sin datos personales: solo valores fijos', () {
    expect(KaeliAnalytics.isSafeProperty('plan', 'pro'), isTrue);
    expect(KaeliAnalytics.isSafeProperty('lang', 'es'), isTrue);
    expect(KaeliAnalytics.isSafeProperty('count', 3), isTrue);
    expect(KaeliAnalytics.isSafeProperty('has_photo', true), isTrue);
    expect(KaeliAnalytics.isSafeProperty('plan', 'Plan Pro'), isFalse, reason: 'texto con espacios y mayúsculas');
    expect(KaeliAnalytics.isSafeProperty('email', 'a@b.com'), isFalse);
    expect(KaeliAnalytics.isSafeProperty('user_id', 'abc'), isFalse);
    expect(KaeliAnalytics.isSafeProperty('amount', 25000), isFalse);
    expect(KaeliAnalytics.isSafeProperty('guest_name', 'ana'), isFalse);
    expect(KaeliAnalytics.isSafeProperty('plan', null), isFalse);
  });

  test('una propiedad con datos personales es un error en las pruebas', () async {
    await KaeliAnalytics.update(remote: true);
    await expectLater(KaeliAnalytics.track('paywall_seen', {'email': 'a@b.com'}), throwsA(isA<AssertionError>()));
  });

  test('si falla el envío, la app sigue', () async {
    await KaeliAnalytics.update(remote: true);
    sink.fail = true;
    await KaeliAnalytics.track('first_open');
    expect(sink.sent, isEmpty);
  });

  test('sin configurar (pruebas de la app, datos de ejemplo): no hace nada ni falla', () async {
    KaeliAnalytics.resetForTesting();
    await KaeliAnalytics.update(remote: true);
    await KaeliAnalytics.track('cualquiera');
    expect(KaeliAnalytics.enabled, isFalse);
  });
}
