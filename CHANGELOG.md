# Cambios

## 0.2.0 (23 oct 2026)

- **Regla nueva para todas las apps:** `KaeliFormBottomBar` y `KaeliFormScaffold` ya **no suben con el teclado**. El
  botón se queda en su lugar; el contenido se achica hasta el teclado (y la barra «Listo») y el formulario se desplaza
  solo para que el campo que se escribe no quede tapado. `KaeliFormScaffold` deja `resizeToAvoidBottomInset`
  encendido.
- `showKaeliMonthYearPicker` / `KaeliMonthYearPicker`: hoja con ruedas de mes y año (✕ y ✓), igual en iPhone y
  Android, con los colores del tema y los meses en el idioma de la app. Nueva dependencia: `intl`.
- Textos nuevos `cancel` y `confirm` en `KaeliUiStrings` (4 idiomas).
- Pruebas: el botón no se mueve con el teclado y el campo activo queda visible (también con la barra «Listo»); el
  selector en 4 idiomas, ✕, ✓ y el rango.

## 0.1.1 (19 oct 2026)

- `kaeliPage`: página de Material para `pageBuilder` de go_router. Con go_router 18.1 y Flutter 3.47, las rutas con
  solo `builder` salían SIN transición y en iPhone no se podía volver deslizando desde el borde en ninguna pantalla.
- Prueba: el gesto de volver funciona en una pantalla sin cambios y queda apagado con cambios sin guardar.

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
