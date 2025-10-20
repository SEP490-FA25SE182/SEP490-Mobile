import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class UserAddress {
  final String userAddressId;
  final String addressInfor;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;       
  final IsActived isActived;

  const UserAddress({
    required this.userAddressId,
    required this.addressInfor,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    this.isActived = IsActived.ACTIVE,
  });

  factory UserAddress.fromJson(Map<String, dynamic> j) => UserAddress(
    userAddressId: (j['userAddressId'] ?? '').toString(),
    addressInfor : (j['addressInfor'] ?? '').toString(),
    userId       : (j['userId'] ?? '').toString(),
    createdAt    : parseInstant(j['createdAt']),
    updatedAt    : parseInstant(j['updatedAt']),
    isActived    : parseIsActived(j['isActived']),
  );

  Map<String, dynamic> toJson() => {
    'userAddressId': userAddressId,
    'addressInfor' : addressInfor,
    'userId'       : userId,
    'createdAt'    : createdAt?.toIso8601String(),
    'updatedAt'    : updatedAt?.toIso8601String(),
    'isActived'    : isActivedToJson(isActived),
  };
}
