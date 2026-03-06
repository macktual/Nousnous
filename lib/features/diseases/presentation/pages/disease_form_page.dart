import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../children/presentation/controllers/children_controllers.dart';
import '../../domain/entities/disease_entry.dart';
import '../controllers/disease_controllers.dart';

class DiseaseFormPage extends ConsumerStatefulWidget {
  const DiseaseFormPage({
    super.key,
    required this.childId,
    this.entry,
  });

  final int childId;
  /// null = nouvelle maladie ; non null = édition
  final DiseaseEntry? entry;

  @override
  ConsumerState<DiseaseFormPage> createState() => _DiseaseFormPageState();
}

class _DiseaseFormPageState extends ConsumerState<DiseaseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  int? _month;
  int? _year;
  int? _day;

  static const List<String> _monthLabels = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static int _lastDayOfMonth(int year, int month) {
    if (month < 1 || month > 12) return 31;
    return DateTime(year, month + 1, 0).day;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.entry != null) {
      final e = widget.entry!;
      _nameCtrl.text = e.name;
      _month = e.dateMonth;
      _year = e.dateYear;
      _day = e.dateDay;
    } else {
      _month = now.month;
      _year = now.year;
      _day = now.day;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final entry = DiseaseEntry(
      id: widget.entry?.id ?? 0,
      childId: widget.childId,
      name: name,
      dateMonth: _month,
      dateYear: _year,
      dateDay: _day,
    );

    await ref.read(saveDiseaseProvider).call(entry);
    ref.invalidate(diseasesListProvider(widget.childId));
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final asyncChild = ref.watch(childDetailProvider(widget.childId));
    final currentYear = DateTime.now().year;
    final years = List.generate(20, (i) => currentYear - 15 + i);

    return asyncChild.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Maladie')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        final title = widget.entry == null ? 'Nouvelle maladie' : 'Modifier la maladie';
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
            title: Text(title),
            actions: [
              TextButton(
                onPressed: _save,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la maladie *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                const Text('Date (par défaut : aujourd’hui, jour optionnel)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('day_$_day'),
                        initialValue: _day,
                        decoration: const InputDecoration(
                          labelText: 'Jour (opt.)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('–')),
                          ...List.generate(31, (i) => DropdownMenuItem<int?>(value: i + 1, child: Text('${i + 1}'))),
                        ],
                        onChanged: (v) => setState(() {
                          _day = v;
                          if (v != null && _month != null && _year != null && v > _lastDayOfMonth(_year!, _month!)) {
                            _day = _lastDayOfMonth(_year!, _month!);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('month_$_month'),
                        initialValue: _month,
                        decoration: const InputDecoration(
                          labelText: 'Mois',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('–')),
                          ...List.generate(12, (i) => DropdownMenuItem<int?>(value: i + 1, child: Text(_monthLabels[i]))),
                        ],
                        onChanged: (v) => setState(() {
                          _month = v;
                          if (_day != null && v != null && _year != null) {
                            final last = _lastDayOfMonth(_year!, v);
                            if (_day! > last) _day = last;
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('year_$_year'),
                        initialValue: _year,
                        decoration: const InputDecoration(
                          labelText: 'Année',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('–')),
                          ...years.map((y) => DropdownMenuItem<int?>(value: y, child: Text(y.toString()))),
                        ],
                        onChanged: (v) => setState(() {
                          _year = v;
                          if (_day != null && _month != null && v != null) {
                            final last = _lastDayOfMonth(v, _month!);
                            if (_day! > last) _day = last;
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
