import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class UserAddress {
  final String userAddressId;
  final String addressInfor;
  final String? phoneNumber;
  final String fullName;
  final String? type;
  final String userId;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final IsActived isActived;

  const UserAddress({
    required this.userAddressId,
    required this.addressInfor,
    this.phoneNumber,
    required this.fullName,
    this.type,
    required this.userId,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
    this.isActived = IsActived.ACTIVE,
  });

  static bool _readBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes' || s == 'y';
  }

  factory UserAddress.fromJson(Map<String, dynamic> j) {
    final rawDefault = j.containsKey('isDefault') ? j['isDefault'] : j['default'];

    return UserAddress(
      userAddressId: (j['userAddressId'] ?? '').toString(),
      addressInfor: (j['addressInfor'] ?? '').toString(),
      phoneNumber: j['phoneNumber']?.toString(),
      fullName: (j['fullName'] ?? '').toString(),
      type: j['type']?.toString(),
      userId: (j['userId'] ?? '').toString(),
      isDefault: _readBool(rawDefault),
      createdAt: parseInstant(j['createdAt']),
      updatedAt: parseInstant(j['updatedAt']),
      isActived: parseIsActived(j['isActived']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userAddressId': userAddressId,
    'addressInfor': addressInfor,
    'phoneNumber': phoneNumber,
    'fullName': fullName,
    'type': type,
    'userId': userId,
    'default': isDefault,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isActived': isActivedToJson(isActived),
  };

  UserAddress copyWith({
    String? userAddressId,
    String? addressInfor,
    String? phoneNumber,
    String? fullName,
    String? type,
    String? userId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    IsActived? isActived,
  }) {
    return UserAddress(
      userAddressId: userAddressId ?? this.userAddressId,
      addressInfor: addressInfor ?? this.addressInfor,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActived: isActived ?? this.isActived,
    );
  }
}
