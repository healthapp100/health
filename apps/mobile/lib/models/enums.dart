/// Mirrors the Postgres enums in supabase/migrations/0001 and 0004. Kept as plain Dart enums
/// with explicit fromString/wireValue rather than codegen — see ARCHITECTURE.md's note on why
/// models are hand-written for now.
enum AppRole {
  patient,
  doctor,
  nutritionist,
  labStaff,
  support,
  admin,
  superAdmin;

  static AppRole fromWire(String value) => switch (value) {
        'patient' => AppRole.patient,
        'doctor' => AppRole.doctor,
        'nutritionist' => AppRole.nutritionist,
        'lab_staff' => AppRole.labStaff,
        'support' => AppRole.support,
        'admin' => AppRole.admin,
        'super_admin' => AppRole.superAdmin,
        _ => throw ArgumentError('Unknown app_role: $value'),
      };

  String get wireValue => switch (this) {
        AppRole.patient => 'patient',
        AppRole.doctor => 'doctor',
        AppRole.nutritionist => 'nutritionist',
        AppRole.labStaff => 'lab_staff',
        AppRole.support => 'support',
        AppRole.admin => 'admin',
        AppRole.superAdmin => 'super_admin',
      };

  bool get isStaff => this != AppRole.patient;
}

enum AppointmentStatus {
  requested,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  static AppointmentStatus fromWire(String value) => switch (value) {
        'requested' => AppointmentStatus.requested,
        'confirmed' => AppointmentStatus.confirmed,
        'in_progress' => AppointmentStatus.inProgress,
        'completed' => AppointmentStatus.completed,
        'cancelled' => AppointmentStatus.cancelled,
        'no_show' => AppointmentStatus.noShow,
        _ => throw ArgumentError('Unknown appointment_status: $value'),
      };

  String get wireValue => switch (this) {
        AppointmentStatus.requested => 'requested',
        AppointmentStatus.confirmed => 'confirmed',
        AppointmentStatus.inProgress => 'in_progress',
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.cancelled => 'cancelled',
        AppointmentStatus.noShow => 'no_show',
      };
}

enum LabOrderStatus {
  ordered,
  sampleCollected,
  inLab,
  reported,
  cancelled;

  static LabOrderStatus fromWire(String value) => switch (value) {
        'ordered' => LabOrderStatus.ordered,
        'sample_collected' => LabOrderStatus.sampleCollected,
        'in_lab' => LabOrderStatus.inLab,
        'reported' => LabOrderStatus.reported,
        'cancelled' => LabOrderStatus.cancelled,
        _ => throw ArgumentError('Unknown lab_order_status: $value'),
      };

  String get wireValue => switch (this) {
        LabOrderStatus.ordered => 'ordered',
        LabOrderStatus.sampleCollected => 'sample_collected',
        LabOrderStatus.inLab => 'in_lab',
        LabOrderStatus.reported => 'reported',
        LabOrderStatus.cancelled => 'cancelled',
      };
}

enum VitalSource {
  manual,
  device,
  lab;

  static VitalSource fromWire(String value) => VitalSource.values.byName(value);
  String get wireValue => name;
}

enum AppointmentMode {
  video,
  audio,
  chat;

  static AppointmentMode fromWire(String value) => AppointmentMode.values.byName(value);
  String get wireValue => name;
}
