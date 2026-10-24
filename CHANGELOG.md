# Cambios

## 0.6.0 (24 oct 2026)

- `KaeliForm` y `kaeliRecheckErrors` (Sesly #63): el error rojo se quita en cuanto el campo es válido, mientras se
  escribe; los campos que estaban bien no se revisan antes de guardar.
- `showKaeliNotice` / `showKaeliNoticeOn` / `KaeliNoticeAction` (Sesly #70): aviso compacto de una línea con ícono y
  una acción con ícono a la derecha, encima del botón flotante, que se cierra deslizando.
- `showKaeliTimePicker` / `KaeliTimePicker` (Sesly #61): elegir la hora con ruedas (hora, minutos y a. m./p. m. según
  el idioma), en una hoja inferior con «Listo».

## 0.5.0 (24 oct 2026)

- Los dos estilos aprobados para elegir (pedido en Sesly #51):
  - Tarjetas con ícono, como «Especialidades»: `KaeliChoiceLayout.cards`, `KaeliMultiChoice` (varias a la vez) y
    `KaeliChoiceCard` (una tarjeta suelta, p. ej. «＋ Agregar otra»).
  - Lista agrupada con círculo, como «Política de cancelación» (`list`, la de siempre).
- `KaeliChoiceOther`: «Otra/Otro» al final con su campo dentro del grupo, para valores libres.
- `KaeliChoice.value` acepta null (nada elegido); `KaeliOption.detail` para una segunda línea con formato propio.
- Sin cambios que rompan: las apps en 0.4.x siguen igual.

## 0.4.1 (23 oct 2026)

- `KaeliChoice(layout:)`: `KaeliChoiceLayout.segmented` o `.list` fijan la forma (p. ej. un selector de vista en una
  barra que no puede crecer hacia abajo); por defecto, la regla (`auto`).

## 0.4.0 (23 oct 2026)

- `KaeliChoice` / `KaeliOption` (pedido en Sesly #35): una sola forma de elegir una opción. 2–3 opciones cortas →
  control segmentado de ancho completo; 4 o más, textos largos, segunda línea o letra muy grande → lista vertical con
  ícono y círculo.
- `showKaeliDatePicker` / `KaeliDatePickerDialog` (Sesly #22): calendario con las ruedas de mes y año, `openAt` para
  abrir en otra fecha sin marcar, límites `first`/`last`, «Cancelar» y «Aceptar» con el mismo formato.
- Pruebas de los dos.

## 0.3.0 (23 oct 2026)

- **Errores de formulario (pedido en Sesly #37):** `kaeliValidateForm(formKey)` valida y, si algo falla, desplaza al
  primer campo con error, lo enfoca y el lector de pantalla lee el error; `kaeliRevealFirstError(context)` hace lo
  mismo con errores marcados a mano.
- `KaeliFormList`: cuerpo de formulario que construye todos los campos (con `ListView`, `Form.validate()` no revisaba
  los de abajo).
- `KaeliRequiredLabel`: «Nombre *» con el asterisco en el color de error del tema; el lector dice «Nombre,
  obligatorio». Texto nuevo `required` en `KaeliUiStrings` (4 idiomas).
- Pruebas de todo lo anterior.

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
