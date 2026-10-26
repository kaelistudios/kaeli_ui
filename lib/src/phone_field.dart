import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'phone.dart';

/// Textos de [KaeliPhoneField]. Igual que [KaeliUiStrings]: solo se pasa lo que se quiere cambiar.
@immutable
class KaeliPhoneStrings {
  const KaeliPhoneStrings({
    this.country,
    this.sheetTitle,
    this.search,
    this.noResults,
    this.invalid,
    this.required,
    this.countryLabel,
    this.invalidLength,
    this.example,
  });

  /// Etiqueta del selector de país («País»).
  final String? country;

  /// Título de la hoja con los países.
  final String? sheetTitle;

  /// Pista del buscador.
  final String? search;

  /// Cuando la búsqueda no encuentra nada.
  final String? noResults;

  /// Error de un número con un largo que no es válido para el país.
  final String? invalid;

  /// Error de un campo obligatorio vacío.
  final String? required;

  /// Lo que anuncia el lector de pantalla en el selector: «País: {name}, +{dial}».
  final String? countryLabel;

  /// 0.12.0: largo equivocado para el país: «Un número de {country} tiene {digits} cifras».
  final String? invalidLength;

  /// 0.12.0: ayuda debajo del campo con un número de ejemplo del país elegido: «Por ejemplo: {number}».
  final String? example;

  static const Map<String, KaeliPhoneStrings> builtIn = {
    'es': KaeliPhoneStrings(
      country: 'País',
      sheetTitle: 'Código de país',
      search: 'Buscar país o código',
      noResults: 'Ningún país coincide con la búsqueda',
      invalid: 'Número no válido',
      required: 'Escribe un número de teléfono',
      countryLabel: 'País: {name}, +{dial}',
      invalidLength: 'Un número de {country} tiene {digits} cifras',
      example: 'Por ejemplo: {number}',
    ),
    'en': KaeliPhoneStrings(
      country: 'Country',
      sheetTitle: 'Country code',
      search: 'Search country or code',
      noResults: 'No country matches your search',
      invalid: 'Invalid number',
      required: 'Enter a phone number',
      countryLabel: 'Country: {name}, +{dial}',
      invalidLength: 'A {country} number has {digits} digits',
      example: 'For example: {number}',
    ),
    'fr': KaeliPhoneStrings(
      country: 'Pays',
      sheetTitle: 'Indicatif du pays',
      search: 'Rechercher un pays ou un indicatif',
      noResults: 'Aucun pays ne correspond à la recherche',
      invalid: 'Numéro non valide',
      required: 'Saisissez un numéro de téléphone',
      countryLabel: 'Pays : {name}, +{dial}',
      invalidLength: 'Un numéro ({country}) comporte {digits} chiffres',
      example: 'Par exemple : {number}',
    ),
    'pt': KaeliPhoneStrings(
      country: 'País',
      sheetTitle: 'Código do país',
      search: 'Buscar país ou código',
      noResults: 'Nenhum país corresponde à busca',
      invalid: 'Número inválido',
      required: 'Digite um número de telefone',
      countryLabel: 'País: {name}, +{dial}',
      invalidLength: 'Um número de {country} tem {digits} dígitos',
      example: 'Por exemplo: {number}',
    ),
  };

  /// Textos completos para [languageCode] (inglés si no está), con lo de [overrides] encima.
  static KaeliPhoneStrings resolve(String? languageCode, [KaeliPhoneStrings? overrides]) {
    final base = builtIn[languageCode] ?? builtIn['en']!;
    return KaeliPhoneStrings(
      country: overrides?.country ?? base.country,
      sheetTitle: overrides?.sheetTitle ?? base.sheetTitle,
      search: overrides?.search ?? base.search,
      noResults: overrides?.noResults ?? base.noResults,
      invalid: overrides?.invalid ?? base.invalid,
      required: overrides?.required ?? base.required,
      countryLabel: overrides?.countryLabel ?? base.countryLabel,
      invalidLength: overrides?.invalidLength ?? base.invalidLength,
      example: overrides?.example ?? base.example,
    );
  }
}

/// Teléfono con código de país, para todas las apps de Kaeli: a la izquierda la bandera y el código (🇨🇷 +506 ▾), que
/// abre una hoja con buscador; a la derecha solo el número, con teclado de teléfono.
///
/// - **Valor:** siempre el número completo en formato internacional E.164 («+50660895761»), al recibirlo
///   ([initialValue]) y al entregarlo ([onChanged], [onSaved]). Un número guardado se separa en país y número.
/// - **País al empezar:** el del número guardado; si no hay, el de la región del teléfono; si no se sabe,
///   [defaultCountry].
/// - **Pegar un número con +** en el campo del número cambia el país solo.
/// - **Validación:** largo mínimo y máximo del país; con [isRequired], no puede quedar vacío. Funciona dentro de un
///   `Form` / `KaeliForm` y con `kaeliValidateForm` (va al campo del número y lo enfoca). Para el asterisco:
///   `decoration: InputDecoration(label: KaeliRequiredLabel(l10n.phone))`.
///
/// ```dart
/// KaeliPhoneField(
///   initialValue: guest.phone,                 // «+50660895761» o null
///   defaultCountry: 'CR',
///   pinnedCountries: const ['CR', 'MX', 'US'],
///   isRequired: true,
///   decoration: InputDecoration(label: KaeliRequiredLabel(l10n.phone)),
///   onSaved: (e164) => guest = guest.copyWith(phone: e164),
/// )
/// ```
class KaeliPhoneField extends StatefulWidget {
  const KaeliPhoneField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.isRequired = false,
    this.decoration = const InputDecoration(),
    this.defaultCountry,
    this.preferredCountry,
    this.onCountryChanged,
    this.showExample = true,
    this.pinnedCountries = const [],
    this.strings,
    this.focusNode,
    this.textInputAction,
    this.enabled = true,
    this.autovalidateMode,
  });

  /// Número guardado en formato E.164 («+50660895761»), o null.
  final String? initialValue;

  /// Cada vez que cambia: el número E.164, o null si está vacío o todavía no es válido.
  final ValueChanged<String?>? onChanged;

  /// Al guardar el `Form`: el número E.164, o null si está vacío.
  final FormFieldSetter<String>? onSaved;

  /// Validación propia, además del largo (recibe el número E.164; solo se llama si el largo es válido).
  final FormFieldValidator<String>? validator;

  /// No puede quedar vacío.
  final bool isRequired;

  /// Decoración del campo del número (etiqueta, ayuda…). El borde y los colores salen del tema de la app; el selector
  /// de país usa el mismo borde.
  final InputDecoration decoration;

  /// País (ISO, «CR») si no hay número guardado ni se sabe la región del teléfono.
  final String? defaultCountry;

  /// País para un número NUEVO (sin número guardado), antes que la región del teléfono (0.11.0). P. ej. el país del
  /// negocio o de la propiedad: un huésped de un alojamiento de Costa Rica casi siempre empieza con +506.
  final String? preferredCountry;

  /// Cuando cambia el país del código (al elegirlo en la hoja o al pegar un número con «+»), con su ISO («CR»)
  /// (0.11.0). Sirve para llenar el país de la persona si está vacío.
  final ValueChanged<String>? onCountryChanged;

  /// 0.12.0: ayuda «Por ejemplo: 8888 7777» con el ejemplo del país elegido, si [decoration] no trae `helperText`.
  final bool showExample;

  /// Países fijos arriba de la lista (ISO, en este orden), p. ej. los más usados por la app.
  final List<String> pinnedCountries;

  final KaeliPhoneStrings? strings;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  /// Para pruebas: el selector de país, el campo del número y el buscador de la hoja.
  static const countryKey = Key('kaeliPhone.country');
  static const numberKey = Key('kaeliPhone.number');
  static const searchKey = Key('kaeliPhone.search');

  /// Fila de un país en la hoja («kaeliPhone.country.CR»).
  static Key countryTileKey(String iso) => Key('kaeliPhone.country.$iso');

  @override
  State<KaeliPhoneField> createState() => _KaeliPhoneFieldState();
}

/// Valor interno del campo cuando hay algo escrito pero no es un número válido.
const _invalid = '#invalid';

class _KaeliPhoneFieldState extends State<KaeliPhoneField> {
  final _field = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _text;
  KaeliPhoneCountry? _country;
  String? _initialFieldValue;
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  /// 0.12.0: el aviso del largo sale al salir del campo (o enseguida si ya se pasó de cifras), sin esperar a guardar.
  var _showLive = false;

  @override
  void initState() {
    super.initState();
    final split = kaeliSplitPhone(widget.initialValue);
    _country = split.country;
    _text = TextEditingController(text: split.country == null ? '' : split.national)..addListener(_onText);
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (!_focus.hasFocus && _text.text.trim().isNotEmpty && !_showLive) setState(() => _showLive = true);
  }

  /// Aviso del largo mientras se escribe (null si está bien o todavía no toca mostrarlo).
  String? get _liveError {
    final c = _country;
    if (c == null || _text.text.trim().isEmpty || _text.text.trim().startsWith('+')) return null;
    final digits = kaeliNationalDigits(_text.text, c).length;
    final tooLong = digits > c.max;
    if (!tooLong && !_showLive) return null;
    return kaeliToE164(_text.text, c) == null ? _lengthMessage(c) : null;
  }

  String _lengthMessage(KaeliPhoneCountry c) => (_texts.invalidLength ?? _texts.invalid!)
      .replaceAll('{country}', c.name(_languageCode))
      .replaceAll('{digits}', kaeliPhoneDigitsLabel(c));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_country != null) {
      _initialFieldValue ??= _currentValue();
      return;
    }
    _country =
        kaeliPhoneCountryOf(widget.preferredCountry) ??
        _regionCountry() ??
        kaeliPhoneCountryOf(widget.defaultCountry) ??
        (widget.pinnedCountries.isEmpty ? null : kaeliPhoneCountryOf(widget.pinnedCountries.first)) ??
        kaeliPhoneCountryOf('US');
    _initialFieldValue ??= _currentValue();
  }

  /// País de la región del teléfono (ajustes del sistema) o, si no tiene, del idioma de la app («es_CR»).
  KaeliPhoneCountry? _regionCountry() {
    for (final l in WidgetsBinding.instance.platformDispatcher.locales) {
      final c = kaeliPhoneCountryOf(l.countryCode);
      if (c != null) return c;
    }
    return kaeliPhoneCountryOf(Localizations.maybeLocaleOf(context)?.countryCode);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    _text.dispose();
    super.dispose();
  }

  String? get _languageCode => Localizations.maybeLocaleOf(context)?.languageCode;

  KaeliPhoneStrings get _texts => KaeliPhoneStrings.resolve(_languageCode, widget.strings);

  /// '' vacío · E.164 válido · [_invalid].
  String _currentValue() {
    if (_text.text.trim().isEmpty) return '';
    return kaeliToE164(_text.text, _country!) ?? _invalid;
  }

  var _adjusting = false;

  void _onText() {
    if (_adjusting) return;
    // Pegó (o escribió completo) un número con su código: se cambia el país y queda solo el número nacional.
    final t = _text.text.trim();
    if (t.startsWith('+') || t.startsWith('00')) {
      final c = kaeliCountryFromPhone(t);
      if (c != null) {
        final national = kaeliToE164(t, c) == null ? null : kaeliSplitPhone(kaeliToE164(t, c)).national;
        if (national != null) {
          _adjusting = true;
          final changed = c != _country;
          setState(() => _country = c);
          if (changed) widget.onCountryChanged?.call(c.iso);
          _text.value = TextEditingValue(
            text: national,
            selection: TextSelection.collapsed(offset: national.length),
          );
          _adjusting = false;
        }
      }
    }
    _notify();
  }

  void _notify() {
    final value = _currentValue();
    if (_field.currentState?.value != value) _field.currentState?.didChange(value);
    widget.onChanged?.call(value.startsWith('+') ? value : null);
  }

  String? _validate(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return widget.isRequired ? _texts.required : null;
    if (v == _invalid) return _lengthMessage(_country!);
    return widget.validator?.call(v);
  }

  Future<void> _pickCountry() async {
    final chosen = await showModalBottomSheet<KaeliPhoneCountry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CountrySheet(
        selected: _country!,
        pinned: [for (final iso in widget.pinnedCountries) ?kaeliPhoneCountryOf(iso)],
        texts: _texts,
        languageCode: _languageCode,
      ),
    );
    if (chosen == null || !mounted || chosen == _country) return;
    setState(() => _country = chosen);
    widget.onCountryChanged?.call(chosen.iso);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final texts = _texts;
    final country = _country!;
    final theme = Theme.of(context);
    final d = widget.decoration;
    return FormField<String>(
      key: _field,
      initialValue: _initialFieldValue,
      enabled: widget.enabled,
      autovalidateMode: widget.autovalidateMode,
      validator: _validate,
      onSaved: (v) => widget.onSaved?.call((v ?? '').startsWith('+') ? v : null),
      builder: (field) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            enabled: widget.enabled,
            label: texts.countryLabel!
                .replaceAll('{name}', country.name(_languageCode))
                .replaceAll('{dial}', country.dial),
            excludeSemantics: true,
            child: InkWell(
              key: KaeliPhoneField.countryKey,
              onTap: widget.enabled ? _pickCountry : null,
              borderRadius: BorderRadius.circular(4),
              child: IntrinsicWidth(
                child: InputDecorator(
                  // El mismo borde, relleno y tamaño que el campo del número; la etiqueta siempre arriba.
                  decoration: InputDecoration(
                    labelText: texts.country,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    enabled: widget.enabled,
                    border: d.border,
                    enabledBorder: d.enabledBorder,
                    focusedBorder: d.focusedBorder,
                    disabledBorder: d.disabledBorder,
                    filled: d.filled,
                    fillColor: d.fillColor,
                    isDense: d.isDense,
                    contentPadding: d.contentPadding,
                    // Mismo alto que el número cuando este lleva ayuda debajo (0.12.0: el ejemplo del país).
                    helperText: (d.helperText != null || widget.showExample) ? ' ' : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(country.flag, style: theme.textTheme.titleMedium),
                      const SizedBox(width: 6),
                      Text('+${country.dial}', style: theme.textTheme.bodyLarge),
                      Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: KaeliPhoneField.numberKey,
              controller: _text,
              focusNode: _focus,
              enabled: widget.enabled,
              keyboardType: TextInputType.phone,
              textInputAction: widget.textInputAction,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-. ]')),
                // 0.12.0: con los espacios del país mientras se escribe («8555 3333»).
                _TypingFormatter(() => _country),
              ],
              decoration: d.copyWith(
                errorText: field.errorText ?? _liveError,
                // 0.12.0: un número de ejemplo del país elegido (si la app no puso su propia ayuda).
                hintText: d.hintText ?? kaeliPhoneExample(country),
                helperText:
                    d.helperText ??
                    (widget.showExample ? texts.example?.replaceAll('{number}', kaeliPhoneExample(country)) : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected, required this.pinned, required this.texts, required this.languageCode});

  final KaeliPhoneCountry selected;
  final List<KaeliPhoneCountry> pinned;
  final KaeliPhoneStrings texts;
  final String? languageCode;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  var _query = '';
  late final _all = kaeliSortPhoneCountries(kaeliPhoneCountries, widget.languageCode);

  Widget _tile(KaeliPhoneCountry c, {bool pinned = false}) => ListTile(
    key: pinned ? Key('kaeliPhone.pinned.${c.iso}') : KaeliPhoneField.countryTileKey(c.iso),
    leading: Text(c.flag, style: Theme.of(context).textTheme.titleLarge),
    title: Text(c.name(widget.languageCode)),
    trailing: Text('+${c.dial}'),
    selected: c == widget.selected,
    onTap: () => Navigator.of(context).pop(c),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = kaeliSearchPhoneCountries(_query, widget.languageCode, _all);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(widget.texts.sheetTitle!, style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: KaeliPhoneField.searchKey,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(hintText: widget.texts.search, prefixIcon: const Icon(Icons.search)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          widget.texts.noResults!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        if (_query.trim().isEmpty && widget.pinned.isNotEmpty) ...[
                          for (final c in widget.pinned) _tile(c, pinned: true),
                          const Divider(),
                        ],
                        for (final c in results) _tile(c),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pone los espacios del país mientras se escribe (no toca un número que empieza con «+» o «00»: ese lo separa el campo).
class _TypingFormatter extends TextInputFormatter {
  _TypingFormatter(this.country);

  final KaeliPhoneCountry? Function() country;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final c = country();
    final t = newValue.text.trimLeft();
    if (c == null || t.startsWith('+') || t.startsWith('00')) return newValue;
    final formatted = kaeliFormatTyping(newValue.text, c);
    if (formatted == newValue.text) return newValue;
    // El cursor queda después de la misma cantidad de cifras que tenía.
    final before = newValue.text.substring(0, newValue.selection.end.clamp(0, newValue.text.length));
    final digitsBefore = before.replaceAll(RegExp(r'\D'), '').length;
    var pos = 0;
    var seen = 0;
    while (pos < formatted.length && seen < digitsBefore) {
      if (RegExp(r'\d').hasMatch(formatted[pos])) seen++;
      pos++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: pos),
    );
  }
}
