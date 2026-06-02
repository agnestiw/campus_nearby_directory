import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mendapatkan session aktif
  Session? get currentSession => _supabase.auth.currentSession;

  // Mendapatkan ID user yang sedang login
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Mendapatkan Email user yang sedang login
  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  // Register
  Future<AuthResponse> signUp({
  required String email,
  required String password,
  required String fullName,
  }) async {
    try {
      debugPrint('========================');
      debugPrint('[REGISTER] START');

      final authResponse =
          await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      debugPrint('[REGISTER] AUTH SUCCESS');

      final user = authResponse.user;

      if (user != null) {
        debugPrint('[REGISTER] USER ID: ${user.id}');

        final insertResult =
            await _supabase
                .from('users')
                .insert({
                  'id': user.id,
                  'role_id': 2,
                  'full_name': fullName,
                  'email': email,
                })
                .select();

        debugPrint(
          '[REGISTER] INSERT SUCCESS',
        );

        debugPrint(
          insertResult.toString(),
        );
      }

      return authResponse;
    } catch (e, stackTrace) {
      debugPrint(
        '[REGISTER ERROR]',
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        stackTrace.toString(),
      );

      rethrow;
    }
  }

  // Login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Mengambil data profile termasuk role dari tabel profiles
  Future<ProfileModel?> getUserProfile(
  String userId,
  ) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('''
                *,
                roles (
                  name
                )
              ''')
              .eq('id', userId)
              .single();

      return ProfileModel.fromJson(
        response,
      );
    } catch (e) {
      return null;
    }
  }
}