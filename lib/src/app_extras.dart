import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compartir la app y calificarla en la tienda (regla de Kaeli: toda app tiene «Compartir» y «Calificar» en Ajustes).
///
/// ```dart
/// const kaeliApp = KaeliAppInfo(appStoreId: '6819557562', downloadUrl: 'https://wibblo.kaeliapps.com/');
///
/// // Botón «Compartir Wibblo» (el texto lo traduce la app e incluye el enlace):
/// onTap: () => kaeliShareApp(context, text: l10n.shareAppText(kaeliApp.downloadUrl)),
///
/// // Botón «Calificar Wibblo»: abre la ficha de la tienda (App Store o Google Play).
/// onTap: () => kaeliOpenStoreToRate(kaeliApp),
///
/// // Después de un logro (3.ª ficha exportada, 1.ª reserva confirmada…): pide UNA vez la ventana nativa.
/// await KaeliReviewPrompt.milestone(after: 3);
/// ```
@immutable
class KaeliAppInfo {
  const KaeliAppInfo({required this.appStoreId, required this.downloadUrl});

  /// Apple ID numérico de la app en el App Store (App Store Connect → Información de la app).
  final String appStoreId;

  /// Enlace para compartir: la página de la app (`https://<app>.kaeliapps.com/`), que manda a cada tienda.
  final String downloadUrl;
}

/// Lo que hace el teléfono. Las pruebas lo cambian con [KaeliPlatformActions.instance] para ver qué se pidió.
abstract class KaeliPlatformActions {
  const KaeliPlatformActions();

  /// Implementación en uso (la real por defecto).
  static KaeliPlatformActions instance = const _DevicePlatformActions();

  /// Hoja nativa de compartir. Devuelve false si no se pudo abrir.
  Future<bool> share(String text, {String? subject, Rect? origin});

  /// Ficha de la app en la tienda del teléfono, en la parte de calificar.
  Future<void> openStoreListing(String appStoreId);

  /// Ventana nativa de calificación (la tienda decide si sale). Devuelve false si no está disponible.
  Future<bool> requestReview();
}

class _DevicePlatformActions extends KaeliPlatformActions {
  const _DevicePlatformActions();

  static bool get _mobile =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> share(String text, {String? subject, Rect? origin}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject, sharePositionOrigin: origin));
      return true;
    } catch (e) {
      debugPrint('kaeli_ui: no se pudo compartir: $e');
      return false;
    }
  }

  @override
  Future<void> openStoreListing(String appStoreId) async {
    if (!_mobile) return;
    try {
      await InAppReview.instance.openStoreListing(appStoreId: appStoreId);
    } catch (e) {
      debugPrint('kaeli_ui: no se pudo abrir la tienda: $e');
    }
  }

  @override
  Future<bool> requestReview() async {
    if (!_mobile) return false;
    try {
      if (!await InAppReview.instance.isAvailable()) return false;
      await InAppReview.instance.requestReview();
      return true;
    } catch (e) {
      debugPrint('kaeli_ui: no se pudo pedir la calificación: $e');
      return false;
    }
  }
}

/// Rectángulo del widget de [context] (el iPad lo necesita para ubicar la hoja de compartir). null si no tiene tamaño.
Rect? kaeliOriginRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Abre la hoja nativa para compartir la app. [text] ya traducido y con el enlace ([KaeliAppInfo.downloadUrl]).
/// Pasa el `context` del botón para que en iPad la hoja salga junto a él. Devuelve false si no se pudo abrir.
Future<bool> kaeliShareApp(BuildContext context, {required String text, String? subject}) =>
    KaeliPlatformActions.instance.share(text, subject: subject, origin: kaeliOriginRect(context));

/// Botón «Calificar»: abre la ficha de la tienda (App Store en iPhone, Google Play en Android).
///
/// Para un botón se usa la ficha y no la ventana nativa: Apple y Google piden no abrir la ventana nativa desde un
/// botón (puede no salir nunca y el botón parecería roto).
Future<void> kaeliOpenStoreToRate(KaeliAppInfo app) => KaeliPlatformActions.instance.openStoreListing(app.appStoreId);

/// La ventana nativa de calificación, pedida una sola vez por teléfono después de un logro de la persona.
///
/// Claves en `SharedPreferences`: `<key>.count` (logros contados) y `<key>.asked` (ya se pidió). Una app que ya
/// guardaba esto con otros nombres los pasa en [countKey] y [askedKey] para no volver a pedirla (Wibblo:
/// `review.exportCount` y `review.asked`; AlojaConmigo: `review.asked`).
abstract final class KaeliReviewPrompt {
  /// Prefijo por defecto de las claves.
  static const defaultKey = 'kaeli.review';

  /// Cuenta un logro y, al llegar a [after], pide la ventana nativa UNA vez (queda marcada aunque la tienda no la
  /// muestre: nunca se insiste). Devuelve true si la pidió en esta llamada.
  static Future<bool> milestone({int after = 1, String key = defaultKey, String? countKey, String? askedKey}) async {
    assert(after >= 1);
    final asked = askedKey ?? '$key.asked';
    final counter = countKey ?? '$key.count';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(asked) ?? false) return false;
    final count = (prefs.getInt(counter) ?? 0) + 1;
    await prefs.setInt(counter, count);
    if (count < after) return false;
    // Se marca antes de pedirla: aunque falle o el sistema no la muestre, no se vuelve a intentar.
    await prefs.setBool(asked, true);
    await KaeliPlatformActions.instance.requestReview();
    return true;
  }

  /// Si ya se pidió en este teléfono.
  static Future<bool> asked({String key = defaultKey, String? askedKey}) async =>
      (await SharedPreferences.getInstance()).getBool(askedKey ?? '$key.asked') ?? false;
}
