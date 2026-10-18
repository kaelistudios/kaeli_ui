// Teclado en toda la app. Nació de una prueba en iPhone (18 oct 2026): costaba mucho cerrar el teclado
// y, al volver con el teclado abierto, quedaba pegado en la pantalla anterior.
//
// [KaeliKeyboard] (en `MaterialApp.builder`) arma todo una sola vez, para que las pantallas nuevas lo tengan sin hacer
// nada:
// - tocar fuera de un campo lo cierra;
// - deslizar cualquier lista lo cierra;
// - en iPhone/iPad muestra la barra «Listo» sobre el teclado en campos de varias líneas, numéricos y de teléfono (que
//   no tienen tecla para cerrarlo).

import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show kMinInteractiveDimensionCupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'strings.dart';

/// Campo de texto que tiene el foco ahora, o null.
EditableText? focusedEditableText() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null || !context.mounted) return null;
  final widget = context.widget;
  if (widget is EditableText) return widget;
  return context.findAncestorWidgetOfExactType<EditableText>();
}

/// Cierra el teclado: quita el foco del campo que lo tenga y le pide al sistema que lo esconda.
///
/// Con [force], se lo pide al sistema aunque ningún campo tenga el foco (así nunca queda un teclado abierto sin campo
/// que lo cierre, p. ej. después de cambiar de pantalla).
void dismissKeyboard({bool force = false}) {
  final hadField = focusedEditableText() != null;
  if (hadField) FocusManager.instance.primaryFocus?.unfocus();
  if (hadField || force) SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}

/// ¿El campo necesita la barra «Listo»? Los de varias líneas (la tecla ↵ escribe un salto de línea) y los numéricos o
/// de teléfono (su teclado en iPhone no tiene tecla para cerrarse).
bool needsKeyboardDoneBar(EditableText field) {
  final type = field.keyboardType.index;
  return field.maxLines != 1 ||
      type == TextInputType.multiline.index ||
      type == TextInputType.number.index ||
      type == TextInputType.phone.index;
}

/// Comportamiento del teclado para toda la app. Va en `MaterialApp.builder`, encima del navegador:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => KaeliKeyboard(child: child!),
///   navigatorObservers: [KaeliKeyboardObserver()],
///   // ...
/// )
/// ```
///
/// - Tocar fuera de un campo le quita el foco (Flutter solo lo hace con mouse). Tocar otro campo, el menú de
///   copiar/pegar, las manijas de selección o la barra «Listo» no cuenta como «fuera»; tocar un botón lo cierra y el
///   botón funciona igual.
/// - Arrastrar cualquier lista (`ListView`, `SingleChildScrollView`, `CustomScrollView`…) cierra el teclado, salvo
///   las que digan otra cosa en su `keyboardDismissBehavior`.
/// - En iPhone/iPad, barra «Listo» sobre el teclado para campos de varias líneas, numéricos y de teléfono. Su alto se
///   suma al del teclado en `MediaQuery.viewInsets`, así lo que sube con el teclado (p. ej. [KaeliFormBottomBar])
///   queda también por encima de la barra.
///
/// Los colores salen del tema de la app (`ColorScheme` y `TextTheme`).
class KaeliKeyboard extends StatelessWidget {
  const KaeliKeyboard({
    super.key,
    required this.child,
    this.strings,
    this.dismissOnTapOutside = true,
    this.dismissOnDrag = true,
    this.doneBar = true,
  });

  final Widget child;

  /// Textos propios (solo los que quieras cambiar). Ver [KaeliUiStrings].
  final KaeliUiStrings? strings;

  /// Tocar fuera de un campo cierra el teclado.
  final bool dismissOnTapOutside;

  /// Arrastrar una lista cierra el teclado.
  final bool dismissOnDrag;

  /// Barra «Listo» sobre el teclado de iPhone/iPad.
  final bool doneBar;

  /// Clave de la barra «Listo» (para pruebas).
  static const barKey = Key('kaeli_ui.keyboard.doneBar');

  /// Clave del botón «Listo» (para pruebas).
  static const doneKey = Key('kaeli_ui.keyboard.done');

  /// Cierra el teclado ahora (aunque ningún campo tenga el foco). Igual que `dismissKeyboard(force: true)`.
  static void dismiss([BuildContext? context]) => dismissKeyboard(force: true);

  @override
  Widget build(BuildContext context) {
    Widget result = doneBar ? _KaeliDoneBar(child: child) : child;
    if (dismissOnDrag) {
      result = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        ),
        child: result,
      );
    }
    if (dismissOnTapOutside) {
      result = Actions(
        actions: <Type, Action<Intent>>{
          EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
        },
        child: result,
      );
    }
    return KaeliUiStringsScope(strings: strings, child: result);
  }
}

/// Barra «Listo» sobre el teclado (solo iPhone/iPad) cuando el campo con foco la necesita ([needsKeyboardDoneBar]).
class _KaeliDoneBar extends StatefulWidget {
  const _KaeliDoneBar({required this.child});

  final Widget child;

  @override
  State<_KaeliDoneBar> createState() => _KaeliDoneBarState();
}

class _KaeliDoneBarState extends State<_KaeliDoneBar> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_update);
    _visible = _wanted();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_update);
    super.dispose();
  }

  bool _wanted() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    final field = focusedEditableText();
    return field != null && !field.readOnly && needsKeyboardDoneBar(field);
  }

  void _update() {
    final wanted = _wanted();
    if (wanted != _visible && mounted) setState(() => _visible = wanted);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const gap = 8.0;
    // Alto de un botón de iOS, o más si el texto del teléfono está muy grande.
    final height = math.max(
      kMinInteractiveDimensionCupertino,
      media.textScaler.scale(theme.textTheme.labelLarge?.fontSize ?? 14) + 2 * gap,
    );
    final keyboard = media.viewInsets.bottom;
    // La estructura no cambia al mostrar u ocultar la barra: el navegador nunca se vuelve a crear.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        MediaQuery(
          data: _visible ? media.copyWith(viewInsets: media.viewInsets.copyWith(bottom: keyboard + height)) : media,
          child: widget.child,
        ),
        if (_visible)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: keyboard,
            height: height,
            // Dentro de la región de los campos: tocarla no cuenta como «tocar fuera».
            child: TextFieldTapRegion(
              child: Material(
                key: KaeliKeyboard.barKey,
                color: colors.surfaceContainerHigh,
                shape: Border(top: BorderSide(color: colors.outlineVariant)),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: gap),
                    child: TextButton(
                      key: KaeliKeyboard.doneKey,
                      onPressed: () => dismissKeyboard(),
                      child: Text(KaeliUiTexts.of(context).done),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
