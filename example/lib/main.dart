// Ejemplo de kaeli_ui con los 4 pasos del README:
// 1. KaeliKeyboard en MaterialApp.builder.
// 2. KaeliKeyboardObserver en cada navegador (la raíz y una por pestaña).
// 3. KaeliTabDismiss al cambiar de pestaña.
// 4. KaeliUnsavedChangesGuard + KaeliFormBottomBar en el formulario.
// Además (0.7.0): tutorial de primera vez y la pestaña «Ajustes» con «Ver el tutorial», «Compartir» y «Calificar».
//
// Los textos del ejemplo están fijos en español para que se lea fácil; en una app de Kaeli salen de sus traducciones.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, this.locale, this.firstRunTour = true});

  /// Idioma fijo (para pruebas); si es null, el del teléfono.
  final Locale? locale;

  /// Mostrar el tutorial la primera vez (las pruebas de formularios lo apagan).
  final bool firstRunTour;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'kaeli_ui',
    locale: locale,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF2A78D6)),
    supportedLocales: const [Locale('es'), Locale('en'), Locale('fr'), Locale('pt')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    // Paso 1.
    builder: (context, child) => KaeliKeyboard(child: child!),
    // Paso 2 (navegador raíz).
    navigatorObservers: [KaeliKeyboardObserver()],
    home: HomeTabs(firstRunTour: firstRunTour),
  );
}

/// Dos pestañas, cada una con su navegador (como `StatefulShellRoute.indexedStack` de go_router).
class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key, this.firstRunTour = true});

  final bool firstRunTour;

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  var _index = 0;

  // Paso 2 (una instancia por pestaña).
  final _observers = [KaeliKeyboardObserver(), KaeliKeyboardObserver(), KaeliKeyboardObserver()];

  @override
  void initState() {
    super.initState();
    // Tutorial de primera vez: una sola vez por teléfono, al llegar a la primera pantalla.
    if (widget.firstRunTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showKaeliTourOnce(context, pages: tourPages);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        Navigator(
          observers: [_observers[0]],
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const PropertyListScreen()),
        ),
        Navigator(
          observers: [_observers[1]],
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const NotesScreen()),
        ),
        Navigator(
          observers: [_observers[2]],
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      // Paso 3.
      onDestinationSelected: KaeliTabDismiss.wrap((i) => setState(() => _index = i)),
      destinations: const [
        NavigationDestination(key: Key('tab.properties'), icon: Icon(Icons.home_outlined), label: 'Propiedades'),
        NavigationDestination(key: Key('tab.notes'), icon: Icon(Icons.notes), label: 'Notas'),
        NavigationDestination(key: Key('tab.settings'), icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
      ],
    ),
  );
}

/// Datos de una propiedad del ejemplo.
class Property {
  const Property({required this.name, required this.description, required this.priceCents, required this.phone});

  final String name;
  final String description;
  final int priceCents;
  final String phone;
}

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _items = [
    const Property(name: 'Casa Colibrí', description: 'Frente al mar.', priceCents: 85000, phone: '+50688880000'),
    const Property(name: 'Cabaña del Bosque', description: '', priceCents: 60000, phone: ''),
  ];

  Future<void> _edit(int i) async {
    final saved = await Navigator.of(context)
        .push<Property>(MaterialPageRoute(builder: (_) => PropertyFormScreen(initial: _items[i])));
    if (saved != null) setState(() => _items[i] = saved);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Propiedades')),
    body: ListView(
      children: [
        // Buscar: campo de una línea; tocar fuera o deslizar la lista cierra el teclado.
        const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            key: Key('list.search'),
            decoration: InputDecoration(labelText: 'Buscar'),
          ),
        ),
        for (final (i, p) in _items.indexed)
          ListTile(
            key: Key('list.item$i'),
            title: Text(p.name),
            subtitle: Text('${(p.priceCents / 100).toStringAsFixed(2)} por noche'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _edit(i),
          ),
      ],
    ),
  );
}

/// Formulario con campo de varias líneas, numérico y de teléfono, «Guardar» abajo y aviso de cambios (paso 4).
class PropertyFormScreen extends StatefulWidget {
  const PropertyFormScreen({super.key, required this.initial});

  final Property initial;

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> with KaeliDirtyTracker<PropertyFormScreen> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _description = TextEditingController(text: widget.initial.description);
  late final _price = TextEditingController(text: (widget.initial.priceCents ~/ 100).toString());
  // Teléfono en formato E.164 («+50688880000»), como lo entrega KaeliPhoneField (null si está vacío o no es válido).
  late final _phone = ValueNotifier<String?>(widget.initial.phone.isEmpty ? null : widget.initial.phone);
  late final _changes = Listenable.merge([_name, _description, _price, _phone]);
  final _form = GlobalKey<FormState>();

  @override
  Object? dirtySnapshot() => (_name.text, _description.text, _price.text, _phone.value);

  @override
  void dispose() {
    for (final c in [_name, _description, _price]) {
      c.dispose();
    }
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!kaeliValidateForm(_form)) return;
    final saved = Property(
      name: _name.text,
      description: _description.text,
      priceCents: (int.tryParse(_price.text) ?? 0) * 100,
      phone: _phone.value ?? '',
    );
    setState(markSaved);
    kaeliPopAfterSave(context, saved);
  }

  @override
  Widget build(BuildContext context) => KaeliUnsavedChangesGuard(
    isDirty: () => hasUnsavedChanges,
    listenable: _changes,
    child: Scaffold(
      appBar: AppBar(title: const Text('Editar propiedad')),
      body: KaeliForm(
        formKey: _form,
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            TextField(
              key: const Key('form.name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('form.description'),
              controller: _description,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('form.price'),
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio por noche'),
            ),
            const SizedBox(height: 16),
            // Teléfono con código de país (0.8.0): bandera y código a la izquierda, el número a la derecha.
            KaeliPhoneField(
              key: const Key('form.phone'),
              initialValue: widget.initial.phone,
              defaultCountry: 'CR',
              pinnedCountries: const ['CR', 'MX', 'US', 'ES'],
              decoration: const InputDecoration(labelText: 'Teléfono'),
              onChanged: (v) => _phone.value = v,
            ),
          ],
        ),
      ),
      bottomNavigationBar: KaeliFormBottomBar(
        child: FilledButton(key: const Key('form.save'), onPressed: _save, child: const Text('Guardar')),
      ),
    ),
  );
}

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notas')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        key: Key('notes.text'),
        maxLines: null,
        decoration: InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
      ),
    ),
  );
}

/// Páginas del tutorial (en una app salen de sus traducciones).
const tourPages = [
  KaeliTourPage(
    icon: Icons.home_outlined,
    title: 'Tus propiedades',
    body: 'Agrega cada propiedad con su precio por noche y edítala cuando quieras.',
  ),
  KaeliTourPage(
    icon: Icons.notes,
    title: 'Notas a mano',
    body: 'Apunta lo que no quieras olvidar en la pestaña «Notas».',
  ),
  KaeliTourPage(
    icon: Icons.settings_outlined,
    title: 'Todo en Ajustes',
    body: 'Vuelve a ver este tutorial, comparte la app o califícala desde «Ajustes».',
  ),
];

/// Datos de la app para compartir y calificar (en una app real: su Apple ID y `https://<app>.kaeliapps.com/`).
const exampleApp = KaeliAppInfo(appStoreId: '6819557562', downloadUrl: 'https://wibblo.kaeliapps.com/');

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes')),
    body: ListView(
      children: [
        ListTile(
          key: const Key('settings.tour'),
          leading: const Icon(Icons.school_outlined),
          title: const Text('Ver el tutorial'),
          onTap: () => showKaeliTour(context, pages: tourPages),
        ),
        Builder(
          builder: (context) => ListTile(
            key: const Key('settings.share'),
            leading: const Icon(Icons.ios_share),
            title: const Text('Compartir la app'),
            onTap: () => kaeliShareApp(context, text: 'Te recomiendo esta app: ${exampleApp.downloadUrl}'),
          ),
        ),
        ListTile(
          key: const Key('settings.rate'),
          leading: const Icon(Icons.star_outline),
          title: const Text('Calificar la app'),
          // El botón abre la ficha de la tienda; la ventana nativa solo después de un logro (KaeliReviewPrompt).
          onTap: () => kaeliOpenStoreToRate(exampleApp),
        ),
        ListTile(
          key: const Key('settings.resetTour'),
          leading: const Icon(Icons.restart_alt),
          title: const Text('Mostrar el tutorial al abrir otra vez'),
          subtitle: const Text('Solo para probar'),
          onTap: () async {
            await KaeliTourMemory.reset();
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Listo: saldrá al abrir la app.')));
            }
          },
        ),
      ],
    ),
  );
}
