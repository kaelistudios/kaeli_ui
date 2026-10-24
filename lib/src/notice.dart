import 'package:flutter/material.dart';

/// Aviso compacto de una línea (Sesly #70), igual en toda la app: ícono y mensaje a la izquierda y, si hay, una
/// acción con ícono a la derecha («✓ Cita aceptada · 💬 Avisar por WhatsApp»). Flota encima del botón flotante, usa
/// los colores del `SnackBarTheme` de la app, dura [duration] (8 s con acción, 4 s sin) y se cierra deslizando.
///
/// ```dart
/// showKaeliNotice(context, l10n.accepted, icon: Icons.check,
///     action: KaeliNoticeAction(label: l10n.notify, icon: Icons.chat_outlined, onPressed: notify));
/// ```
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showKaeliNotice(
  BuildContext context,
  String message, {
  IconData? icon,
  KaeliNoticeAction? action,
  Duration? duration,
}) => showKaeliNoticeOn(ScaffoldMessenger.of(context), message, icon: icon, action: action, duration: duration);

/// Igual que [showKaeliNotice], con el `ScaffoldMessenger` guardado antes (cuando la pantalla que lo pidió ya se
/// cerró, p. ej. después de esperar al servidor).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showKaeliNoticeOn(
  ScaffoldMessengerState messenger,
  String message, {
  IconData? icon,
  KaeliNoticeAction? action,
  Duration? duration,
}) {
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      duration: duration ?? Duration(seconds: action == null ? 4 : 8),
      padding: const EdgeInsetsDirectional.only(start: 16, end: 4, top: 4, bottom: 4),
      content: KaeliNoticeContent(message: message, icon: icon, action: action, messenger: messenger),
    ),
  );
}

/// La acción del aviso (un botón con ícono a la derecha).
@immutable
class KaeliNoticeAction {
  const KaeliNoticeAction({required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
}

/// Contenido del aviso: una fila. El texto se corta en dos líneas como mucho; la acción no se parte.
class KaeliNoticeContent extends StatelessWidget {
  const KaeliNoticeContent({super.key, required this.message, this.icon, this.action, this.messenger});

  final String message;
  final IconData? icon;
  final KaeliNoticeAction? action;
  final ScaffoldMessengerState? messenger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snack = theme.snackBarTheme;
    final fg = snack.contentTextStyle?.color ?? theme.colorScheme.onInverseSurface;
    final actionColor = snack.actionTextColor ?? theme.colorScheme.inversePrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 12)],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: snack.contentTextStyle),
            ),
          ),
          if (action case final a?)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: actionColor, minimumSize: const Size(48, 48)),
              icon: a.icon == null ? null : Icon(a.icon, size: 18),
              label: Text(a.label),
              onPressed: () {
                messenger?.hideCurrentSnackBar();
                a.onPressed();
              },
            ),
        ],
      ),
    );
  }
}
