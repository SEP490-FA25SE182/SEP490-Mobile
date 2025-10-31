import 'package:meta/meta.dart';

@immutable
class CreateCheckoutResponse {
  final String checkoutUrl;
  final String qrCode;
  final String paymentLinkId;
  final int orderCode;
  final int amount;

  const CreateCheckoutResponse({
    required this.checkoutUrl,
    required this.qrCode,
    required this.paymentLinkId,
    required this.orderCode,
    required this.amount,
  });

  factory CreateCheckoutResponse.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;

    return CreateCheckoutResponse(
      checkoutUrl   : (j['checkoutUrl'] ?? '').toString(),
      qrCode        : (j['qrCode'] ?? '').toString(),
      paymentLinkId : (j['paymentLinkId'] ?? '').toString(),
      orderCode     : _int(j['orderCode']),
      amount        : _int(j['amount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'checkoutUrl'  : checkoutUrl,
    'qrCode'       : qrCode,
    'paymentLinkId': paymentLinkId,
    'orderCode'    : orderCode,
    'amount'       : amount,
  };
}
