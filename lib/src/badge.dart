// Número del ícono de la app y notificaciones ya vistas (0.10.0; nació en AlojaConmigo 1.0.0 (13), reporte de
// Patricia: el número no bajaba).
//
// Cada app le pasa su número de avisos SIN LEER (lo calcula ella; el paquete no sabe qué es un aviso):
// - iPhone: ese número va en el ícono; 0 lo quita. Al abrir la app y al volver a ella se quitan del centro de
//   notificaciones las que ya llegaron.
// - Android: no hay un número del ícono que la app pueda poner; el lanzador muestra el número o el punto según las
//   notificaciones que siguen en la barra. Al abrir la app, al volver a ella y con 0 sin leer se quitan de la barra.
//
// Lo más simple es envolver la app con [KaeliBadgeSync] (se actualiza al abrir, al volver y cuando cambia el número).
// [KaeliBadge.set] y [KaeliBadge.clearDelivered] quedan para usarlos a mano.
//
// Push: si el servidor pone el número en la notificación (APNs `aps.badge`), tiene que ser el conteo REAL de no
// leídas de esa cuenta ([KaeliBadge.pushBadgeFor] ayuda a no mandar números inventados); si el servidor no lo sabe
// (los avisos se calculan en el teléfono), mejor no mandar número: el ícono queda con el último que puso la app.
// Canal nativo «kaeli_ui/badge» (ios/…/KaeliUiPlugin.swift y android/…/KaeliUiPlugin.java).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Lo que hace el teléfono. Se puede cambiar en las pruebas: `KaeliBadge.platform = MiFalso();`.
abstract class KaeliBadgePlatform {
  const KaeliBadgePlatform();

  /// Pone el número del ícono (0 lo quita).
  Future<void> set(int count);

  /// Quita de la barra (Android) o del centro de notificaciones (iPhone) las que llegaron.
  Future<void> clearDelivered();
}

class _ChannelBadge extends KaeliBadgePlatform {
  const _ChannelBadge();

  static const _channel = MethodChannel('kaeli_ui/badge');

  @override
  Future<void> set(int count) => _call('set', {'count': count < 0 ? 0 : count});

  @override
  Future<void> clearDelivered() => _call('clearDelivered');

  Future<void> _call(String method, [Object? args]) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } catch (_) {
      // Sin canal (pruebas, escritorio, una app sin compilar de nuevo): no pasa nada.
    }
  }
}

/// Número del ícono y notificaciones ya vistas.
abstract final class KaeliBadge {
  /// Implementación en uso (la del teléfono por defecto).
  static KaeliBadgePlatform platform = const _ChannelBadge();

  /// Pone el número del ícono = [unread] avisos sin leer (0 = sin número; en Android, con 0 limpia la barra).
  static Future<void> set(int unread) => platform.set(unread < 0 ? 0 : unread);

  /// Quita las notificaciones que ya llegaron (al abrir la app o volver a ella: ya se vieron).
  static Future<void> clearDelivered() => platform.clearDelivered();

  /// Número para el push (APNs `aps.badge`): el conteo real de no leídas, o null si no se sabe (entonces el push no
  /// lleva número). Nunca negativo.
  static int? pushBadgeFor(int? realUnread) => realUnread == null ? null : (realUnread < 0 ? 0 : realUnread);
}

/// Mantiene el número del ícono en [unread] y limpia las notificaciones ya vistas:
/// - al abrir la app (al montarse): limpia y pone el número;
/// - al volver a ella (`resumed`): limpia y pone el número;
/// - cuando cambia [unread] (p. ej. al leer los avisos): pone el número.
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => KaeliKeyboard(child: KaeliBadgeSync(unread: avisosSinLeer, child: child!)),
/// )
/// ```
/// Con [enabled] en false (p. ej. sin sesión) pone 0 y no limpia nada más.
class KaeliBadgeSync extends StatefulWidget {
  const KaeliBadgeSync({super.key, required this.unread, required this.child, this.enabled = true});

  /// Avisos sin leer de la app (los calcula la app).
  final int unread;
  final bool enabled;
  final Widget child;

  @override
  State<KaeliBadgeSync> createState() => _KaeliBadgeSyncState();
}

class _KaeliBadgeSyncState extends State<KaeliBadgeSync> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sync(clear: true);
  }

  @override
  void didUpdateWidget(KaeliBadgeSync old) {
    super.didUpdateWidget(old);
    if (old.unread != widget.unread || old.enabled != widget.enabled) _sync(clear: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync(clear: true);
  }

  void _sync({required bool clear}) {
    if (clear && widget.enabled) KaeliBadge.clearDelivered();
    KaeliBadge.set(widget.enabled ? widget.unread : 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
