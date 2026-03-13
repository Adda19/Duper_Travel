import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../places/models/place_model.dart';

/// Bottom sheet shown when the user taps a place marker on the map.
class MapBottomSheet extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onViewDetail;
  final VoidCallback onGetDirections;

  const MapBottomSheet({
    super.key,
    required this.place,
    required this.onViewDetail,
    required this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = PlaceTypeColor.of(place.tipo);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PlaceType.icon(place.tipo),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TypeChip(tipo: place.tipo),
                          const SizedBox(width: 6),
                          _StatusChip(estado: place.estado),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Meta info grid ───────────────────────────────────────────────
            Row(
              children: [
                _MetaItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Día ${place.dia}',
                ),
                const SizedBox(width: 16),
                _MetaItem(
                  icon: Icons.schedule_outlined,
                  label: _formatTime(place.tiempoEstimadoMin),
                ),
                if (place.costoEstimado > 0) ...[
                  const SizedBox(width: 16),
                  _MetaItem(
                    icon: Icons.attach_money_outlined,
                    label: place.costoEstimado.toStringAsFixed(0),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGetDirections,
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Cómo llegar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onViewDetail,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ver detalle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String tipo;
  const _TypeChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = PlaceTypeColor.of(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        PlaceType.label(tipo),
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String estado;
  const _StatusChip({required this.estado});

  static const _map = {
    PlaceStatus.pending: (label: 'Pendiente', color: Color(0xFF757575)),
    PlaceStatus.visited: (label: 'Visitado', color: Color(0xFF2E7D32)),
    PlaceStatus.skipped: (label: 'Omitido', color: Color(0xFFBF360C)),
    'confirmed': (label: 'Confirmado', color: Color(0xFF1565C0)),
  };

  @override
  Widget build(BuildContext context) {
    final info = _map[estado] ??
        (label: 'Pendiente', color: const Color(0xFF757575));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info.color.withAlpha(80)),
      ),
      child: Text(
        info.label,
        style: TextStyle(
            fontSize: 11,
            color: info.color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
