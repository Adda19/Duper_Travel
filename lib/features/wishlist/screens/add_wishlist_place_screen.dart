import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../places/widgets/place_form_map_picker.dart';
import '../models/wishlist_place_model.dart';
import '../providers/wishlist_provider.dart';

const _linkSep = ':::';

class AddWishlistPlaceScreen extends StatefulWidget {
  final WishlistPlaceModel? existing;
  const AddWishlistPlaceScreen({super.key, this.existing});

  @override
  State<AddWishlistPlaceScreen> createState() => _AddWishlistPlaceScreenState();
}

class _AddWishlistPlaceScreenState extends State<AddWishlistPlaceScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _paisCtrl;
  late final TextEditingController _horarioCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _comentariosCtrl;
  late final TextEditingController _linkPublicacionCtrl;
  final _tagCtrl = TextEditingController();

  late String _tipo;
  late String _fuente;
  late List<String> _tags;
  late List<_LinkEntry> _links;

  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _ciudadCtrl = TextEditingController(text: p?.ciudad ?? '');
    _paisCtrl = TextEditingController(text: p?.pais ?? '');
    _horarioCtrl = TextEditingController(text: p?.horario ?? '');
    _costoCtrl = TextEditingController(
      text: (p?.costoEstimado ?? 0) > 0
          ? p!.costoEstimado.toStringAsFixed(0)
          : '',
    );
    _comentariosCtrl = TextEditingController(text: p?.comentarios ?? '');
    _linkPublicacionCtrl = TextEditingController();
    _tipo = p?.tipo ?? PlaceType.attraction;
    _fuente = p?.fuente ?? WishlistSource.other;
    _tags = List<String>.from(p?.tags ?? []);
    _links = (p?.links ?? []).map((raw) {
      final parts = raw.split(_linkSep);
      return _LinkEntry(
        label: parts.length > 1 ? parts[0] : '',
        url: parts.length > 1 ? parts[1] : parts[0],
      );
    }).toList();
    if (p != null && p.latitud != 0) {
      _lat = p.latitud;
      _lng = p.longitud;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    _paisCtrl.dispose();
    _horarioCtrl.dispose();
    _costoCtrl.dispose();
    _comentariosCtrl.dispose();
    _linkPublicacionCtrl.dispose();
    _tagCtrl.dispose();
    for (final l in _links) {
      l.dispose();
    }
    super.dispose();
  }

  // ── Nominatim city search ──────────────────────────────────────────────────

  Future<List<_CityResult>> _searchCity(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=6&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'TripPlannerApp/1.0'},
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return [];
      final List data = jsonDecode(response.body);
      final results = <_CityResult>[];
      for (final e in data) {
        final addr = e['address'] as Map<String, dynamic>? ?? {};
        final city = (addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['municipality'] ??
                '') as String;
        final country = (addr['country'] ?? '') as String;
        if (city.isNotEmpty) {
          results.add(_CityResult(
            display: '$city, $country',
            city: city,
            country: country,
          ));
        } else if (country.isNotEmpty) {
          // fallback to display name first segment
          final display = (e['display_name'] as String? ?? '');
          final seg = display.split(',').first.trim();
          results.add(_CityResult(
            display: display.length > 60
                ? '${display.substring(0, 60)}…'
                : display,
            city: seg,
            country: country,
          ));
        }
      }
      // Deduplicate
      final seen = <String>{};
      return results.where((r) => seen.add(r.display)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar lugar' : 'Nuevo lugar por visitar'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Nombre ──────────────────────────────────────────────────────
            _SectionLabel('Información básica'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del lugar *',
                hintText: 'Ej: Torre Eiffel',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 24),

            // ── Tipo ────────────────────────────────────────────────────────
            _SectionLabel('Tipo de lugar *'),
            const SizedBox(height: 10),
            _TypeSelector(
              selected: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
            const SizedBox(height: 24),

            // ── Fuente ──────────────────────────────────────────────────────
            _SectionLabel('¿Dónde lo descubriste?'),
            const SizedBox(height: 10),
            _SourceSelector(
              selected: _fuente,
              onChanged: (s) => setState(() => _fuente = s),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkPublicacionCtrl,
              decoration: const InputDecoration(
                labelText: 'Link de publicación (opcional)',
                hintText: 'https://instagram.com/...',
                prefixIcon: Icon(Icons.link_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // ── Ciudad / País ────────────────────────────────────────────────
            _SectionLabel('Ciudad y país'),
            const SizedBox(height: 12),
            TypeAheadField<_CityResult>(
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  hintText: 'Buscar ciudad...',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => _ciudadCtrl.text = v,
              ),
              controller: _ciudadCtrl,
              suggestionsCallback: _searchCity,
              debounceDuration: const Duration(milliseconds: 500),
              itemBuilder: (context, result) => ListTile(
                dense: true,
                leading: const Icon(Icons.location_city_outlined, size: 18),
                title: Text(result.display, style: const TextStyle(fontSize: 13)),
              ),
              onSelected: (result) {
                setState(() {
                  _ciudadCtrl.text = result.city;
                  _paisCtrl.text = result.country;
                });
                FocusScope.of(context).unfocus();
              },
              emptyBuilder: (_) => const SizedBox.shrink(),
              loadingBuilder: (_) => const LinearProgressIndicator(minHeight: 2),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paisCtrl,
              decoration: const InputDecoration(
                labelText: 'País',
                hintText: 'Se autocompleta al elegir ciudad',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // ── Ubicación en mapa ────────────────────────────────────────────
            _SectionLabel('Ubicación exacta (opcional)'),
            const SizedBox(height: 12),
            if (_lat != null && _lng != null) ...[
              _CoordCard(lat: _lat!, lng: _lng!),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map_outlined),
              label: Text(_lat == null
                  ? 'Marcar en el mapa'
                  : 'Cambiar en el mapa'),
            ),
            const SizedBox(height: 24),

            // ── Horario ──────────────────────────────────────────────────────
            _SectionLabel('Horario (opcional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _horarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Horario',
                hintText: 'Ej: Lun–Dom 9:00–18:00',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ── Costo estimado ───────────────────────────────────────────────
            _SectionLabel('Costo estimado (opcional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costoCtrl,
              decoration: const InputDecoration(
                labelText: 'Costo estimado',
                hintText: '0',
                prefixIcon: Icon(Icons.attach_money_outlined),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Tags ─────────────────────────────────────────────────────────
            _SectionLabel('Etiquetas'),
            const SizedBox(height: 12),
            _TagsField(
              tags: _tags,
              controller: _tagCtrl,
              onAdd: (t) => setState(() => _tags.add(t)),
              onRemove: (t) => setState(() => _tags.remove(t)),
            ),
            const SizedBox(height: 24),

            // ── Comentarios ──────────────────────────────────────────────────
            _SectionLabel('Comentarios (opcional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _comentariosCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas, recomendaciones...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Links ────────────────────────────────────────────────────────
            _SectionLabel('Links útiles'),
            const SizedBox(height: 12),
            _LinksField(
              links: _links,
              onAdd: () => setState(() => _links.add(_LinkEntry())),
              onRemove: (i) => setState(() => _links.removeAt(i)),
            ),
            const SizedBox(height: 40),

            // ── Save ─────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.favorite),
                label: Text(isEdit ? 'Guardar cambios' : 'Guardar en wishlist'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _openMapPicker() async {
    final initial =
        (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null;
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(builder: (_) => PlaceFormMapPicker(initial: initial)),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = result.latlng.latitude;
        _lng = result.latlng.longitude;
        if (_nombreCtrl.text.trim().isEmpty &&
            result.placeName != null &&
            result.placeName!.isNotEmpty) {
          _nombreCtrl.text = result.placeName!;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final costo = double.tryParse(_costoCtrl.text.trim()) ?? 0.0;
    var linksList = _links
        .where((l) => l.url.trim().isNotEmpty)
        .map((l) => '${l.label.trim()}$_linkSep${l.url.trim()}')
        .toList();

    // Prepend the publication link if provided
    final pubLink = _linkPublicacionCtrl.text.trim();
    if (pubLink.isNotEmpty && widget.existing == null) {
      linksList = ['${_fuente}$_linkSep$pubLink', ...linksList];
    }

    if (widget.existing != null) {
      final p = widget.existing!;
      p.nombre = _nombreCtrl.text.trim();
      p.tipo = _tipo;
      p.fuente = _fuente;
      p.ciudad = _ciudadCtrl.text.trim();
      p.pais = _paisCtrl.text.trim();
      p.latitud = _lat ?? 0;
      p.longitud = _lng ?? 0;
      p.horario = _horarioCtrl.text.trim();
      p.costoEstimado = costo;
      p.tags = _tags;
      p.comentarios = _comentariosCtrl.text.trim();
      p.links = linksList;
      await WishlistProvider.instance.updatePlace(p);
    } else {
      final place = WishlistPlaceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreCtrl.text.trim(),
        tipo: _tipo,
        fuente: _fuente,
        ciudad: _ciudadCtrl.text.trim(),
        pais: _paisCtrl.text.trim(),
        latitud: _lat ?? 0,
        longitud: _lng ?? 0,
        horario: _horarioCtrl.text.trim(),
        costoEstimado: costo,
        tags: _tags,
        comentarios: _comentariosCtrl.text.trim(),
        links: linksList,
        fechaGuardado: DateTime.now(),
      );
      await WishlistProvider.instance.addPlace(place);
    }

    if (mounted) Navigator.of(context).pop();
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _CityResult {
  final String display;
  final String city;
  final String country;
  const _CityResult(
      {required this.display, required this.city, required this.country});
}

class _LinkEntry {
  final TextEditingController labelCtrl;
  final TextEditingController urlCtrl;
  _LinkEntry({String label = '', String url = ''})
      : labelCtrl = TextEditingController(text: label),
        urlCtrl = TextEditingController(text: url);
  String get label => labelCtrl.text;
  String get url => urlCtrl.text;
  void dispose() {
    labelCtrl.dispose();
    urlCtrl.dispose();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlaceType.all.map((type) {
        final isSelected = selected == type;
        final color = PlaceTypeColor.of(type);
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : color.withAlpha(80),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PlaceType.icon(type),
                    size: 16,
                    color: isSelected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  PlaceType.label(type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SourceSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _SourceSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WishlistSource.all.map((source) {
        final isSelected = selected == source;
        return GestureDetector(
          onTap: () => onChanged(source),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.secondary
                  : cs.secondary.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? cs.secondary
                    : cs.secondary.withAlpha(80),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(WishlistSource.icon(source),
                    size: 16,
                    color: isSelected ? Colors.white : cs.secondary),
                const SizedBox(width: 6),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : cs.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CoordCard extends StatelessWidget {
  final double lat;
  final double lng;
  const _CoordCard({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    final textColor = Theme.of(context).colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.location_pin, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TagsField extends StatelessWidget {
  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _TagsField({
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => onRemove(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(fontSize: 13),
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Añadir etiqueta...',
                  prefixIcon: Icon(Icons.label_outline),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (v) {
                  final tag = v.trim();
                  if (tag.isNotEmpty && !tags.contains(tag)) {
                    onAdd(tag);
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty && !tags.contains(tag)) {
                  onAdd(tag);
                  controller.clear();
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinksField extends StatelessWidget {
  final List<_LinkEntry> links;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _LinksField({
    required this.links,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...links.asMap().entries.map((entry) {
          final i = entry.key;
          final link = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: link.labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Etiqueta',
                      hintText: 'Ej: Sitio web',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: link.urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://...',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_link),
            label: const Text('Agregar link'),
          ),
        ),
      ],
    );
  }
}
