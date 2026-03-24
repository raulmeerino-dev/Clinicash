import 'package:flutter/material.dart';

class TreatmentVisual {
  const TreatmentVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class TreatmentIconOption {
  const TreatmentIconOption({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

const List<TreatmentIconOption> kTreatmentIconOptions = [
  TreatmentIconOption(key: 'clean_hands', icon: Icons.clean_hands, label: 'Limpieza'),
  TreatmentIconOption(key: 'healing', icon: Icons.healing, label: 'Implante'),
  TreatmentIconOption(
    key: 'medical_services',
    icon: Icons.medical_services,
    label: 'Endodoncia',
  ),
  TreatmentIconOption(key: 'shield', icon: Icons.shield, label: 'Férula'),
  TreatmentIconOption(key: 'auto_awesome', icon: Icons.auto_awesome, label: 'Estética'),
  TreatmentIconOption(key: 'architecture', icon: Icons.architecture, label: 'Ortodoncia'),
  TreatmentIconOption(key: 'local_hospital', icon: Icons.local_hospital, label: 'Cirugía'),
  TreatmentIconOption(
    key: 'precision_manufacturing',
    icon: Icons.precision_manufacturing,
    label: 'Prótesis',
  ),
  TreatmentIconOption(key: 'workspace_premium', icon: Icons.workspace_premium, label: 'Corona'),
  TreatmentIconOption(key: 'content_cut', icon: Icons.content_cut, label: 'Exodoncia'),
  TreatmentIconOption(key: 'science', icon: Icons.science, label: 'Laboratorio'),
  TreatmentIconOption(key: 'spa', icon: Icons.spa, label: 'Injerto'),
  TreatmentIconOption(key: 'grid_view', icon: Icons.grid_view, label: 'Bracket'),
  TreatmentIconOption(key: 'straighten', icon: Icons.straighten, label: 'Placa'),
  TreatmentIconOption(key: 'bolt', icon: Icons.bolt, label: 'General'),
  TreatmentIconOption(key: 'mood', icon: Icons.mood, label: 'Blanqueamiento'),
];

const List<Color> kTreatmentColorOptions = [
  Color(0xFF0EA5E9),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFEF4444),
  Color(0xFF06B6D4),
  Color(0xFFEAB308),
  Color(0xFFF43F5E),
  Color(0xFF22C55E),
  Color(0xFF6366F1),
  Color(0xFF0EA5A4),
  Color(0xFF64748B),
  Color(0xFF15803D),
  Color(0xFF7C3AED),
  Color(0xFF334155),
];

Map<String, IconData> get _iconByKey {
  return {for (final option in kTreatmentIconOptions) option.key: option.icon};
}

String encodeColorHex(Color color) {
  return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
}

Color? decodeColorHex(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final hex = value.trim().replaceAll('#', '');
  if (hex.length != 6 && hex.length != 8) return null;

  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

IconData? iconFromKey(String? iconKey) {
  if (iconKey == null || iconKey.trim().isEmpty) return null;
  return _iconByKey[iconKey.trim()];
}

const List<TreatmentVisual> _fallbackVisuals = [
  TreatmentVisual(icon: Icons.clean_hands, color: Color(0xFF0EA5E9)),
  TreatmentVisual(icon: Icons.architecture, color: Color(0xFF14B8A6)),
  TreatmentVisual(icon: Icons.healing, color: Color(0xFFF97316)),
  TreatmentVisual(icon: Icons.shield_moon, color: Color(0xFF8B5CF6)),
  TreatmentVisual(icon: Icons.mood, color: Color(0xFF10B981)),
  TreatmentVisual(icon: Icons.psychology, color: Color(0xFFEF4444)),
  TreatmentVisual(icon: Icons.science, color: Color(0xFF06B6D4)),
  TreatmentVisual(icon: Icons.auto_awesome, color: Color(0xFFEAB308)),
  TreatmentVisual(icon: Icons.bolt, color: Color(0xFFF43F5E)),
  TreatmentVisual(icon: Icons.spa, color: Color(0xFF22C55E)),
  TreatmentVisual(icon: Icons.precision_manufacturing, color: Color(0xFF6366F1)),
  TreatmentVisual(icon: Icons.straighten, color: Color(0xFF0EA5A4)),
];

const Map<String, TreatmentVisual> _namedVisuals = {
  'limpieza': TreatmentVisual(icon: Icons.clean_hands, color: Color(0xFF0EA5E9)),
  'ortodoncia': TreatmentVisual(icon: Icons.architecture, color: Color(0xFF14B8A6)),
  'implante': TreatmentVisual(icon: Icons.healing, color: Color(0xFFF97316)),
  'endodoncia': TreatmentVisual(icon: Icons.medical_services, color: Color(0xFF8B5CF6)),
  'blanqueamiento': TreatmentVisual(icon: Icons.mood, color: Color(0xFF10B981)),
  'cirugia': TreatmentVisual(icon: Icons.local_hospital, color: Color(0xFFEF4444)),
  'corona': TreatmentVisual(icon: Icons.workspace_premium, color: Color(0xFFEAB308)),
  'carilla': TreatmentVisual(icon: Icons.auto_awesome, color: Color(0xFF06B6D4)),
  'puente': TreatmentVisual(icon: Icons.view_stream, color: Color(0xFF6366F1)),
  'protesis': TreatmentVisual(icon: Icons.precision_manufacturing, color: Color(0xFFF43F5E)),
  'ferula': TreatmentVisual(icon: Icons.shield, color: Color(0xFF64748B)),
  'exodoncia': TreatmentVisual(icon: Icons.content_cut, color: Color(0xFFFB7185)),
  'injerto': TreatmentVisual(icon: Icons.spa, color: Color(0xFF22C55E)),
  'regeneracion': TreatmentVisual(icon: Icons.eco, color: Color(0xFF15803D)),
  'raspaje': TreatmentVisual(icon: Icons.brush, color: Color(0xFF0EA5A4)),
  'placa': TreatmentVisual(icon: Icons.straighten, color: Color(0xFF0F766E)),
  'bracket': TreatmentVisual(icon: Icons.grid_view, color: Color(0xFF7C3AED)),
  'sellador': TreatmentVisual(icon: Icons.opacity, color: Color(0xFF38BDF8)),
};

TreatmentVisual treatmentVisualByName(String treatmentName) {
  final normalized = treatmentName.toLowerCase().trim();

  for (final entry in _namedVisuals.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }

  final index = normalized.isEmpty
      ? 0
      : normalized.runes.reduce((value, element) => value + element) %
          _fallbackVisuals.length;
  return _fallbackVisuals[index];
}

TreatmentVisual treatmentVisualForTreatment({
  required String treatmentName,
  String? iconKey,
  String? colorHex,
}) {
  final fallback = treatmentVisualByName(treatmentName);
  return TreatmentVisual(
    icon: iconFromKey(iconKey) ?? fallback.icon,
    color: decodeColorHex(colorHex) ?? fallback.color,
  );
}
