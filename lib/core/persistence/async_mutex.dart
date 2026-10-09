/// Fila serializada de futures — uma ação só começa depois da anterior.
///
/// Compartilhar a mesma instância entre UI e handlers de notificação evita
/// RMW concorrente em SharedPreferences.
class AsyncMutex {
  Future<void> _tail = Future<void>.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then((_) {}, onError: (_) {});
    return next;
  }

}

/// Locks process-wide por domínio de persistência.
class PersistenceLocks {
  PersistenceLocks._();

  static final AsyncMutex medications = AsyncMutex();
  static final AsyncMutex tasks = AsyncMutex();
  static final AsyncMutex mood = AsyncMutex();
  static final AsyncMutex routine = AsyncMutex();
  static final AsyncMutex syncLedger = AsyncMutex();
  static final AsyncMutex careContacts = AsyncMutex();
}
