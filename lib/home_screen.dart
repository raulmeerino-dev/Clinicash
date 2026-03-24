import 'package:flutter/material.dart';

import 'add_treatment_screen.dart';
import 'currency_utils.dart';
import 'database_helper.dart';
import 'doctor_session.dart';
import 'treatment_visuals.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<Map<String, dynamic>> _todayRecords = [];
  double _doctorDayTotal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  // Carga todos los registros del día actual y los totales por doctor.
  Future<void> _loadTodayData() async {
    final doctorId = DoctorSession.selectedDoctorId;
    if (doctorId == null) return;

    setState(() {
      _isLoading = true;
    });

    final records =
        await _db.getRecordsByDateAndDoctor(DateTime.now(), doctorId);
    final total = await _db.getTotalByDoctorForDate(doctorId, DateTime.now());

    if (!mounted) return;

    setState(() {
      _todayRecords = records;
      _doctorDayTotal = total;
      _isLoading = false;
    });
  }

  // Navega al formulario de alta o edición y recarga la pantalla al volver.
  Future<void> _openAddOrEdit({Map<String, dynamic>? record}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTreatmentScreen(existingRecord: record),
      ),
    );
    await _loadTodayData();
  }

  // Elimina un registro diario y actualiza la vista.
  Future<void> _deleteRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Seguro que quieres eliminar este tratamiento?'),
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
    await _db.deleteDailyRecord(id);
    await _loadTodayData();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final doctorName = DoctorSession.selectedDoctorName ?? 'Sin doctor';
    final cs = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final summaryGradientColors = isDarkMode
        ? [
            Color.lerp(cs.primary, Colors.black, 0.45)!,
            Color.lerp(cs.secondary, Colors.black, 0.55)!,
          ]
        : [cs.primary, cs.secondary];

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            DoctorSession.clear();
            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(doctorName),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/history')
                .then((_) => _loadTodayData()),
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings')
                .then((_) => _loadTodayData()),
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddOrEdit,
        icon: const Icon(Icons.add),
        label: const Text('Agregar tratamiento'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: summaryGradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: isDarkMode ? 0.12 : 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.insights,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Resumen del día',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Doctor activo: $doctorName',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          dateLabel,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatChip(
                                icon: Icons.receipt_long,
                                label: 'Registros',
                                value: _todayRecords.length.toString(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatChip(
                                icon: Icons.payments,
                                label: 'Total día',
                                value: formatEuro(_doctorDayTotal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      const Expanded(
                        child: _SectionTitle(title: 'Tratamientos de hoy'),
                      ),
                      Text(
                        '${_todayRecords.length} items',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_todayRecords.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aún no hay tratamientos registrados hoy.'),
                      ),
                    )
                  else
                    ..._todayRecords.map((record) {
                      final price = (record['precio_final'] as num).toDouble();
                      final visual = treatmentVisualForTreatment(
                        treatmentName: record['tratamiento'] as String,
                        iconKey: record['tratamiento_icon_key'] as String?,
                        colorHex: record['tratamiento_color_hex'] as String?,
                      );
                      final patientName = '${record['paciente']}';
                      final treatmentName = '${record['tratamiento']}';
                      final createdAt =
                          DateTime.fromMillisecondsSinceEpoch(record['created_at'] as int);
                      final timeLabel =
                          '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: visual.color.withValues(alpha: 0.2),
                              child: Icon(
                                visual.icon,
                                color: visual.color,
                              ),
                            ),
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: patientName,
                                    style: TextStyle(
                                      color: cs.secondary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const TextSpan(text: ' · '),
                                  TextSpan(text: treatmentName),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              timeLabel,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openAddOrEdit(record: record);
                                } else if (value == 'delete') {
                                  _deleteRecord(record['id'] as int);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar'),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  formatEuro(price),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 14),

                  const _SectionTitle(title: 'Mi total (hoy)'),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: cs.secondaryContainer,
                        child: Icon(
                          Icons.payments,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      title: Text(doctorName),
                      subtitle: const Text('Total acumulado del día actual'),
                      trailing: Text(
                        formatEuro(_doctorDayTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
