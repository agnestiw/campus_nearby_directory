import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_logger.dart';
import '../models/profile_model.dart';
import '../models/role_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ProfileModel>> getUsers() async {
    try {
      AppLogger.info('Fetching users...');
      final response = await _supabase
          .from('users')
          .select('*, roles(name)')
          .order('full_name');

      final users = (response as List)
          .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.success('Users fetched: ${users.length}');
      return users;
    } catch (e) {
      AppLogger.error('Error fetching users: $e');
      rethrow;
    }
  }

  Future<ProfileModel?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, roles(name)')
          .eq('id', id)
          .single();
      return ProfileModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Error getting user by id: $e');
      return null;
    }
  }

  Future<List<RoleModel>> getRoles() async {
    try {
      final response = await _supabase.from('roles').select().order('name');
      return (response as List)
          .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching roles: $e');
      rethrow;
    }
  }

  Future<ProfileModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required int roleId,
    String? phone,
  }) async {
    try {
      AppLogger.info('Creating user: $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role_id': roleId,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.user == null) {
        throw Exception('Tidak dapat membuat user baru');
      }

      await Future.delayed(const Duration(seconds: 2));
      final created = await getUserById(response.user!.id);
      if (created == null) {
        throw Exception('User dibuat tetapi tidak ditemukan di database');
      }
      return created;
    } catch (e) {
      AppLogger.error('Error creating user: $e');
      rethrow;
    }
  }

  Future<ProfileModel> updateUser({
    required String userId,
    required String fullName,
    String? phone,
    required int roleId,
  }) async {
    try {
      AppLogger.info('Updating user $userId');
      await _supabase.from('users').update({
        'full_name': fullName,
        'role_id': roleId,
        if (phone != null) 'phone': phone,
      }).eq('id', userId);

      final updatedUser = await getUserById(userId);
      if (updatedUser == null) {
        throw Exception('User tidak ditemukan setelah update');
      }
      return updatedUser;
    } catch (e) {
      AppLogger.error('Error updating user: $e');
      rethrow;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      AppLogger.info('Deleting user $userId');

      final existing = await _supabase.from('users').select('id').eq('id', userId).maybeSingle();
      AppLogger.info('Existing user lookup for $userId: $existing');

      if (existing == null) {
        throw Exception('User dengan id $userId tidak ditemukan sebelum delete');
      }

      final response = await _supabase.from('users').delete().eq('id', userId).select();
      AppLogger.info('Delete response for user $userId: $response');

      if (response is List && response.isNotEmpty) {
        return true;
      }

      throw Exception('Delete query dijalankan tetapi tidak ada baris dihapus. Periksa kebijakan RLS/permission.');
    } catch (e) {
      AppLogger.error('Error deleting user: $e');
      rethrow;
    }
  }

  Future<int> countUsers() async {
    try {
      final response = await _supabase.from('users').select('id');
      if (response is List) {
        return response.length;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Error counting users: $e');
      rethrow;
    }
  }

  Future<List<ProfileModel>> getRecentUsers({int limit = 3}) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, roles(name)')
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching recent users: $e');
      return [];
    }
  }
}
