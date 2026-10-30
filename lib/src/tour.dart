import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tutorial que sale la primera vez que se abre la app (regla de Kaeli), con «Saltar», y que se puede volver a ver
/// desde Ajustes («Ver el tutorial»).
///
/// Los textos de cada página los pone la app (traducidos); los botones vienen en es/en/fr/pt ([KaeliTourStrings]).
/// Los colores salen del tema. Para que cada app se vea distinta, [KaeliTourPage.visual] acepta cualquier widget
/// (ilustración, animación, captura) y [KaeliTour.pageBuilder] reemplaza el diseño de la página entera.
///
/// ```dart
/// // Al llegar a la primera pantalla (una sola vez por teléfono):
/// await showKaeliTourOnce(context, pages: [
///   KaeliTourPage(icon: Icons.edit_note, title: l10n.tour1Title, body: l10n.tour1Body),
///   KaeliTourPage(icon: Icons.ios_share, title: l10n.tour2Title, body: l10n.tour2Body),
/// ]);
///
/// // Ajustes → «Ver el tutorial»:
/// onTap: () => showKaeliTour(context, pages: tourPages(l10n)),
/// ```
@immutable
class KaeliTourPage {
  const KaeliTourPage({required this.title, required this.body, this.icon, this.visual})
    : assert(icon != null || visual != null, 'Pon un icon o un visual');

  final String title;
  final String body;

  /// Ícono grande (si no hay [visual]).
  final IconData? icon;

  /// Ilustración propia de la app; reemplaza al ícono.
  final Widget? visual;
}

/// Textos de los botones del tutorial. Igual que [KaeliUiStrings]: solo se pasa lo que se quiere cambiar.
@immutable
class KaeliTourStrings {
  const KaeliTourStrings({this.skip, this.next, this.start, this.pageOf});

  /// «Saltar».
  final String? skip;

  /// «Siguiente».
  final String? next;

  /// Botón de la última página («Empezar»).
  final String? start;

  /// Lo que lee el lector de pantalla: «Página {n} de {total}».
  final String? pageOf;

  static const Map<String, KaeliTourStrings> builtIn = {
    'es': KaeliTourStrings(skip: 'Saltar', next: 'Siguiente', start: 'Empezar', pageOf: 'Página {n} de {total}'),
    'en': KaeliTourStrings(skip: 'Skip', next: 'Next', start: 'Get started', pageOf: 'Page {n} of {total}'),
    'fr': KaeliTourStrings(skip: 'Passer', next: 'Suivant', start: 'Commencer', pageOf: 'Page {n} sur {total}'),
    'pt': KaeliTourStrings(skip: 'Pular', next: 'Próximo', start: 'Começar', pageOf: 'Página {n} de {total}'),
  };

  /// Textos completos para [context] (inglés si el idioma no está), con lo de [overrides] encima.
  static KaeliTourStrings resolve(BuildContext context, [KaeliTourStrings? overrides]) {
    final base = builtIn[Localizations.maybeLocaleOf(context)?.languageCode] ?? builtIn['en']!;
    return KaeliTourStrings(
      skip: overrides?.skip ?? base.skip,
      next: overrides?.next ?? base.next,
      start: overrides?.start ?? base.start,
      pageOf: overrides?.pageOf ?? base.pageOf,
    );
  }
}

/// Si el tutorial ya salió en este teléfono. Clave por defecto en `SharedPreferences`: `kaeli.tour.seen`
/// (una app que ya tenía su propio tutorial pasa su clave vieja para no volver a mostrarlo).
abstract final class KaeliTourMemory {
  static const defaultKey = 'kaeli.tour.seen';

  static Future<bool> seen({String key = defaultKey}) async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;

  static Future<void> markSeen({String key = defaultKey}) async =>
      (await SharedPreferences.getInstance()).setBool(key, true);

  /// Para pruebas o un «Restablecer» de desarrollo.
  static Future<void> reset({String key = defaultKey}) async => (await SharedPreferences.getInstance()).remove(key);
}

/// Abre el tutorial a pantalla completa si todavía no salió en este teléfono. Se marca como visto al abrirlo
/// (aunque la persona cierre la app a la mitad, no vuelve a salir solo). Devuelve true si lo mostró.
Future<bool> showKaeliTourOnce(
  BuildContext context, {
  required List<KaeliTourPage> pages,
  String key = KaeliTourMemory.defaultKey,
  KaeliTourStrings? strings,
  KaeliTourPageBuilder? pageBuilder,
  double? iconRadius,
}) async {
  if (await KaeliTourMemory.seen(key: key)) return false;
  await KaeliTourMemory.markSeen(key: key);
  if (!context.mounted) return false;
  await showKaeliTour(context, pages: pages, strings: strings, pageBuilder: pageBuilder, iconRadius: iconRadius);
  return true;
}

/// Abre el tutorial siempre (Ajustes → «Ver el tutorial»). Termina al tocar «Saltar» o «Empezar».
Future<void> showKaeliTour(
  BuildContext context, {
  required List<KaeliTourPage> pages,
  KaeliTourStrings? strings,
  KaeliTourPageBuilder? pageBuilder,
  double? iconRadius,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (context) => KaeliTour(
      pages: pages,
      strings: strings,
      pageBuilder: pageBuilder,
      iconRadius: iconRadius,
      onFinished: () => Navigator.of(context).pop(),
    ),
  ),
);

/// Diseño propio de una página del tutorial ([KaeliTour.pageBuilder]).
typedef KaeliTourPageBuilder = Widget Function(BuildContext context, KaeliTourPage page);

/// La pantalla del tutorial (si la app prefiere ponerla en su router en vez de usar [showKaeliTour]).
class KaeliTour extends StatefulWidget {
  const KaeliTour({
    super.key,
    required this.pages,
    required this.onFinished,
    this.strings,
    this.pageBuilder,
    this.iconRadius,
  }) : assert(pages.length > 0);

  final List<KaeliTourPage> pages;

  /// Al tocar «Saltar» o «Empezar».
  final VoidCallback onFinished;

  final KaeliTourStrings? strings;

  /// Diseño propio de cada página (lo de arriba de los puntos y el botón). Por defecto: visual, título y texto
  /// centrados.
  final KaeliTourPageBuilder? pageBuilder;

  /// Forma del ícono grande (0.18.0): sin valor, un círculo (como siempre); con valor, un cuadrado con ese radio
  /// (por ejemplo, el del tema de la app).
  final double? iconRadius;

  static const skipKey = Key('kaeliTour.skip');
  static const nextKey = Key('kaeliTour.next');

  @override
  State<KaeliTour> createState() => _KaeliTourState();
}

class _KaeliTourState extends State<KaeliTour> {
  final _controller = PageController();
  var _index = 0;

  bool get _last => _index == widget.pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) return widget.onFinished();
    _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final texts = KaeliTourStrings.resolve(context, widget.strings);
    final scheme = Theme.of(context).colorScheme;
    final total = widget.pages.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(8),
                // Se oculta (sin mover nada) en la última página: ahí el botón principal ya termina.
                child: Visibility(
                  visible: !_last,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(key: KaeliTour.skipKey, onPressed: widget.onFinished, child: Text(texts.skip!)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: total,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Semantics(
                  label: texts.pageOf!.replaceAll('{n}', '${i + 1}').replaceAll('{total}', '$total'),
                  child:
                      widget.pageBuilder?.call(context, widget.pages[i]) ??
                      _DefaultTourPage(page: widget.pages[i], iconRadius: widget.iconRadius),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < total; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: KaeliTour.nextKey,
                  onPressed: _next,
                  child: Text(_last ? texts.start! : texts.next!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultTourPage extends StatelessWidget {
  const _DefaultTourPage({required this.page, this.iconRadius});

  final KaeliTourPage page;
  final double? iconRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          page.visual ??
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: iconRadius == null ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: iconRadius == null ? null : BorderRadius.circular(iconRadius!),
                ),
                child: Icon(page.icon, size: 56, color: theme.colorScheme.onPrimaryContainer),
              ),
          const SizedBox(height: 32),
          Text(page.title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
