import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../../places/models/place_model.dart';
import '../../places/providers/place_provider.dart';
import '../../places/screens/add_place_screen.dart';
import '../../places/screens/place_detail_screen.dart';
import '../../trips/models/trip_model.dart';
import '../widgets/itinerary_day_header.dart';
import '../widgets/itinerary_place_tile.dart';
import '../widgets/itinerary_summary_card.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  // Which day sections are expanded (default: all open)
  final Map<int, bool> _expanded = {};

  // Per-day custom ordering persisted to settings box
  final _settingsBox = Hive.box(HiveBoxes.settings);

  @override
  void initState() {
    super.initState();
    TripProvider.instance.activeTrip.addListener(_onTripChanged);
  }

  @override
  void dispose() {
    TripProvider.instance.activeTrip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _onTripChanged() => setState(() => _expanded.clear());

  // ── Order persistence ────────────────────────────────────────────────────────

  String _orderKey(String tripId, int day) => 'order_${tripId}_$day';

  List<PlaceModel> _orderedPlaces(String tripId, int day) {
    final places = PlaceProvider.instance.getPlacesByDay(tripId, day);
    final key = _orderKey(tripId, day);
    final savedOrder = _settingsBox.get(key);
    if (savedOrder is List && savedOrder.isNotEmpty) {
      final idOrder = List<String>.from(savedOrder);
      final byId = {for (final p in places) p.id: p};
      final ordered = <PlaceModel>[];
      for (final id in idOrder) {
        if (byId.containsKey(id)) ordered.add(byId[id]!);
      }
      for (final p in places) {
        if (!idOrder.contains(p.id)) ordered.add(p);
      }
      return ordered;
    }
    return places;
  }

  void _saveOrder(String tripId, int day, List<PlaceModel> ordered) {
    _settingsBox.put(
        _orderKey(tripId, day), ordered.map((p) => p.id).toList());
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(PlaceModel place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Eliminar "${place.nombre}" del itinerario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PlaceProvider.instance.deletePlace(place);
    }
  }

  Future<void> _cycleStatus(PlaceModel place) async {
    final next = switch (place.estado) {
      PlaceStatus.pending => PlaceStatus.visited,
      PlaceStatus.visited => PlaceStatus.skipped,
      _ => PlaceStatus.pending,
    };
    place.estado = next;
    await place.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${place.nombre}: ${PlaceStatus.label(next)}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TripModel?>(
      valueListenable: TripProvider.instance.activeTrip,
      builder: (context, trip, _) {
        if (trip == null) return const _NoTripCard();

        return ValueListenableBuilder(
          valueListenable:
              Hive.box<PlaceModel>(HiveBoxes.places).listenable(),
          builder: (context, _, __) {
            final days = List.generate(trip.duracionDias, (i) => i + 1);

            return CustomScrollView(
              slivers: [
                // ── App bar ─────────────────────────────────────────────
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: Text(trip.nombre),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      tooltip: 'Agregar lugar',
                      icon: const Icon(Icons.add_location_alt_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddPlaceScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Summary card ─────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: ItinerarySummaryCard(),
                ),

                // ── Day sections ─────────────────────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final day = days[index];
                      final isExpanded = _expanded[day] ?? true;
                      final date =
                          trip.fechaInicio.add(Duration(days: day - 1));
                      final places = _orderedPlaces(trip.id, day);

                      return _DaySection(
                        day: day,
                        date: date,
                        places: places,
                        currency: trip.moneda,
                        isExpanded: isExpanded,
                        onToggle: () =>
                            setState(() => _expanded[day] = !isExpanded),
                        onReorder: (oldIdx, newIdx) {
                          setState(() {
                            if (newIdx > oldIdx) newIdx--;
                            final updated = List<PlaceModel>.from(places);
                            final item = updated.removeAt(oldIdx);
                            updated.insert(newIdx, item);
                            _saveOrder(trip.id, day, updated);
                          });
                        },
                        onDelete: _confirmDelete,
                        onCycleStatus: _cycleStatus,
                        onTap: (p) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(place: p),
                          ),
                        ),
                      );
                    },
                    childCount: days.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Day section card ───────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  final int day;
  final DateTime? date;
  final List<PlaceModel> places;
  final String currency;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(int, int) onReorder;
  final Future<void> Function(PlaceModel) onDelete;
  final Future<void> Function(PlaceModel) onCycleStatus;
  final void Function(PlaceModel) onTap;

  const _DaySection({
    required this.day,
    this.date,
    required this.places,
    required this.currency,
    required this.isExpanded,
    required this.onToggle,
    required this.onReorder,
    required this.onDelete,
    required this.onCycleStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: ItineraryDayHeader(
              day: day,
              date: date,
              places: places,
              currency: currency,
              isExpanded: isExpanded,
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: places.isEmpty
                ? _EmptyDay(day: day)
                : _ReorderablePlaceList(
                    places: places,
                    onReorder: onReorder,
                    onDelete: onDelete,
                    onCycleStatus: onCycleStatus,
                    onTap: onTap,
                  ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          if (isExpanded && places.isNotEmpty)
            Divider(height: 1, color: cs.outlineVariant),
        ],
      ),
    );
  }
}

// ── Reorderable list ───────────────────────────────────────────────────────────

class _ReorderablePlaceList extends StatelessWidget {
  final List<PlaceModel> places;
  final void Function(int, int) onReorder;
  final Future<void> Function(PlaceModel) onDelete;
  final Future<void> Function(PlaceModel) onCycleStatus;
  final void Function(PlaceModel) onTap;

  const _ReorderablePlaceList({
    required this.places,
    required this.onReorder,
    required this.onDelete,
    required this.onCycleStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: places.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final place = places[index];
        return _SwipeableTile(
          key: ValueKey(place.id),
          place: place,
          index: index,
          onDelete: onDelete,
          onCycleStatus: onCycleStatus,
          onTap: onTap,
        );
      },
    );
  }
}

// ── Swipeable tile ─────────────────────────────────────────────────────────────

class _SwipeableTile extends StatelessWidget {
  final PlaceModel place;
  final int index;
  final Future<void> Function(PlaceModel) onDelete;
  final Future<void> Function(PlaceModel) onCycleStatus;
  final void Function(PlaceModel) onTap;

  const _SwipeableTile({
    super.key,
    required this.place,
    required this.index,
    required this.onDelete,
    required this.onCycleStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismiss_${place.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await onDelete(place);
        } else {
          await onCycleStatus(place);
        }
        return false; // providers handle actual state/removal
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: cs.primaryContainer,
        child: Row(
          children: [
            Icon(Icons.sync_outlined, color: cs.onPrimaryContainer),
            const SizedBox(width: 8),
            Text('Cambiar estado',
                style: TextStyle(color: cs.onPrimaryContainer)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.errorContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Eliminar',
                style: TextStyle(color: cs.onErrorContainer)),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline, color: cs.onErrorContainer),
          ],
        ),
      ),
      child: ItineraryPlaceTile(
        place: place,
        onTap: () => onTap(place),
        trailing: ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.drag_handle, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Empty day placeholder ──────────────────────────────────────────────────────

class _EmptyDay extends StatelessWidget {
  final int day;
  const _EmptyDay({required this.day});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_location_alt_outlined,
                size: 32, color: cs.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              'Sin lugares para el día $day',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No active trip ─────────────────────────────────────────────────────────────

class _NoTripCard extends StatelessWidget {
  const _NoTripCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No hay viaje activo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona un viaje en la pestaña Viajes para ver su itinerario.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
