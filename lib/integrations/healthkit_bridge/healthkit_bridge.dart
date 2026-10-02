import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../features/state_of_mind/domain/state_of_mind_entry.dart';

/// Ponte nativa iOS para tipos HealthKit não cobertos pelo pacote `health`.
class HealthKitBridge {
  static const MethodChannel _channel =
      MethodChannel('dev.prism.lumen/healthkit_bridge');

  static bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Solicita autorizações extras (SoM, daylight, áudio, meds quando disponíveis).
  static Future<bool> requestAuthorization() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } catch (e) {
      debugPrint('[HealthKitBridge] requestAuthorization: $e');
      return false;
    }
  }

  static Future<bool> writeStateOfMind(StateOfMindEntry entry) async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('writeStateOfMind', {
        'kind': entry.kind.name,
        'valence': entry.valence,
        'labels': entry.labels.toList(),
        'associations': entry.associations.toList(),
        'timestampMs': entry.timestamp.millisecondsSinceEpoch,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('[HealthKitBridge] writeStateOfMind: $e');
      return false;
    }
  }

  static Future<List<StateOfMindEntry>> readStateOfMind({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('readStateOfMind', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (raw == null) return const [];
      return raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return StateOfMindEntry(
          kind: StateOfMindKind.values.firstWhere(
            (k) => k.name == map['kind'],
            orElse: () => StateOfMindKind.dailyMood,
          ),
          valence: (map['valence'] as num?)?.toDouble() ?? 0,
          labels: (map['labels'] as List<dynamic>?)
                  ?.map((x) => x.toString())
                  .toSet() ??
              {},
          associations: (map['associations'] as List<dynamic>?)
                  ?.map((x) => x.toString())
                  .toSet() ??
              {},
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (map['timestampMs'] as num).toInt(),
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('[HealthKitBridge] readStateOfMind: $e');
      return const [];
    }
  }

  /// Minutos de luz do dia agregados por dia (chave yyyy-MM-dd → minutos).
  static Future<Map<String, double>> readTimeInDaylight({
    required DateTime start,
    required DateTime end,
  }) async {
    return _readDailyDoubles('readTimeInDaylight', start, end);
  }

  /// dB médios de exposição sonora ambiental por dia.
  static Future<Map<String, double>> readEnvironmentalAudio({
    required DateTime start,
    required DateTime end,
  }) async {
    return _readDailyDoubles('readEnvironmentalAudio', start, end);
  }

  /// dB médios de exposição sonora de fones por dia.
  static Future<Map<String, double>> readHeadphoneAudio({
    required DateTime start,
    required DateTime end,
  }) async {
    return _readDailyDoubles('readHeadphoneAudio', start, end);
  }

  static Future<Map<String, double>> _readDailyDoubles(
    String method,
    DateTime start,
    DateTime end,
  ) async {
    if (!isSupported) return const {};
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(method, {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (raw == null) return const {};
      return raw.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    } catch (e) {
      debugPrint('[HealthKitBridge] $method: $e');
      return const {};
    }
  }

  static Future<List<HealthKitMedicationInfo>> readMedications() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('readMedications');
      if (raw == null) return const [];
      return raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return HealthKitMedicationInfo(
          appleConceptId: map['id']?.toString() ??
              map['appleConceptId']?.toString() ??
              '',
          name: map['name']?.toString() ?? '',
          nickname: map['nickname']?.toString(),
          form: map['form']?.toString(),
          rxNormCode: map['rxNormCode']?.toString(),
          isActive: map['isActive'] as bool? ?? true,
        );
      }).where((m) => m.appleConceptId.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[HealthKitBridge] readMedications: $e');
      return const [];
    }
  }

  static Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('readDoseEvents', {
        'medicationId': appleConceptId,
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (raw == null) return const [];
      return raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return HealthKitDoseEvent(
          appleConceptId: appleConceptId,
          status: map['status']?.toString() ?? 'unknown',
          loggedAt: DateTime.fromMillisecondsSinceEpoch(
            (map['timestampMs'] as num).toInt(),
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('[HealthKitBridge] readDoseEvents: $e');
      return const [];
    }
  }

  /// Escrita de dose não faz parte do escopo público atual (somente leitura).
  @Deprecated('Medications API is read-only for third-party apps')
  static Future<bool> writeDoseEvent({
    required String healthKitMedicationId,
    required DateTime when,
    String status = 'taken',
  }) async {
    return false;
  }

  static Future<bool> isMedicationsApiAvailable() async {
    if (!isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('isMedicationsApiAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}

class HealthKitMedicationInfo {
  final String appleConceptId;
  final String name;
  final String? nickname;
  final String? form;
  final String? rxNormCode;
  final bool isActive;

  const HealthKitMedicationInfo({
    required this.appleConceptId,
    required this.name,
    this.nickname,
    this.form,
    this.rxNormCode,
    this.isActive = true,
  });

  /// Alias legado usado em versões anteriores da ponte.
  String get healthKitMedicationId => appleConceptId;
}

class HealthKitDoseEvent {
  final String appleConceptId;
  final String status;
  final DateTime loggedAt;

  const HealthKitDoseEvent({
    required this.appleConceptId,
    required this.status,
    required this.loggedAt,
  });

  String get healthKitMedicationId => appleConceptId;
}
