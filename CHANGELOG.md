# Cambios

## 0.1.0 (17 oct 2026)

Primera versión, sacada de las correcciones del teclado hechas tras una prueba en iPhone.

- `KaeliKeyboard`: tocar fuera de un campo cierra el teclado; deslizar cualquier lista lo cierra; barra «Listo»
  sobre el teclado de iPhone/iPad para campos de varias líneas, numéricos y de teléfono.
- `KaeliKeyboardObserver`: cierra el teclado al abrir, cerrar, quitar o reemplazar pantallas, diálogos y hojas, y al
  empezar el gesto de volver de iPhone.
- `dismissKeyboard()`, `KaeliKeyboard.dismiss()` y `KaeliTabDismiss` (`wrap` y `goBranch`) para cambiar de pestaña.
- `KaeliFormBottomBar` y `KaeliFormScaffold`: «Guardar» siempre visible encima del teclado.
- `KaeliUnsavedChangesGuard`, `showKaeliDiscardDialog`, `KaeliDirtyTracker`, `kaeliSnapshotEquals` y
  `kaeliPopAfterSave`: aviso «¿Descartar cambios?» al salir con cambios sin guardar.
- Textos en español, inglés, francés y portugués; todos se pueden cambiar con `KaeliUiStrings`.
- App de ejemplo en `example/`.
