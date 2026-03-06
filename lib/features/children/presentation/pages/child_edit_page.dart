import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/photo/photo_helper.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/entities/child.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/weekly_pattern.dart';
import '../controllers/children_controllers.dart';

class ChildEditPage extends ConsumerStatefulWidget {
  const ChildEditPage({super.key, this.childId});

  /// null ou 0 = création ; sinon édition
  final int? childId;

  @override
  ConsumerState<ChildEditPage> createState() => _ChildEditPageState();
}

class _ChildEditPageState extends ConsumerState<ChildEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _p1FirstNameCtrl = TextEditingController();
  final _p1LastNameCtrl = TextEditingController();
  final _p1AddressCtrl = TextEditingController();
  final _p1PostalCodeCtrl = TextEditingController();
  final _p1CityCtrl = TextEditingController();
  final _p1PhoneCtrl = TextEditingController();
  final _p1EmailCtrl = TextEditingController();
  final _p2FirstNameCtrl = TextEditingController();
  final _p2LastNameCtrl = TextEditingController();
  final _p2AddressCtrl = TextEditingController();
  final _p2PostalCodeCtrl = TextEditingController();
  final _p2CityCtrl = TextEditingController();
  final _p2PhoneCtrl = TextEditingController();
  final _p2EmailCtrl = TextEditingController();

  /// Contrôleurs dédiés aux horaires pour éviter les mélanges d’état (téléphone, etc.).
  /// [patternIndex][dayIndex 0..4] : arrivée et départ.
  late final List<List<TextEditingController>> _scheduleArrivals;
  late final List<List<TextEditingController>> _scheduleDeparts;

  DateTime? _birthDate;
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  bool _sameAddressAsP1 = true;
  bool _hasSemaineB = false;

  String _toTitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .split(RegExp(r'\\s+'))
        .where((p) => p.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }
  String? _photoPath;
  bool? _vacancesScolaires;
  final _particularitesAccueilCtrl = TextEditingController();
  /// Motif de départ (saisi à l'archivage), conservé en édition
  String? _particularitesFinContrat;

  static const List<String> _patternNames = ['Semaine type', 'Semaine B'];

  /// Valeurs par défaut pour les horaires (à modifier si besoin).
  static const String _defaultArrival = '08:00';
  static const String _defaultDeparture = '18:00';

  @override
  void initState() {
    super.initState();
    _scheduleArrivals = [
      List.generate(5, (_) => TextEditingController(text: _defaultArrival)),
      List.generate(5, (_) => TextEditingController(text: _defaultArrival)),
    ];
    _scheduleDeparts = [
      List.generate(5, (_) => TextEditingController(text: _defaultDeparture)),
      List.generate(5, (_) => TextEditingController(text: _defaultDeparture)),
    ];
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _p1FirstNameCtrl.dispose();
    _p1LastNameCtrl.dispose();
    _p1AddressCtrl.dispose();
    _p1PostalCodeCtrl.dispose();
    _p1CityCtrl.dispose();
    _p1PhoneCtrl.dispose();
    _p1EmailCtrl.dispose();
    _p2FirstNameCtrl.dispose();
    _p2LastNameCtrl.dispose();
    _p2AddressCtrl.dispose();
    _p2PostalCodeCtrl.dispose();
    _p2CityCtrl.dispose();
    _p2PhoneCtrl.dispose();
    _p2EmailCtrl.dispose();
    for (final list in _scheduleArrivals) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in _scheduleDeparts) {
      for (final c in list) {
        c.dispose();
      }
    }
    _particularitesAccueilCtrl.dispose();
    super.dispose();
  }

  bool get _isCreate => widget.childId == null || widget.childId == 0;

  @override
  Widget build(BuildContext context) {
    if (_isCreate) {
      return _buildForm(context, null);
    }
    final asyncChild = ref.watch(childDetailProvider(widget.childId!));
    return asyncChild.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Modifier l\'enfant')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child != null && child.isArchived) {
          return _buildArchivedMessage(context);
        }
        if (!_isCreate && child == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              title: const Text('Modifier l\'enfant'),
            ),
            body: const Center(child: Text('Enfant introuvable.')),
          );
        }
        if (child != null && _firstNameCtrl.text.isEmpty && child.firstName.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _fillFromChild(child));
        }
        return _buildForm(context, child);
      },
    );
  }

  Widget _buildArchivedMessage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Modifier l\'enfant'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.archive, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Cet enfant est archivé.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Les données ne peuvent plus être modifiées.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fillFromChild(Child child) {
    _firstNameCtrl.text = child.firstName;
    _lastNameCtrl.text = child.lastName;
    _photoPath = child.photoPath;
    _birthDate = child.birthDate;
    _contractStartDate = child.contractStartDate;
    _contractEndDate = child.contractEndDate;
    _vacancesScolaires = child.vacancesScolaires;
    _particularitesAccueilCtrl.text = child.particularitesAccueil ?? '';
    _particularitesFinContrat = child.particularitesFinContrat;
    ParentInfo? p1;
    ParentInfo? p2;
    for (final p in child.parents) {
      if (p.role == 'parent1') p1 = p;
      if (p.role == 'parent2') p2 = p;
    }
    if (p1 != null) {
      _p1FirstNameCtrl.text = p1.firstName;
      _p1LastNameCtrl.text = p1.lastName;
      _p1AddressCtrl.text = p1.address;
      _p1PostalCodeCtrl.text = p1.postalCode ?? '';
      _p1CityCtrl.text = p1.city ?? '';
      _p1PhoneCtrl.text = p1.phone;
      _p1EmailCtrl.text = p1.email;
    }
    if (p2 != null) {
      _p2FirstNameCtrl.text = p2.firstName;
      _p2LastNameCtrl.text = p2.lastName;
      _p2AddressCtrl.text = p2.address;
      _p2PostalCodeCtrl.text = p2.postalCode ?? '';
      _p2CityCtrl.text = p2.city ?? '';
      _p2PhoneCtrl.text = p2.phone;
      _p2EmailCtrl.text = p2.email;
      _sameAddressAsP1 = p2.address == p1?.address &&
          (p2.postalCode ?? '') == (p1?.postalCode ?? '') &&
          (p2.city ?? '') == (p1?.city ?? '');
    }
    final currentPatterns = child.weeklyPatterns.where((p) => p.validUntil == null).toList();
    if (currentPatterns.isNotEmpty) {
      _hasSemaineB = currentPatterns.length > 1;
      for (var p = 0; p < currentPatterns.length && p < 2; p++) {
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
    setState(() {});
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
      if (xFile == null || !mounted) return;
      final path = await savePickedPhoto(xFile, childId: widget.childId);
      if (path != null && mounted) setState(() => _photoPath = path);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir l\'appareil photo ou la galerie. Vérifiez les autorisations.')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
                title: Text('Supprimer la photo', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final initial = _firstNameCtrl.text.trim().isNotEmpty
        ? _firstNameCtrl.text.trim().characters.first.toUpperCase()
        : '?';
    const radius = 48.0;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showPhotoOptions,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: buildChildPhotoAvatar(
                context: context,
                photoPath: _photoPath,
                initial: initial,
                radius: radius,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyer pour changer la photo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, Child? child) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
        title: Text(_isCreate ? 'Nouvel enfant' : 'Modifier l\'enfant'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Enfant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (isPhotoSupported) _buildPhotoSection(),
            if (isPhotoSupported) const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Prénom *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            _DateField(
              label: 'Date de naissance *',
              value: _birthDate,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _birthDate ?? DateTime.now(),
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _birthDate = d);
              },
              format: dateFormat,
            ),
            const SizedBox(height: 16),
            const Text('Contrat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _DateField(
              label: 'Début de contrat *',
              value: _contractStartDate,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _contractStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _contractStartDate = d);
              },
              format: dateFormat,
            ),
            const SizedBox(height: 8),
            _DateField(
              label: 'Fin de contrat (optionnel)',
              value: _contractEndDate,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _contractEndDate ?? DateTime.now(),
                  firstDate: _contractStartDate ?? DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _contractEndDate = d);
              },
              format: dateFormat,
            ),
            const SizedBox(height: 12),
            const Text('Vacances scolaires', style: TextStyle(fontSize: 12)),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Oui'),
                  selected: _vacancesScolaires == true,
                  onSelected: (v) => setState(() => _vacancesScolaires = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Non'),
                  selected: _vacancesScolaires == false,
                  onSelected: (v) => setState(() => _vacancesScolaires = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _particularitesAccueilCtrl,
              decoration: const InputDecoration(
                labelText: 'Particularités d\'accueil / Motif de départ',
                hintText: 'À compléter (motif de départ à l\'archivage)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Parent 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _p1LastNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p1FirstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p1AddressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adresse (voie, numéro)',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _p1PostalCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code postal',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _p1CityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p1PhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p1EmailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            const Text('Parent 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Même adresse que le parent 1'),
              value: _sameAddressAsP1,
              onChanged: (v) {
                setState(() {
                  _sameAddressAsP1 = v ?? true;
                  if (_sameAddressAsP1) {
                    _p2AddressCtrl.text = _p1AddressCtrl.text;
                    _p2PostalCodeCtrl.text = _p1PostalCodeCtrl.text;
                    _p2CityCtrl.text = _p1CityCtrl.text;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _p2LastNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p2FirstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p2AddressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adresse (voie, numéro)',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
              enabled: !_sameAddressAsP1,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _p2PostalCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code postal',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_sameAddressAsP1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _p2CityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_sameAddressAsP1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p2PhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _p2EmailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text('Horaires (semaine type)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ScheduleGrid(
              arrivalControllers: _scheduleArrivals[0],
              departureControllers: _scheduleDeparts[0],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Modifier un horaire le reporte sur les jours suivants.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (_hasSemaineB) ...[
              const SizedBox(height: 8),
              const Text('Horaires Semaine B', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              _ScheduleGrid(
                arrivalControllers: _scheduleArrivals[1],
                departureControllers: _scheduleDeparts[1],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Modifier un horaire le reporte sur les jours suivants.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _hasSemaineB = false),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Retirer la Semaine B'),
              ),
            ] else
              TextButton.icon(
                onPressed: () => setState(() => _hasSemaineB = true),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Ajouter une Semaine B'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _onSave,
              child: Text(_isCreate ? 'Créer l\'enfant' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renseignez la date de naissance.')));
      return;
    }
    if (_contractStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renseignez le début de contrat.')));
      return;
    }

    final p1Address = _p1AddressCtrl.text.trim();
    final p1PostalCode = _p1PostalCodeCtrl.text.trim();
    final p1City = _p1CityCtrl.text.trim();
    final p2Address = _sameAddressAsP1 ? p1Address : _p2AddressCtrl.text.trim();
    final p2PostalCode = _sameAddressAsP1 ? p1PostalCode : _p2PostalCodeCtrl.text.trim();
    final p2City = _sameAddressAsP1 ? p1City : _p2CityCtrl.text.trim();

    final parents = <ParentInfo>[
      ParentInfo(
        id: 0,
        childId: 0,
        role: 'parent1',
        firstName: _toTitleCase(_p1FirstNameCtrl.text),
        lastName: _toTitleCase(_p1LastNameCtrl.text),
        address: p1Address,
        phone: _p1PhoneCtrl.text.trim(),
        email: _p1EmailCtrl.text.trim(),
        postalCode: p1PostalCode.isEmpty ? null : p1PostalCode,
        city: p1City.isEmpty ? null : p1City,
      ),
      ParentInfo(
        id: 0,
        childId: 0,
        role: 'parent2',
        firstName: _toTitleCase(_p2FirstNameCtrl.text),
        lastName: _toTitleCase(_p2LastNameCtrl.text),
        address: p2Address,
        phone: _p2PhoneCtrl.text.trim(),
        email: _p2EmailCtrl.text.trim(),
        postalCode: p2PostalCode.isEmpty ? null : p2PostalCode,
        city: p2City.isEmpty ? null : p2City,
      ),
    ];

    final patterns = <WeeklyPattern>[];
    final patternCount = _hasSemaineB ? 2 : 1;
    for (var i = 0; i < patternCount; i++) {
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
        childId: 0,
        name: _patternNames[i],
        isActive: true,
        entries: entries,
      ));
    }

    final childEntity = Child(
      id: _isCreate ? 0 : widget.childId!,
      firstName: _toTitleCase(_firstNameCtrl.text),
      lastName: _toTitleCase(_lastNameCtrl.text),
      birthDate: _birthDate!,
      contractStartDate: _contractStartDate!,
      contractEndDate: _contractEndDate,
      isArchived: false,
      photoPath: _photoPath,
      parents: parents,
      weeklyPatterns: patterns,
      currentPatternId: null,
      vacancesScolaires: _vacancesScolaires,
      particularitesAccueil: _particularitesAccueilCtrl.text.trim().isEmpty ? null : _particularitesAccueilCtrl.text.trim(),
      particularitesFinContrat: _particularitesFinContrat,
    );

    try {
      if (_isCreate) {
        final id = await ref.read(createChildProvider).call(childEntity);
        ref.invalidate(activeChildrenControllerProvider);
        if (!mounted) return;
        context.go('/children/$id');
      } else {
        await ref.read(updateChildProvider).call(childEntity);
        ref.invalidate(activeChildrenControllerProvider);
        ref.invalidate(childDetailProvider(widget.childId!));
        if (!mounted) return;
        context.pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isCreate ? 'Enfant créé.' : 'Modifications enregistrées.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.format,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final DateFormat format;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: Text(value == null ? 'Choisir une date' : format.format(value!))),
            const Icon(Icons.calendar_today),
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
                  onChanged: (value) {
                    for (var j = i + 1; j < 5; j++) {
                      if (arrivalControllers[j].text != value) {
                        arrivalControllers[j].text = value;
                      }
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: TextFormField(
                  controller: departureControllers[i],
                  decoration: const InputDecoration(hintText: '18:00', isDense: true),
                  onChanged: (value) {
                    for (var j = i + 1; j < 5; j++) {
                      if (departureControllers[j].text != value) {
                        departureControllers[j].text = value;
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
