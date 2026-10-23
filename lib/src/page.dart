import 'package:flutter/material.dart';

/// Página de Material para routers con páginas (go_router, Router propio): con la animación del sistema y, en iPhone,
/// el gesto de deslizar desde el borde para volver.
///
/// go_router 18.1 con Flutter 3.47 ya no reconoce `MaterialApp` y, en las rutas que solo traen `builder`, arma páginas
/// SIN transición: en iPhone no se puede volver deslizando en ninguna pantalla (pasó en AlojaConmigo, 19 oct 2026).
/// Usa `pageBuilder` con esta función en cada `GoRoute`:
///
/// ```dart
/// GoRoute(
///   path: '/reserva/:id',
///   pageBuilder: (context, state) => kaeliPage(key: state.pageKey, child: BookingScreen(id: state.pathParameters['id']!)),
/// )
/// ```
///
/// Con cambios sin guardar, [KaeliUnsavedChangesGuard] sigue apagando el gesto (y la flecha pregunta «¿Descartar
/// cambios?»).
Page<T> kaeliPage<T>({
  required LocalKey key,
  required Widget child,
  String? name,
  bool fullscreenDialog = false,
}) => MaterialPage<T>(
  key: key,
  name: name,
  restorationId: key is ValueKey<String> ? key.value : null,
  fullscreenDialog: fullscreenDialog,
  child: child,
);
