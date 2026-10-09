import 'package:flutter/foundation.dart';

/// Pedidos de UI vindos da notificação de tarefa, fora do Riverpod.
class TaskNotificationBus {
  TaskNotificationBus._();

  static final ValueNotifier<int> openRoutine = ValueNotifier<int>(0);
  static final ValueNotifier<int> openTasks = ValueNotifier<int>(0);
  static final ValueNotifier<int> tasksChanged = ValueNotifier<int>(0);

  static void requestOpenRoutine() {
    openRoutine.value++;
  }

  /// Abre a Central de Tarefas na aba Ficha.
  static void requestOpenTasks() {
    openTasks.value++;
  }

  static void notifyTasksChanged() {
    tasksChanged.value++;
  }
}
