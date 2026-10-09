import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/persistence/async_mutex.dart';
import '../../../core/providers.dart';
import '../domain/care_contact.dart';

/// Repositório de contatos clínicos para compartilhamento terapêutico.
class TherapistContactRepository {
  TherapistContactRepository(this._prefs);

  static const String contactsKey = 'noa_care_contacts_v1';
  static const String legacyPhoneV1Key = 'noa_therapist_phone_v1';
  static const String legacyPhoneKey = 'noa_therapist_phone';
  static const String migratedKey = 'noa_care_contacts_migrated_v1';

  // Compatibilidade com referências antigas.
  static const String currentKey = contactsKey;
  static const String legacyKey = legacyPhoneKey;

  final SharedPreferences _prefs;

  Future<T> _synchronized<T>(Future<T> Function() action) =>
      PersistenceLocks.careContacts.synchronized(action);

  List<CareContact> listContacts() {
    final raw = _prefs.getString(contactsKey);
    final parsed = _decodeContacts(raw);
    if (parsed.isNotEmpty) return parsed;

    if (_prefs.getBool(migratedKey) ?? false) return const [];

    final legacyPhone = _readLegacyPhone();
    if (legacyPhone.isEmpty) return const [];

    final migrated = [
      CareContact(
        id: 'legacy-therapist',
        role: CareContactRole.therapist,
        phone: legacyPhone,
        updatedAt: DateTime.now(),
      ),
    ];
    // Persistência one-shot só quando há telefone legado a conservar.
    _persistContactsSync(migrated);
    _prefs.setBool(migratedKey, true);
    return migrated;
  }

  Future<void> saveContacts(List<CareContact> contacts) {
    return _synchronized(() async {
      await _persistContacts(contacts);
    });
  }

  Future<void> _persistContacts(List<CareContact> contacts) async {
    final encoded = contacts.map((contact) => contact.toMap()).toList();
    await _prefs.setString(contactsKey, _encodeContacts(encoded));
  }

  void _persistContactsSync(List<CareContact> contacts) {
    final encoded = contacts.map((contact) => contact.toMap()).toList();
    _prefs.setString(contactsKey, _encodeContacts(encoded));
  }

  Future<void> upsert(CareContact contact) {
    return _synchronized(() async {
      final items = listContacts().toList();
      final index = items.indexWhere((item) => item.id == contact.id);
      if (index >= 0) {
        items[index] = contact;
      } else {
        items.add(contact);
      }
      await _persistContacts(items);
    });
  }

  Future<void> delete(String id) {
    return _synchronized(() async {
      final items = listContacts().where((item) => item.id != id).toList();
      await _persistContacts(items);
    });
  }

  String readPrimaryPhone() {
    for (final contact in listContacts()) {
      final phone = contact.phone.trim();
      if (phone.isNotEmpty) return phone;
    }
    return '';
  }

  // Compatibilidade com a UI atual enquanto o fluxo de contatos não é exposto.
  String readPhone() => readPrimaryPhone();

  Future<void> savePhone(String value) {
    final trimmed = value.trim();
    final contacts = listContacts().toList();
    if (contacts.isEmpty) {
      final fallback = CareContact(
        id: 'therapist-primary',
        role: CareContactRole.therapist,
        phone: trimmed,
        updatedAt: DateTime.now(),
      );
      return saveContacts([fallback]);
    }

    final targetIndex = contacts.indexWhere(
      (contact) => contact.role == CareContactRole.therapist,
    );
    final index = targetIndex >= 0 ? targetIndex : 0;
    final current = contacts[index];
    contacts[index] = current.copyWith(
      phone: trimmed,
      updatedAt: DateTime.now(),
    );
    return saveContacts(contacts);
  }

  String _readLegacyPhone() {
    final v1 = _prefs.getString(legacyPhoneV1Key)?.trim();
    if (v1 != null && v1.isNotEmpty) return v1;
    final legacy = _prefs.getString(legacyPhoneKey)?.trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    return '';
  }

  List<CareContact> _decodeContacts(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = _decodeJsonList(raw);
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CareContact.fromMap)
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<dynamic> _decodeJsonList(String raw) {
    final value = jsonDecode(raw);
    if (value is List<dynamic>) return value;
    return const [];
  }

  String _encodeContacts(List<Map<String, dynamic>> contacts) {
    return jsonEncode(contacts);
  }
}

final therapistContactRepositoryProvider = Provider<TherapistContactRepository>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return TherapistContactRepository(prefs);
  },
);

final careContactsProvider =
    StateNotifierProvider<CareContactsNotifier, AsyncValue<List<CareContact>>>((
      ref,
    ) {
      return CareContactsNotifier(ref);
    });

class CareContactsNotifier
    extends StateNotifier<AsyncValue<List<CareContact>>> {
  CareContactsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    try {
      final items = _ref
          .read(therapistContactRepositoryProvider)
          .listContacts();
      if (!mounted) return;
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveContacts(List<CareContact> contacts) async {
    await _ref.read(therapistContactRepositoryProvider).saveContacts(contacts);
    if (!mounted) return;
    state = AsyncValue.data(contacts);
  }

  Future<void> upsert(CareContact contact) async {
    await _ref.read(therapistContactRepositoryProvider).upsert(contact);
    await load();
  }

  Future<void> delete(String id) async {
    await _ref.read(therapistContactRepositoryProvider).delete(id);
    await load();
  }
}
