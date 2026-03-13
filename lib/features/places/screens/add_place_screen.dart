import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../../trips/models/trip_model.dart';
import '../models/place_model.dart';
import '../providers/place_provider.dart';
import '../widgets/place_form_map_picker.dart';

// Links are stored as "label:::url" inside List<String> links.
const _linkSep = ':::';

class AddPlaceScreen extends StatefulWidget {
  final PlaceModel? existing;
  const AddPlaceScreen({super.key, this.existing});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _horarioCtrl;
  late final TextEditingController _comentariosCtrl;
  late final TextEditingController _costoCtrl;
  final _tagCtrl = TextEditingController();

  late String _tipo;
  late String _estado;
  late int _dia;

  double? _lat;
  double? _lng;

  late int _horas;
  late int _minutos;
  late List<String> _tags;
  late double _calificacion;
  late List<_LinkEntry> _links;

  bool _saving = false;

  TripModel? get _activeTrip => TripProvider.instance.getActiveTrip();
  int get _tripDays => _activeTrip?.duracionDias ?? 7;
  String get _moneda => _activeTrip?.moneda ?? 'USD';

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _horarioCtrl = TextEditingController(text: p?.horario ?? '');
    _comentariosCtrl = TextEditingController(text: p?.comentarios ?? '');
    _costoCtrl = TextEditingController(
      text: (p?.costoEstimado ?? 0) > 0
          ? p!.costoEstimado.toStringAsFixed(0)
          : '',
    );
    _tipo = p?.tipo ?? PlaceType.attraction;
    _estado = p?.estado ?? PlaceStatus.pending;
    _dia = p?.dia ?? 1;
    _lat = (p != null && p.latitud != 0) ? p.latitud : null;
    _lng = (p != null && p.longitud != 0) ? p.longitud : null;
    final totalMin = p?.tiempoEstimadoMin ?? 60;
    _horas = totalMin ~/ 60;
    _minutos = totalMin % 60;
    _tags = List<String>.from(p?.tags ?? []);
    _calificacion = p?.calificacion ?? 0;
    _links = (p?.links ?? []).map((raw) {
      final parts = raw.split(_linkSep);
      return _LinkEntry(
        label: parts.length > 1 ? parts[0] : '',
        url: parts.length > 1 ? parts[1] : parts[0],
      );
    }).toList();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _horarioCtrl.dispose();
    _comentariosCtrl.dispose();
    _costoCtrl.dispose();
    _tagCtrl.dispose();
    for (final l in _links) {
      l.dispose();
    }
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar lugar' : 'Nuevo lugar'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Nombre ─────────────────────────────────────────────────────
            const _SectionLabel('Información básica'),
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
            const _SectionLabel('Tipo de lugar *'),
            const SizedBox(height: 10),
            _TypeSelector(
              selected: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
            const SizedBox(height: 24),

            // ── Planificación ───────────────────────────────────────────────
            const _SectionLabel('Planificación'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20),
                const SizedBox(width: 10),
                const Text('Día asignado', style: TextStyle(fontSize: 15)),
                const Spacer(),
                DropdownButton<int>(
                  value: _dia.clamp(1, _tripDays),
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: List.generate(
                    _tripDays,
                    (i) {
                      final base = _activeTrip?.fechaInicio;
                      final label = base != null
                          ? 'Día ${i + 1} — ${DateFormat('EEE d MMM', 'es').format(base.add(Duration(days: i)))}'
                          : 'Día ${i + 1}';
                      return DropdownMenuItem(value: i + 1, child: Text(label));
                    },
                  ),
                  onChanged: (v) => setState(() => _dia = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Estado', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            _StatusSelector(
              selected: _estado,
              onChanged: (s) => setState(() => _estado = s),
            ),
            const SizedBox(height: 24),

            // ── Ubicación ───────────────────────────────────────────────────
            const _SectionLabel('Ubicación'),
            const SizedBox(height: 12),
            if (_lat != null && _lng != null) ...[
              _CoordCard(lat: _lat!, lng: _lng!),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(
                      _lat == null ? 'Seleccionar en mapa' : 'Cambiar en mapa',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text(
                      'Mi ubicación',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Costo estimado ──────────────────────────────────────────────
            const _SectionLabel('Costo estimado'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costoCtrl,
              decoration: InputDecoration(
                labelText: 'Costo estimado (opcional)',
                hintText: '0',
                prefixIcon: const Icon(Icons.attach_money_outlined),
                suffixText: _moneda,
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

            // ── Tiempo estimado ─────────────────────────────────────────────
            const _SectionLabel('Tiempo estimado'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 20),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _horas,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: List.generate(
                    24,
                    (i) => DropdownMenuItem(value: i, child: Text('${i}h')),
                  ),
                  onChanged: (v) => setState(() => _horas = v!),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _minutos,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: [0, 15, 30, 45]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('${m}min'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _minutos = v!),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Horario ─────────────────────────────────────────────────────
            const _SectionLabel('Horario de apertura'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _horarioCtrl,
              decoration: const InputDecoration(
                labelText: 'Horario (opcional)',
                hintText: 'Ej: 9:00 - 18:00',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ── Tags ────────────────────────────────────────────────────────
            const _SectionLabel('Tags'),
            const SizedBox(height: 12),
            _TagsField(
              tags: _tags,
              controller: _tagCtrl,
              onAdd: (tag) => setState(() => _tags.add(tag)),
              onRemove: (tag) => setState(() => _tags.remove(tag)),
            ),
            const SizedBox(height: 24),

            // ── Calificación ────────────────────────────────────────────────
            const _SectionLabel('Calificación'),
            const SizedBox(height: 8),
            _StarRating(
              value: _calificacion,
              onChanged: (v) => setState(() => _calificacion = v),
            ),
            const SizedBox(height: 24),

            // ── Comentarios ─────────────────────────────────────────────────
            const _SectionLabel('Comentarios'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _comentariosCtrl,
              decoration: const InputDecoration(
                labelText: 'Comentarios (opcional)',
                hintText: 'Notas, recomendaciones...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Links ───────────────────────────────────────────────────────
            const _SectionLabel('Links útiles'),
            const SizedBox(height: 12),
            _LinksField(
              links: _links,
              onAdd: () => setState(() => _links.add(_LinkEntry())),
              onRemove: (i) => setState(() => _links.removeAt(i)),
            ),
            const SizedBox(height: 40),

            // ── Save ────────────────────────────────────────────────────────
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
                    : const Icon(Icons.check),
                label: Text(isEdit ? 'Guardar cambios' : 'Crear lugar'),
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
      MaterialPageRoute(
        builder: (_) => PlaceFormMapPicker(initial: initial),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = result.latlng.latitude;
        _lng = result.latlng.longitude;
        // Pre-fill name if still empty and Nominatim returned a name
        if (_nombreCtrl.text.trim().isEmpty &&
            result.placeName != null &&
            result.placeName!.isNotEmpty) {
          _nombreCtrl.text = result.placeName!;
        }
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado permanentemente.\n'
            'Habilítalo en Configuración del dispositivo.');
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener la ubicación: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final trip = _activeTrip;
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un viaje activo primero'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final costo = double.tryParse(_costoCtrl.text.trim()) ?? 0.0;
    final linksList = _links
        .where((l) => l.url.trim().isNotEmpty)
        .map((l) => '${l.label.trim()}$_linkSep${l.url.trim()}')
        .toList();

    if (widget.existing != null) {
      final p = widget.existing!;
      p.nombre = _nombreCtrl.text.trim();
      p.tipo = _tipo;
      p.dia = _dia;
      p.estado = _estado;
      p.latitud = _lat ?? 0;
      p.longitud = _lng ?? 0;
      p.costoEstimado = costo;
      p.tiempoEstimadoMin = _horas * 60 + _minutos;
      p.horario = _horarioCtrl.text.trim();
      p.tags = _tags;
      p.calificacion = _calificacion;
      p.comentarios = _comentariosCtrl.text.trim();
      p.links = linksList;
      await PlaceProvider.instance.updatePlace(p);
    } else {
      final place = PlaceModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: trip.id,
        nombre: _nombreCtrl.text.trim(),
        tipo: _tipo,
        latitud: _lat ?? 0,
        longitud: _lng ?? 0,
        dia: _dia,
        estado: _estado,
        costoEstimado: costo,
        tiempoEstimadoMin: _horas * 60 + _minutos,
        horario: _horarioCtrl.text.trim(),
        tags: _tags,
        calificacion: _calificacion,
        comentarios: _comentariosCtrl.text.trim(),
        links: linksList,
      );
      await PlaceProvider.instance.addPlace(place);
    }

    if (mounted) Navigator.of(context).pop();
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

// ── Type selector ─────────────────────────────────────────────────────────────

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Icon(
                  PlaceType.icon(type),
                  size: 16,
                  color: isSelected ? Colors.white : color,
                ),
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

// ── Status selector ───────────────────────────────────────────────────────────

class _StatusItem {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatusItem(this.value, this.label, this.icon, this.color);
}

class _StatusSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  static const _statuses = [
    _StatusItem(PlaceStatus.pending, 'Pendiente',
        Icons.radio_button_unchecked, Color(0xFF757575)),
    _StatusItem('confirmed', 'Confirmado',
        Icons.check_circle_outline, Color(0xFF1565C0)),
    _StatusItem(PlaceStatus.visited, 'Visitado',
        Icons.check_circle, Color(0xFF2E7D32)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _statuses.map((s) {
        final isSelected = selected == s.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(s.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? s.color.withAlpha(30) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? s.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(s.icon,
                        color: isSelected ? s.color : Colors.grey, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected ? s.color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Coord card ────────────────────────────────────────────────────────────────

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
                fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Tags field ────────────────────────────────────────────────────────────────

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
                  hintText: 'Añadir tag...',
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

// ── Star rating ───────────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _StarRating({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Row(
      children: List.generate(5, (i) {
        final starValue = (i + 1).toDouble();
        return GestureDetector(
          onTap: () => onChanged(value == starValue ? 0 : starValue),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              i < value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < value ? color : Colors.grey.shade400,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}

// ── Link entry + field ────────────────────────────────────────────────────────

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
