import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'doctor_session.dart';
import 'treatment_visuals.dart';

class AddTreatmentScreen extends StatefulWidget {
  const AddTreatmentScreen({super.key, this.existingRecord});

  final Map<String, dynamic>? existingRecord;

  @override
  State<AddTreatmentScreen> createState() => _AddTreatmentScreenState();
}

class _AddTreatmentScreenState extends State<AddTreatmentScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _treatmentSearchController =
      TextEditingController();

  List<Map<String, dynamic>> _treatments = [];
  List<Map<String, dynamic>> _patientSuggestions = [];
  List<Map<String, dynamic>> _quickTreatments = [];

  int? _selectedTreatmentId;
  bool _isSaving = false;

  bool get _isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    _patientController.addListener(_onPatientInputChanged);
    _treatmentSearchController.addListener(_onTreatmentSearchChanged);
    _loadCatalogs();
  }

  @override
  void dispose() {
    _patientController.removeListener(_onPatientInputChanged);
    _treatmentSearchController.removeListener(_onTreatmentSearchChanged);
    _patientController.dispose();
    _priceController.dispose();
    _treatmentSearchController.dispose();
    super.dispose();
  }

  String get _treatmentQuery => _treatmentSearchController.text.trim().toLowerCase();

  List<Map<String, dynamic>> get _filteredTreatments {
    if (_treatmentQuery.isEmpty) return _treatments;
    return _treatments.where((item) {
      final name = (item['nombre'] as String).toLowerCase();
      return name.contains(_treatmentQuery);
    }).toList();
  }

  List<Map<String, dynamic>> _buildFallbackQuickTreatments() {
    const commonKeywords = [
      'limpieza',
      'ortodoncia',
      'implante',
      'endodoncia',
      'blanqueamiento',
      'caries',
    ];

    final quick = <Map<String, dynamic>>[];
    for (final keyword in commonKeywords) {
      final match = _treatments.where(
        (item) =>
            (item['nombre'] as String).toLowerCase().contains(keyword) &&
            !quick.contains(item),
      );
      quick.addAll(match);
      if (quick.length >= 6) break;
    }

    if (quick.length < 6) {
      for (final item in _treatments) {
        if (!quick.contains(item)) {
          quick.add(item);
        }
        if (quick.length >= 6) break;
      }
    }

    return quick;
  }

  Future<void> _loadQuickTreatmentsForDoctor() async {
    final doctorId = DoctorSession.selectedDoctorId;
    List<Map<String, dynamic>> quick = [];

    if (doctorId != null) {
      quick = await _db.getTopTreatmentsByDoctor(doctorId, limit: 8);
    }

    if (quick.isEmpty) {
      quick = _buildFallbackQuickTreatments();
    }

    if (!mounted) return;
    setState(() {
      _quickTreatments = quick;
    });
  }

  List<Map<String, dynamic>> get _dropdownTreatments {
    if (_selectedTreatmentId == null) return _filteredTreatments;
    final alreadyIncluded =
        _filteredTreatments.any((item) => item['id'] == _selectedTreatmentId);
    if (alreadyIncluded) return _filteredTreatments;

    final selected = _treatments.where(
      (item) => item['id'] == _selectedTreatmentId,
    );
    return [..._filteredTreatments, ...selected];
  }

  Future<void> _onPatientInputChanged() async {
    final suggestions = await _db.searchPatientsByName(_patientController.text);
    if (!mounted) return;
    setState(() {
      _patientSuggestions = suggestions;
    });
  }

  void _onTreatmentSearchChanged() {
    setState(() {});
  }

  void _selectPatientSuggestion(String name) {
    _patientController
      ..text = name
      ..selection = TextSelection.collapsed(offset: name.length);
    setState(() {
      _patientSuggestions = [];
    });
  }

  // Carga odontólogos y tratamientos para los selectores del formulario.
  Future<void> _loadCatalogs() async {
    final treatments = await _db.getTreatments();

    if (!mounted) return;

    setState(() {
      _treatments = treatments;
    });

    await _loadQuickTreatmentsForDoctor();

    if (_isEdit) {
      _loadEditValues();
      return;
    }

    if (_treatments.isNotEmpty) {
      final initial = _quickTreatments.isNotEmpty
          ? _quickTreatments.first
          : _treatments.first;
      _selectedTreatmentId = initial['id'] as int;
      final defaultPrice = initial['precio_predeterminado'] as num;
      _priceController.text = defaultPrice.toStringAsFixed(2);
    }

    setState(() {});
  }

  // Precarga datos cuando se edita un registro existente.
  void _loadEditValues() {
    final record = widget.existingRecord!;
    _patientController.text = record['paciente'] as String;
    _selectedTreatmentId = record['tratamiento_id'] as int;
    final price = (record['precio_final'] as num).toDouble();
    _priceController.text = price.toStringAsFixed(2);
    setState(() {});
  }

  // Aplica precio predeterminado del tratamiento elegido (editable por usuario).
  void _applyTreatmentDefaultPrice(int treatmentId) {
    final selected = _treatments.firstWhere(
      (item) => item['id'] == treatmentId,
      orElse: () => <String, dynamic>{},
    );

    if (selected.isEmpty) return;
    final defaultPrice = selected['precio_predeterminado'] as num;
    _priceController.text = defaultPrice.toStringAsFixed(2);
  }

  // Guarda alta o edición en la tabla registro_diario.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTreatmentId == null) return;

    final doctorId = DoctorSession.selectedDoctorId;
    if (doctorId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final patientId = await _db.upsertPatientByName(_patientController.text);
      final now = DateTime.now();

      final payload = <String, dynamic>{
        'fecha': _db.dateKey(now),
        'paciente_id': patientId,
        'odontologo_id': doctorId,
        'tratamiento_id': _selectedTreatmentId,
        'precio_final': double.parse(_priceController.text.replaceAll(',', '.')),
        'created_at': _isEdit
            ? widget.existingRecord!['created_at'] as int
            : now.millisecondsSinceEpoch,
      };

      if (_isEdit) {
        await _db.updateDailyRecord(widget.existingRecord!['id'] as int, payload);
      } else {
        await _db.insertDailyRecord(payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DatabaseException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el tratamiento.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCatalogEmpty = _treatments.isEmpty;
    final cs = Theme.of(context).colorScheme;
    final doctorName = DoctorSession.selectedDoctorName ?? 'Sin doctor';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar tratamiento' : 'Agregar tratamiento'),
      ),
      body: isCatalogEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Debes crear al menos un odontólogo y un tratamiento en Ajustes.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            _isEdit ? Icons.edit_note : Icons.note_add,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isEdit
                                ? 'Actualiza el tratamiento y guarda cambios.'
                                : 'Registra un tratamiento de forma rápida y precisa.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.person, color: cs.onPrimaryContainer),
                      ),
                      title: const Text('Doctor activo'),
                      subtitle: Text(
                        doctorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo de paciente (nuevo o existente).
                  TextFormField(
                    controller: _patientController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del paciente',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el nombre del paciente';
                      }
                      return null;
                    },
                  ),
                  if (_patientSuggestions.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: _patientSuggestions
                            .map(
                              (patient) => ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: cs.secondaryContainer,
                                  child: Icon(
                                    Icons.person_search,
                                    size: 18,
                                    color: cs.onSecondaryContainer,
                                  ),
                                ),
                                title: Text(patient['nombre'] as String),
                                onTap: () => _selectPatientSuggestion(
                                  patient['nombre'] as String,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),

                  if (_quickTreatments.isNotEmpty) ...[
                    const Text(
                      'Selección rápida',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickTreatments.map((treatment) {
                        final id = treatment['id'] as int;
                        final isSelected = _selectedTreatmentId == id;
                        final name = treatment['nombre'] as String;
                        final visual = treatmentVisualByName(name);
                        return SizedBox(
                          width: 160,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: isSelected
                                  ? visual.color
                                  : visual.color.withValues(alpha: 0.16),
                              foregroundColor:
                                  isSelected ? Colors.white : visual.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedTreatmentId = id;
                              });
                              if (!_isEdit) {
                                _applyTreatmentDefaultPrice(id);
                              }
                            },
                            icon: Icon(visual.icon),
                            label: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: _treatmentSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar tratamiento específico',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selector de tratamiento configurable en Ajustes.
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTreatmentId,
                    items: _dropdownTreatments
                        .map(
                          (t) => DropdownMenuItem<int>(
                            value: t['id'] as int,
                            child: Text(t['nombre'] as String),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Tratamiento',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedTreatmentId = value;
                      });
                      if (!_isEdit) {
                        _applyTreatmentDefaultPrice(value);
                      }
                    },
                  ),
                  if (_dropdownTreatments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No hay tratamientos para esa búsqueda.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Precio final editable para descuentos u otros ajustes.
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio final',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el precio final';
                      }
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      if (parsed == null) {
                        return 'Precio inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isEdit ? 'Actualizar' : 'Guardar'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver sin guardar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
