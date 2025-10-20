import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class Role {
  final String roleId;
  final String roleName;
  final DateTime? createdAt;
  final IsActived isActived;

  const Role({
    required this.roleId,
    required this.roleName,
    this.createdAt,
    this.isActived = IsActived.ACTIVE,
  });

  factory Role.fromJson(Map<String, dynamic> j) => Role(
    roleId   : (j['roleId'] ?? '').toString(),
    roleName : (j['roleName'] ?? '').toString(),
    createdAt: parseInstant(j['createdAt']),
    isActived: parseIsActived(j['isActived']),
  );

  Map<String, dynamic> toJson() => {
    'roleId'   : roleId,
    'roleName' : roleName,
    'createdAt': createdAt?.toIso8601String(),
    'isActived': isActivedToJson(isActived),
  };
}
