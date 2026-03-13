import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../places/models/place_model.dart';
import '../../../core/constants/app_constants.dart';

/// Expandable section header for a single day in the itinerary.
/// Shows: day number, real date (if available), total hours, total cost,
/// and a LinearProgressIndicator for visited progress.
class ItineraryDayHeader extends StatelessWidget {
  final int day;
  final DateTime? date;
  final List<PlaceModel> places;
  final String currency;
  final bool isExpanded;

  const ItineraryDayHeader({
    super.key,
    required this.day,
    this.date,
    required this.places,
    required this.currency,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final totalMin = places.fold<int>(0, (s, p) => s + p.tiempoEstimadoMin);
    final totalCost = places.fold<double>(0, (s, p) => s + p.costoEstimado);
    final visited =
        places.where((p) => p.estado == PlaceStatus.visited).length;
    final total = places.length;
    final progress = total == 0 ? 0.0 : visited / total;

    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    final timeLabel = h == 0
        ? '${m}min'
        : m == 0
            ? '${h}h'
            : '${h}h ${m}min';

    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final dateLabel = date != null
        ? cap(DateFormat("EEEE d 'de' MMMM", 'es').format(date!))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              // ── Day badge ──────────────────────────────────────────────
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Día title + date ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel != null ? 'Día $day — $dateLabel' : 'Día $day',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Cost chip ──────────────────────────────────────────────
              if (totalCost > 0)
                _HeaderChip(
                  icon: Icons.attach_money_outlined,
                  label:
                      '$currency ${totalCost.toStringAsFixed(0)}',
                  color: cs.primary,
                ),
              const SizedBox(width: 6),

              // ── Time chip ──────────────────────────────────────────────
              if (totalMin > 0)
                _HeaderChip(
                  icon: Icons.schedule_outlined,
                  label: timeLabel,
                  color: cs.secondary,
                ),
              const SizedBox(width: 4),

              // ── Places count ───────────────────────────────────────────
              Text(
                '$total ${total == 1 ? 'lugar' : 'lugares'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),

              // ── Expand icon ────────────────────────────────────────────
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // ── Progress bar ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: cs.surfaceVariant,
                    color: progress >= 1.0
                        ? const Color(0xFF2E7D32)
                        : cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$visited/$total',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: progress >= 1.0
                      ? const Color(0xFF2E7D32)
                      : cs.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Internal helper ────────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
