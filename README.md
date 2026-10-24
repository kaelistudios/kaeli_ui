# kaeli_ui

Paquete Flutter compartido por las apps de Kaeli. Resuelve el **teclado**, los **formularios** y el selector de
**mes y año**, y funciona con cualquier app: no depende de go_router, Riverpod ni de los temas o
traducciones de ninguna app. Los colores salen del tema de cada app (`Theme.of(context)`).

## Qué resuelve

En una prueba en iPhone (18 oct 2026) encontramos estos problemas con el teclado:

| Problema en iPhone | Solución en kaeli_ui |
| --- | --- |
| Tocar fuera de un campo no cerraba el teclado (Flutter solo lo hace con mouse). | `KaeliKeyboard` lo cierra al tocar fuera, sin romper botones, el menú de copiar/pegar ni las manijas de selección. |
| Deslizar una lista no cerraba el teclado. | `KaeliKeyboard` hace que **todas** las listas lo cierren al arrastrarlas. |
| Los campos de varias líneas, numéricos y de teléfono no tienen tecla para cerrar el teclado. | Barra «Listo» encima del teclado (solo iPhone/iPad). |
| Al volver a la pantalla anterior (flecha o gesto de deslizar), el teclado quedaba abierto. | `KaeliKeyboardObserver` lo cierra en cada cambio de pantalla y apenas empieza el gesto de volver. |
| Al cambiar de pestaña, el teclado seguía abierto (la pestaña de antes sigue montada). | `KaeliTabDismiss` lo cierra al cambiar de pestaña. |
| El botón «Guardar» saltaba con el teclado y tapaba el formulario. | **Regla (0.2.0):** `KaeliFormBottomBar` se queda en su lugar; el contenido se achica hasta el teclado (y la barra «Listo») y se desplaza solo para que el campo que se escribe se vea. Para guardar, se cierra el teclado. |
| Cambiar de mes en un calendario pedía tocar la flecha muchas veces. | `showKaeliMonthYearPicker`: hoja con ruedas de mes y año (✕ y ✓), igual en iPhone y Android. **0.4.0:** `showKaeliDatePicker`, el calendario completo que las usa. |
| Botones sueltos y desordenados para elegir una opción. | **0.4.0:** `KaeliChoice`: 2–3 opciones cortas → control segmentado de ancho completo; 4 o más o textos largos → lista vertical con ícono y círculo. |
| Salir de un formulario perdía los cambios sin avisar. | `KaeliUnsavedChangesGuard` pregunta «¿Descartar cambios?» (Descartar / Seguir editando). |
| «Este dato es obligatorio» sin decir cuál (el campo quedaba fuera de la pantalla, y con `ListView` los campos de abajo ni se validaban). | **0.3.0:** `KaeliFormList` (todos los campos existen), `kaeliValidateForm` (va al primer error, lo enfoca y lo lee) y `KaeliRequiredLabel` (asterisco desde el principio). |

## Instalación

Con la versión fija (etiqueta de git):

```yaml
dependencies:
  kaeli_ui:
    git:
      url: https://github.com/kaelistudios/kaeli_ui.git
      ref: v0.4.0
```

Después: `flutter pub get` e `import 'package:kaeli_ui/kaeli_ui.dart';`.

Requiere Flutter 3.24 o más nuevo (usa `PopScope.onPopInvokedWithResult`) y Dart `^3.13.4`.

## Integración en una app: 4 pasos

### 1. `KaeliKeyboard` en `MaterialApp.builder`

```dart
MaterialApp.router(
  builder: (context, child) => KaeliKeyboard(child: child!),
  // ...
)
```

Si la app ya tiene su propio `builder`, `KaeliKeyboard` va por fuera de lo demás:
`builder: (context, child) => KaeliKeyboard(child: MiOtroWidget(child: child!))`.

Opciones: `strings` (textos propios), `dismissOnTapOutside`, `dismissOnDrag` y `doneBar` (todas en `true` por defecto).

### 2. `KaeliKeyboardObserver` en cada navegador

Una instancia nueva **por navegador** (go_router no deja compartir la misma).

Con `MaterialApp` / `Navigator`:

```dart
MaterialApp(navigatorObservers: [KaeliKeyboardObserver()], ...)
Navigator(observers: [KaeliKeyboardObserver()], ...)
```

Con go_router, en la raíz y en **cada** rama de las pestañas:

```dart
GoRouter(
  observers: [KaeliKeyboardObserver()],
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(observers: [KaeliKeyboardObserver()], routes: [...]),
        StatefulShellBranch(observers: [KaeliKeyboardObserver()], routes: [...]),
      ],
    ),
  ],
)
```

### 3. Cerrar el teclado al cambiar de pestaña

Con go_router (`StatefulNavigationShell`):

```dart
NavigationBar(
  selectedIndex: shell.currentIndex,
  onDestinationSelected: (i) => KaeliTabDismiss.goBranch(i, shell.goBranch, currentIndex: shell.currentIndex),
  destinations: [...],
)
```

Con cualquier otra barra: `onDestinationSelected: KaeliTabDismiss.wrap((i) => setState(() => _index = i))`.

Para cerrarlo a mano en cualquier otro momento: `dismissKeyboard()` o `KaeliKeyboard.dismiss()`.

### 4. En cada formulario: `KaeliUnsavedChangesGuard` + `KaeliFormBottomBar`

```dart
class _EditState extends State<Edit> with KaeliDirtyTracker<Edit> {
  final _name = TextEditingController();
  final _price = TextEditingController();

  // Lo que se compara con los valores del principio (registros, listas, mapas y conjuntos por contenido).
  @override
  Object? dirtySnapshot() => (_name.text, _price.text);

  void _save() {
    // ... guardar ...
    setState(markSaved);
    kaeliPopAfterSave(context);
  }

  @override
  Widget build(BuildContext context) => KaeliUnsavedChangesGuard(
    isDirty: () => hasUnsavedChanges,
    listenable: Listenable.merge([_name, _price]),
    child: Scaffold(
      appBar: AppBar(title: Text(l10n.editTitle)),
      body: ListView(children: [...]),
      bottomNavigationBar: KaeliFormBottomBar(
        child: FilledButton(onPressed: _save, child: Text(l10n.save)),
      ),
    ),
  );
}
```

- Dentro de un `Form`, el guardián se revisa solo con cada cambio de sus campos (no hace falta `listenable`).
- También acepta `dirty: true/false` o un `ValueListenable<bool>` en `listenable`.
- Si los valores iniciales se cargan después de abrir (p. ej. del servidor), llama a `markSaved()` al cargarlos.
- Con cambios, el gesto de deslizar para volver de iPhone queda apagado (así funciona `PopScope`); la flecha muestra
  el aviso.
- `KaeliFormScaffold(appBar:, body:, bottomAction:)` es un atajo de `Scaffold` + `KaeliFormBottomBar`.
- **Regla de Kaeli para todas las apps:** el botón principal o «Guardar» del final de un formulario **no sube con el
  teclado**. El `Scaffold` (con `resizeToAvoidBottomInset`, que viene encendido) achica el contenido y Flutter desplaza
  el campo activo para que no quede tapado; el cuerpo tiene que poder desplazarse (`ListView`,
  `SingleChildScrollView`…). No pongas el botón dentro de un `Padding` con `MediaQuery.viewInsets`.

### Elegir una opción: `KaeliChoice` (0.4.0)

```dart
KaeliChoice<Status>(
  label: l10n.status,
  value: _status,
  options: [for (final s in Status.values) KaeliOption(s, label(s), icon: icon(s))],
  onChanged: (s) => setState(() => _status = s),
)
```

Regla de Kaeli: 2 o 3 opciones cortas (hasta 14 letras, sin segunda línea y con letra hasta 150 %) → control
segmentado de ancho completo; si no, lista vertical con ícono y círculo de selección. `KaeliChoice.segmented(...)` dice
cuál toca.

### Elegir un día: `showKaeliDatePicker` (0.4.0)

```dart
final d = await showKaeliDatePicker(
  context,
  initial: _birth,                                  // null: se abre en openAt sin marcar
  openAt: DateTime(now.year - 6, now.month),        // p. ej. fecha de nacimiento: unos años atrás
  first: DateTime(1920),
  last: now,                                        // sin fechas futuras
);
```

Calendario del mes con ‹ ›; al tocar «octubre 2026 ▾» se abren las ruedas de mes y año. «Cancelar» y «Aceptar» con el
mismo formato, en el idioma de la app.

### Errores de un formulario: `KaeliFormList`, `kaeliValidateForm` y `KaeliRequiredLabel` (0.3.0)

```dart
Form(
  key: _form,
  child: KaeliFormList(              // no ListView: así se validan también los campos de abajo
    padding: EdgeInsets.all(16),
    children: [
      TextFormField(
        decoration: InputDecoration(label: KaeliRequiredLabel(l10n.name)),   // «Nombre *»
        validator: (v) => (v ?? '').trim().isEmpty ? l10n.required : null,
      ),
      // ...
    ],
  ),
)

void _save() {
  if (!kaeliValidateForm(_form)) return;   // desplaza al primer error, lo enfoca y el lector lo dice
  // ... guardar ...
}
```

- Regla de Kaeli: el error va **debajo del campo** con su texto, y al guardar la pantalla va al primero.
- `kaeliRevealFirstError(context)` hace lo mismo con errores que la app marca a mano.
- Con `ListView`, `Form.validate()` solo revisa los campos ya construidos (los que se ven): usar `KaeliFormList`.

### Volver deslizando en iPhone (go_router)

Con go_router 18.1 y Flutter 3.47, las rutas que solo traen `builder` salen **sin transición** y en iPhone no se puede
volver deslizando desde el borde. Usa `pageBuilder` con `kaeliPage` en cada `GoRoute`:

```dart
GoRoute(
  path: '/reserva/:id',
  pageBuilder: (context, state) => kaeliPage(key: state.pageKey, child: BookingScreen(id: state.pathParameters['id']!)),
)
```

Con `Navigator` y `MaterialPageRoute` (sin go_router) no hace falta. `kaeli check` avisa si una app con go_router tiene
rutas con solo `builder`.

### Mes y año con ruedas: `showKaeliMonthYearPicker`

En todo calendario o selector de fecha, tocar el mes y el año abre una hoja desde abajo con dos ruedas (meses y años),
como el selector de hora del iPhone, con ✕ (cancelar) y ✓ (aceptar). Igual en iPhone y Android.

```dart
final month = await showKaeliMonthYearPicker(
  context,
  initial: visibleMonth,          // cualquier día del mes
  title: l10n.chooseMonth,        // opcional
);
if (month != null) setState(() => visibleMonth = month); // primer día del mes elegido
```

- Rango por defecto: de 5 años atrás a 10 adelante (siempre incluye `initial`); `first:` y `last:` lo cambian.
- Meses en el idioma de la app (datos de `intl`, sin inicializar nada); `monthNames:` los cambia.
- Colores y letras del tema (`ColorScheme`, `TextTheme`); la rueda crece con la letra del teléfono.
- `KaeliMonthYearPicker` es el contenido, por si se quiere poner en otro lugar.

## Textos e idiomas

Los textos incluidos (barra «Listo», aviso de cambios y ✕/✓ del selector de mes y año) están en español, inglés, francés y portugués; se elige el
idioma de la app (`Localizations.localeOf(context)`) y, si no está, inglés. Para cambiar uno o varios:

```dart
KaeliKeyboard(
  strings: KaeliUiStrings(
    discardTitle: AppLocalizations.of(context).unsavedTitle,
    done: AppLocalizations.of(context).keyboardDone,
  ),
  child: child!,
)
```

Lo que no se cambia sale del idioma actual. `KaeliUnsavedChangesGuard(strings: ...)` cambia los textos solo en ese
formulario, y `confirmDiscard:` permite usar un diálogo propio de la app.

## Cómo probarlo en una app

En las pruebas de widgets (`flutter test`) de la app:

```dart
// Tocar fuera cierra el teclado.
await tester.tap(find.byKey(const Key('campo')));
await tester.pump();
await tester.tap(find.byType(AppBar));
await tester.pumpAndSettle();
expect(focusedEditableText(), isNull);
expect(tester.testTextInput.isVisible, isFalse);

// Barra «Listo» (solo iPhone).
debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
// ... tocar un campo numérico ...
expect(find.byKey(KaeliKeyboard.barKey), findsOneWidget);
await tester.tap(find.byKey(KaeliKeyboard.doneKey));
debugDefaultTargetPlatformOverride = null;

// «Guardar» encima del teclado.
tester.view.viewInsets = const FakeViewPadding(bottom: 340);
await tester.pumpAndSettle();
expect(find.byKey(const Key('guardar')).hitTestable(), findsOneWidget);

// Aviso de cambios.
await tester.enterText(find.byKey(const Key('campo')), 'otro');
await tester.tap(find.byType(BackButton));
await tester.pumpAndSettle();
expect(find.byKey(KaeliUnsavedChangesGuard.keepEditingKey), findsOneWidget);
```

Las pruebas de este paquete (`test/`) sirven de modelo. En el teléfono, revisar a mano: tocar fuera, deslizar una
lista, la barra «Listo» en campos numéricos y de varias líneas, volver con el gesto de deslizar con el teclado abierto,
cambiar de pestaña con el teclado abierto, «Guardar» visible mientras se escribe y el aviso al salir con cambios.

## Ejemplo

`example/` tiene una app con una lista → formulario (varias líneas, número y teléfono), «Guardar» abajo, aviso de
cambios y dos pestañas:

```sh
cd example
flutter run        # en el simulador de iPhone para ver la barra «Listo»
flutter test
```

## Desarrollo

```sh
flutter pub get
flutter analyze
flutter test
```

**Todos los derechos reservados · Kaeli.** El código es visible, pero no tiene licencia abierta: no se puede
copiar, modificar ni redistribuir sin permiso de Kaeli (ver `LICENSE`).
