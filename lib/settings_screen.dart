import 'package:flutter/material.dart';

import 'currency_utils.dart';
import 'database_helper.dart';
import 'treatment_visuals.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
  });

  final ValueChanged<bool> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _treatmentFilterController =
      TextEditingController();

  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _dentists = [];
  List<Map<String, dynamic>> _treatments = [];
  List<Map<String, dynamic>> _patients = [];
  String _treatmentFilter = '';

  @override
  void initState() {
    super.initState();
    _treatmentFilterController.addListener(() {
      setState(() {
        _treatmentFilter = _treatmentFilterController.text.trim().toLowerCase();
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _treatmentFilterController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTreatments {
    if (_treatmentFilter.isEmpty) return _treatments;
    return _treatments.where((item) {
      final name = '${item['nombre'] ?? ''}'.toLowerCase();
      return name.contains(_treatmentFilter);
    }).toList();
  }

  // Carga catálogos editables de odontólogos y tratamientos.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final dentists = await _db.getDentists();
      final treatments = await _db.getTreatments();
      final patients = await _db.getPatientsWithStats();

      if (!mounted) return;
      setState(() {
        _dentists = dentists;
        _treatments = treatments;
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'No se pudieron cargar los ajustes.';
      });
    }
  }

  // Diálogo reutilizable para crear/editar odontólogos.
  Future<void> _openDentistDialog({Map<String, dynamic>? item}) async {
    final nameController = TextEditingController(text: item?['nombre'] as String? ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Nuevo odontólogo' : 'Editar odontólogo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final data = {
                  'nombre': name,
                };

                if (item == null) {
                  await _db.insertDentist(data);
                } else {
                  await _db.updateDentist(item['id'] as int, data);
                }

                if (!context.mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    nameController.dispose();

    if (saved == true) {
      await _loadData();
    }
  }

  // Diálogo reutilizable para crear/editar tipos de tratamiento.
  Future<void> _openTreatmentDialog({Map<String, dynamic>? item}) async {
    final nameController = TextEditingController(text: item?['nombre'] as String? ?? '');
    final priceController = TextEditingController(
      text: item == null
          ? ''
          : (item['precio_predeterminado'] as num).toString(),
    );
    String selectedIconKey =
        (item?['icon_key'] as String?) ?? kTreatmentIconOptions.first.key;
    String selectedColorHex =
        (item?['color_hex'] as String?) ?? encodeColorHex(kTreatmentColorOptions.first);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(item == null ? 'Nuevo tratamiento' : 'Editar tratamiento'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Precio predeterminado',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Icono',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kTreatmentIconOptions.map((option) {
                          final selected = selectedIconKey == option.key;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) {
                              setDialogState(() {
                                selectedIconKey = option.key;
                              });
                            },
                            avatar: Icon(option.icon, size: 18),
                            label: Text(option.label),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Color',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kTreatmentColorOptions.map((color) {
                          final encoded = encodeColorHex(color);
                          final selected = selectedColorHex == encoded;
                          return InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              setDialogState(() {
                                selectedColorHex = encoded;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final parsed =
                        double.tryParse(priceController.text.trim().replaceAll(',', '.'));

                    if (name.isEmpty || parsed == null) return;

                    final data = {
                      'nombre': name,
                      'precio_predeterminado': parsed,
                      'icon_key': selectedIconKey,
                      'color_hex': selectedColorHex,
                    };

                    if (item == null) {
                      await _db.insertTreatmentType(data);
                    } else {
                      await _db.updateTreatmentType(item['id'] as int, data);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    priceController.dispose();

    if (saved == true) {
      await _loadData();
    }
  }

  // Confirmación y eliminación de odontólogo.
  Future<void> _deleteDentist(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar odontólogo'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _db.deleteDentist(id);
    await _loadData();
  }

  // Confirmación y eliminación de tratamiento.
  Future<void> _deleteTreatment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tratamiento'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _db.deleteTreatmentType(id);
    await _loadData();
  }

  Future<void> _clearTreatmentsCatalog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar catálogo de tratamientos'),
        content: const Text(
          'Se eliminarán del catálogo los tratamientos que no estén usados en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar catálogo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final removed = await _db.clearUnusedTreatmentTypes();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tratamientos eliminados: $removed')),
    );
    await _loadData();
  }

  Widget _buildDentistsTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Doctores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: _openDentistDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_dentists.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin odontólogos.'),
            ),
          )
        else
          ..._dentists.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(Icons.person, color: cs.onSecondaryContainer),
                  ),
                  title: Text(d['nombre'] as String),
                  subtitle: const Text('Doctor disponible para seleccionar'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openDentistDialog(item: d),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _deleteDentist(d['id'] as int),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTreatmentsTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tratamientos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: _openTreatmentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Vaciar catálogo actual'),
            subtitle: const Text(
              'Elimina del catálogo los tratamientos no usados en historial.',
            ),
            onTap: _clearTreatmentsCatalog,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _treatmentFilterController,
          decoration: const InputDecoration(
            labelText: 'Buscar tratamiento',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mostrando ${_filteredTreatments.length} de ${_treatments.length} tratamientos',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (_treatments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin tratamientos.'),
            ),
          )
        else if (_filteredTreatments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay resultados para esa búsqueda.'),
            ),
          )
        else
          ..._filteredTreatments.map((t) {
            final price = (t['precio_predeterminado'] as num).toDouble();
            final treatmentName = '${t['nombre'] ?? ''}';
            final visual = treatmentVisualForTreatment(
              treatmentName: treatmentName,
              iconKey: t['icon_key'] as String?,
              colorHex: t['color_hex'] as String?,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: visual.color.withValues(alpha: 0.18),
                    child: Icon(
                      visual.icon,
                      color: visual.color,
                    ),
                  ),
                  title: Text(treatmentName),
                  subtitle: Text('Precio: ${formatEuro(price)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openTreatmentDialog(item: t),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _deleteTreatment(t['id'] as int),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPatientsTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pacientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (_patients.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin pacientes registrados todavía.'),
            ),
          )
        else
          ..._patients.map((patient) {
            final treatments = (patient['tratamientos'] as num).toInt();
            final total = (patient['total_facturado'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person_outline, color: cs.onPrimaryContainer),
                  ),
                  title: Text(patient['nombre'] as String),
                  subtitle: Text('Tratamientos: $treatments'),
                  trailing: Text(
                    formatEuro(total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildHistoryTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Historial',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.history, color: cs.onPrimaryContainer),
            ),
            title: const Text('Abrir historial completo'),
            subtitle: const Text('Filtros por día/mes/rango, edición y exportación.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajustes'),
          actions: [
            IconButton(
              tooltip: 'Modo oscuro',
              onPressed: () {
                final isDarkMode =
                    Theme.of(context).brightness == Brightness.dark;
                widget.onThemeChanged(!isDarkMode);
              },
              icon: const Icon(Icons.dark_mode_rounded),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.groups_2), text: 'Doctores'),
              Tab(icon: Icon(Icons.medical_services_outlined), text: 'Tratamientos'),
              Tab(icon: Icon(Icons.person_outline), text: 'Pacientes'),
              Tab(icon: Icon(Icons.history), text: 'Historial'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildDentistsTab(cs),
                      _buildTreatmentsTab(cs),
                      _buildPatientsTab(cs),
                      _buildHistoryTab(cs),
                    ],
                  ),
      ),
    );
  }
}
