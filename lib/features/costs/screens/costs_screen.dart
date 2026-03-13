import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/trip_provider.dart';
import '../../places/models/place_model.dart';
import '../../places/providers/place_provider.dart';
import '../../trips/models/trip_model.dart';
import '../models/manual_expense_model.dart';
import '../providers/cost_provider.dart';
import '../widgets/cost_category_card.dart';
import '../widgets/cost_summary_card.dart';

class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen> {
  bool _showPerPerson = false;
  bool _expandedPlaces = false;

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

  void _onTripChanged() => setState(() {});

  // ── Persons stepper ──────────────────────────────────────────────────────

  Future<void> _changePersons(TripModel trip, int delta) async {
    final next = (trip.numeroPersonas + delta).clamp(1, 99);
    if (next == trip.numeroPersonas) return;
    trip.numeroPersonas = next;
    await trip.save();
    setState(() {});
  }

  // ── Manual expense dialog ────────────────────────────────────────────────

  Future<void> _showAddExpenseDialog(TripModel trip,
      {ManualExpenseModel? existing}) async {
    await showDialog(
      context: context,
      builder: (_) => _ExpenseDialog(trip: trip, existing: existing),
    );
  }

  // ── Edit costoReal for a place ───────────────────────────────────────────

  Future<void> _editCostoReal(PlaceModel place, String currency) async {
    final ctrl = TextEditingController(
        text: place.costoReal > 0
            ? place.costoReal.toStringAsFixed(0)
            : '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Costo real — ${place.nombre}'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Monto real ($currency)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      place.costoReal = double.tryParse(ctrl.text) ?? 0;
      await place.save();
    }
    ctrl.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
            return ValueListenableBuilder(
              valueListenable: Hive.box<ManualExpenseModel>(
                      HiveBoxes.expenses)
                  .listenable(),
              builder: (context, _, __) => _buildBody(trip),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(TripModel trip) {
    final totalEstimado =
        CostProvider.instance.getTotalEstimado(trip.id);
    final totalReal = CostProvider.instance.getTotalReal(trip.id);
    final estimadoByCategory =
        CostProvider.instance.getTotalEstimadoByCategory(trip.id);
    final realByCategory =
        CostProvider.instance.getTotalRealByCategory(trip.id);
    final manualExpenses =
        CostProvider.instance.getManualExpenses(trip.id);
    final placesWithCost = PlaceProvider.instance
        .getPlacesByTrip(trip.id)
        .where((p) => p.costoEstimado > 0 || p.costoReal > 0)
        .toList();

    final activeCategories = CostCategory.all
        .where((c) =>
            (estimadoByCategory[c] ?? 0) > 0 ||
            (realByCategory[c] ?? 0) > 0)
        .toList();

    return CustomScrollView(
      slivers: [
        // ── App bar ──────────────────────────────────────────────────
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text(trip.nombre),
          centerTitle: false,
          actions: [
            _PersonsStepper(
              value: trip.numeroPersonas,
              onDecrement: () => _changePersons(trip, -1),
              onIncrement: () => _changePersons(trip, 1),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // ── Toggle ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: _ToggleBar(
              showPerPerson: _showPerPerson,
              onChanged: (v) => setState(() => _showPerPerson = v),
            ),
          ),
        ),

        // ── A: Resumen general ───────────────────────────────────────
        SliverToBoxAdapter(
          child: CostSummaryCard(
            presupuesto: trip.presupuestoTotal,
            totalEstimado: totalEstimado,
            totalReal: totalReal,
            currency: trip.moneda,
            personas: trip.numeroPersonas,
            showPerPerson: _showPerPerson,
          ),
        ),

        // ── B: Desglose por categoría ────────────────────────────────
        if (activeCategories.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.pie_chart_outline,
              label: 'Desglose por categoría',
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final cat = activeCategories[i];
                return CostCategoryCard(
                  categoria: cat,
                  estimado: estimadoByCategory[cat] ?? 0,
                  real: realByCategory[cat] ?? 0,
                  totalEstimado: totalEstimado,
                  currency: trip.moneda,
                  personas: trip.numeroPersonas,
                  showPerPerson: _showPerPerson,
                );
              },
              childCount: activeCategories.length,
            ),
          ),
        ],

        // ── C: Gastos manuales ───────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionHeader(
            icon: Icons.edit_note_outlined,
            label: 'Gastos manuales',
            trailing: TextButton.icon(
              onPressed: () => _showAddExpenseDialog(trip),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar'),
            ),
          ),
        ),

        if (manualExpenses.isEmpty)
          const SliverToBoxAdapter(
            child: _EmptyHint(
              icon: Icons.receipt_long_outlined,
              text:
                  'Sin gastos manuales. Usa "Agregar" para registrar '
                  'gastos no asociados a un lugar.',
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final expense = manualExpenses[i];
                return _ExpenseTile(
                  expense: expense,
                  currency: trip.moneda,
                  personas: trip.numeroPersonas,
                  showPerPerson: _showPerPerson,
                  onEdit: () =>
                      _showAddExpenseDialog(trip, existing: expense),
                  onDelete: () =>
                      CostProvider.instance
                          .deleteManualExpense(expense),
                );
              },
              childCount: manualExpenses.length,
            ),
          ),

        // ── D: Lugares con costo ─────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionHeader(
            icon: Icons.place_outlined,
            label: 'Lugares con costo (${placesWithCost.length})',
            trailing: TextButton(
              onPressed: () =>
                  setState(() => _expandedPlaces = !_expandedPlaces),
              child: Text(_expandedPlaces ? 'Colapsar' : 'Ver todos'),
            ),
          ),
        ),

        if (_expandedPlaces)
          placesWithCost.isEmpty
              ? const SliverToBoxAdapter(
                  child: _EmptyHint(
                    icon: Icons.location_off_outlined,
                    text: 'Ningún lugar tiene costo registrado.',
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final place = placesWithCost[i];
                      return _PlaceCostTile(
                        place: place,
                        currency: trip.moneda,
                        personas: trip.numeroPersonas,
                        showPerPerson: _showPerPerson,
                        onEditReal: () =>
                            _editCostoReal(place, trip.moneda),
                      );
                    },
                    childCount: placesWithCost.length,
                  ),
                ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── Persons stepper ────────────────────────────────────────────────────────────

class _PersonsStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _PersonsStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value <= 1 ? null : onDecrement,
          color: cs.primary,
          padding: EdgeInsets.zero,
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline,
                  size: 14, color: cs.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(
                '$value',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: value >= 99 ? null : onIncrement,
          color: cs.primary,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ── Toggle bar ─────────────────────────────────────────────────────────────────

class _ToggleBar extends StatelessWidget {
  final bool showPerPerson;
  final ValueChanged<bool> onChanged;

  const _ToggleBar(
      {required this.showPerPerson, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Total del grupo',
            icon: Icons.group_outlined,
            selected: !showPerPerson,
            onTap: () => onChanged(false),
          ),
          _ToggleOption(
            label: 'Por persona',
            icon: Icons.person_outline,
            selected: showPerPerson,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? cs.onPrimary
                      : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? cs.onPrimary
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;

  const _SectionHeader(
      {required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Manual expense tile ────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final ManualExpenseModel expense;
  final String currency;
  final int personas;
  final bool showPerPerson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.currency,
    required this.personas,
    required this.showPerPerson,
    required this.onEdit,
    required this.onDelete,
  });

  double get _divisor =>
      showPerPerson && personas > 0 ? personas.toDouble() : 1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = CostCategory.color(expense.categoria);
    final catIcon = CostCategory.icon(expense.categoria);
    final est = expense.montoEstimado / _divisor;
    final real = expense.montoReal / _divisor;

    return Dismissible(
      key: ValueKey('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Container(
          margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: catColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(catIcon, size: 20, color: catColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.descripcion,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        CostCategory.label(expense.categoria),
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency ${est.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    if (real > 0)
                      Text(
                        'Real: $currency ${real.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: real > est
                              ? cs.error
                              : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Place cost tile ────────────────────────────────────────────────────────────

class _PlaceCostTile extends StatelessWidget {
  final PlaceModel place;
  final String currency;
  final int personas;
  final bool showPerPerson;
  final VoidCallback onEditReal;

  const _PlaceCostTile({
    required this.place,
    required this.currency,
    required this.personas,
    required this.showPerPerson,
    required this.onEditReal,
  });

  double get _divisor =>
      showPerPerson && personas > 0 ? personas.toDouble() : 1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typeColor = PlaceTypeColor.of(place.tipo);
    final est = place.costoEstimado / _divisor;
    final real = place.costoReal / _divisor;

    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: typeColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(PlaceType.icon(place.tipo),
                size: 20, color: typeColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${PlaceType.label(place.tipo)} · Día ${place.dia}',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Est: $currency ${est.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12),
                ),
                GestureDetector(
                  onTap: onEditReal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: real > 0
                          ? (real > place.costoEstimado
                              ? cs.errorContainer
                              : cs.primaryContainer)
                          : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 10,
                            color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          real > 0
                              ? 'Real: $currency ${real.toStringAsFixed(0)}'
                              : 'Añadir real',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: real > 0
                                ? (real > place.costoEstimado
                                    ? cs.onErrorContainer
                                    : cs.onPrimaryContainer)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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

// ── Add/Edit expense dialog ────────────────────────────────────────────────────

class _ExpenseDialog extends StatefulWidget {
  final TripModel trip;
  final ManualExpenseModel? existing;

  const _ExpenseDialog({required this.trip, this.existing});

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _estCtrl;
  late final TextEditingController _realCtrl;
  late String _categoria;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descCtrl = TextEditingController(text: e?.descripcion ?? '');
    _estCtrl = TextEditingController(
        text: e != null && e.montoEstimado > 0
            ? e.montoEstimado.toStringAsFixed(0)
            : '');
    _realCtrl = TextEditingController(
        text: e != null && e.montoReal > 0
            ? e.montoReal.toStringAsFixed(0)
            : '');
    _categoria = e?.categoria ?? CostCategory.other;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _estCtrl.dispose();
    _realCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final est = double.tryParse(_estCtrl.text) ?? 0;
    final real = double.tryParse(_realCtrl.text) ?? 0;

    if (widget.existing != null) {
      widget.existing!
        ..descripcion = _descCtrl.text.trim()
        ..categoria = _categoria
        ..montoEstimado = est
        ..montoReal = real;
      await CostProvider.instance
          .updateManualExpense(widget.existing!);
    } else {
      await CostProvider.instance.addManualExpense(
        ManualExpenseModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tripId: widget.trip.id,
          descripcion: _descCtrl.text.trim(),
          categoria: _categoria,
          montoEstimado: est,
          montoReal: real,
          fecha: DateTime.now(),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar gasto' : 'Nuevo gasto manual'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Requerido'
                    : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: CostCategory.all
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(CostCategory.icon(c),
                                  size: 16,
                                  color: CostCategory.color(c)),
                              const SizedBox(width: 8),
                              Text(CostCategory.label(c)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _categoria = v ?? _categoria),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _estCtrl,
                decoration: InputDecoration(
                  labelText:
                      'Monto estimado (${widget.trip.moneda})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[\d.]')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _realCtrl,
                decoration: InputDecoration(
                  labelText:
                      'Monto real (${widget.trip.moneda}) — opcional',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[\d.]')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEdit ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}

// ── Empty hint ─────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
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
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No hay viaje activo',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Selecciona un viaje en la pestaña Viajes para ver sus costos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
