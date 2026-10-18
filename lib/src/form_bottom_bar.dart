import 'package:flutter/material.dart';

/// Barra de la acción principal de un formulario (p. ej. «Guardar») que **siempre se ve**, también con el teclado
/// abierto. Va en `Scaffold.bottomNavigationBar`:
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
/// El `Scaffold` deja la barra inferior detrás del teclado; esta barra se sube sola con el alto del teclado
/// (`MediaQuery.viewInsets`, que incluye la barra «Listo» de [KaeliKeyboard]) y respeta la zona segura (la raya de
/// inicio del iPhone) cuando el teclado está cerrado.
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
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: bar,
    );
  }
}

/// `Scaffold` de formulario: barra superior, contenido y [KaeliFormBottomBar] con [bottomAction].
///
/// Atajo para lo más común; para algo distinto, usa un `Scaffold` con [KaeliFormBottomBar].
class KaeliFormScaffold extends StatelessWidget {
  const KaeliFormScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomAction,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;

  /// Acción principal (p. ej. el botón «Guardar»). Si es null no hay barra inferior.
  final Widget? bottomAction;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    backgroundColor: backgroundColor,
    body: body,
    bottomNavigationBar: bottomAction == null ? null : KaeliFormBottomBar(child: bottomAction!),
  );
}
