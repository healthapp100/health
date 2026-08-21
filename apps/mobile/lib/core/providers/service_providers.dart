import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/consent_service.dart';
import '../../services/content_service.dart';
import '../../services/lab_service.dart';
import '../../services/learn_content_service.dart';
import '../../services/meal_plan_service.dart';
import '../../services/profile_service.dart';
import '../../services/services_directory_service.dart';
import '../../services/vitals_service.dart';
import '../supabase/supabase_client.dart';

/// One Provider per service (ARCHITECTURE.md's convention: screens call services via Riverpod,
/// never Supabase directly). Each is trivially overridable in tests with a fake service.
final authServiceProvider = Provider((ref) => AuthService(ref.watch(supabaseClientProvider)));
final profileServiceProvider = Provider((ref) => ProfileService(ref.watch(supabaseClientProvider)));
final appointmentServiceProvider =
    Provider((ref) => AppointmentService(ref.watch(supabaseClientProvider)));
final mealPlanServiceProvider = Provider((ref) => MealPlanService(ref.watch(supabaseClientProvider)));
final medicineReminderServiceProvider =
    Provider((ref) => MedicineReminderService(ref.watch(supabaseClientProvider)));
final vitalsServiceProvider = Provider((ref) => VitalsService(ref.watch(supabaseClientProvider)));
final labServiceProvider = Provider((ref) => LabService(ref.watch(supabaseClientProvider)));
final contentServiceProvider = Provider((ref) => ContentService(ref.watch(supabaseClientProvider)));
final learnContentServiceProvider =
    Provider((ref) => LearnContentService(ref.watch(supabaseClientProvider)));
final consentServiceProvider = Provider((ref) => ConsentService(ref.watch(supabaseClientProvider)));
final servicesDirectoryServiceProvider =
    Provider((ref) => ServicesDirectoryService(ref.watch(supabaseClientProvider)));
