# Cambios

## 0.12.0 (25 oct 2026)

- `KaeliPhoneField`: el número sale con los espacios del país mientras se escribe («8555 3333»,
  `kaeliFormatTyping`); debajo, «Por ejemplo: 8888 7777» con un número del país elegido (`kaeliPhoneExample`,
  `showExample`, y de pista dentro del campo); el aviso del largo dice cuántas cifras lleva el país («Un número de
  Colombia tiene 10 cifras», `KaeliPhoneStrings.invalidLength`) y sale al salir del campo (o enseguida si se pasa de
  cifras), sin esperar a guardar. Textos nuevos en es/en/fr/pt. Sin cambios que rompan (el mensaje de largo reemplaza
  a «Número no válido» en los avisos de largo).

## 0.11.0 (25 oct 2026)

- `KaeliPhoneField`: `preferredCountry` (país para un número nuevo, antes que la región del teléfono: p. ej. el del
  negocio) y `onCountryChanged` (ISO del país al elegirlo o al pegar un número con «+»; sirve para llenar el país de la
  persona). Sin cambios que rompan.
- `KaeliOption.key`: la clave va en la fila, la tarjeta o el segmento de `KaeliChoice` y `KaeliMultiChoice` (para las
  pruebas de cada app).

## 0.10.0 (24 oct 2026)

- `KaeliBadge` y `KaeliBadgeSync`: número del ícono = avisos sin leer que pasa la app (0 = sin número); al abrir la app
  y al volver a ella se quitan las notificaciones ya vistas (iPhone: centro de notificaciones; Android: barra, que es
  de donde el lanzador saca el número o el punto). `KaeliBadge.pushBadgeFor` para que el push lleve el conteo real o
  nada. Sale de AlojaConmigo 1.0.0 (13).
- El paquete pasa a ser **plugin** (canal nativo «kaeli_ui/badge»): Swift (Swift Package Manager y CocoaPods) y Java.
  Hay que compilar la app de nuevo. Sin cambios que rompan en Dart.

## 0.9.0 (24 oct 2026)

- `KaeliWeekdayPicker` (Sesly #86, #83): los 7 días en una fila de círculos iguales (L M M J V S D); el marcado se
  rellena del color principal, sin ✓ y sin cambiar de tamaño. Atajos con borde «Lunes a viernes» y «Todos», y días
  desactivados (`disabled`). Sin cambios que rompan.

## 0.8.0 (24 oct 2026)

- `KaeliPhoneField`: teléfono con código de país para todas las apps. Bandera y código a la izquierda (abre una hoja con
  buscador por nombre o por código y países fijos arriba), número a la derecha con teclado de teléfono. Recibe y
  entrega E.164 (`+50660895761`); país inicial del número guardado, de la región del teléfono o `defaultCountry`;
  pegar un número con `+` cambia el país; validación de largo por país, compatible con `KaeliForm`,
  `kaeliValidateForm` y `KaeliRequiredLabel`; anuncia «País: Costa Rica, +506».
- `KaeliPhoneStrings` (es/en/fr/pt) y funciones `kaeliToE164`, `kaeliSplitPhone`, `kaeliCountryFromPhone`,
  `kaeliFormatNational`, `kaeliSearchPhoneCountries`.
- `kaeliPhoneCountries`: 225 países con código, largo del número y nombre en 4 idiomas, sin paquetes nuevos
  (generada por `tool/gen_phone_countries.mjs`, con las reglas de AlojaConmigo).
- Sin cambios que rompan: las apps en 0.7.x siguen igual.

## 0.7.0 (24 oct 2026)

- Tutorial de primera vez: `showKaeliTourOnce` (una sola vez por teléfono, con la clave que ya usara la app),
  `showKaeliTour` (Ajustes → «Ver el tutorial»), `KaeliTour`, `KaeliTourPage` (ícono o ilustración propia),
  `KaeliTourStrings` («Saltar», «Siguiente», «Empezar» en es/en/fr/pt) y `KaeliTourMemory`.
- Compartir y calificar: `KaeliAppInfo`, `kaeliShareApp` (hoja nativa junto al botón en iPad),
  `kaeliOpenStoreToRate` (el botón abre la ficha de la tienda) y `KaeliReviewPrompt.milestone` (la ventana nativa
  una sola vez, después de N logros; `countKey`/`askedKey` para seguir con las claves que ya tiene una app).
- `KaeliPlatformActions` para sustituir el teléfono en las pruebas.
- Dependencias nuevas: `shared_preferences`, `share_plus` (11 a 13) e `in_app_review`.
- Sin cambios que rompan: las apps en 0.6.x siguen igual.

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
