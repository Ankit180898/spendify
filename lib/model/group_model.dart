class GroupModel {
  final String id;
  final String name;
  final String emoji;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  List<GroupMember> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
  });

  factory GroupModel.fromMap(Map<String, dynamic> m) => GroupModel(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: (m['emoji'] as String?) ?? '🧳',
        inviteCode: m['invite_code'] as String,
        createdBy: m['created_by'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class GroupMember {
  final String groupId;
  final String userId;
  final String displayName;
  final DateTime joinedAt;

  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.displayName,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> m) => GroupMember(
        groupId: m['group_id'] as String,
        userId: m['user_id'] as String,
        displayName: m['display_name'] as String,
        joinedAt: DateTime.parse(m['joined_at'] as String),
      );
}
