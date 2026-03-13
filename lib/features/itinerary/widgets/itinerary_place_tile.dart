import 'package:flutter/material.dart';

import '../../places/models/place_model.dart';
import '../../../core/constants/app_constants.dart';

/// A single place row inside an itinerary day section.
/// Colored left border by [PlaceType], icon, name, schedule, duration, cost,
/// and a status chip. Accepts an optional [trailing] widget (drag handle).
class ItineraryPlaceTile extends StatelessWidget {
  final PlaceModel place;

  /// Optional widget shown at the right edge — used for the drag handle.
  final Widget? trailing;

  /// Called when the tile is tapped (navigate to detail).
  final VoidCallback? onTap;

  const ItineraryPlaceTile({
    super.key,
    required this.place,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typeColor = PlaceTypeColor.of(place.tipo);
    final icon = PlaceType.icon(place.tipo);

    // Build time label
    final h = place.tiempoEstimadoMin ~/ 60;
    final m = place.tiempoEstimadoMin % 60;
    final timeLabel = place.tiempoEstimadoMin == 0
        ? null
        : h == 0
            ? '${m}min'
            : m == 0
                ? '${h}h'
                : '${h}h ${m}min';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: typeColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ── Type icon ────────────────────────────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: typeColor),
              ),
              const SizedBox(width: 10),

              // ── Main content ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.nombre,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusChip(status: place.estado),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Meta: schedule · time · cost
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        if (place.horario.isNotEmpty)
                          _MetaItem(
                            icon: Icons.access_time_outlined,
                            label: place.horario,
                          ),
                        if (timeLabel != null)
                          _MetaItem(
                            icon: Icons.hourglass_empty_outlined,
                            label: timeLabel,
                          ),
                        if (place.costoEstimado > 0)
                          _MetaItem(
                            icon: Icons.attach_money_outlined,
                            label: place.costoEstimado.toStringAsFixed(0),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Trailing (drag handle) ────────────────────────────────
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  static const _map = <String, _StatusInfo>{
    PlaceStatus.pending: _StatusInfo('Pendiente', Color(0xFFF57C00)),
    PlaceStatus.visited: _StatusInfo('Visitado', Color(0xFF2E7D32)),
    PlaceStatus.skipped: _StatusInfo('Omitido', Color(0xFF757575)),
    'confirmed': _StatusInfo('Confirmado', Color(0xFF1565C0)),
  };

  @override
  Widget build(BuildContext context) {
    final info = _map[status] ??
        _StatusInfo(
          status.isEmpty ? 'Pendiente' : status[0].toUpperCase() + status.substring(1),
          const Color(0xFF757575),
        );
    final color = info.color;
    final label = info.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

}

// ── Meta item ──────────────────────────────────────────────────────────────────

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
