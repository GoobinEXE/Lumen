enum CareContactRole { therapist, psychologist, psychiatrist, other }

extension CareContactRoleCodec on CareContactRole {
  String get code {
    switch (this) {
      case CareContactRole.therapist:
        return 'therapist';
      case CareContactRole.psychologist:
        return 'psychologist';
      case CareContactRole.psychiatrist:
        return 'psychiatrist';
      case CareContactRole.other:
        return 'other';
    }
  }

  static CareContactRole fromCode(String? code) {
    switch (code) {
      case 'therapist':
        return CareContactRole.therapist;
      case 'psychologist':
        return CareContactRole.psychologist;
      case 'psychiatrist':
        return CareContactRole.psychiatrist;
      default:
        return CareContactRole.other;
    }
  }
}

class CareContact {
  const CareContact({
    required this.id,
    required this.role,
    required this.phone,
    required this.updatedAt,
    this.displayName,
  });

  final String id;
  final CareContactRole role;
  final String? displayName;
  final String phone;
  final DateTime updatedAt;

  CareContact copyWith({
    String? id,
    CareContactRole? role,
    String? displayName,
    bool clearDisplayName = false,
    String? phone,
    DateTime? updatedAt,
  }) {
    return CareContact(
      id: id ?? this.id,
      role: role ?? this.role,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      phone: phone ?? this.phone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role.code,
    'displayName': displayName,
    'phone': phone,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CareContact.fromMap(Map<String, dynamic> map) {
    final updatedAtRaw = map['updatedAt'];
    return CareContact(
      id: map['id'] as String? ?? '',
      role: CareContactRoleCodec.fromCode(map['role'] as String?),
      displayName: map['displayName'] as String?,
      phone: map['phone'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(updatedAtRaw as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
