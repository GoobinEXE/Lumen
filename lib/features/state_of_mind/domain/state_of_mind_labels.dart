/// Conjunto completo e exclusivo de [HKStateOfMind.Label] (iOS 18+).
///
/// São exatamente 38 casos oficiais da Apple — não há labels extras no
/// HealthKit. Qualquer palavra fora desta lista não sincroniza com o app Saúde.
/// IDs em inglês batem 1:1 com o enum nativo (ver HealthKitBridge.mapLabels).
class StateOfMindLabels {
  StateOfMindLabels._();

  /// Ordem alfabética pelos IDs em inglês (contrato HealthKit).
  static const List<String> ids = [
    'amazed',
    'amused',
    'angry',
    'annoyed',
    'anxious',
    'ashamed',
    'brave',
    'calm',
    'confident',
    'content',
    'disappointed',
    'discouraged',
    'disgusted',
    'drained',
    'embarrassed',
    'excited',
    'frustrated',
    'grateful',
    'guilty',
    'happy',
    'hopeful',
    'hopeless',
    'indifferent',
    'irritated',
    'jealous',
    'joyful',
    'lonely',
    'overwhelmed',
    'passionate',
    'peaceful',
    'proud',
    'relieved',
    'sad',
    'satisfied',
    'scared',
    'stressed',
    'surprised',
    'worried',
  ];

  /// IDs ordenados pelo rótulo localizado (como a UI do app Saúde).
  static List<String> sortedIds(String languageCode) {
    final copy = List<String>.from(ids);
    copy.sort(
      (a, b) => label(a, languageCode)
          .toLowerCase()
          .compareTo(label(b, languageCode).toLowerCase()),
    );
    return copy;
  }

  static const Map<String, Map<String, String>> _i18n = {
    'amazed': {
      'pt': 'Maravilhado(a)',
      'en': 'Amazed',
      'es': 'Maravillado/a',
      'ja': '驚嘆',
    },
    'amused': {
      'pt': 'Divertido(a)',
      'en': 'Amused',
      'es': 'Divertido/a',
      'ja': '楽しんでいる',
    },
    'angry': {'pt': 'Com raiva', 'en': 'Angry', 'es': 'Enojado/a', 'ja': '怒り'},
    'annoyed': {
      'pt': 'Aborrecido(a)',
      'en': 'Annoyed',
      'es': 'Molesto/a',
      'ja': 'いらいら',
    },
    'anxious': {
      'pt': 'Ansioso(a)',
      'en': 'Anxious',
      'es': 'Ansioso/a',
      'ja': '不安',
    },
    'ashamed': {
      'pt': 'Envergonhado(a)',
      'en': 'Ashamed',
      'es': 'Avergonzado/a',
      'ja': '恥ずかしい',
    },
    'brave': {
      'pt': 'Corajoso(a)',
      'en': 'Brave',
      'es': 'Valiente',
      'ja': '勇敢',
    },
    'calm': {'pt': 'Calmo(a)', 'en': 'Calm', 'es': 'Calmado/a', 'ja': '落ち着き'},
    'confident': {
      'pt': 'Confiante',
      'en': 'Confident',
      'es': 'Seguro/a',
      'ja': '自信',
    },
    'content': {
      'pt': 'Contente',
      'en': 'Content',
      'es': 'Contento/a',
      'ja': '満足',
    },
    'disappointed': {
      'pt': 'Desapontado(a)',
      'en': 'Disappointed',
      'es': 'Decepcionado/a',
      'ja': 'がっかり',
    },
    'discouraged': {
      'pt': 'Desanimado(a)',
      'en': 'Discouraged',
      'es': 'Desanimado/a',
      'ja': '落胆',
    },
    'disgusted': {
      'pt': 'Com nojo',
      'en': 'Disgusted',
      'es': 'Asqueado/a',
      'ja': '嫌悪',
    },
    'drained': {
      'pt': 'Esgotado(a)',
      'en': 'Drained',
      'es': 'Agotado/a',
      'ja': '消耗',
    },
    'embarrassed': {
      'pt': 'Constrangido(a)',
      'en': 'Embarrassed',
      'es': 'Avergonzado/a',
      'ja': '気まずさ',
    },
    'excited': {
      'pt': 'Animado(a)',
      'en': 'Excited',
      'es': 'Emocionado/a',
      'ja': 'ワクワク',
    },
    'frustrated': {
      'pt': 'Frustrado(a)',
      'en': 'Frustrated',
      'es': 'Frustrado/a',
      'ja': 'もどかしい',
    },
    'grateful': {
      'pt': 'Grato(a)',
      'en': 'Grateful',
      'es': 'Agradecido/a',
      'ja': '感謝',
    },
    'guilty': {
      'pt': 'Culpado(a)',
      'en': 'Guilty',
      'es': 'Culpable',
      'ja': '罪悪感',
    },
    'happy': {'pt': 'Feliz', 'en': 'Happy', 'es': 'Feliz', 'ja': '幸せ'},
    'hopeful': {
      'pt': 'Esperançoso(a)',
      'en': 'Hopeful',
      'es': 'Esperanzado/a',
      'ja': '希望',
    },
    'hopeless': {
      'pt': 'Sem esperança',
      'en': 'Hopeless',
      'es': 'Sin esperanza',
      'ja': '絶望',
    },
    'indifferent': {
      'pt': 'Indiferente',
      'en': 'Indifferent',
      'es': 'Indiferente',
      'ja': '無関心',
    },
    'irritated': {
      'pt': 'Irritado(a)',
      'en': 'Irritated',
      'es': 'Irritado/a',
      'ja': '苛立ち',
    },
    'jealous': {
      'pt': 'Com ciúme',
      'en': 'Jealous',
      'es': 'Celoso/a',
      'ja': '嫉妬',
    },
    'joyful': {'pt': 'Alegre', 'en': 'Joyful', 'es': 'Alegre', 'ja': '喜び'},
    'lonely': {
      'pt': 'Solitário(a)',
      'en': 'Lonely',
      'es': 'Solo/a',
      'ja': '孤独',
    },
    'overwhelmed': {
      'pt': 'Sobrecarregado(a)',
      'en': 'Overwhelmed',
      'es': 'Abrumado/a',
      'ja': '圧倒',
    },
    'passionate': {
      'pt': 'Apaixonado(a)',
      'en': 'Passionate',
      'es': 'Apasionado/a',
      'ja': '情熱',
    },
    'peaceful': {
      'pt': 'Em paz',
      'en': 'Peaceful',
      'es': 'En paz',
      'ja': '穏やか',
    },
    'proud': {
      'pt': 'Orgulhoso(a)',
      'en': 'Proud',
      'es': 'Orgulloso/a',
      'ja': '誇り',
    },
    'relieved': {
      'pt': 'Aliviado(a)',
      'en': 'Relieved',
      'es': 'Aliviado/a',
      'ja': '安心',
    },
    'sad': {'pt': 'Triste', 'en': 'Sad', 'es': 'Triste', 'ja': '悲しい'},
    'satisfied': {
      'pt': 'Satisfeito(a)',
      'en': 'Satisfied',
      'es': 'Satisfecho/a',
      'ja': '満ち足りた',
    },
    'scared': {
      'pt': 'Com medo',
      'en': 'Scared',
      'es': 'Asustado/a',
      'ja': '怖い',
    },
    'stressed': {
      'pt': 'Estressado(a)',
      'en': 'Stressed',
      'es': 'Estresado/a',
      'ja': 'ストレス',
    },
    'surprised': {
      'pt': 'Surpreso(a)',
      'en': 'Surprised',
      'es': 'Sorprendido/a',
      'ja': '驚き',
    },
    'worried': {
      'pt': 'Preocupado(a)',
      'en': 'Worried',
      'es': 'Preocupado/a',
      'ja': '心配',
    },
  };

  static String label(String id, String languageCode) {
    final map = _i18n[id];
    if (map == null) return id;
    return map[languageCode] ?? map['en'] ?? id;
  }
}
