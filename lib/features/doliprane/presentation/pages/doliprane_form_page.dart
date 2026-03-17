import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/doliprane_notification_service.dart';
import '../../../../core/photo/photo_helper.dart';
import '../../../children/domain/entities/child.dart';
import '../../../children/presentation/controllers/children_controllers.dart';
import '../../domain/entities/doliprane_prescription.dart';
import '../controllers/doliprane_controllers.dart';

class DolipraneFormPage extends ConsumerStatefulWidget {
  const DolipraneFormPage({
    super.key,
    required this.childId,
    this.prescription,
  });

  final int childId;
  /// null = nouvelle ordonnance ; non null = édition
  final DolipranePrescription? prescription;

  @override
  ConsumerState<DolipraneFormPage> createState() => _DolipraneFormPageState();
}

class _DolipraneFormPageState extends ConsumerState<DolipraneFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();

  late DateTime _endDate;
  /// Date de l'ordonnance = date de prise du poids (une seule date).
  DateTime? _dateOrdonnance;
  int? _reminderWeeks;
  String? _photoPath;
  bool _initialized = false;

  /// Rappel : uniquement 1 à 8 semaines avant la fin.
  static const List<int> _reminderWeeksOptions = [1, 2, 3, 4, 5, 6, 7, 8];

  /// Date de fin = date de l'ordonnance + 6 mois (calculée, non modifiable).
  static DateTime _endDateFromDateOrdonnance(DateTime dateOrdonnance) {
    return DateTime(
      dateOrdonnance.year,
      dateOrdonnance.month + DolipranePrescription.validityMonths,
      dateOrdonnance.day,
    );
  }

  /// Ordonnance valable 6 mois : date de début = date de l'ordonnance.
  static DateTime _startDateFromEnd(DateTime endDate) {
    return DateTime(
      endDate.year,
      endDate.month - DolipranePrescription.validityMonths,
      endDate.day,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.prescription != null) {
      final p = widget.prescription!;
      _dateOrdonnance = p.prescriptionDate ?? p.weightDate;
      _endDate = _dateOrdonnance != null
          ? _endDateFromDateOrdonnance(_dateOrdonnance!)
          : p.endDate;
      final rawReminder = p.reminderWeeksBeforeEnd;
      _reminderWeeks = (rawReminder != null && rawReminder >= 1 && rawReminder <= 8)
          ? rawReminder
          : null;
      _photoPath = p.photoPath;
      if (p.childWeightKg != null) {
        _weightCtrl.text = p.childWeightKg.toString();
      }
    } else {
      final now = DateTime.now();
      _dateOrdonnance = now;
      _endDate = _endDateFromDateOrdonnance(now);
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  /// Date de l'ordonnance = date de prise du poids. La date de fin est calculée (ordonnance + 6 mois).
  Future<void> _pickDateOrdonnance() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateOrdonnance ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() {
        _dateOrdonnance = date;
        _endDate = _endDateFromDateOrdonnance(date);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    final path = await saveDolipranePrescriptionPhoto(
      file,
      prescriptionId: widget.prescription?.id,
    );
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  Future<void> _save(Child child) async {
    if (!_formKey.currentState!.validate()) return;

    double? weight;
    if (_weightCtrl.text.trim().isNotEmpty) {
      weight = double.tryParse(_weightCtrl.text.trim().replaceFirst(',', '.'));
    }
    final reminderWeeksVal = _reminderWeeks;

    final startDate = _startDateFromEnd(_endDate);
    final prescription = DolipranePrescription(
      id: widget.prescription?.id ?? 0,
      childId: widget.childId,
      startDate: startDate,
      endDate: _endDate,
      prescriptionDate: _dateOrdonnance,
      childWeightKg: weight,
      weightDate: _dateOrdonnance,
      reminderWeeksBeforeEnd: reminderWeeksVal,
      photoPath: _photoPath,
    );

    final saved = await ref.read(saveDolipranePrescriptionProvider).call(prescription);
    ref.invalidate(dolipraneListProvider(widget.childId));

    if (widget.prescription != null) {
      await DolipraneNotificationService.cancelReminder(widget.prescription!.id);
    }
    if (saved.reminderWeeksBeforeEnd != null && saved.reminderDate != null) {
      await DolipraneNotificationService.scheduleReminder(
        prescriptionId: saved.id,
        reminderDate: saved.reminderDate!,
        childFirstName: child.firstName.isNotEmpty ? child.firstName : null,
      );
    }

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final asyncChild = ref.watch(childDetailProvider(widget.childId));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return asyncChild.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Ordonnance Doliprane')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ordonnance Doliprane')),
            body: const Center(child: Text('Enfant introuvable')),
          );
        }
        final title = widget.prescription == null ? 'Nouvelle ordonnance Doliprane' : 'Modifier l\'ordonnance';
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
            title: Text(title),
            actions: [
              TextButton(
                onPressed: () => _save(child),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Date de l\'ordonnance', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'La date de fin est calculée automatiquement (ordonnance + 6 mois)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de l\'ordonnance'),
                  subtitle: Text(
                    _dateOrdonnance != null
                        ? dateFormat.format(_dateOrdonnance!)
                        : 'Non renseignée',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateOrdonnance,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(
                    'Également date de prise du poids',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Valable jusqu\'au'),
                  subtitle: Text(
                    _initialized ? dateFormat.format(_endDate) : '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Poids de l\'enfant', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Poids (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.trim().replaceFirst(',', '.'));
                    if (n == null || n <= 0 || n > 200) return 'Poids invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('Rappel avant fin d\'ordonnance', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Choisir le nombre de semaines avant la fin (optionnel)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reminderWeeksOptions.map((w) {
                    return FilterChip(
                      label: Text('$w sem.'),
                      selected: _reminderWeeks == w,
                      onSelected: (selected) {
                        setState(() {
                          _reminderWeeks = selected ? w : (_reminderWeeks == w ? null : _reminderWeeks);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Photo de l\'ordonnance', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_photoPath != null && _photoPath!.isNotEmpty) ...[
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => showJustificationPhotoViewer(context, _photoPath!),
                        child: buildJustificationPhotoThumbnail(_photoPath!, size: 80),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Remplacer la photo'),
                        ),
                      ),
                    ],
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Ajouter une photo de l\'ordonnance'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
