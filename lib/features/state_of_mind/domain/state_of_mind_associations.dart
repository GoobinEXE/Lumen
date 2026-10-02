/// 18 associações oficiais HKStateOfMind.Association (IDs em inglês).
class StateOfMindAssociations {
  StateOfMindAssociations._();

  static const List<String> ids = [
    'community',
    'currentEvents',
    'dating',
    'education',
    'family',
    'fitness',
    'friends',
    'health',
    'hobbies',
    'identity',
    'money',
    'partner',
    'selfCare',
    'spirituality',
    'tasks',
    'travel',
    'weather',
    'work',
  ];

  static const Map<String, Map<String, String>> _i18n = {
    'community': {
      'pt': 'Comunidade',
      'en': 'Community',
      'es': 'Comunidad',
      'ja': 'コミュニティ',
    },
    'currentEvents': {
      'pt': 'Atualidades',
      'en': 'Current events',
      'es': 'Actualidad',
      'ja': '時事',
    },
    'dating': {
      'pt': 'Encontros',
      'en': 'Dating',
      'es': 'Citas',
      'ja': 'デート',
    },
    'education': {
      'pt': 'Educação',
      'en': 'Education',
      'es': 'Educación',
      'ja': '教育',
    },
    'family': {'pt': 'Família', 'en': 'Family', 'es': 'Familia', 'ja': '家族'},
    'fitness': {
      'pt': 'Atividade física',
      'en': 'Fitness',
      'es': 'Fitness',
      'ja': 'フィットネス',
    },
    'friends': {'pt': 'Amigos', 'en': 'Friends', 'es': 'Amigos', 'ja': '友人'},
    'health': {'pt': 'Saúde', 'en': 'Health', 'es': 'Salud', 'ja': '健康'},
    'hobbies': {'pt': 'Hobbies', 'en': 'Hobbies', 'es': 'Pasatiempos', 'ja': '趣味'},
    'identity': {
      'pt': 'Identidade',
      'en': 'Identity',
      'es': 'Identidad',
      'ja': 'アイデンティティ',
    },
    'money': {'pt': 'Dinheiro', 'en': 'Money', 'es': 'Dinero', 'ja': 'お金'},
    'partner': {
      'pt': 'Parceiro(a)',
      'en': 'Partner',
      'es': 'Pareja',
      'ja': 'パートナー',
    },
    'selfCare': {
      'pt': 'Autocuidado',
      'en': 'Self-care',
      'es': 'Autocuidado',
      'ja': 'セルフケア',
    },
    'spirituality': {
      'pt': 'Espiritualidade',
      'en': 'Spirituality',
      'es': 'Espiritualidad',
      'ja': 'スピリチュアリティ',
    },
    'tasks': {'pt': 'Tarefas', 'en': 'Tasks', 'es': 'Tareas', 'ja': 'タスク'},
    'travel': {'pt': 'Viagem', 'en': 'Travel', 'es': 'Viajes', 'ja': '旅行'},
    'weather': {'pt': 'Clima', 'en': 'Weather', 'es': 'Clima', 'ja': '天気'},
    'work': {'pt': 'Trabalho', 'en': 'Work', 'es': 'Trabajo', 'ja': '仕事'},
  };

  static String label(String id, String languageCode) {
    final map = _i18n[id];
    if (map == null) return id;
    return map[languageCode] ?? map['en'] ?? id;
  }
}
