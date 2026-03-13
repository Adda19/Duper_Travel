import 'package:flutter/material.dart';

/// Floating button that controls route-drawing mode on the map.
///
/// Normal mode  → shows "Trazar ruta" button.
/// Route mode   → shows selection counter + Confirm / Cancel actions.
class MapRouteButton extends StatelessWidget {
  final bool routeMode;
  final int selectedCount;
  final VoidCallback onToggleMode;
  final VoidCallback onConfirmRoute;

  const MapRouteButton({
    super.key,
    required this.routeMode,
    required this.selectedCount,
    required this.onToggleMode,
    required this.onConfirmRoute,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!routeMode) {
      // ── Normal mode ───────────────────────────────────────────────────────
      return FloatingActionButton.extended(
        heroTag: 'fab_route',
        onPressed: onToggleMode,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: 4,
        icon: const Icon(Icons.alt_route),
        label: const Text(
          'Trazar ruta',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    // ── Route selection mode ───────────────────────────────────────────────
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Counter
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route, color: colorScheme.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  selectedCount == 0
                      ? 'Toca los lugares'
                      : '$selectedCount ${selectedCount == 1 ? 'lugar' : 'lugares'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Buttons row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: onToggleMode,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: selectedCount >= 2 ? onConfirmRoute : null,
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Abrir ruta'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
