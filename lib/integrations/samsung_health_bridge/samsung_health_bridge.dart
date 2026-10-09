import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../health/models/daily_recovery_snapshot.dart';
import '../health/models/health_demographics.dart';
import '../health/models/sleep_record.dart';

/// Ponte nativa Android para o Samsung Health Data SDK.
///
/// Sem o AAR oficial em `android/app/libs/`, [isSdkLinked] fica falso e
/// [isAvailable] ainda detecta o app Samsung Health instalado — o connector
/// usa Health Connect como fallback de dados.
class SamsungHealthBridge {
  SamsungHealthBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'dev.prism.lumen/samsung_health_bridge';
  static const String samsungHealthPackage = 'com.sec.android.app.shealth';

  final MethodChannel _channel;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('[SamsungHealthBridge] isAvailable: $e');
      return false;
    }
  }

  /// True quando o AAR do Samsung Health Data SDK está linkado no build.
  Future<bool> isSdkLinked() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isSdkLinked');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('connect');
      return result ?? false;
    } catch (e) {
      debugPrint('[SamsungHealthBridge] connect: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('[SamsungHealthBridge] requestPermissions: $e');
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('hasPermissions');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveError() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('resolveError');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<SleepRecord>> readSleep({int days = 7}) async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('readSleep', {
        'days': days,
      });
      if (raw == null) return const [];
      return raw
          .map((e) => SleepRecord.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[SamsungHealthBridge] readSleep: $e');
      return const [];
    }
  }

  Future<List<DailyRecoverySnapshot>> readRecovery({int days = 14}) async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('readRecovery', {
        'days': days,
      });
      if (raw == null) return const [];
      return raw
          .map(
            (e) => DailyRecoverySnapshot.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[SamsungHealthBridge] readRecovery: $e');
      return const [];
    }
  }

  Future<HealthDemographics> readDemographics() async {
    if (!isSupported) return HealthDemographics.empty;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readDemographics',
      );
      if (raw == null) return HealthDemographics.empty;
      return HealthDemographics.fromMap(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('[SamsungHealthBridge] readDemographics: $e');
      return HealthDemographics.empty;
    }
  }

  Future<bool> writeWater({
    required DateTime when,
    required double liters,
  }) async {
    if (!isSupported || liters <= 0) return false;
    try {
      final result = await _channel.invokeMethod<bool>('writeWater', {
        'whenMs': when.millisecondsSinceEpoch,
        'liters': liters,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('[SamsungHealthBridge] writeWater: $e');
      return false;
    }
  }

  Future<bool> writeMindfulnessExercise({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isSupported || !end.isAfter(start)) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('writeMindfulnessExercise', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('[SamsungHealthBridge] writeMindfulnessExercise: $e');
      return false;
    }
  }
}
