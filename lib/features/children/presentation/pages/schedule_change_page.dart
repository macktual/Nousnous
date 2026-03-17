import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/child.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/weekly_pattern.dart';
import '../controllers/children_controllers.dart';

class ScheduleChangePage extends ConsumerStatefulWidget {
  const ScheduleChangePage({super.key, required this.child});

  final Child child;

  @override
  ConsumerState<ScheduleChangePage> createState() => _ScheduleChangePageState();
}

class _ScheduleChangePageState extends ConsumerState<ScheduleChangePage> {
  static const int _maxPatterns = 5;
  static const List<String> _patternNames = ['Semaine type', 'Semaine B', 'Semaine C', 'Semaine D', 'Semaine E'];
  static const String _defaultArrival = '08:00';
  static const String _defaultDeparture = '18:00';

  late final List<List<TextEditingController>> _scheduleArrivals;
  late final List<List<TextEditingController>> _scheduleDeparts;
  DateTime? _validFromDate;
  int _patternCount = 1;

  @override
  void initState() {
    super.initState();
    _scheduleArrivals = List.generate(
      _maxPatterns,
      (_) => List.generate(5, (_) => TextEditingController(text: _defaultArrival)),
    );
    _scheduleDeparts = List.generate(
      _maxPatterns,
      (_) => List.generate(5, (_) => TextEditingController(text: _defaultDeparture)),
    );
    final currentPatterns = widget.child.weeklyPatterns.where((p) => p.validUntil == null).toList();
    if (currentPatterns.isNotEmpty) {
      _patternCount = currentPatterns.length.clamp(1, _maxPatterns);
      for (var p = 0; p < currentPatterns.length && p < _maxPatterns; p++) {
        final w = currentPatterns[p];
        for (final e in w.entries) {
          if (e.weekday >= 1 && e.weekday <= 5) {
            final i = e.weekday - 1;
            if (p < _scheduleArrivals.length && i < _scheduleArrivals[p].length) {
              _scheduleArrivals[p][i].text = e.arrivalTime ?? '';
            }
            if (p < _scheduleDeparts.length && i < _scheduleDeparts[p].length) {
              _scheduleDeparts[p][i].text = e.departureTime ?? '';
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final list in _scheduleArrivals) {
      for (final c in list) c.dispose();
    }
    for (final list in _scheduleDeparts) {
      for (final c in list) c.dispose();
    }
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_validFromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez la date à compter de laquelle les nouveaux horaires s\'appliquent.')),
      );
      return;
    }

    final patterns = <WeeklyPattern>[];
    for (var i = 0; i < _patternCount; i++) {
      final entries = <ScheduleEntry>[];
      for (var d = 0; d < 5; d++) {
        final arr = _scheduleArrivals[i][d].text.trim();
        final dep = _scheduleDeparts[i][d].text.trim();
        entries.add(ScheduleEntry(
          id: 0,
          patternId: 0,
          weekday: d + 1,
          arrivalTime: arr.isEmpty ? null : arr,
          departureTime: dep.isEmpty ? null : dep,
        ));
      }
      patterns.add(WeeklyPattern(
        id: 0,
        childId: widget.child.id,
        name: _patternNames[i],
        isActive: true,
        entries: entries,
        validFrom: _validFromDate,
        validUntil: null,
      ));
    }

    try {
      await ref.read(addScheduleChangeProvider).call(widget.child.id, _validFromDate!, patterns);
      ref.invalidate(childDetailProvider(widget.child.id));
      ref.invalidate(activeChildrenControllerProvider);
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveaux horaires enregistrés. L\'historique est conservé.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveaux horaires'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ces horaires seront applicables à compter de la date choisie. Les horaires précédents restent enregistrés dans l\'historique.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _validFromDate ?? DateTime.now(),
                  firstDate: widget.child.contractStartDate,
                  lastDate: widget.child.contractEndDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _validFromDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Nouveaux horaires à compter du',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _validFromDate == null
                      ? 'Choisir une date'
                      : dateFormat.format(_validFromDate!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_patternCount, (p) => [
              if (p > 0) const SizedBox(height: 12),
              Text(
                'Horaires ${_patternNames[p]}',
                style: TextStyle(
                  fontSize: p == 0 ? 18 : 16,
                  fontWeight: p == 0 ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _ScheduleGrid(
                arrivalControllers: _scheduleArrivals[p],
                departureControllers: _scheduleDeparts[p],
              ),
            ]).expand((e) => e),
            const SizedBox(height: 8),
            if (_patternCount < _maxPatterns)
              TextButton.icon(
                onPressed: () => setState(() => _patternCount++),
                icon: const Icon(Icons.add_circle_outline),
                label: Text('Ajouter une ${_patternNames[_patternCount]}'),
              ),
            if (_patternCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  onPressed: () => setState(() => _patternCount--),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text('Retirer la ${_patternNames[_patternCount - 1]}'),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _onSave,
              child: const Text('Enregistrer les nouveaux horaires'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({
    required this.arrivalControllers,
    required this.departureControllers,
  });

  final List<TextEditingController> arrivalControllers;
  final List<TextEditingController> departureControllers;

  static const _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(40),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        const TableRow(
          children: [
            SizedBox(),
            Text('Arrivée', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('Départ', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        for (var i = 0; i < 5; i++) ...[
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(_days[i]),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: TextFormField(
                  controller: arrivalControllers[i],
                  decoration: const InputDecoration(hintText: '08:00', isDense: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: TextFormField(
                  controller: departureControllers[i],
                  decoration: const InputDecoration(hintText: '18:00', isDense: true),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
