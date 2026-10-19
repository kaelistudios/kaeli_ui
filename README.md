# kaeli_ui

Paquete Flutter compartido por las apps de Kaeli. Esta primera versión resuelve el
**teclado** y los **formularios**, y funciona con cualquier app: no depende de go_router, Riverpod ni de los temas o
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
| El botón «Guardar» quedaba tapado por el teclado. | `KaeliFormBottomBar` lo sube con el teclado (y por encima de la barra «Listo»). |
| Salir de un formulario perdía los cambios sin avisar. | `KaeliUnsavedChangesGuard` pregunta «¿Descartar cambios?» (Descartar / Seguir editando). |

## Instalación

Con la versión fija (etiqueta de git):

```yaml
dependencies:
  kaeli_ui:
    git:
      url: https://github.com/kaelistudios/kaeli_ui.git
      ref: v0.1.0
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

## Textos e idiomas

Los textos incluidos (barra «Listo» y aviso de cambios) están en español, inglés, francés y portugués; se elige el
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
