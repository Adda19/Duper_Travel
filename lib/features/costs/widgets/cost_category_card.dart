import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Card showing estimated vs real cost for a single [CostCategory],
/// with a progress bar relative to the trip's total estimated cost.
class CostCategoryCard extends StatelessWidget {
  final String categoria;
  final double estimado;
  final double real;

  /// Total estimado del viaje completo (para la barra relativa).
  final double totalEstimado;
  final String currency;
  final int personas;
  final bool showPerPerson;

  const CostCategoryCard({
    super.key,
    required this.categoria,
    required this.estimado,
    required this.real,
    required this.totalEstimado,
    required this.currency,
    required this.personas,
    required this.showPerPerson,
  });

  double get _divisor =>
      showPerPerson && personas > 0 ? personas.toDouble() : 1;
  double get _est => estimado / _divisor;
  double get _rl => real / _divisor;
  double get _total => totalEstimado / _divisor;
  double get _relativeProgress =>
      _total > 0 ? (_est / _total).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = CostCategory.color(categoria);
    final icon = CostCategory.icon(categoria);
    final label = CostCategory.label(categoria);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                // ── Category icon ──────────────────────────────────────
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),

                // ── Label + amounts ────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Est: $currency ${_est.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (_rl > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Real: $currency ${_rl.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _rl > _est
                                    ? cs.error
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Percentage badge ───────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_relativeProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Relative progress bar ──────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _relativeProgress,
                minHeight: 5,
                backgroundColor: cs.surfaceVariant,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
