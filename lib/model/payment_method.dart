import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class PaymentMethod {
  final String paymentMethodId;
  final String? methodName;
  final String? provider;
  final String? decription;
  final DateTime? createdAt;
  final IsActived isActived;

  const PaymentMethod({
    required this.paymentMethodId,
    this.methodName,
    this.provider,
    this.decription,
    this.createdAt,
    this.isActived = IsActived.ACTIVE,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
    paymentMethodId: (j['paymentMethodId'] ?? '').toString(),
    methodName     : j['methodName']?.toString(),
    provider       : j['provider']?.toString(),
    decription     : j['decription']?.toString(),
    createdAt      : parseInstant(j['createdAt']),
    isActived      : parseIsActived(j['isActived']),
  );

  Map<String, dynamic> toJson() => {
    'paymentMethodId': paymentMethodId,
    'methodName'     : methodName,
    'provider'       : provider,
    'decription'     : decription,
    'createdAt'      : createdAt?.toIso8601String(),
    'isActived'      : isActived.name,
  };
}
