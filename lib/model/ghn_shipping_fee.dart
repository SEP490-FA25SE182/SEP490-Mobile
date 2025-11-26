import 'package:meta/meta.dart';

@immutable
class GhnShippingFee {
  final int? fee;
  final int? serviceFee;
  final int? insuranceFee;
  final int? codFee;
  final int? total;

  const GhnShippingFee({
    this.fee,
    this.serviceFee,
    this.insuranceFee,
    this.codFee,
    this.total,
  });

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory GhnShippingFee.fromJson(Map<String, dynamic> j) => GhnShippingFee(
    fee: _parseInt(j['fee']),
    serviceFee: _parseInt(j['serviceFee']),
    insuranceFee: _parseInt(j['insuranceFee']),
    codFee: _parseInt(j['codFee']),
    total: _parseInt(j['total']),
  );

  Map<String, dynamic> toJson() => {
    if (fee != null) 'fee': fee,
    if (serviceFee != null) 'serviceFee': serviceFee,
    if (insuranceFee != null) 'insuranceFee': insuranceFee,
    if (codFee != null) 'codFee': codFee,
    if (total != null) 'total': total,
  };

  @override
  String toString() => 'GhnShippingFee(total: $total)';
}