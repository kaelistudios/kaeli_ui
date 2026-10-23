import 'dart:async';

import 'package:flutter/widgets.dart';

import 'keyboard.dart';

/// Cierra el teclado en cada cambio de pantalla del navegador al que se agrega: al abrir o cerrar una pantalla,
/// diálogo u hoja inferior, al reemplazarla o quitarla, y apenas empieza el gesto de volver de iPhone (deslizar desde
/// el borde).
///
/// Se agrega una instancia **por navegador** (go_router no deja compartir la misma entre la raíz y las pestañas):
///
/// ```dart
/// // MaterialApp / Navigator
/// MaterialApp(navigatorObservers: [KaeliKeyboardObserver()], ...)
/// Navigator(observers: [KaeliKeyboardObserver()], ...)
///
/// // go_router
/// GoRouter(
///   observers: [KaeliKeyboardObserver()],
///   routes: [
///     StatefulShellRoute.indexedStack(
///       branches: [
///         StatefulShellBranch(observers: [KaeliKeyboardObserver()], routes: [...]),
///         StatefulShellBranch(observers: [KaeliKeyboardObserver()], routes: [...]),
///       ],
///       ...
///     ),
///   ],
/// )
/// ```
///
/// El navegador avisa mientras cambia sus pantallas (a veces en medio de la construcción del árbol): el teclado se
/// cierra justo después, en una microtarea, cuando el árbol ya está estable (y antes de que se dibuje el cuadro).
class KaeliKeyboardObserver extends NavigatorObserver {
  void _dismiss({bool force = false}) => scheduleMicrotask(() => dismissKeyboard(force: force));

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _dismiss();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _dismiss(force: true);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _dismiss(force: true);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _dismiss(force: true);

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) => _dismiss();
}
