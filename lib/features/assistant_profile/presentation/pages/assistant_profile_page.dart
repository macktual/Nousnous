import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/photo/photo_helper.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/signature/signature_pad.dart';
import '../../domain/entities/assistant.dart';
import '../controllers/assistant_profile_controller.dart';

class AssistantProfilePage extends ConsumerStatefulWidget {
  const AssistantProfilePage({super.key});

  @override
  ConsumerState<AssistantProfilePage> createState() => _AssistantProfilePageState();
}

class _AssistantProfilePageState extends ConsumerState<AssistantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _signatureKey = GlobalKey();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _accessCodeCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _approvalNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  DateTime? _approvalDate;
  Assistant? _lastFilledAssistant;
  String? _civility; // "Mme" ou "M."
  int? _agreementMaxChildren; // 1 à 4
  bool _isSigning = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _postalCodeCtrl.dispose();
    _cityCtrl.dispose();
    _accessCodeCtrl.dispose();
    _floorCtrl.dispose();
    _approvalNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _fillFromAssistant(Assistant? a) {
    if (a == null) return;
    _firstNameCtrl.text = a.firstName;
    _lastNameCtrl.text = a.lastName;
    _addressCtrl.text = a.address;
    _postalCodeCtrl.text = a.postalCode ?? '';
    _cityCtrl.text = a.city ?? '';
    _accessCodeCtrl.text = a.accessCode ?? '';
    _floorCtrl.text = a.floor ?? '';
    _approvalNumberCtrl.text = a.approvalNumber;
    _approvalDate = a.approvalDate;
    _agreementMaxChildren = a.agreementMaxChildren;
    _civility = a.civility;
    _phoneCtrl.text = a.phone ?? '';
    _emailCtrl.text = a.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(assistantProfileControllerProvider);

    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Profil assistant maternel')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur : $e'),
        ),
      ),
      data: (state) {
        if (!state.isStorageAvailable) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil assistant maternel')),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Le stockage SQLite n’est pas disponible sur navigateur.\n\n'
                'Pour tester la persistance, lancez l’app sur macOS, iOS ou Android.',
              ),
            ),
          );
        }

        // Ne remplir le formulaire que lorsque les données chargées changent (premier affichage ou après enregistrement),
        // pour ne pas écraser la date d'agrément que l'utilisateur vient de modifier avant d'avoir cliqué sur Enregistrer.
        if (state.assistant != _lastFilledAssistant) {
          _lastFilledAssistant = state.assistant;
          _fillFromAssistant(state.assistant);
        }

        final approvalDateText = _approvalDate == null
            ? 'Choisir une date'
            : DateFormat('dd/MM/yyyy').format(_approvalDate!);

        final isFirstRoute = ModalRoute.of(context)?.isFirst ?? false;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(isFirstRoute ? Icons.home : Icons.arrow_back),
              tooltip: isFirstRoute ? 'Accéder à l\'app' : 'Retour',
              onPressed: () {
                if (isFirstRoute) {
                  context.go(RoutePaths.home);
                } else {
                  context.pop();
                }
              },
            ),
            title: const Text('Profil assistant maternel'),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: _isSigning ? const NeverScrollableScrollPhysics() : null,
                children: [
                  const Text(
                    'Informations professionnelles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text('Civilité', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Madame'),
                        selected: _civility == 'Mme',
                        onSelected: (selected) {
                          if (selected) setState(() => _civility = 'Mme');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Monsieur'),
                        selected: _civility == 'M.',
                        onSelected: (selected) {
                          if (selected) setState(() => _civility = 'M.');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Champ obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _firstNameCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Champ obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Adresse (voie, numéro)',
                      alignLabelWithHint: true,
                    ),
                    minLines: 1,
                    maxLines: 2,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Champ obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _postalCodeCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Code postal'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Obligatoire';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _cityCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Ville'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Obligatoire';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _accessCodeCtrl,
                          decoration: const InputDecoration(labelText: "Code d'accès"),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _floorCtrl,
                          decoration: const InputDecoration(labelText: 'Étage'),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _approvalNumberCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Numéro d’agrément'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Champ obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de l’agrément',
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(approvalDateText)),
                        TextButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final initial = _approvalDate ?? DateTime(now.year, now.month, now.day);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(1970),
                              lastDate: DateTime(now.year + 1),
                              helpText: 'Sélectionner la date de l’agrément',
                            );
                            if (picked == null) return;
                            setState(() => _approvalDate = picked);
                          },
                          child: const Text('Choisir'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Avec agrément : pour combien d’enfants ? (maxi 4)', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [1, 2, 3, 4].map((n) {
                      final selected = _agreementMaxChildren == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$n'),
                          selected: selected,
                          onSelected: (v) => setState(() => _agreementMaxChildren = v == true ? n : null),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Courriel'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ma signature (pour les déclarations arrivée/départ)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.assistant?.signaturePath != null
                        ? 'Une signature est enregistrée. Redessinez ci-dessous pour la remplacer.'
                        : 'Signez dans le cadre ci-dessous. Cette signature sera utilisée dans les documents de déclaration arrivée/départ.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Listener(
                    onPointerDown: (_) => setState(() => _isSigning = true),
                    onPointerUp: (_) => setState(() => _isSigning = false),
                    onPointerCancel: (_) => setState(() => _isSigning = false),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SignaturePad(repaintBoundaryKey: _signatureKey, height: 160),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: asyncState.isLoading
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final formOk = _formKey.currentState?.validate() ?? false;
                            if (!formOk) return;
                            final date = _approvalDate;
                            if (date == null) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Veuillez choisir la date de l’agrément.')),
                              );
                              return;
                            }
                            String? signaturePath;
                            try {
                              final image = await SignaturePad.capture(_signatureKey);
                              if (image != null) {
                                final list = await SignaturePad.imageToPngBytes(image);
                                if (list != null && list.isNotEmpty) {
                                  signaturePath = await saveAssistantSignature(Uint8List.fromList(list));
                                }
                              }
                            } catch (_) {}
                            await ref.read(assistantProfileControllerProvider.notifier).save(
                                  firstName: _firstNameCtrl.text,
                                  lastName: _lastNameCtrl.text,
                                  address: _addressCtrl.text,
                                  approvalNumber: _approvalNumberCtrl.text,
                                  approvalDate: date,
                                  civility: _civility,
                                  postalCode: _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
                                  city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
                                  accessCode: _accessCodeCtrl.text.trim().isEmpty ? null : _accessCodeCtrl.text.trim(),
                                  floor: _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
                                  phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                                  email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                                  agreementMaxChildren: _agreementMaxChildren,
                                  signaturePath: signaturePath,
                                );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Profil enregistré.')),
                            );
                          },
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

