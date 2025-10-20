import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class User {
  final String userId;
  final String fullName;
  final DateTime? birthDate;
  final String? gender;
  final String email;
  final String? password;
  final String? phoneNumber;
  final String? avatarUrl;
  final String roleId;
  final DateTime? createdAt;
  final DateTime? updateAt;
  final IsActived isActived;

  const User({
    required this.userId,
    required this.fullName,
    this.birthDate,
    this.gender,
    required this.email,
    this.password,
    this.phoneNumber,
    this.avatarUrl,
    required this.roleId,
    this.createdAt,
    this.updateAt,
    this.isActived = IsActived.ACTIVE,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    userId     : (j['userId'] ?? '').toString(),
    fullName   : (j['fullName'] ?? '').toString(),
    birthDate  : parseLocalDate(j['birthDate']),
    gender     : j['gender']?.toString(),
    email      : (j['email'] ?? '').toString(),
    password   : j['password']?.toString(),
    phoneNumber: j['phoneNumber']?.toString(),
    avatarUrl  : j['avatarUrl']?.toString(),
    roleId     : (j['roleId'] ?? '').toString(),
    createdAt  : parseInstant(j['createdAt']),
    updateAt   : parseInstant(j['updateAt']),
    isActived  : parseIsActived(j['isActived']),
  );

  Map<String, dynamic> toJson() => {
    'userId'     : userId,
    'fullName'   : fullName,
    'birthDate'  : birthDate == null
        ? null
        : birthDate!.toIso8601String().split('T').first,
    'gender'     : gender,
    'email'      : email,
    'password'   : password,
    'phoneNumber': phoneNumber,
    'avatarUrl'  : avatarUrl,
    'roleId'     : roleId,
    'createdAt'  : createdAt?.toIso8601String(),
    'updateAt'   : updateAt?.toIso8601String(),
    'isActived'  : isActivedToJson(isActived),
  };
}
