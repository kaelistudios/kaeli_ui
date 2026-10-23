import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'strings.dart';

/// Pregunta «¿Descartar cambios?» (Descartar / Seguir editando) si se intenta salir de un formulario con cambios sin
/// guardar: flecha de volver, gesto de deslizar en iPhone o botón atrás de Android. Sin cambios, vuelve como siempre.
///
/// Hay cambios si alguno de estos lo dice:
/// - [dirty] es true;
/// - [isDirty] devuelve true (p. ej. `() => hasUnsavedChanges` de [KaeliDirtyTracker]);
/// - [listenable] es un `ValueListenable<bool>` con valor true.
///
/// El aviso se vuelve a revisar cada vez que la pantalla se reconstruye, cada vez que cambia un campo del `Form` que
/// lo rodea (por eso conviene ponerlo DENTRO del `Form`), cada vez que avisa [listenable] (p. ej. controladores de
/// texto fuera de un `Form`; varios con `Listenable.merge`) y justo al volver (si ya no hay cambios, vuelve sin
/// preguntar).
///
/// Con cambios, el gesto de deslizar para volver de iPhone queda apagado (así lo hace Flutter con `PopScope`): la
/// flecha de volver muestra el aviso.
///
/// ```dart
/// Form(
///   child: KaeliUnsavedChangesGuard(
///     isDirty: () => hasUnsavedChanges,
///     child: Scaffold(...),
///   ),
/// )
/// ```
class KaeliUnsavedChangesGuard extends StatelessWidget {
  const KaeliUnsavedChangesGuard({
    super.key,
    this.dirty = false,
    this.isDirty,
    this.listenable,
    this.strings,
    this.confirmDiscard,
    required this.child,
  });

  final bool dirty;
  final bool Function()? isDirty;

  /// Avisa cuando algo cambió. Si es un `ValueListenable<bool>`, su valor también dice si hay cambios.
  final Listenable? listenable;

  /// Textos propios del aviso (encima de los de [KaeliKeyboard] y del idioma actual).
  final KaeliUiStrings? strings;

  /// Aviso propio (en vez del diálogo incluido). Devuelve true para salir sin guardar.
  final Future<bool> Function(BuildContext context)? confirmDiscard;

  final Widget child;

  /// Claves de los botones del diálogo (para pruebas).
  static const discardKey = Key('kaeli_ui.unsaved.discard');
  static const keepEditingKey = Key('kaeli_ui.unsaved.keepEditing');

  bool _hasChanges() {
    final l = listenable;
    return dirty || (isDirty?.call() ?? false) || (l is ValueListenable<bool> && l.value);
  }

  @override
  Widget build(BuildContext context) {
    // Depender del Form: se reconstruye (y revisa de nuevo) cuando cambia cualquiera de sus campos.
    Form.maybeOf(context);
    final l = listenable;
    if (l == null) return _scope(context);
    return ListenableBuilder(listenable: l, builder: (context, _) => _scope(context));
  }

  Widget _scope(BuildContext context) => PopScope<Object?>(
    canPop: !_hasChanges(),
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final navigator = Navigator.of(context);
      // Primera pantalla del navegador: no hay a dónde volver.
      if (!navigator.canPop()) return;
      // Guardado justo antes de volver (o el aviso todavía no se había actualizado): vuelve sin preguntar.
      if (!_hasChanges()) {
        navigator.pop(result);
        return;
      }
      final leave = await (confirmDiscard?.call(context) ?? showKaeliDiscardDialog(context, strings: strings));
      if (leave && context.mounted) navigator.pop(result);
    },
    child: child,
  );
}

/// Diálogo «¿Descartar cambios?». Devuelve true si se elige «Descartar».
Future<bool> showKaeliDiscardDialog(BuildContext context, {KaeliUiStrings? strings}) async {
  final texts = KaeliUiTexts.of(context, strings);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(texts.discardTitle),
        content: Text(texts.discardMessage),
        actions: [
          TextButton(
            key: KaeliUnsavedChangesGuard.keepEditingKey,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(texts.keepEditing),
          ),
          TextButton(
            key: KaeliUnsavedChangesGuard.discardKey,
            style: TextButton.styleFrom(foregroundColor: colors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(texts.discard),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Después de guardar: vuelve atrás en el siguiente cuadro, cuando el aviso de cambios ya se apagó (si se vuelve en el
/// mismo cuadro, [KaeliUnsavedChangesGuard] todavía cree que hay cambios).
///
/// Antes de llamarla, marca el formulario como guardado (p. ej. `markSaved()` de [KaeliDirtyTracker] dentro de
/// `setState`).
void kaeliPopAfterSave(BuildContext context, [Object? result]) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.of(context).maybePop(result);
  });
}
