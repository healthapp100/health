import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the initialized Supabase client via Riverpod so screens/services never call
/// `Supabase.instance.client` directly — keeps every data access mockable in tests
/// (ARCHITECTURE.md §State management convention).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Emits the current auth state (signed in/out, token refresh) so the router and any screen
/// that needs to react to auth changes can do so via Riverpod rather than polling.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});
