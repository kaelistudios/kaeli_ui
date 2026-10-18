// Ejemplo de kaeli_ui con los 4 pasos del README:
// 1. KaeliKeyboard en MaterialApp.builder.
// 2. KaeliKeyboardObserver en cada navegador (la raíz y una por pestaña).
// 3. KaeliTabDismiss al cambiar de pestaña.
// 4. KaeliUnsavedChangesGuard + KaeliFormBottomBar en el formulario.
//
// Los textos del ejemplo están fijos en español para que se lea fácil; en una app de Kaeli salen de sus traducciones.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, this.locale});

  /// Idioma fijo (para pruebas); si es null, el del teléfono.
  final Locale? locale;

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
    home: const HomeTabs(),
  );
}

/// Dos pestañas, cada una con su navegador (como `StatefulShellRoute.indexedStack` de go_router).
class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  var _index = 0;

  // Paso 2 (una instancia por pestaña).
  final _observers = [KaeliKeyboardObserver(), KaeliKeyboardObserver()];

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
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      // Paso 3.
      onDestinationSelected: KaeliTabDismiss.wrap((i) => setState(() => _index = i)),
      destinations: const [
        NavigationDestination(key: Key('tab.properties'), icon: Icon(Icons.home_outlined), label: 'Propiedades'),
        NavigationDestination(key: Key('tab.notes'), icon: Icon(Icons.notes), label: 'Notas'),
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
    const Property(name: 'Casa Colibrí', description: 'Frente al mar.', priceCents: 85000, phone: '+506 8888 0000'),
    const Property(name: 'Cabaña del Bosque', description: '', priceCents: 60000, phone: ''),
  ];

  Future<void> _edit(int i) async {
    final saved = await Navigator.of(context).push<Property>(
      MaterialPageRoute(builder: (_) => PropertyFormScreen(initial: _items[i])),
    );
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
          child: TextField(key: Key('list.search'), decoration: InputDecoration(labelText: 'Buscar')),
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
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _changes = Listenable.merge([_name, _description, _price, _phone]);

  @override
  Object? dirtySnapshot() => (_name.text, _description.text, _price.text, _phone.text);

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final saved = Property(
      name: _name.text,
      description: _description.text,
      priceCents: (int.tryParse(_price.text) ?? 0) * 100,
      phone: _phone.text,
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
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          TextField(key: const Key('form.name'), controller: _name, decoration: const InputDecoration(labelText: 'Nombre')),
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
          TextField(
            key: const Key('form.phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono'),
          ),
        ],
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
