import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../domain/profile_demographics.dart';
import '../domain/user_profile.dart';
import '../domain/voice_tone_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._prefs);

  static const String prefsKey = 'noa_user_profile_v1';

  final SharedPreferences _prefs;

  UserProfile read() {
    final raw = _prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) {
      return UserProfile(id: const Uuid().v4(), updatedAt: DateTime.now());
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final profile = UserProfile.fromMap(map);
      if (profile.id.isEmpty) {
        return profile.copyWith(id: const Uuid().v4());
      }
      return profile;
    } catch (_) {
      return UserProfile(id: const Uuid().v4(), updatedAt: DateTime.now());
    }
  }

  Future<UserProfile> save(UserProfile profile) async {
    final next = profile.copyWith(updatedAt: DateTime.now());
    await _prefs.setString(prefsKey, jsonEncode(next.toMap()));
    return next;
  }

  Future<UserProfile> saveName(String? name) {
    final current = read();
    final trimmed = name?.trim();
    return save(
      current.copyWith(
        name: trimmed,
        clearName: trimmed == null || trimmed.isEmpty,
      ),
    );
  }

  /// Atualiza campos específicos sem tocar nos demais; passar `clear*` zera.
  Future<UserProfile> updateFields({
    String? name,
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    String? biologicalSex,
    VoiceToneProfile? voiceToneProfile,
    bool? importedFromHealth,
    bool clearName = false,
    bool clearBirthDate = false,
    bool clearWeightKg = false,
    bool clearHeightCm = false,
    bool clearBiologicalSex = false,
  }) {
    final current = read();
    return save(
      current.copyWith(
        name: name,
        birthDate: birthDate,
        weightKg: weightKg,
        heightCm: heightCm,
        biologicalSex: biologicalSex,
        voiceToneProfile: voiceToneProfile,
        importedFromHealth: importedFromHealth,
        clearName: clearName,
        clearBirthDate: clearBirthDate,
        clearWeightKg: clearWeightKg,
        clearHeightCm: clearHeightCm,
        clearBiologicalSex: clearBiologicalSex,
      ),
    );
  }

  Future<UserProfile> saveVoiceToneProfile(VoiceToneProfile tone) {
    return save(read().copyWith(voiceToneProfile: tone));
  }

  /// Preenche só as lacunas (campos nulos) com dados externos.
  Future<UserProfile> applyDemographicsGaps(
    ProfileDemographics demographics,
  ) {
    final current = read();
    final filled = current.applyDemographicsGaps(demographics);
    if (identical(filled, current)) return Future.value(current);
    return save(filled);
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.watch(sharedPreferencesProvider));
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref.watch(userProfileRepositoryProvider));
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._repository) : super(_repository.read());

  final UserProfileRepository _repository;

  Future<void> updateName(String? name) async {
    state = await _repository.saveName(name);
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = await _repository.save(profile);
  }

  Future<void> updateFields({
    String? name,
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    String? biologicalSex,
    VoiceToneProfile? voiceToneProfile,
    bool? importedFromHealth,
    bool clearName = false,
    bool clearBirthDate = false,
    bool clearWeightKg = false,
    bool clearHeightCm = false,
    bool clearBiologicalSex = false,
  }) async {
    state = await _repository.updateFields(
      name: name,
      birthDate: birthDate,
      weightKg: weightKg,
      heightCm: heightCm,
      biologicalSex: biologicalSex,
      voiceToneProfile: voiceToneProfile,
      importedFromHealth: importedFromHealth,
      clearName: clearName,
      clearBirthDate: clearBirthDate,
      clearWeightKg: clearWeightKg,
      clearHeightCm: clearHeightCm,
      clearBiologicalSex: clearBiologicalSex,
    );
  }

  Future<void> updateVoiceToneProfile(VoiceToneProfile tone) async {
    state = await _repository.saveVoiceToneProfile(tone);
  }

  Future<void> applyDemographicsGaps(ProfileDemographics demographics) async {
    state = await _repository.applyDemographicsGaps(demographics);
  }
}

/// Nome para saudação e export; fallback genérico do l10n.
String profileDisplayName(UserProfile profile, String fallback) {
  return profile.trimmedName ?? fallback;
}
