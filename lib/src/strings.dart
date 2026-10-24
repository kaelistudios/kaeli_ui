import 'package:flutter/widgets.dart';

/// Textos que muestra kaeli_ui (barra «Listo» y aviso de cambios sin guardar).
///
/// Trae los textos en español, inglés, francés y portugués; se elige el idioma de
/// `Localizations.localeOf(context)` y, si no está, se usa inglés.
///
/// Para cambiar uno o varios textos, pasa un [KaeliUiStrings] solo con lo que quieras cambiar (lo demás sale del
/// idioma actual) a [KaeliKeyboard] o a [KaeliUnsavedChangesGuard]:
///
/// ```dart
/// KaeliKeyboard(strings: const KaeliUiStrings(done: 'Cerrar'), child: child!)
/// ```
///
/// Si el texto debe cambiar según el idioma, arma el objeto en `MaterialApp.builder` con
/// `Localizations.localeOf(context)` o con las traducciones de la app.
@immutable
class KaeliUiStrings {
  const KaeliUiStrings({
    this.done,
    this.discardTitle,
    this.discardMessage,
    this.discard,
    this.keepEditing,
    this.cancel,
    this.confirm,
    this.required,
  });

  /// Botón de la barra sobre el teclado de iPhone («Listo»).
  final String? done;

  /// Título del aviso al salir con cambios («¿Descartar cambios?»).
  final String? discardTitle;

  /// Texto del aviso al salir con cambios.
  final String? discardMessage;

  /// Botón que sale sin guardar («Descartar»).
  final String? discard;

  /// Botón que se queda en el formulario («Seguir editando»).
  final String? keepEditing;

  /// ✕ del selector de mes y año (lo lee el lector de pantalla: «Cancelar»).
  final String? cancel;

  /// ✓ del selector de mes y año («Aceptar»).
  final String? confirm;

  /// Lo que lee el lector de pantalla después de un campo con asterisco («obligatorio»).
  final String? required;

  /// Textos incluidos, por código de idioma.
  static const Map<String, KaeliUiStrings> builtIn = {
    'es': KaeliUiStrings(
      done: 'Listo',
      discardTitle: '¿Descartar cambios?',
      discardMessage: 'Hiciste cambios que todavía no guardaste.',
      discard: 'Descartar',
      keepEditing: 'Seguir editando',
      cancel: 'Cancelar',
      confirm: 'Aceptar',
      required: 'obligatorio',
    ),
    'en': KaeliUiStrings(
      done: 'Done',
      discardTitle: 'Discard changes?',
      discardMessage: "You made changes you haven't saved yet.",
      discard: 'Discard',
      keepEditing: 'Keep editing',
      cancel: 'Cancel',
      confirm: 'OK',
      required: 'required',
    ),
    'fr': KaeliUiStrings(
      done: 'OK',
      discardTitle: 'Abandonner les modifications ?',
      discardMessage: 'Vous avez des modifications qui ne sont pas encore enregistrées.',
      discard: 'Abandonner',
      keepEditing: 'Continuer',
      cancel: 'Annuler',
      confirm: 'Valider',
      required: 'obligatoire',
    ),
    'pt': KaeliUiStrings(
      done: 'OK',
      discardTitle: 'Descartar alterações?',
      discardMessage: 'Você fez alterações que ainda não salvou.',
      discard: 'Descartar',
      keepEditing: 'Continuar editando',
      cancel: 'Cancelar',
      confirm: 'Confirmar',
      required: 'obrigatório',
    ),
  };

  /// Textos completos para [languageCode] (inglés si no está), con lo de [overrides] encima.
  static KaeliUiTexts resolve(String? languageCode, [KaeliUiStrings? overrides]) {
    final base = builtIn[languageCode] ?? builtIn['en']!;
    return KaeliUiTexts(
      done: overrides?.done ?? base.done!,
      discardTitle: overrides?.discardTitle ?? base.discardTitle!,
      discardMessage: overrides?.discardMessage ?? base.discardMessage!,
      discard: overrides?.discard ?? base.discard!,
      keepEditing: overrides?.keepEditing ?? base.keepEditing!,
      cancel: overrides?.cancel ?? base.cancel!,
      confirm: overrides?.confirm ?? base.confirm!,
      required: overrides?.required ?? base.required!,
    );
  }

  /// Lo de [other] encima de esto.
  KaeliUiStrings merge(KaeliUiStrings? other) => other == null
      ? this
      : KaeliUiStrings(
          done: other.done ?? done,
          discardTitle: other.discardTitle ?? discardTitle,
          discardMessage: other.discardMessage ?? discardMessage,
          discard: other.discard ?? discard,
          keepEditing: other.keepEditing ?? keepEditing,
          cancel: other.cancel ?? cancel,
          confirm: other.confirm ?? confirm,
          required: other.required ?? required,
        );
}

/// Textos ya resueltos (ninguno vacío) para el idioma actual.
@immutable
class KaeliUiTexts {
  const KaeliUiTexts({
    required this.done,
    required this.discardTitle,
    required this.discardMessage,
    required this.discard,
    required this.keepEditing,
    required this.cancel,
    required this.confirm,
    required this.required,
  });

  final String done;
  final String discardTitle;
  final String discardMessage;
  final String discard;
  final String keepEditing;
  final String cancel;
  final String confirm;
  final String required;

  /// Textos para [context]: idioma de `Localizations`, cambios de [KaeliKeyboard] y, encima, [overrides].
  static KaeliUiTexts of(BuildContext context, [KaeliUiStrings? overrides]) {
    final scope = context.dependOnInheritedWidgetOfExactType<KaeliUiStringsScope>();
    final merged = (scope?.strings ?? const KaeliUiStrings()).merge(overrides);
    return KaeliUiStrings.resolve(Localizations.maybeLocaleOf(context)?.languageCode, merged);
  }
}

/// Lleva los textos cambiados de [KaeliKeyboard] a todas las pantallas (lo pone [KaeliKeyboard]; no hace falta usarlo
/// a mano).
class KaeliUiStringsScope extends InheritedWidget {
  const KaeliUiStringsScope({super.key, required this.strings, required super.child});

  final KaeliUiStrings? strings;

  @override
  bool updateShouldNotify(KaeliUiStringsScope oldWidget) => strings != oldWidget.strings;
}
