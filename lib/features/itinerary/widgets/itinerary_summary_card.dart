import 'package:flutter/material.dart';

import '../../../core/utils/trip_provider.dart';
import '../../places/providers/place_provider.dart';
import '../../../core/constants/app_constants.dart';

/// Fixed card at the top of the itinerary screen.
/// Shows total/per-person cost, total hours, and visited-place progress.
/// Toggle button switches between total and per-person cost view.
class ItinerarySummaryCard extends StatefulWidget {
  const ItinerarySummaryCard({super.key});

  @override
  State<ItinerarySummaryCard> createState() => _ItinerarySummaryCardState();
}

class _ItinerarySummaryCardState extends State<ItinerarySummaryCard> {
  bool _showPerPerson = false;

  @override
  Widget build(BuildContext context) {
    final trip = TripProvider.instance.getActiveTrip();
    if (trip == null) return const SizedBox.shrink();

    final places = PlaceProvider.instance.getPlacesByTrip(trip.id);
    final totalMin = places.fold<int>(0, (s, p) => s + p.tiempoEstimadoMin);
    final totalCost = places.fold<double>(0, (s, p) => s + p.costoEstimado);
    final visited =
        places.where((p) => p.estado == PlaceStatus.visited).length;
    final total = places.length;
    final progress = total == 0 ? 0.0 : visited / total;

    final displayCost =
        _showPerPerson && trip.numeroPersonas > 0
            ? totalCost / trip.numeroPersonas
            : totalCost;

    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    final timeLabel = h == 0
        ? '${m}min'
        : m == 0
            ? '${h}h'
            : '${h}h ${m}min';

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.summarize_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Toggle button
                GestureDetector(
                  onTap: () => setState(() => _showPerPerson = !_showPerPerson),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showPerPerson
                              ? Icons.person_outline
                              : Icons.group_outlined,
                          size: 14,
                          color: cs.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showPerPerson ? 'Por persona' : 'Total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Stats row ─────────────────────────────────────────────────
            Row(
              children: [
                _StatItem(
                  icon: Icons.attach_money_outlined,
                  label: _showPerPerson ? 'Por persona' : 'Costo total',
                  value:
                      '${trip.moneda} ${displayCost.toStringAsFixed(0)}',
                  color: cs.primary,
                ),
                const SizedBox(width: 12),
                _StatItem(
                  icon: Icons.schedule_outlined,
                  label: 'Tiempo total',
                  value: timeLabel,
                  color: cs.secondary,
                ),
                const SizedBox(width: 12),
                _StatItem(
                  icon: Icons.place_outlined,
                  label: 'Visitados',
                  value: '$visited / $total',
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Progress bar ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: cs.surfaceVariant,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal helper ────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
