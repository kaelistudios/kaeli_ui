// Medición de uso para las apps de Kaeli (kaeli-tools/docs/ANALITICA.md).
//
// kaeli_ui NO depende de PostHog: la app le pasa un [KaeliAnalyticsSink] (el de PostHog está en
// kaeli-tools/templates/analytics/app/posthog_sink.dart). Así las apps que no miden no cargan el SDK.
//
// Reglas que hace cumplir:
// - Solo eventos de la lista que aprobó Susana (apps/<app>/analytics.yaml). Uno que no está: error en las pruebas
//   (assert) y se ignora en la app publicada.
// - Sin datos personales: propiedades solo con valores fijos (true/false, números o palabras cortas en minúsculas,
//   como «pro», «free», «es»). Nada de textos escritos, nombres, correos, teléfonos ni montos.
// - Apagado hasta que el interruptor del servidor ([update] con `remote: true`) Y la persona (opción en Ajustes) lo
//   permitan. Si falla el envío, no pasa nada: la app nunca se rompe por la medición.

import 'package:flutter/foundation.dart';

/// Quien manda los eventos (PostHog u otro). Ver `templates/analytics/app/posthog_sink.dart` en kaeli-tools.
abstract class KaeliAnalyticsSink {
  /// Prende el envío (se llama la primera vez que todo permite medir).
  Future<void> start();

  /// Manda un evento ya revisado.
  Future<void> send(String event, Map<String, Object> properties);

  /// Apaga el envío. Con [clear], borra lo que haya guardado en el teléfono (la persona apagó la medición).
  Future<void> stop({bool clear = false});
}

/// Medición de uso, igual en todas las apps de Kaeli.
///
/// ```dart
/// // main.dart (solo en la app publicada; nunca en pruebas ni en el modo de datos de ejemplo):
/// if (kReleaseMode && !useFakeData) {
///   KaeliAnalytics.configure(sink: PostHogSink(key: Env.posthogKey), events: analyticsEvents);
/// }
/// // Al leer el interruptor del servidor y la preferencia guardada:
/// await KaeliAnalytics.update(remote: config.analyticsEnabled, userAllows: prefs.analyticsAllowed);
/// // En el código:
/// KaeliAnalytics.track('setup_done');
/// KaeliAnalytics.track('paywall_seen', {'plan': 'free'});
/// ```
abstract final class KaeliAnalytics {
  static KaeliAnalyticsSink? _sink;
  static Set<String> _events = const {};
  static bool _remote = false;
  static bool _userAllows = true;
  static bool _started = false;

  static final _name = RegExp(r'^[a-z][a-z0-9_]{2,39}$');
  static final _word = RegExp(r'^[a-z0-9][a-z0-9_.-]{0,39}$');
  static final _personal = RegExp(
    r'(mail|correo|name|nombre|phone|telefono|tel$|user|usuario|uid|address|direccion|text|texto|note|nota|amount|monto|price|precio|token|ip$|lat|lng|lon)',
  );

  /// Prepara la medición. Hasta llamar a [update] con `remote: true`, no se manda nada.
  static void configure({required KaeliAnalyticsSink sink, required Set<String> events}) {
    assert(
      events.every(_name.hasMatch),
      'Nombres de evento: minúsculas, números y _, de 3 a 40 (${events.where((e) => !_name.hasMatch(e))})',
    );
    _sink = sink;
    _events = Set.unmodifiable(events);
  }

  /// true si ahora se mandan eventos.
  static bool get enabled => _sink != null && _remote && _userAllows;

  /// La persona permite medir (opción de Ajustes). Por defecto, sí.
  static bool get userAllows => _userAllows;

  /// Actualiza el interruptor del servidor ([remote]) y/o la opción de la persona ([userAllows]).
  static Future<void> update({bool? remote, bool? userAllows}) async {
    final wasAllowed = _userAllows;
    if (remote != null) _remote = remote;
    if (userAllows != null) _userAllows = userAllows;
    final sink = _sink;
    if (sink == null) return;
    try {
      if (enabled && !_started) {
        await sink.start();
        _started = true;
      } else if (!enabled && _started) {
        await sink.stop(clear: wasAllowed && !_userAllows);
        _started = false;
      } else if (!_userAllows && wasAllowed) {
        await sink.stop(clear: true);
      }
    } catch (_) {
      // La medición nunca rompe la app.
    }
  }

  /// Manda [event] si está permitido. [properties]: solo valores fijos (ver arriba); las demás se quitan.
  static Future<void> track(String event, [Map<String, Object?> properties = const {}]) async {
    if (!_events.contains(event)) {
      assert(
        _sink == null,
        'Evento no aprobado: «$event» (agrégalo a apps/<app>/analytics.yaml y a la lista de la app)',
      );
      return;
    }
    final clean = <String, Object>{};
    for (final e in properties.entries) {
      final ok = isSafeProperty(e.key, e.value);
      assert(ok, 'Propiedad no permitida en «$event»: ${e.key} (solo valores fijos, sin datos personales)');
      if (ok) clean[e.key] = e.value!;
    }
    if (!enabled) return;
    try {
      await _sink!.send(event, clean);
    } catch (_) {
      // Sin conexión o error del servicio: se pierde el evento, la app sigue.
    }
  }

  /// ¿Se puede mandar esta propiedad? Nombre corto que no sugiera datos personales y valor fijo.
  static bool isSafeProperty(String key, Object? value) {
    if (!_name.hasMatch(key) || _personal.hasMatch(key)) return false;
    return switch (value) {
      bool() => true,
      int v => v.abs() < 100000,
      double v => v.isFinite && v.abs() < 100000,
      String v => _word.hasMatch(v),
      _ => false,
    };
  }

  /// Vuelve todo al principio (solo para pruebas).
  @visibleForTesting
  static void resetForTesting() {
    _sink = null;
    _events = const {};
    _remote = false;
    _userAllows = true;
    _started = false;
  }
}
