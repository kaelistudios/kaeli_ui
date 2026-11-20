// Campo con buscador para listas largas o que crecen (marcas, bancos, categorías, servicios…). Regla 8 de las reglas
// generales de Kaeli. Nació del buscador de marcas de Katawi (Ronda 1, 12 nov 2026) y lo mejora en una cosa: la lista
// se abre apenas se toca el campo, sin tener que escribir.
//
// Para teléfonos NO se usa este campo: el código de país con bandera es [KaeliPhoneField].

import 'package:flutter/material.dart';

/// Una opción de [KaeliSearchField].
@immutable
class KaeliSearchOption<T> {
  const KaeliSearchOption(this.value, this.label, {this.subtitle, this.icon, this.leading, this.keywords = const [], this.key});

  final T value;

  /// Nombre que se ve y con el que se busca («Farmasi»).
  final String label;

  /// Segunda línea opcional (no se usa para buscar).
  final String? subtitle;

  /// Ícono a la izquierda. [leading] lo reemplaza (p. ej. un punto de color o un logo).
  final IconData? icon;
  final Widget? leading;

  /// Otros nombres con los que también se encuentra («Unique», «Yanbal», «Banco de Bogotá» → «bogota»).
  final List<String> keywords;

  /// Clave de la fila, para encontrarla en las pruebas de la app.
  final Key? key;
}

/// Textos de [KaeliSearchField]. Igual que [KaeliPhoneStrings]: solo se pasa lo que se quiere cambiar.
@immutable
class KaeliSearchStrings {
  const KaeliSearchStrings({this.hint, this.addNew, this.noResults, this.alreadyAdded});

  /// Pista dentro del campo («Escribe para buscar»).
  final String? hint;

  /// Fila para agregar lo escrito: «Agregar «{text}»».
  final String? addNew;

  /// Cuando no hay coincidencias y no se puede agregar.
  final String? noResults;

  /// Aviso de [KaeliSearchField.onTaken] si la app no pasa el suyo: «{name} ya está agregada».
  final String? alreadyAdded;

  static const Map<String, KaeliSearchStrings> builtIn = {
    'es': KaeliSearchStrings(
      hint: 'Escribe para buscar',
      addNew: 'Agregar «{text}»',
      noResults: 'No hay coincidencias',
      alreadyAdded: '«{name}» ya está agregada',
    ),
    'en': KaeliSearchStrings(
      hint: 'Type to search',
      addNew: 'Add “{text}”',
      noResults: 'No matches',
      alreadyAdded: '“{name}” is already added',
    ),
    'fr': KaeliSearchStrings(
      hint: 'Tapez pour rechercher',
      addNew: 'Ajouter « {text} »',
      noResults: 'Aucun résultat',
      alreadyAdded: '« {name} » est déjà ajouté',
    ),
    'pt': KaeliSearchStrings(
      hint: 'Digite para buscar',
      addNew: 'Adicionar “{text}”',
      noResults: 'Nenhum resultado',
      alreadyAdded: '“{name}” já foi adicionado',
    ),
  };

  /// Textos completos para [languageCode] (inglés si no está), con lo de [overrides] encima.
  static KaeliSearchStrings resolve(String? languageCode, [KaeliSearchStrings? overrides]) {
    final base = builtIn[languageCode] ?? builtIn['en']!;
    return KaeliSearchStrings(
      hint: overrides?.hint ?? base.hint,
      addNew: overrides?.addNew ?? base.addNew,
      noResults: overrides?.noResults ?? base.noResults,
      alreadyAdded: overrides?.alreadyAdded ?? base.alreadyAdded,
    );
  }
}

const _accents = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a', //
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
  'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y',
};

/// Texto para comparar: minúsculas, sin tildes, espacios ni signos («Ésika» → «esika», «Unique / Yanbal» →
/// «uniqueyanbal»). Las letras que no son latinas se dejan como están.
String kaeliSearchFold(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final plain = _accents[ch] ?? ch;
    if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(plain)) out.write(plain);
  }
  return out.toString();
}

/// Errores de letra que se perdonan según el largo de lo escrito: ninguno hasta 4 letras, 1 desde 5 y 2 desde 8.
int _allowedTypos(int length) => length >= 8 ? 2 : (length >= 5 ? 1 : 0);

/// Distancia de edición (Levenshtein) entre dos textos ya normalizados.
int _distance(String a, String b) {
  if (a == b) return 0;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final best = prev[j] + 1 < cur[j - 1] + 1 ? prev[j] + 1 : cur[j - 1] + 1;
      cur[j] = best < prev[j - 1] + cost ? best : prev[j - 1] + cost;
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Parecido con errores de letra: el nombre entero, o su principio mientras se sigue escribiendo («Farmsa» → Farmasi).
bool _closeEnough(String q, String candidate) {
  final allowed = _allowedTypos(q.length);
  if (allowed == 0) return false;
  if (_distance(q, candidate) <= allowed) return true;
  return candidate.length > q.length && _distance(q, candidate.substring(0, q.length)) <= allowed;
}

/// Textos con los que se encuentra una opción: el nombre entero, sus partes («Unique / Yanbal» → unique, yanbal) y
/// las [KaeliSearchOption.keywords].
Set<String> _candidates(KaeliSearchOption<Object?> o) => {
  kaeliSearchFold(o.label),
  for (final part in o.label.split(RegExp(r'[/,·()]'))) kaeliSearchFold(part),
  for (final k in o.keywords) kaeliSearchFold(k),
}..remove('');

/// Qué tan bien coincide [q] (ya normalizado) con la opción: 0 igual, 1 empieza igual, 2 contiene, 3 parecido con
/// errores de letra; null si no coincide.
int? _score(String q, KaeliSearchOption<Object?> o) {
  int? best;
  for (final c in _candidates(o)) {
    final s = c == q
        ? 0
        : c.startsWith(q)
        ? 1
        : c.contains(q)
        ? 2
        : _closeEnough(q, c)
        ? 3
        : null;
    if (s != null && (best == null || s < best)) best = s;
  }
  return best;
}

/// Opciones que coinciden con [query], de la más parecida a la menos; en empate se respeta el orden de [options] (por
/// eso conviene pasar primero las más usadas o las de la región). Con [query] vacío, todas en su orden.
List<KaeliSearchOption<T>> kaeliSearchOptions<T>(String query, List<KaeliSearchOption<T>> options, {int? limit}) {
  final q = kaeliSearchFold(query);
  final List<KaeliSearchOption<T>> result;
  if (q.isEmpty) {
    result = options;
  } else {
    final scored = <(int, int, KaeliSearchOption<T>)>[];
    for (final (i, o) in options.indexed) {
      final s = _score(q, o);
      if (s != null) scored.add((s, i, o));
    }
    scored.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    result = [for (final s in scored) s.$3];
  }
  return limit == null || result.length <= limit ? result : result.sublist(0, limit);
}

/// La opción conocida que corresponde a lo escrito: el mismo nombre (sin importar tildes ni mayúsculas) o uno muy
/// parecido («Farmasy» → Farmasi). Null si no hay ninguna; así se agrega como nueva.
KaeliSearchOption<T>? kaeliMatchOption<T>(String typed, List<KaeliSearchOption<T>> options) {
  final q = kaeliSearchFold(typed);
  if (q.isEmpty) return null;
  for (final o in options) {
    if (_candidates(o).contains(q)) return o;
  }
  final allowed = _allowedTypos(q.length);
  if (allowed == 0) return null;
  KaeliSearchOption<T>? best;
  var bestDistance = allowed + 1;
  for (final o in options) {
    final d = _distance(q, kaeliSearchFold(o.label));
    if (d < bestDistance) {
      best = o;
      bestDistance = d;
    }
  }
  return best;
}

/// Campo con buscador, para todas las apps de Kaeli (regla 8): para listas largas o que crecen. Para 2 a ~10
/// opciones fijas, [KaeliChoice]; para teléfonos, [KaeliPhoneField].
///
/// - Con **solo tocar el campo** se abre la lista (las primeras [maxResults] de [options], en su orden), sin escribir.
/// - Al escribir se filtra sin importar tildes, mayúsculas, espacios ni signos, y perdona errores de letra en nombres
///   de 5 letras o más.
/// - Con [onAddNew], al final va «Agregar «lo escrito»» para poner un valor que no está. Si lo escrito se parece a
///   una opción conocida, se elige esa (con su nombre oficial) en vez de crear otra.
/// - [isTaken]: las ya agregadas no aparecen; si se vuelve a escribir una, se llama a [onTaken] (o se muestra un aviso).
/// - El campo sube a la parte de arriba al abrir la lista, para que no quede bajo el teclado. La lista no se cierra al
///   desplazar la pantalla (aunque el teclado sí); se cierra al elegir o al tocar fuera.
///
/// ```dart
/// KaeliSearchField<String>(
///   label: l10n.brand,
///   options: [for (final b in knownBrands) KaeliSearchOption(b, b)],
///   isTaken: (b) => _brands.any((x) => x.name == b),
///   onSelected: (o) => setState(() => _brands.add(Brand(o.value))),
///   onAddNew: (text) => setState(() => _brands.add(Brand(text))),
/// )
/// ```
///
/// Para elegir **un** valor (no ir agregando), [clearOnSelect] en false: el campo queda con el nombre elegido.
class KaeliSearchField<T> extends StatefulWidget {
  const KaeliSearchField({
    super.key,
    required this.options,
    required this.onSelected,
    this.onAddNew,
    this.isTaken,
    this.onTaken,
    this.label,
    this.hintText,
    this.strings,
    this.maxResults = 8,
    this.clearOnSelect = true,
    this.keepOpenAfterSelect = false,
    this.controller,
    this.focusNode,
    this.fieldKey,
    this.prefixIcon = Icons.search_rounded,
    this.textCapitalization = TextCapitalization.sentences,
    this.addNewIcon = Icons.edit_outlined,
    this.enabled = true,
  });

  /// Todas las opciones, en el orden en que deben salir con el campo vacío (las más usadas o las de la región primero).
  final List<KaeliSearchOption<T>> options;

  /// Se tocó una opción (o se escribió una conocida y se agregó).
  final ValueChanged<KaeliSearchOption<T>> onSelected;

  /// Agregar lo escrito, ya sin espacios de más. Null: solo se puede elegir de la lista.
  final ValueChanged<String>? onAddNew;

  /// Opciones que ya se agregaron (no se muestran).
  final bool Function(T value)? isTaken;

  /// Se escribió una que ya estaba agregada. Sin esto, un aviso con [KaeliSearchStrings.alreadyAdded].
  final ValueChanged<KaeliSearchOption<T>>? onTaken;

  final String? label;
  final String? hintText;
  final KaeliSearchStrings? strings;

  /// Filas como máximo (sin contar «Agregar»).
  final int maxResults;

  /// true (por defecto): al elegir, el campo se vacía para agregar otra. false: queda el nombre elegido.
  final bool clearOnSelect;

  /// true: la lista sigue abierta después de elegir (para agregar varias seguidas).
  final bool keepOpenAfterSelect;

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Clave del campo de texto (para pruebas).
  final Key? fieldKey;

  final IconData? prefixIcon;
  final TextCapitalization textCapitalization;
  final IconData addNewIcon;
  final bool enabled;

  /// Clave de la fila «Agregar «…»» (para pruebas).
  static const addNewKey = Key('kaeliSearch.addNew');

  /// Clave del texto «No hay coincidencias» (para pruebas).
  static const noResultsKey = Key('kaeliSearch.noResults');

  @override
  State<KaeliSearchField<T>> createState() => _KaeliSearchFieldState<T>();
}

class _KaeliSearchFieldState<T> extends State<KaeliSearchField<T>> {
  final _fieldKey = GlobalKey();
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  var _open = false;

  TextEditingController get _controller => widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(KaeliSearchField<T> old) {
    super.didUpdateWidget(old);
    final oldFocus = old.focusNode ?? _ownFocus;
    if (oldFocus != _focus) {
      oldFocus?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    final oldController = old.controller ?? _ownController;
    if (oldController != _controller) {
      oldController?.removeListener(_onText);
      _controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _controller.removeListener(_onText);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    // Abre al entrar al campo. Al perder el foco (p. ej. al desplazar la pantalla, que cierra el teclado) la lista se
    // queda: se cierra al elegir o al tocar fuera.
    if (_focus.hasFocus && !_open) {
      setState(() => _open = true);
      _lift();
    }
  }

  void _onText() {
    if (!mounted) return;
    setState(() => _open = _open || _focus.hasFocus);
  }

  /// Sube el campo a la parte de arriba para que la lista no quede bajo el teclado.
  void _lift() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final field = _fieldKey.currentContext;
      if (!mounted || field == null) return;
      Scrollable.ensureVisible(field, alignment: 0.05, duration: kThemeAnimationDuration);
    });
  }

  void _close() {
    if (_open) setState(() => _open = false);
  }

  bool _taken(KaeliSearchOption<T> o) => widget.isTaken?.call(o.value) ?? false;

  KaeliSearchStrings get _texts => KaeliSearchStrings.resolve(Localizations.maybeLocaleOf(context)?.languageCode, widget.strings);

  void _choose(KaeliSearchOption<T> option) {
    if (_taken(option)) {
      _notifyTaken(option);
      return;
    }
    widget.onSelected(option);
    _afterChoose(option.label);
  }

  void _addTyped() {
    final typed = _controller.text.trim();
    if (typed.isEmpty) return;
    final known = kaeliMatchOption(typed, widget.options);
    if (known != null) return _choose(known);
    final add = widget.onAddNew;
    if (add == null) {
      final results = _results();
      if (results.length == 1) _choose(results.single);
      return;
    }
    add(typed);
    _afterChoose(typed);
  }

  void _afterChoose(String label) {
    if (widget.clearOnSelect) {
      _controller.clear();
    } else {
      _controller.value = TextEditingValue(text: label, selection: TextSelection.collapsed(offset: label.length));
    }
    if (widget.keepOpenAfterSelect) return;
    _focus.unfocus();
    _close();
  }

  void _notifyTaken(KaeliSearchOption<T> option) {
    _controller.clear();
    final onTaken = widget.onTaken;
    if (onTaken != null) return onTaken(option);
    final text = _texts.alreadyAdded!.replaceAll('{name}', option.label);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  List<KaeliSearchOption<T>> _results() {
    final free = [for (final o in widget.options) if (!_taken(o)) o];
    // Con el nombre elegido en el campo (clearOnSelect: false), al volver a tocarlo se ve la lista completa.
    final query = !widget.clearOnSelect && free.any((o) => o.label == _controller.text) ? '' : _controller.text;
    return kaeliSearchOptions(query, free, limit: widget.maxResults);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = _texts;
    final query = _controller.text.trim();
    final results = _open ? _results() : <KaeliSearchOption<T>>[];
    final exact = query.isNotEmpty && widget.options.any((o) => _candidates(o).contains(kaeliSearchFold(query)));
    final showAdd = _open && widget.onAddNew != null && query.isNotEmpty && !exact;
    final showEmpty = _open && query.isNotEmpty && results.isEmpty && !showAdd;

    return TapRegion(
      onTapOutside: (_) => _close(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          KeyedSubtree(
            key: _fieldKey,
            child: TextField(
              key: widget.fieldKey,
              controller: _controller,
              focusNode: _focus,
              enabled: widget.enabled,
              textCapitalization: widget.textCapitalization,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onTap: () {
                if (!_open) setState(() => _open = true);
                _lift();
              },
              onSubmitted: (_) => _addTyped(),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hintText ?? texts.hint,
                prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
              ),
            ),
          ),
          if (_open && (results.isNotEmpty || showAdd || showEmpty))
            // Parte del campo para el teclado: tocar una fila no lo cierra antes de elegirla.
            TextFieldTapRegion(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Material(
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final o in results)
                        _SearchRow(
                          key: o.key,
                          leading: o.leading ?? (o.icon == null ? null : Icon(o.icon, color: theme.colorScheme.primary)),
                          label: o.label,
                          subtitle: o.subtitle,
                          onTap: () => _choose(o),
                        ),
                      if (showAdd)
                        _SearchRow(
                          key: KaeliSearchField.addNewKey,
                          leading: Icon(widget.addNewIcon, color: theme.colorScheme.primary),
                          label: texts.addNew!.replaceAll('{text}', query),
                          onTap: _addTyped,
                        ),
                      if (showEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            texts.noResults!,
                            key: KaeliSearchField.noResultsKey,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila de la lista: 48 de alto como mínimo, ancho completo, crece con la letra.
class _SearchRow extends StatelessWidget {
  const _SearchRow({super.key, required this.label, required this.onTap, this.leading, this.subtitle});

  final Widget? leading;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (leading != null) ...[ExcludeSemantics(child: leading!), const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: theme.textTheme.bodyLarge),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
