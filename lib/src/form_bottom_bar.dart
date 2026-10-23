import 'package:flutter/material.dart';

/// Barra de la acción principal de un formulario (p. ej. «Guardar»), fija abajo. Va en `Scaffold.bottomNavigationBar`:
///
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: const Text('Editar')),
///   body: ListView(children: [...]),
///   bottomNavigationBar: KaeliFormBottomBar(
///     child: FilledButton(onPressed: _save, child: const Text('Guardar')),
///   ),
/// )
/// ```
///
/// Regla de Kaeli (desde 0.2.0): el botón **se queda en su lugar** y no sube con el teclado. Con el teclado abierto,
/// el `Scaffold` achica el contenido hasta el borde del teclado (y de la barra «Listo» de [KaeliKeyboard], que suma su
/// alto a `MediaQuery.viewInsets`) y el formulario se desplaza solo para que el campo que se escribe no quede tapado.
/// Para guardar, se cierra el teclado (tocando fuera, deslizando o con «Listo») y el botón vuelve a verse. Respeta la
/// zona segura de abajo (la raya de inicio del iPhone).
class KaeliFormBottomBar extends StatelessWidget {
  const KaeliFormBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
    this.color,
    this.showDivider = false,
  });

  /// Botón o fila de botones.
  final Widget child;

  /// Margen alrededor de [child].
  final EdgeInsetsGeometry padding;

  /// Fondo de la barra (por defecto, transparente: se ve el del `Scaffold`).
  final Color? color;

  /// Raya fina arriba de la barra (color `ColorScheme.outlineVariant`).
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget bar = SafeArea(
      top: false,
      child: Padding(padding: padding, child: child),
    );
    if (color != null || showDivider) {
      bar = DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: showDivider ? Border(top: BorderSide(color: colors.outlineVariant)) : null,
        ),
        child: bar,
      );
    }
    return bar;
  }
}

/// `Scaffold` de formulario: barra superior, contenido y [KaeliFormBottomBar] con [bottomAction].
///
/// El contenido se achica con el teclado (`resizeToAvoidBottomInset`) para que el campo activo se vea; el botón queda
/// fijo abajo, detrás del teclado.
///
/// Atajo para lo más común; para algo distinto, usa un `Scaffold` con [KaeliFormBottomBar].
class KaeliFormScaffold extends StatelessWidget {
  const KaeliFormScaffold({super.key, this.appBar, required this.body, this.bottomAction, this.backgroundColor});

  final PreferredSizeWidget? appBar;
  final Widget body;

  /// Acción principal (p. ej. el botón «Guardar»). Si es null no hay barra inferior.
  final Widget? bottomAction;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: true,
    body: body,
    bottomNavigationBar: bottomAction == null ? null : KaeliFormBottomBar(child: bottomAction!),
  );
}
