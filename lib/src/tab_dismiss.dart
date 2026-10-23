import 'package:flutter/widgets.dart';

import 'keyboard.dart';

/// Cambiar de pestaña en la barra inferior debe cerrar el teclado: la pestaña que se deja sigue montada (escondida) y
/// su campo conservaría el foco con el teclado abierto.
///
/// Con `NavigationBar` / `BottomNavigationBar` y cualquier forma de cambiar de pestaña:
///
/// ```dart
/// NavigationBar(
///   onDestinationSelected: KaeliTabDismiss.wrap((i) => setState(() => _index = i)),
///   ...
/// )
/// ```
///
/// Con `StatefulNavigationShell` de go_router (sin que kaeli_ui dependa de go_router):
///
/// ```dart
/// onDestinationSelected: (i) => KaeliTabDismiss.goBranch(i, shell.goBranch, currentIndex: shell.currentIndex),
/// ```
abstract final class KaeliTabDismiss {
  /// Devuelve [onSelected] precedido de cerrar el teclado.
  static ValueChanged<int> wrap(ValueChanged<int> onSelected) => (index) {
    dismissKeyboard(force: true);
    onSelected(index);
  };

  /// Cierra el teclado y llama a `goBranch` de `StatefulNavigationShell`. Tocar la pestaña en la que ya se está
  /// ([currentIndex]) vuelve a su primera pantalla (`initialLocation: true`), como hacen las apps del sistema.
  static void goBranch(int index, void Function(int index, {bool initialLocation}) goBranch, {int? currentIndex}) {
    dismissKeyboard(force: true);
    goBranch(index, initialLocation: index == currentIndex);
  }
}
