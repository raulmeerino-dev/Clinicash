import 'package:flutter/material.dart';

class TreatmentVisual {
  const TreatmentVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
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
