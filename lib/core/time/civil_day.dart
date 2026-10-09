/// Dia civil local (meia-noite) — sem hora, sem fuso embutido.
DateTime civilDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameCivilDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Chave estável `yyyy-mm-dd` para índices e caches.
String civilDayKey(DateTime value) {
  final day = civilDay(value);
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
