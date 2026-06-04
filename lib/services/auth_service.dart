import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
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
      debugPrint('');
      debugPrint('========================');
      debugPrint('[REGISTER START]');
      debugPrint('Email: $email');
      debugPrint('Full Name: $fullName');

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      debugPrint('');
      debugPrint('[AUTH SUCCESS]');

      debugPrint(
        'Auth User ID: ${authResponse.user?.id}',
      );

      debugPrint(
        'Auth Email: ${authResponse.user?.email}',
      );

      debugPrint(
        'Current User: ${_supabase.auth.currentUser?.id}',
      );

      debugPrint(
        'Current Session: ${_supabase.auth.currentSession?.user.id}',
      );

      debugPrint(
        'Email Confirmed At: ${authResponse.user?.emailConfirmedAt}',
      );

      // TUNGGU 3 DETIK AGAR TRIGGER SELESAI
      await Future.delayed(
        const Duration(seconds: 3),
      );

      // CEK APAKAH DATA SUDAH MASUK KE public.users
      final userData =
          await _supabase
              .from('users')
              .select()
              .eq(
                'id',
                authResponse.user!.id,
              )
              .maybeSingle();

      debugPrint('');
      debugPrint('[CHECK USERS TABLE]');
      debugPrint(userData.toString());

      if (userData != null) {
        debugPrint(
          '[SUCCESS] USER BERHASIL MASUK KE public.users DARI TRIGGER',
        );
      } else {
        debugPrint(
          '[FAILED] USER TIDAK ADA DI public.users',
        );
      }

      debugPrint('');
      debugPrint('[REGISTER FINISHED]');
      debugPrint('========================');

      return authResponse;
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('========================');
      debugPrint('[REGISTER ERROR]');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint('========================');

      rethrow;
    }
  }

  // Login
  Future<AuthResponse> signIn({
  required String email,
  required String password,
  }) async {
    try {
      debugPrint('================');
      debugPrint('[LOGIN START]');

      final response =
          await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('[LOGIN SUCCESS]');
      debugPrint(
        'User ID: ${response.user?.id}',
      );

      debugPrint(
        'Session Exists: ${response.session != null}',
      );

      return response;
    } catch (e) {
      debugPrint('[LOGIN ERROR]');
      debugPrint(e.toString());

      rethrow;
    }
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

  // Update profil user ke database
  Future<bool> updateUserProfile({
    required String userId,
    required String fullName,
    String? phone,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({
            'full_name': fullName,
            if (phone != null) 'phone': phone,
          })
          .eq('id', userId);

      debugPrint('[UPDATE PROFILE SUCCESS] User ID: $userId');
      return true;
    } catch (e) {
      debugPrint('[UPDATE PROFILE ERROR]');
      debugPrint(e.toString());
      return false;
    }
  }

  // Upload profile photo ke Supabase Storage
  Future<String?> uploadProfilePhoto({
    required String userId,
    required Uint8List fileBytes,
  }) async {
    try {
      debugPrint('[UPLOAD PHOTO START] File size: ${fileBytes.length} bytes');
      
      final fileName = 'profile_$userId.jpg';

      
      // Upload file ke storage bucket 'profile_photos'
      try {
        // Coba hapus file lama jika ada
        try {
          await _supabase.storage.from('profile_photo').remove([fileName]);
        } catch (_) {
          // File lama tidak ada, skip delete
        }
        
        // Upload file baru
        await _supabase.storage.from('profile_photo').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
        
        debugPrint('[UPLOAD PHOTO] File uploaded successfully');
      } catch (uploadError) {
        debugPrint('[UPLOAD PHOTO BUCKET ERROR]');
        debugPrint(uploadError.toString());
        
        // Fallback: coba ke bucket 'avatars' jika profile_photo tidak ada
        try {
          await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );
          debugPrint('[UPLOAD PHOTO] Fallback to avatars bucket successful');
        } catch (fallbackError) {
          debugPrint('[UPLOAD PHOTO FALLBACK ERROR]');
          debugPrint(fallbackError.toString());
          rethrow;
        }
      }

      // Dapatkan public URL dari bucket yang berhasil
      String? publicUrl;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      try {
        final baseUrl = _supabase.storage
            .from('profile_photo')
            .getPublicUrl(fileName);
        publicUrl = '$baseUrl?t=$timestamp';
      } catch (_) {
        try {
          final baseUrl = _supabase.storage
              .from('avatars')
              .getPublicUrl(fileName);
          publicUrl = '$baseUrl?t=$timestamp';
        } catch (_) {
          debugPrint('[UPLOAD PHOTO ERROR] Gagal mendapatkan public URL');
          return null;
        }
      }

      debugPrint('[UPLOAD PHOTO SUCCESS] URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[UPLOAD PHOTO ERROR]');
      debugPrint('Exception: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update profile photo URL di database
  Future<bool> updateProfilePhotoUrl({
    required String userId,
    required String photoUrl,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({
            'profile_photo': photoUrl,
          })
          .eq('id', userId);

      debugPrint('[UPDATE PHOTO URL SUCCESS] User ID: $userId');
      return true;
    } catch (e) {
      debugPrint('[UPDATE PHOTO URL ERROR]');
      debugPrint(e.toString());
      return false;
    }
  }
}