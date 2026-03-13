import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip_model.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  final bool isActive;
  final VoidCallback onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy', 'es');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    _ActiveBadge(color: colorScheme.primary),
                  ],
                ],
              ),

              const SizedBox(height: 6),

              // ── Destination ────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trip.destino,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Meta row ───────────────────────────────────────────────────
              Row(
                children: [
                  _Meta(
                    icon: Icons.calendar_today,
                    label:
                        '${dateFmt.format(trip.fechaInicio)} – ${dateFmt.format(trip.fechaFin)}',
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  _Meta(
                    icon: Icons.schedule,
                    label: '${trip.duracionDias} '
                        '${trip.duracionDias == 1 ? 'día' : 'días'}',
                  ),
                  const SizedBox(width: 20),
                  _Meta(
                    icon: Icons.group,
                    label: '${trip.numeroPersonas} '
                        '${trip.numeroPersonas == 1 ? 'persona' : 'personas'}',
                  ),
                  const Spacer(),
                  _CurrencyChip(
                    moneda: trip.moneda,
                    presupuesto: trip.presupuestoTotal,
                    color: colorScheme.primaryContainer,
                    textColor: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  final Color color;
  const _ActiveBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'ACTIVO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String moneda;
  final double presupuesto;
  final Color color;
  final Color textColor;
  const _CurrencyChip({
    required this.moneda,
    required this.presupuesto,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = presupuesto > 0
        ? '$moneda ${NumberFormat.compact().format(presupuesto)}'
        : moneda;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
