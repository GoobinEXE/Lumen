import 'package:flutter/foundation.dart';

/// Pedidos de UI vindos da notificação do sistema, fora do Riverpod.
class MedicationNotificationBus {
  MedicationNotificationBus._();

  static final ValueNotifier<int> openMedications = ValueNotifier<int>(0);
  static final ValueNotifier<int> doseChanged = ValueNotifier<int>(0);

  static void requestOpenMedications() {
    openMedications.value++;
  }

  static void notifyDoseChanged() {
    doseChanged.value++;
  }
}
