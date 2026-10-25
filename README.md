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
| Botones sueltos y desordenados para elegir una opción. | **0.4.0:** `KaeliChoice`: 2–3 opciones cortas → control segmentado de ancho completo; 4 o más o textos largos → lista vertical con ícono y círculo. **0.5.0:** tarjetas con ícono (`cards`, `KaeliMultiChoice`) y «Otra» al final (`KaeliChoiceOther`). |
| Salir de un formulario perdía los cambios sin avisar. | `KaeliUnsavedChangesGuard` pregunta «¿Descartar cambios?» (Descartar / Seguir editando). |
| Cada app tenía su propio tutorial de primera vez, su «Compartir» y su «Calificar». | **0.7.0:** `showKaeliTourOnce` / `showKaeliTour` (tutorial con «Saltar»), `kaeliShareApp`, `kaeliOpenStoreToRate` y `KaeliReviewPrompt.milestone`. |
| Cada app escribía el teléfono a su manera (con o sin código de país, guardado en formatos distintos). | **0.8.0:** `KaeliPhoneField`: bandera y código a la izquierda, número a la derecha; siempre E.164. |
| El número del ícono no bajaba al leer los avisos (AlojaConmigo, reporte de Patricia). | **0.10.0:** `KaeliBadge` / `KaeliBadgeSync`: el ícono muestra solo los avisos sin leer que pasa la app; al abrir o volver a la app se limpian las notificaciones ya vistas. |
| «Este dato es obligatorio» sin decir cuál (el campo quedaba fuera de la pantalla, y con `ListView` los campos de abajo ni se validaban). | **0.3.0:** `KaeliFormList` (todos los campos existen), `kaeliValidateForm` (va al primer error, lo enfoca y lo lee) y `KaeliRequiredLabel` (asterisco desde el principio). |

## Instalación

Con la versión fija (etiqueta de git):

```yaml
dependencies:
  kaeli_ui:
    git:
      url: https://github.com/kaelistudios/kaeli_ui.git
      ref: v0.13.1
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
cuál toca; `layout: KaeliChoiceLayout.segmented` la fija (selectores de vista en una barra).

**Los dos estilos aprobados (0.5.0, Sesly #51)**, además del segmentado para 2–3 opciones cortas:

| Estilo | Para | Cómo |
| --- | --- | --- |
| Tarjetas con ícono (como «Especialidades») | cosas con identidad propia: especialidades, tipos de cita, «¿Dónde?», consultorios | `layout: KaeliChoiceLayout.cards`; varias a la vez: `KaeliMultiChoice`; una tarjeta suelta: `KaeliChoiceCard` |
| Lista agrupada con círculo (como «Política de cancelación») | valores simples: horas, minutos, estados, filtros, idioma, tema | `layout: KaeliChoiceLayout.list` (o `auto`) |

Cuando el valor puede ser libre, siempre «Otra/Otro» al final con `other: KaeliChoiceOther(label:, selected:,
onSelected:, field:)`: al elegirla aparece el campo dentro del mismo grupo. Con `value: null` no hay nada elegido.

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

### Teléfono con código de país: `KaeliPhoneField` (0.8.0)

**Regla:** todo teléfono de una app de Kaeli usa `KaeliPhoneField` y se **guarda en formato internacional E.164**
(`+50660895761`): sin espacios, con `+` y el código del país. Así sirve para llamar, para WhatsApp (`wa.me`) y para
reconocer a la misma persona aunque se haya escrito distinto.

```dart
KaeliPhoneField(
  initialValue: client.phone,                     // «+50660895761» o null
  defaultCountry: 'CR',                           // si no se sabe la región del teléfono
  pinnedCountries: const ['CR', 'MX', 'US', 'ES'], // arriba de la lista, en ese orden
  isRequired: true,
  decoration: InputDecoration(label: KaeliRequiredLabel(l10n.phone)),
  onChanged: (e164) => _phone = e164,              // null si está vacío o todavía no es válido
  onSaved: (e164) => client = client.copyWith(phone: e164),
)
```

- **Dos campos lado a lado:** a la izquierda la bandera y el código (🇨🇷 +506 ▾); a la derecha solo el número, con
  teclado de teléfono. Mismo borde, relleno y altura que el resto de los campos (salen del tema y de `decoration`).
  Pon siempre una etiqueta en `decoration`: el selector lleva la suya («País») y así quedan a la misma altura.
- **País al empezar:** el del número guardado; si no hay, el de la región del teléfono (`PlatformDispatcher`, o la
  del idioma de la app como `es_CR`); si no se sabe, `defaultCountry`.
- **Hoja de países:** buscador por nombre (en el idioma de la app, sin importar acentos, también en inglés), por
  código ISO (`CR`) o por código telefónico (`+506`, `506`). `pinnedCountries` fija los más usados arriba.
- **Pegar un número completo** con `+` (o `00`) en el número cambia el país solo y deja el número nacional.
- **Validación** con el largo mínimo y máximo de cada país (y el 0 de larga distancia donde se usa, como Francia o
  Argentina). Funciona en `Form`, `KaeliForm` (el error se quita al corregir) y `kaeliValidateForm` (va al número y lo
  enfoca). `validator:` agrega una regla propia.
- **Textos** («País», buscar, sin resultados, número no válido, obligatorio) en es/en/fr/pt; `strings:
  KaeliPhoneStrings(…)` cambia los que se pasen. Los nombres de los países salen de Unicode CLDR en los 4 idiomas.
- **Accesible:** el selector se anuncia «País: Costa Rica, +506».
- **Sin paquetes de teléfonos:** la lista propia (`kaeliPhoneCountries`, 225 países, con las reglas de AlojaConmigo)
  se genera con `node tool/gen_phone_countries.mjs`. Funciones sueltas para el servidor o la app:
  `kaeliToE164`, `kaeliSplitPhone`, `kaeliCountryFromPhone`, `kaeliFormatNational`, `kaeliSearchPhoneCountries`.
- **Pruebas:** `KaeliPhoneField.countryKey`, `numberKey`, `searchKey` y `countryTileKey('CR')`. Para fijar la región:
  `tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')]`. Ver `test/phone_field_test.dart`.

**0.12.0:** espacios del país mientras se escribe, «Por ejemplo: …» con el país elegido y aviso del largo al salir
del campo.

**0.11.0:** `preferredCountry` (el país del negocio para un número nuevo, antes que la región del teléfono) y
`onCountryChanged` (para llenar el país de la persona si está vacío). **Toda app de Kaeli usa este campo para el
teléfono:** `kaeli check` avisa si una app tiene un campo de teléfono propio.

### Tutorial de primera vez, compartir y calificar (0.7.0)

**Tutorial.** Sale una sola vez por teléfono, al llegar a la primera pantalla, con «Saltar», «Siguiente» y
«Empezar» (en es/en/fr/pt). En Ajustes, «Ver el tutorial» lo vuelve a abrir. Los textos de cada página los pone la
app; los colores salen del tema.

```dart
List<KaeliTourPage> tourPages(AppLocalizations l10n) => [
  KaeliTourPage(icon: Icons.edit_note, title: l10n.tour1Title, body: l10n.tour1Body),
  KaeliTourPage(visual: Image.asset('assets/tour2.png', height: 160), title: l10n.tour2Title, body: l10n.tour2Body),
];

// Primera pantalla (initState o al terminar de cargar):
await showKaeliTourOnce(context, pages: tourPages(l10n));

// Ajustes → «Ver el tutorial»:
onTap: () => showKaeliTour(context, pages: tourPages(l10n)),
```

- Queda marcado como visto **al abrirse** (aunque se cierre la app a la mitad, no vuelve a salir solo).
- Clave en `SharedPreferences`: `kaeli.tour.seen`. Una app que ya tenía su tutorial pasa **su clave vieja** para que
  a nadie le vuelva a salir: `showKaeliTourOnce(context, pages: …, key: 'settings.onboardingSeen')`.
- `strings: KaeliTourStrings(start: l10n.letsGo)` cambia solo los botones que se pasen.
- `pageBuilder:` reemplaza el diseño de cada página; `KaeliTour` es la pantalla, por si la app la pone en su router.
- Pruebas: `KaeliTour.skipKey` y `KaeliTour.nextKey`; `KaeliTourMemory.reset()` para volver a verlo.

**Compartir y calificar.** Toda app tiene «Compartir» y «Calificar» en Ajustes.

```dart
const kaeliApp = KaeliAppInfo(appStoreId: '6819557562', downloadUrl: 'https://wibblo.kaeliapps.com/');

// «Compartir Wibblo»: el texto lo traduce la app e incluye el enlace.
onTap: () => kaeliShareApp(context, text: l10n.shareAppText(kaeliApp.downloadUrl)),

// «Calificar Wibblo»: abre la ficha de la tienda (App Store en iPhone, Google Play en Android).
onTap: () => kaeliOpenStoreToRate(kaeliApp),

// Después de un logro (3.ª ficha exportada, 1.ª reserva confirmada…): la ventana nativa, UNA vez.
await KaeliReviewPrompt.milestone(after: 3);
```

**Reglas:**
- El botón **«Calificar» abre la ficha de la tienda**. La **ventana nativa** de calificación **solo después de un
  logro** de la persona (`KaeliReviewPrompt.milestone`), una sola vez por teléfono: queda marcada aunque la tienda no
  la muestre, y nunca se insiste. Apple y Google piden no abrir la ventana nativa desde un botón (puede no salir
  nunca y el botón parecería roto).
- El **enlace para compartir** es la página de la app: `https://<app>.kaeliapps.com/` (manda a cada tienda).
- Pasa el `context` del botón a `kaeliShareApp`: en iPad la hoja sale junto a él.
- Claves de la ventana nativa: `kaeli.review.count` y `kaeli.review.asked`. Una app que ya las guardaba con otros
  nombres los pasa: `milestone(after: 3, countKey: 'review.exportCount', askedKey: 'review.asked')`.
- **En pruebas**, `KaeliPlatformActions.instance = MiTelefonoFalso();` (una clase que extiende
  `KaeliPlatformActions`) anota lo que se compartió, la ficha abierta y las ventanas pedidas, y
  `SharedPreferences.setMockInitialValues({})` empieza sin nada guardado. Ver `test/tour_test.dart` y
  `test/app_extras_test.dart`.

### Número del ícono: `KaeliBadge` y `KaeliBadgeSync` (0.10.0)

Para **toda app que recibe notificaciones**. Cada app calcula sus avisos **sin leer** (el paquete no sabe qué es un
aviso) y se los pasa:

```dart
MaterialApp.router(
  builder: (context, child) => KaeliKeyboard(
    child: KaeliBadgeSync(unread: avisosSinLeer, enabled: haySesion, child: child!),
  ),
)
```

- Al abrir la app y al volver a ella: quita las notificaciones ya vistas y pone el número.
- Cuando cambia `unread` (al leer los avisos): pone el número. `0` = sin número; sin sesión (`enabled: false`), 0.
- **iPhone:** el número va en el ícono. **Android:** el lanzador muestra el número o el punto según lo que queda en la
  barra; la app la limpia al abrir, al volver y con 0.
- A mano: `KaeliBadge.set(n)` y `KaeliBadge.clearDelivered()`. En pruebas: `KaeliBadge.platform = MiFalso();`.
- **Push:** si el servidor manda número (`aps.badge`), que sea el conteo **real** de no leídas
  (`KaeliBadge.pushBadgeFor(real)`, null = no mandar número). Si los avisos se calculan en el teléfono, el push no
  lleva número.
- Es un **plugin** (código nativo): después de actualizar, compilar la app de nuevo (no basta con recargar). iPhone con
  Swift Package Manager o CocoaPods; Android en Java (sirve con cualquier versión de Kotlin de la app).
- `kaeli check --app <app>` avisa si una app recibe notificaciones y no usa `KaeliBadge`.

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
cambios, el teléfono con código de país (`KaeliPhoneField`), el tutorial de primera vez y una pestaña «Ajustes» con «Ver el tutorial», «Compartir», «Calificar» y
«Mostrar el tutorial al abrir otra vez» (para probarlo de nuevo):

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
