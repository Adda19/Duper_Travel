import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../models/trip_model.dart';
import '../widgets/trip_card.dart';
import 'add_trip_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Viajes')),
      body: ValueListenableBuilder<Box<TripModel>>(
        valueListenable:
            Hive.box<TripModel>(HiveBoxes.trips).listenable(),
        builder: (context, box, _) {
          final trips = TripProvider.instance.getAllTrips();

          if (trips.isEmpty) {
            return const _EmptyState();
          }

          return ValueListenableBuilder<TripModel?>(
            valueListenable: TripProvider.instance.activeTrip,
            builder: (context, activeTrip, _) {
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 96),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Dismissible(
                    key: ValueKey(trip.id),
                    direction: DismissDirection.endToStart,
                    background: _DeleteBackground(),
                    confirmDismiss: (_) => _confirmDelete(context, trip),
                    onDismissed: (_) async {
                      await TripProvider.instance.deleteTrip(trip);
                    },
                    child: TripCard(
                      trip: trip,
                      isActive: activeTrip?.id == trip.id,
                      onTap: () => _onTripTap(context, trip, activeTrip),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_trips',
        onPressed: () => _openAddTrip(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo viaje'),
      ),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onTripTap(
      BuildContext context, TripModel trip, TripModel? active) async {
    if (active?.id == trip.id) {
      _openAddTrip(context, existing: trip);
    } else {
      await TripProvider.instance.setActiveTrip(trip);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${trip.nombre}" es ahora tu viaje activo'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openAddTrip(BuildContext context, {TripModel? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTripScreen(existing: existing),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, TripModel trip) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar viaje'),
            content: Text(
                '¿Eliminar "${trip.nombre}"? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flight_takeoff,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Crea tu primer viaje',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega destinos, planifica tu itinerario\ny lleva el control de tus gastos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Swipe-to-delete background ────────────────────────────────────────────────

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            'Eliminar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
