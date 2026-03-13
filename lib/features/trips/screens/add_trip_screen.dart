import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../models/trip_model.dart';

class AddTripScreen extends StatefulWidget {
  /// Pass an existing trip to edit it; null means create new.
  final TripModel? existing;

  const AddTripScreen({super.key, this.existing});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _destinoSearchCtrl;
  late final TextEditingController _presupuestoCtrl;

  late List<String> _destinos;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late int _personas;
  late String _moneda;
  late String _tipoTransporte;
  TimeOfDay? _horaSalida;

  bool _saving = false;

  static const _currencies = ['USD', 'EUR', 'COP', 'MXN', 'ARS'];

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _nombreCtrl = TextEditingController(text: t?.nombre ?? '');
    _destinoSearchCtrl = TextEditingController();
    _presupuestoCtrl = TextEditingController(
      text: (t?.presupuestoTotal ?? 0) > 0
          ? (t!.presupuestoTotal.toStringAsFixed(0))
          : '',
    );
    _destinos = List<String>.from(t?.destinos ?? []);
    _fechaInicio = t?.fechaInicio ?? DateTime.now();
    _fechaFin = t?.fechaFin ?? DateTime.now().add(const Duration(days: 7));
    _personas = t?.numeroPersonas ?? 1;
    _moneda = (t?.moneda != null && _currencies.contains(t!.moneda))
        ? t.moneda
        : 'USD';
    _tipoTransporte = t?.tipoTransporte ?? 'vuelo';
    final h = t?.horaSalida;
    _horaSalida = h != null ? TimeOfDay(hour: h.hour, minute: h.minute) : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _destinoSearchCtrl.dispose();
    _presupuestoCtrl.dispose();
    super.dispose();
  }

  // ── Nominatim search ────────────────────────────────────────────────────────

  Future<List<String>> _searchDestinos(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(q)}&format=json&limit=5'
        '&featuretype=city&featuretype=country',
      );
      final response = await http
          .get(uri, headers: {
            'User-Agent': 'TripPlannerApp/1.0',
            'Accept-Language': 'es,en',
          })
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<String>((e) {
          final parts = (e['display_name'] as String).split(',');
          return parts.take(2).map((s) => s.trim()).join(', ');
        }).toList();
      }
    } catch (_) {
      // No internet or timeout
    }
    return [];
  }

  void _addDestino(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _destinos.contains(trimmed)) return;
    setState(() => _destinos.add(trimmed));
    _destinoSearchCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _removeDestino(String name) {
    setState(() => _destinos.remove(name));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar viaje' : 'Nuevo viaje'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SectionLabel('Información básica'),
            const SizedBox(height: 12),

            // Nombre
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del viaje *',
                hintText: 'Ej: Vacaciones Europa 2025',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Destinos
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Typeahead search field
                TypeAheadField<String>(
                  controller: _destinoSearchCtrl,
                  debounceDuration: const Duration(milliseconds: 500),
                  suggestionsCallback: _searchDestinos,
                  builder: (context, controller, focusNode) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Destinos *',
                        hintText: 'Buscar ciudad o país...',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.add_circle_outlined),
                                tooltip: 'Agregar destino',
                                onPressed: () =>
                                    _addDestino(controller.text),
                              )
                            : null,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onFieldSubmitted: (v) {
                        if (v.trim().isNotEmpty) _addDestino(v);
                      },
                      validator: (_) => _destinos.isEmpty
                          ? 'Agrega al menos un destino'
                          : null,
                    );
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: Icon(Icons.location_on_outlined,
                          color: cs.primary, size: 20),
                      title: Text(suggestion,
                          style: const TextStyle(fontSize: 14)),
                    );
                  },
                  onSelected: _addDestino,
                  loadingBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Buscando...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  emptyBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Sin resultados',
                        style: TextStyle(fontSize: 13)),
                  ),
                  errorBuilder: (context, error) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Error al buscar. Verifica tu conexión.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),

                // Chips for selected destinations
                if (_destinos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _destinos
                        .map((d) => Chip(
                              label: Text(d,
                                  style: const TextStyle(fontSize: 13)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeDestino(d),
                              backgroundColor: cs.primaryContainer,
                              labelStyle:
                                  TextStyle(color: cs.onPrimaryContainer),
                              deleteIconColor: cs.onPrimaryContainer,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),

            const _SectionLabel('Fechas'),
            const SizedBox(height: 12),

            // Fecha inicio
            _DateField(
              label: 'Fecha de inicio',
              icon: Icons.flight_takeoff,
              date: _fechaInicio,
              onPicked: (d) {
                setState(() {
                  _fechaInicio = d;
                  if (_fechaFin.isBefore(_fechaInicio)) {
                    _fechaFin = _fechaInicio.add(const Duration(days: 1));
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            // Fecha fin
            _DateField(
              label: 'Fecha de regreso',
              icon: Icons.flight_land,
              date: _fechaFin,
              firstDate: _fechaInicio,
              onPicked: (d) => setState(() => _fechaFin = d),
            ),

            // Duración calculada
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _duracionLabel(),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 28),

            const _SectionLabel('Transporte'),
            const SizedBox(height: 12),

            // Tipo de transporte
            _TransportSelector(
              selected: _tipoTransporte,
              onChanged: (t) => setState(() => _tipoTransporte = t),
            ),
            const SizedBox(height: 16),

            // Hora de salida
            _TimePickerField(
              time: _horaSalida,
              onPicked: (t) => setState(() => _horaSalida = t),
              onCleared: () => setState(() => _horaSalida = null),
            ),
            const SizedBox(height: 28),

            const _SectionLabel('Detalles'),
            const SizedBox(height: 16),

            // Número de personas
            Row(
              children: [
                const Icon(Icons.group_outlined, size: 20),
                const SizedBox(width: 10),
                const Text('Personas', style: TextStyle(fontSize: 15)),
                const Spacer(),
                _Stepper(
                  value: _personas,
                  min: 1,
                  max: 50,
                  onChanged: (v) => setState(() => _personas = v),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Moneda
            Row(
              children: [
                const Icon(Icons.currency_exchange_outlined, size: 20),
                const SizedBox(width: 10),
                const Text('Moneda', style: TextStyle(fontSize: 15)),
                const Spacer(),
                DropdownButton<String>(
                  value: _moneda,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _moneda = v!),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Presupuesto
            TextFormField(
              controller: _presupuestoCtrl,
              decoration: InputDecoration(
                labelText: 'Presupuesto total (opcional)',
                hintText: '0',
                prefixIcon: const Icon(Icons.savings_outlined),
                suffixText: _moneda,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.trim());
                if (n == null || n < 0) return 'Ingresa un número válido';
                return null;
              },
            ),
            const SizedBox(height: 40),

            // Guardar
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
                label: Text(isEdit ? 'Guardar cambios' : 'Crear viaje'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Logic ───────────────────────────────────────────────────────────────────

  String _duracionLabel() {
    final dias = _fechaFin.difference(_fechaInicio).inDays + 1;
    return '$dias ${dias == 1 ? 'día' : 'días'} de viaje';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final box = Hive.box<TripModel>(HiveBoxes.trips);
    final presupuesto =
        double.tryParse(_presupuestoCtrl.text.trim()) ?? 0.0;

    if (widget.existing != null) {
      final trip = widget.existing!;
      trip.nombre = _nombreCtrl.text.trim();
      trip.destinos = List<String>.from(_destinos);
      trip.fechaInicio = _fechaInicio;
      trip.fechaFin = _fechaFin;
      trip.numeroPersonas = _personas;
      trip.moneda = _moneda;
      trip.presupuestoTotal = presupuesto;
      trip.tipoTransporte = _tipoTransporte;
      trip.horaSalida = _horaSalida != null
          ? DateTime(2000, 1, 1, _horaSalida!.hour, _horaSalida!.minute)
          : null;
      await trip.save();

      final active = TripProvider.instance.activeTrip.value;
      if (active?.id == trip.id) {
        TripProvider.instance.activeTrip.value = trip;
      }
    } else {
      final trip = TripModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreCtrl.text.trim(),
        destinos: List<String>.from(_destinos),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        numeroPersonas: _personas,
        moneda: _moneda,
        presupuestoTotal: presupuesto,
        tipoTransporte: _tipoTransporte,
        horaSalida: _horaSalida != null
            ? DateTime(2000, 1, 1, _horaSalida!.hour, _horaSalida!.minute)
            : null,
      );
      await box.put(trip.id, trip);
      if (box.length == 1) {
        await TripProvider.instance.setActiveTrip(trip);
      }
    }

    if (mounted) Navigator.of(context).pop();
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

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
            letterSpacing: 0.5,
          ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime date;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPicked;

  const _DateField({
    required this.label,
    required this.icon,
    required this.date,
    required this.onPicked,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatted =
        '${date.day.toString().padLeft(2, '0')} / '
        '${date.month.toString().padLeft(2, '0')} / '
        '${date.year}';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('es'),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.edit_calendar_outlined),
        ),
        child: Text(
          formatted,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TransportSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TransportSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransportType.all.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(TransportType.emoji(type),
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  TransportType.label(type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
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

class _TimePickerField extends StatelessWidget {
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onPicked;
  final VoidCallback onCleared;
  const _TimePickerField(
      {required this.time, required this.onPicked, required this.onCleared});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : 'Sin hora definida';

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          helpText: '¿A qué hora sales?',
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '¿A qué hora sales? (opcional)',
          prefixIcon: const Icon(Icons.schedule_outlined),
          suffixIcon: time != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onCleared,
                )
              : const Icon(Icons.access_time_outlined),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: time != null ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        IconButton.outlined(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
