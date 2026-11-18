import 'dart:io';

import 'package:drift/drift.dart';
import 'package:notes_app/data/local/database/app_database.dart';
import 'package:notes_app/data/network/api/api_client.dart';
import 'package:notes_app/data/network/dto/request/profile/profile_request_dto.dart';
import 'package:notes_app/data/network/dto/response/profile/profile_response_dto.dart';

class ProfileRepo {
  final ApiClient client;
  final AppDatabase database;

  ProfileRepo({required this.client, required this.database});

  Future<ProfileResponseDto?> getCachedProfile(int userId) async {
    final profile = await database.getProfile(userId);
    if (profile == null) return null;

    return ProfileResponseDto(
      success: true,
      data: ProfileData(
        id: profile.profileId,
        name: profile.name,
        email: profile.email,
        mobile: profile.mobile,
        gender: profile.gender,
      ),
    );
  }

  Stream<ProfileData?> watchProfile(int userId) {
    return database.watchProfile(userId).map((profile) {
      if (profile == null) return null;
      return ProfileData(
        id: profile.profileId,
        name: profile.name,
        email: profile.email,
        mobile: profile.mobile,
        gender: profile.gender,
      );
    });
  }

  Future<void> refreshProfile(int userId) async {
    final response = await client.getUserDetails(ProfileRequestDto(id: userId));
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }

    final result = ProfileResponseDto.fromJson(response.data);
    final profile = result.data;
    if (result.success != true || profile == null) {
      throw StateError(result.message ?? 'The server returned no profile.');
    }

    await database.saveProfile(
      CachedProfilesCompanion.insert(
        userId: Value(userId),
        profileId: Value(profile.id),
        name: Value(profile.name),
        email: Value(profile.email),
        mobile: Value(profile.mobile),
        gender: Value(profile.gender),
      ),
    );
  }

  Future<void> updateProfile({
    required int userId,
    required String name,
    required String mobile,
    required String gender,
  }) async {
    final response = await client.updateUser({
      'userId': userId,
      'name': name,
      'mobile': mobile,
      'gender': gender,
    });
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }
    final existing = await database.getProfile(userId);
    await database.saveProfile(
      CachedProfilesCompanion.insert(
        userId: Value(userId),
        profileId: Value(userId),
        name: Value(name),
        email: Value(existing?.email ?? ''),
        mobile: Value(mobile),
        gender: Value(gender),
      ),
    );
  }

  Future<bool> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await client.changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }
    return response.data['success'] == true;
  }

  Future<void> deleteUser(int userId) async {
    final response = await client.deleteUser(userId);
    if (response.statusCode != 200) {
      throw HttpException((response.statusCode ?? 500).toString());
    }
    await (database.delete(database.cachedNotes)..where((n) => n.userId.equals(userId))).go();
    await (database.delete(database.cachedProfiles)..where((p) => p.userId.equals(userId))).go();
  }
}
