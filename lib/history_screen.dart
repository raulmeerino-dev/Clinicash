import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'add_treatment_screen.dart';
import 'currency_utils.dart';
import 'database_helper.dart';
import 'doctor_session.dart';
import 'treatment_visuals.dart';

enum _HistoryMode { day, month, range }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  bool _isLoading = true;
  double _selectedDoctorGlobalTotal = 0;
  List<Map<String, dynamic>> _recordsForFilter = [];
  Map<String, List<Map<String, dynamic>>> _groupedRecords = {};
  Set<String> _doctorRecordedDates = {};

  _HistoryMode _mode = _HistoryMode.day;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  late DateTime _selectedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final doctorId = DoctorSession.selectedDoctorId;
    if (doctorId == null) return;

    setState(() {
      _isLoading = true;
    });

    final total = await _db.getTotalByDoctor(doctorId);
    final records = await _loadRecordsForCurrentFilter(doctorId);
    final recordedDates = await _db.getRecordedDatesByDoctor(doctorId);

    if (!mounted) return;
    setState(() {
      _selectedDoctorGlobalTotal = total;
      _recordsForFilter = records;
      _groupedRecords = _buildGroups(records);
      _doctorRecordedDates = recordedDates.toSet();
      _isLoading = false;
    });
  }

  bool _hasRecordsOnDay(DateTime day) {
    return _doctorRecordedDates.contains(_db.dateKey(day));
  }

  Widget _buildDayCalendar(ColorScheme cs, bool isDarkMode) {
    return TableCalendar<DateTime>(
      firstDay: DateTime(2020),
      lastDay: DateTime(2100),
      focusedDay: _focusedDate,
      selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
      availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
      eventLoader: (day) => _hasRecordsOnDay(day) ? [day] : const [],
      locale: 'es_ES',
      onDaySelected: (selectedDay, focusedDay) async {
        setState(() {
          _selectedDate = selectedDay;
          _focusedDate = focusedDay;
        });
        await _loadHistory();
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDate = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        markerDecoration: BoxDecoration(
          color: cs.tertiary,
          shape: BoxShape.circle,
        ),
        markersAlignment: Alignment.bottomCenter,
        todayDecoration: BoxDecoration(
          color: cs.secondary.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: cs.primary,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(
          color: isDarkMode ? cs.onSurface : cs.onSurface,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        leftChevronIcon: Icon(Icons.chevron_left, color: cs.onSurface),
        rightChevronIcon: Icon(Icons.chevron_right, color: cs.onSurface),
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: cs.onSurfaceVariant),
        weekendStyle: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadRecordsForCurrentFilter(int doctorId) async {
    if (_mode == _HistoryMode.day) {
      return _db.getRecordsByDateAndDoctor(_selectedDate, doctorId);
    }

    if (_mode == _HistoryMode.month) {
      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      return _db.getRecordsByDoctorBetweenDates(doctorId, start, end);
    }

    final today = DateTime.now();
    final start = _rangeStart ?? today.subtract(const Duration(days: 6));
    final end = _rangeEnd ?? today;
    return _db.getRecordsByDoctorBetweenDates(doctorId, start, end);
  }

  Map<String, List<Map<String, dynamic>>> _buildGroups(List<Map<String, dynamic>> records) {
    final map = <String, List<Map<String, dynamic>>>{};

    for (final record in records) {
      late final String key;
      if (_mode == _HistoryMode.day) {
        key = record['paciente'] as String;
      } else {
        key = record['fecha'] as String;
      }

      map.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(record);
    }

    return map;
  }

  double _sumTotal(Iterable<Map<String, dynamic>> rows) {
    return rows.fold<double>(
      0,
      (sum, item) => sum + (item['precio_final'] as num).toDouble(),
    );
  }

  int _distinctPatientsCount(Iterable<Map<String, dynamic>> rows) {
    final names = rows.map((e) => e['paciente'] as String).toSet();
    return names.length;
  }

  String get _periodLabel {
    if (_mode == _HistoryMode.day) {
      return
          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    }
    if (_mode == _HistoryMode.month) {
      return '${_selectedMonth.month.toString().padLeft(2, '0')}/${_selectedMonth.year}';
    }

    final start = _rangeStart;
    final end = _rangeEnd;
    if (start == null || end == null) return 'Últimos 7 días';
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecciona un día del mes',
    );
    if (picked == null) return;

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });
    await _loadHistory();
  }

  Future<void> _pickRange({required bool start}) async {
    final initialDate = start ? (_rangeStart ?? DateTime.now()) : (_rangeEnd ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (start) {
        _rangeStart = picked;
      } else {
        _rangeEnd = picked;
      }
    });

    await _loadHistory();
  }

  Future<void> _openAddOrEdit(Map<String, dynamic> record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTreatmentScreen(existingRecord: record),
      ),
    );
    await _loadHistory();
  }

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
    await _loadHistory();
  }

  Future<void> _exportCurrentFilterToXlsx() async {
    if (_recordsForFilter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para exportar.')),
      );
      return;
    }

    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Historial'];
    sheet.appendRow([
      excel.TextCellValue('Fecha'),
      excel.TextCellValue('Hora'),
      excel.TextCellValue('Paciente'),
      excel.TextCellValue('Tratamiento'),
      excel.TextCellValue('Doctor'),
      excel.TextCellValue('Precio (€)'),
    ]);

    for (final row in _recordsForFilter) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int);
      final time =
          '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
      final price = (row['precio_final'] as num).toDouble();
      sheet.appendRow([
        excel.TextCellValue(row['fecha'] as String),
        excel.TextCellValue(time),
        excel.TextCellValue(row['paciente'] as String),
        excel.TextCellValue(row['tratamiento'] as String),
        excel.TextCellValue(row['odontologo'] as String),
        excel.DoubleCellValue(price),
      ]);
    }

    final bytes = workbook.encode();
    if (bytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'historial_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exportado: ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final emphasisTextColor = isDarkMode ? cs.tertiary : cs.secondary;
    final doctorName = DoctorSession.selectedDoctorName ?? 'Sin doctor';
    final filterTotal = _sumTotal(_recordsForFilter);
    final patientCount = _distinctPatientsCount(_recordsForFilter);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial · $doctorName'),
        actions: [
          IconButton(
            onPressed: _exportCurrentFilterToXlsx,
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a Excel (.xlsx)',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                                Color.lerp(cs.primaryContainer, cs.surface, 0.45)!,
                                Color.lerp(cs.surface, Colors.black, 0.15)!,
                              ]
                            : [cs.primaryContainer, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDarkMode
                            ? cs.outline.withValues(alpha: 0.25)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDarkMode
                              ? cs.secondaryContainer
                              : cs.primary,
                          child: Icon(
                            Icons.person,
                            color: isDarkMode
                                ? cs.onSecondaryContainer
                                : cs.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: emphasisTextColor,
                                ),
                              ),
                              Text(
                                'Historial completo del doctor activo',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatEuro(_selectedDoctorGlobalTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: emphasisTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SegmentedButton<_HistoryMode>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: isDarkMode
                            ? cs.primary.withValues(alpha: 0.26)
                            : cs.primaryContainer,
                        selectedForegroundColor: isDarkMode
                            ? cs.onPrimary
                            : cs.onPrimaryContainer,
                        foregroundColor: isDarkMode
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: _HistoryMode.day,
                          icon: Icon(Icons.today),
                          label: Text('Día'),
                        ),
                        ButtonSegment(
                          value: _HistoryMode.month,
                          icon: Icon(Icons.calendar_month),
                          label: Text('Mes'),
                        ),
                        ButtonSegment(
                          value: _HistoryMode.range,
                          icon: Icon(Icons.date_range),
                          label: Text('Rango'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (value) async {
                        setState(() {
                          _mode = value.first;
                        });
                        await _loadHistory();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calendario y filtro',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (_mode == _HistoryMode.day)
                          _buildDayCalendar(cs, isDarkMode)
                        else if (_mode == _HistoryMode.month)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: _pickMonth,
                              icon: const Icon(Icons.calendar_month),
                              label: Text('Mes seleccionado: $_periodLabel'),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickRange(start: true),
                                  icon: const Icon(Icons.start),
                                  label: Text(
                                    _rangeStart == null
                                        ? 'Fecha inicio'
                                        : '${_rangeStart!.day.toString().padLeft(2, '0')}/${_rangeStart!.month.toString().padLeft(2, '0')}/${_rangeStart!.year}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickRange(start: false),
                                  icon: const Icon(Icons.flag),
                                  label: Text(
                                    _rangeEnd == null
                                        ? 'Fecha fin'
                                        : '${_rangeEnd!.day.toString().padLeft(2, '0')}/${_rangeEnd!.month.toString().padLeft(2, '0')}/${_rangeEnd!.year}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.secondaryContainer,
                      child: Icon(Icons.analytics, color: cs.onSecondaryContainer),
                    ),
                    title: Text(
                      'Resumen: $_periodLabel',
                      style: TextStyle(
                        color: emphasisTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('Pacientes: $patientCount · Registros: ${_recordsForFilter.length}'),
                    trailing: Text(
                      formatEuro(filterTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: emphasisTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_groupedRecords.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay tratamientos para este filtro.'),
                    ),
                  )
                else
                  ..._groupedRecords.entries.map((entry) {
                    final groupTotal = _sumTotal(entry.value);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(
                              Icons.folder_open,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            entry.key,
                            style: TextStyle(
                              color: emphasisTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text('Registros: ${entry.value.length}'),
                          trailing: Text(
                            formatEuro(groupTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: emphasisTextColor,
                            ),
                          ),
                          children: entry.value.map((record) {
                            final price = (record['precio_final'] as num).toDouble();
                            final visual =
                                treatmentVisualByName(record['tratamiento'] as String);
                            final patientName = '${record['paciente']}';
                            final treatmentName = '${record['tratamiento']}';
                            final createdAt = DateTime.fromMillisecondsSinceEpoch(
                              record['created_at'] as int,
                            );
                            final timeLabel =
                                '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: visual.color.withValues(alpha: 0.2),
                                child: Icon(visual.icon, color: visual.color),
                              ),
                              title: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: patientName,
                                      style: TextStyle(
                                        color: emphasisTextColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const TextSpan(text: ' · '),
                                    TextSpan(text: treatmentName),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Fecha: ${record['fecha']} · Hora: $timeLabel',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openAddOrEdit(record);
                                  } else if (value == 'delete') {
                                    _deleteRecord(record['id'] as int);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                  PopupMenuItem(
                                    enabled: false,
                                    child: Text(
                                      formatEuro(price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
