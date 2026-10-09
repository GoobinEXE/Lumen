/// Categoria de um registro na linha do tempo do perfil (GDD §6/§7).
enum ProfileFeedKind {
  checkIn,
  routine,
  sleep,
  recovery,
  dose,
  task,
  stateOfMind,
}

/// Origem do dado: local (gravado no app) ou vindo do app de saúde do aparelho.
enum ProfileFeedSource { local, health }

/// Item imutável do feed cronológico do perfil. Derivado dos registros locais
/// e do que o app de saúde do aparelho espelhou — nunca de nuvem.
class ProfileFeedItem {
  const ProfileFeedItem({
    required this.id,
    required this.timestamp,
    required this.kind,
    required this.title,
    this.detail,
    this.source = ProfileFeedSource.local,
  });

  final String id;
  final DateTime timestamp;
  final ProfileFeedKind kind;
  final String title;
  final String? detail;
  final ProfileFeedSource source;

  /// Dia civil do registro — usado para abrir o Raio-X do dia.
  DateTime get civilDay => DateTime(timestamp.year, timestamp.month, timestamp.day);

  bool get isFromHealth => source == ProfileFeedSource.health;
}
