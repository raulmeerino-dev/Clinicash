import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'doctor_session.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  bool _isLoading = true;
  List<Map<String, dynamic>> _dentists = [];

  @override
  void initState() {
    super.initState();
    _loadDentists();
  }

  Future<void> _loadDentists() async {
    setState(() {
      _isLoading = true;
    });

    final dentists = await _db.getDentists();
    if (!mounted) return;

    setState(() {
      _dentists = dentists;
      _isLoading = false;
    });
  }

  void _chooseDoctor(Map<String, dynamic> dentist) {
    DoctorSession.setDoctor(
      id: dentist['id'] as int,
      name: dentist['nombre'] as String,
    );
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar odontólogo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Accede directamente al trabajo del día.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (_dentists.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay odontólogos configurados. Ve a Ajustes para crear al menos uno.',
                      ),
                    ),
                  )
                else
                  ..._dentists.map((dentist) {
                    final name = dentist['nombre'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.person, color: cs.onPrimaryContainer),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Entrar como doctor activo'),
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          onTap: () => _chooseDoctor(dentist),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/settings').then(
                    (_) => _loadDentists(),
                  ),
                  icon: const Icon(Icons.settings),
                  label: const Text('Gestionar odontólogos en Ajustes'),
                ),
              ],
            ),
    );
  }
}
