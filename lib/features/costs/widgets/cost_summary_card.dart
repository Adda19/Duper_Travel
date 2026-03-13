import 'package:flutter/material.dart';

/// Budget overview card: shows budget vs total estimated,
/// a color-coded progress bar (green <80%, yellow 80-100%, red >100%),
/// remaining/exceeded amount, and estimated vs real comparison.
class CostSummaryCard extends StatelessWidget {
  final double presupuesto;
  final double totalEstimado;
  final double totalReal;
  final String currency;
  final int personas;
  final bool showPerPerson;

  const CostSummaryCard({
    super.key,
    required this.presupuesto,
    required this.totalEstimado,
    required this.totalReal,
    required this.currency,
    required this.personas,
    required this.showPerPerson,
  });

  double get _divisor => showPerPerson && personas > 0 ? personas.toDouble() : 1;
  double get _budget => presupuesto / _divisor;
  double get _estimado => totalEstimado / _divisor;
  double get _real => totalReal / _divisor;
  double get _progress => _budget > 0 ? (_estimado / _budget).clamp(0.0, 2.0) : 0.0;
  double get _progressClamped => _progress.clamp(0.0, 1.0);

  Color _barColor(BuildContext context) {
    if (_progress < 0.8) return const Color(0xFF2E7D32);
    if (_progress <= 1.0) return const Color(0xFFF57C00);
    return Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final barColor = _barColor(context);
    final remaining = _budget - _estimado;
    final exceeded = remaining < 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ───────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Resumen presupuesto',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Budget vs Estimated ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(
                    label: 'Presupuesto',
                    amount: _budget,
                    currency: currency,
                    color: cs.onSurface,
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Estimado',
                    amount: _estimado,
                    currency: currency,
                    color: barColor,
                  ),
                ),
                if (_real > 0)
                  Expanded(
                    child: _AmountColumn(
                      label: 'Real',
                      amount: _real,
                      currency: currency,
                      color: cs.secondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Progress bar ─────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progressClamped,
                    minHeight: 10,
                    backgroundColor: cs.surfaceVariant,
                    color: barColor,
                  ),
                ),
                if (_progress > 1.0)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1 / _progress,
                        child: Container(color: barColor.withOpacity(0.4)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Progress label + remaining/exceeded ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progressClamped * 100).toStringAsFixed(0)}% del presupuesto',
                  style: TextStyle(
                    fontSize: 11,
                    color: barColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _RemainingChip(
                  amount: remaining.abs(),
                  currency: currency,
                  exceeded: exceeded,
                ),
              ],
            ),

            // ── Real vs Estimado footer ──────────────────────────────────
            if (_real > 0) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Gasto real vs estimado: ',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '$currency ${_real.toStringAsFixed(0)} / '
                    '$currency ${_estimado.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _real > _estimado
                          ? cs.error
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Internal helpers ───────────────────────────────────────────────────────────

class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$currency ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RemainingChip extends StatelessWidget {
  final double amount;
  final String currency;
  final bool exceeded;

  const _RemainingChip({
    required this.amount,
    required this.currency,
    required this.exceeded,
  });

  @override
  Widget build(BuildContext context) {
    final color = exceeded
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF2E7D32);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exceeded ? Icons.trending_up : Icons.savings_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            exceeded
                ? 'Excedido $currency ${amount.toStringAsFixed(0)}'
                : 'Restante $currency ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
