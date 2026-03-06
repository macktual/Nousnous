import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../assistant_profile/domain/entities/assistant.dart';
import '../../../assistant_profile/presentation/controllers/assistant_profile_controller.dart';
import '../../../children/presentation/controllers/children_controllers.dart';
import '../../domain/entities/medication_entry.dart';
import '../controllers/medication_controllers.dart';

class MedicationFormPage extends ConsumerStatefulWidget {
  const MedicationFormPage({
    super.key,
    required this.childId,
    this.entry,
  });

  final int childId;
  /// null = nouvelle prise ; non null = édition
  final MedicationEntry? entry;

  @override
  ConsumerState<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends ConsumerState<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameCtrl = TextEditingController();
  final _medicationNameFocusNode = FocusNode();
  final _posologyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _administeredByCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late DateTime _dateTime;
  bool _initialized = false;
  bool _defaultAdministeredSet = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final e = widget.entry!;
      _dateTime = e.dateTime;
      _medicationNameCtrl.text = e.medicationName;
      _posologyCtrl.text = e.posology ?? '';
      _reasonCtrl.text = e.reason ?? '';
      _administeredByCtrl.text = e.administeredBy ?? '';
      _notesCtrl.text = e.notes ?? '';
    } else {
      _dateTime = DateTime.now();
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _medicationNameCtrl.dispose();
    _posologyCtrl.dispose();
    _reasonCtrl.dispose();
    _administeredByCtrl.dispose();
    _notesCtrl.dispose();
    _medicationNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _medicationNameCtrl.text.trim();
    if (name.isEmpty) return;

    final entry = MedicationEntry(
      id: widget.entry?.id ?? 0,
      childId: widget.childId,
      dateTime: _dateTime,
      medicationName: name,
      posology: _posologyCtrl.text.trim().isEmpty ? null : _posologyCtrl.text.trim(),
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      administeredBy: _administeredByCtrl.text.trim().isEmpty ? null : _administeredByCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await ref.read(saveMedicationProvider).call(entry);
    ref.invalidate(medicationsListProvider(widget.childId));
    if (!mounted) return;
    context.pop();
  }

  void _applyDefaultAdministeredBy(Assistant? assistant) {
    if (assistant == null || widget.entry != null || _defaultAdministeredSet) return;
    final name = '${assistant.firstName} ${assistant.lastName}'.trim();
    if (name.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_defaultAdministeredSet && _administeredByCtrl.text.isEmpty) {
        _defaultAdministeredSet = true;
        _administeredByCtrl.text = name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncChild = ref.watch(childDetailProvider(widget.childId));
    final assistantAsync = ref.watch(assistantProfileControllerProvider);
    final medicationNamesAsync = ref.watch(medicationNamesProvider);
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    assistantAsync.whenData((state) => _applyDefaultAdministeredBy(state.assistant));

    return asyncChild.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Médicament')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        final title = widget.entry == null ? 'Nouvelle prise' : 'Modifier la prise';
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date et heure'),
                  subtitle: Text(_initialized ? dateFormat.format(_dateTime) : ''),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 8),
                medicationNamesAsync.when(
                  data: (names) {
                    if (names.isEmpty) {
                      // Aucun historique : simple champ texte.
                      return TextFormField(
                        controller: _medicationNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Médicament *',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      );
                    }
                    // Autocomplétion : liste filtrée au fur et à mesure de la saisie.
                    return RawAutocomplete<String>(
                      textEditingController: _medicationNameCtrl,
                      focusNode: _medicationNameFocusNode,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.trim().toLowerCase();
                        if (query.isEmpty) {
                          return names;
                        }
                        return names.where(
                          (name) => name.toLowerCase().contains(query),
                        );
                      },
                      displayStringForOption: (option) => option,
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Médicament *',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: options.map((option) {
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => TextFormField(
                    controller: _medicationNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Médicament *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  error: (_, __) => TextFormField(
                    controller: _medicationNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Médicament *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _posologyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Posologie',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motif',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _administeredByCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Administré par',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Observations',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
