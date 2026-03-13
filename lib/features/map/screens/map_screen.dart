import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../../places/models/place_model.dart';
import '../../places/providers/place_provider.dart';
import '../../places/screens/add_place_screen.dart';
import '../../places/screens/place_detail_screen.dart';
import '../../wishlist/models/wishlist_place_model.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../wishlist/screens/wishlist_detail_screen.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/map_filter_bar.dart';
import '../widgets/map_route_button.dart';
import '../widgets/place_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();

  String _filterType = '';
  int _filterDay = 0;
  bool _showWishlist = false;

  bool _routeMode = false;
  final Set<String> _routeSelected = {};

  static const _defaultCenter = LatLng(4.711, -74.0721);
  static const _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    TripProvider.instance.activeTrip.addListener(_onTripChanged);
  }

  @override
  void dispose() {
    TripProvider.instance.activeTrip.removeListener(_onTripChanged);
    _mapController.dispose();
    super.dispose();
  }

  void _onTripChanged() => setState(() {
        _filterDay = 0;
        _routeMode = false;
        _routeSelected.clear();
      });

  List<PlaceModel> _filtered(List<PlaceModel> all) => all.where((p) {
        if (_filterType.isNotEmpty && p.tipo != _filterType) return false;
        if (_filterDay > 0 && p.dia != _filterDay) return false;
        return true;
      }).toList();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeTrip = TripProvider.instance.getActiveTrip();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ValueListenableBuilder<Box<PlaceModel>>(
        valueListenable:
            Hive.box<PlaceModel>(HiveBoxes.places).listenable(),
        builder: (context, _, __) {
          final allPlaces = activeTrip != null
              ? PlaceProvider.instance.getPlacesByTrip(activeTrip.id)
              : <PlaceModel>[];
          final withLocation = _filtered(allPlaces)
              .where((p) => p.latitud != 0 || p.longitud != 0)
              .toList();

          return ValueListenableBuilder<Box<WishlistPlaceModel>>(
            valueListenable:
                Hive.box<WishlistPlaceModel>(HiveBoxes.wishlist).listenable(),
            builder: (context, __, ___) {
              final wishlistWithLocation = _showWishlist
                  ? WishlistProvider.instance
                      .getAll()
                      .where((p) => p.hasLocation)
                      .toList()
                  : <WishlistPlaceModel>[];

              return Stack(
                children: [
                  // ── Map ───────────────────────────────────────────────────
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _defaultCenter,
                      zoom: _defaultZoom,
                      maxZoom: 18,
                      minZoom: 3,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.dupper',
                      ),
                      // Trip place markers
                      MarkerLayer(
                        markers: withLocation
                            .map(
                              (place) => Marker(
                                point: LatLng(place.latitud, place.longitud),
                                width: 60,
                                height: 60,
                                builder: (_) => PlaceMarker(
                                  key: ValueKey(place.id),
                                  tipo: place.tipo,
                                  estado: place.estado,
                                  dia: place.dia,
                                  routeMode: _routeMode,
                                  isSelected:
                                      _routeSelected.contains(place.id),
                                  onTap: () => _onMarkerTap(place),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      // Wishlist markers (independent of type/day filters)
                      if (_showWishlist)
                        MarkerLayer(
                          markers: wishlistWithLocation
                              .map(
                                (wp) => Marker(
                                  point: LatLng(wp.latitud, wp.longitud),
                                  width: 56,
                                  height: 56,
                                  builder: (_) => _WishlistMarker(
                                    key: ValueKey('w_${wp.id}'),
                                    isVisited: wp.isVisited,
                                    onTap: () => _openWishlistDetail(wp),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),

                  // ── Filter bar ─────────────────────────────────────────────
                  Positioned(
                    top: topPadding + 8,
                    left: 0,
                    right: 0,
                    child: MapFilterBar(
                      selectedType: _filterType,
                      selectedDay: _filterDay,
                      maxDays: activeTrip?.duracionDias ?? 0,
                      tripStart: activeTrip?.fechaInicio,
                      showWishlist: _showWishlist,
                      onWishlistToggled: () =>
                          setState(() => _showWishlist = !_showWishlist),
                      onTypeChanged: (t) => setState(() => _filterType = t),
                      onDayChanged: (d) => setState(() => _filterDay = d),
                    ),
                  ),

                  // ── No active trip notice ──────────────────────────────────
                  if (activeTrip == null && !_showWishlist)
                    const Positioned(
                      bottom: 120,
                      left: 16,
                      right: 16,
                      child: _NoTripCard(),
                    ),

                  // ── Route button (bottom-left) ─────────────────────────────
                  if (activeTrip != null)
                    Positioned(
                      bottom: 24,
                      left: 16,
                      child: MapRouteButton(
                        routeMode: _routeMode,
                        selectedCount: _routeSelected.length,
                        onToggleMode: () => setState(() {
                          _routeMode = !_routeMode;
                          if (!_routeMode) _routeSelected.clear();
                        }),
                        onConfirmRoute: () => _openRoute(allPlaces),
                      ),
                    ),

                  // ── FABs (bottom-right) ────────────────────────────────────
                  Positioned(
                    bottom: 24,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'fab_my_location',
                          onPressed: _centerOnMyLocation,
                          tooltip: 'Mi ubicación',
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: 'fab_add_place',
                          onPressed: _openAddPlace,
                          tooltip: 'Agregar lugar',
                          child: const Icon(Icons.add_location_alt_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Marker interaction ─────────────────────────────────────────────────────

  void _onMarkerTap(PlaceModel place) {
    if (_routeMode) {
      setState(() {
        if (_routeSelected.contains(place.id)) {
          _routeSelected.remove(place.id);
        } else {
          _routeSelected.add(place.id);
        }
      });
    } else {
      _showBottomSheet(place);
    }
  }

  void _openWishlistDetail(WishlistPlaceModel wp) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WishlistDetailScreen(place: wp)),
    );
  }

  void _showBottomSheet(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MapBottomSheet(
        place: place,
        onViewDetail: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(place: place),
            ),
          );
        },
        onGetDirections: () {
          Navigator.pop(context);
          _openDirections(place);
        },
      ),
    );
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _centerOnMyLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado permanentemente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
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

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _openAddPlace() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
    );
  }

  Future<void> _openDirections(PlaceModel place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${place.latitud},${place.longitud}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Route builder ──────────────────────────────────────────────────────────

  Future<void> _openRoute(List<PlaceModel> allPlaces) async {
    final selected = allPlaces
        .where((p) =>
            _routeSelected.contains(p.id) &&
            (p.latitud != 0 || p.longitud != 0))
        .toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));

    if (selected.length < 2) return;

    final origin = '${selected.first.latitud},${selected.first.longitud}';
    final dest = '${selected.last.latitud},${selected.last.longitud}';

    var url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$dest';

    if (selected.length > 2) {
      final waypoints = selected
          .sublist(1, selected.length - 1)
          .map((p) => '${p.latitud},${p.longitud}')
          .join('|');
      url += '&waypoints=${Uri.encodeComponent(waypoints)}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (mounted) {
      setState(() {
        _routeMode = false;
        _routeSelected.clear();
      });
    }
  }
}

// ── Wishlist marker ───────────────────────────────────────────────────────────

class _WishlistMarker extends StatelessWidget {
  final bool isVisited;
  final VoidCallback onTap;

  const _WishlistMarker({super.key, required this.isVisited, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isVisited ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E);
    final icon = isVisited ? Icons.favorite : Icons.favorite_border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── No active trip card ───────────────────────────────────────────────────────

class _NoTripCard extends StatelessWidget {
  const _NoTripCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Selecciona un viaje activo en la pestaña '
                'Viajes para ver sus lugares en el mapa.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
