import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Returned by [PlaceFormMapPicker] when the user confirms a location.
class MapPickerResult {
  final LatLng latlng;

  /// Short place name from Nominatim, or null if the user tapped manually.
  final String? placeName;

  const MapPickerResult({required this.latlng, this.placeName});
}

// ── Nominatim data class ───────────────────────────────────────────────────────

class _NominatimResult {
  final String displayName;
  final double lat;
  final double lon;

  const _NominatimResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  /// First segment of display_name (before the first comma).
  String get shortName => displayName.split(',').first.trim();

  /// The rest of display_name after the short name.
  String get locationHint {
    final parts = displayName.split(',');
    return parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
  }

  factory _NominatimResult.fromJson(Map<String, dynamic> json) {
    return _NominatimResult(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }
}

// ── Widget ─────────────────────────────────────────────────────────────────────

/// Full-screen modal that lets the user pick a location by:
///   1. Searching an address with Nominatim (OSM geocoder), or
///   2. Tapping directly on the map.
///
/// Returns a [MapPickerResult] via [Navigator.pop], or null if cancelled.
class PlaceFormMapPicker extends StatefulWidget {
  final LatLng? initial;

  const PlaceFormMapPicker({super.key, this.initial});

  @override
  State<PlaceFormMapPicker> createState() => _PlaceFormMapPickerState();
}

class _PlaceFormMapPickerState extends State<PlaceFormMapPicker> {
  late final MapController _mapController;
  late final TextEditingController _searchCtrl;

  LatLng? _selected;
  String? _selectedName; // set when a Nominatim result is chosen
  bool _searchHasText = false;

  static const _defaultCenter = LatLng(4.711, -74.0721); // Bogotá
  static const _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(_onSearchChanged);
    _selected = widget.initial;
  }

  void _onSearchChanged() {
    final has = _searchCtrl.text.isNotEmpty;
    if (has != _searchHasText) setState(() => _searchHasText = has);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Nominatim search ────────────────────────────────────────────────────────

  Future<List<_NominatimResult>> _searchNominatim(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(q)}&format=json&limit=5',
      );
      final response = await http
          .get(uri, headers: {
            'User-Agent': 'TripPlannerApp/1.0',
            'Accept-Language': 'es,en',
          })
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => _NominatimResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // No internet or timeout — fall through to empty list
    }
    return [];
  }

  // ── Confirm ─────────────────────────────────────────────────────────────────

  void _confirm() {
    if (_selected == null) return;
    Navigator.pop(
      context,
      MapPickerResult(latlng: _selected!, placeName: _selectedName),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          if (_selected != null)
            TextButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Confirmar',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: widget.initial ?? _defaultCenter,
              zoom: widget.initial != null ? 15.0 : _defaultZoom,
              onTap: (_, point) {
                setState(() {
                  _selected = point;
                  _selectedName = null; // manual tap clears search name
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dupper',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 48,
                      height: 48,
                      builder: (ctx) => Icon(
                        Icons.location_pin,
                        color: cs.primary,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Search bar ───────────────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TypeAheadField<_NominatimResult>(
                controller: _searchCtrl,
                debounceDuration: const Duration(milliseconds: 500),
                suggestionsCallback: _searchNominatim,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección o lugar...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchHasText
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Limpiar',
                              onPressed: () {
                                _searchCtrl.clear();
                                focusNode.unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  );
                },
                itemBuilder: (context, result) {
                  return ListTile(
                    leading: Icon(Icons.location_on_outlined,
                        color: cs.primary, size: 20),
                    title: Text(
                      result.shortName,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: result.locationHint.isNotEmpty
                        ? Text(
                            result.locationHint,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                  );
                },
                onSelected: (result) {
                  final latlng = LatLng(result.lat, result.lon);
                  setState(() {
                    _selected = latlng;
                    _selectedName = result.shortName;
                  });
                  _mapController.move(latlng, 15.0);
                  _searchCtrl.text = result.shortName;
                  FocusScope.of(context).unfocus();
                },
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
            ),
          ),

          // ── Coords hint (manual tap, no Nominatim name) ──────────────
          if (_selected != null && _selectedName == null)
            Positioned(
              bottom: 84,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app,
                          color: cs.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${_selected!.latitude.toStringAsFixed(5)}  '
                        'Lng: ${_selected!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom action ────────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _selected != null
                ? FilledButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar ubicación'),
                  )
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app,
                              color: cs.primary, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Toca el mapa o busca una dirección',
                            style: TextStyle(fontSize: 13),
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
