class DoctorSession {
  static int? selectedDoctorId;
  static String? selectedDoctorName;

  static bool get hasDoctor => selectedDoctorId != null;

  static void setDoctor({required int id, required String name}) {
    selectedDoctorId = id;
    selectedDoctorName = name;
  }

  static void clear() {
    selectedDoctorId = null;
    selectedDoctorName = null;
  }
}
