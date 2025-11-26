import 'package:meta/meta.dart';
import 'ghn_shipping.dart';

@immutable
class GhnShippingFeeRequestDTO {
  final int serviceTypeId;
  final int fromDistrictId;
  final String fromWardCode;
  final int toDistrictId;
  final String toWardCode;
  final int? length;
  final int? width;
  final int? height;
  final int? weight;
  final int? insuranceValue;
  final String? coupon;
  final int? codFailedAmount;
  final int? codValue;
  final List<GhnItemDTO>? items;

  const GhnShippingFeeRequestDTO({
    required this.serviceTypeId,
    required this.fromDistrictId,
    required this.fromWardCode,
    required this.toDistrictId,
    required this.toWardCode,
    this.length,
    this.width,
    this.height,
    this.weight,
    this.insuranceValue,
    this.coupon,
    this.codFailedAmount,
    this.codValue,
    this.items,
  });

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory GhnShippingFeeRequestDTO.fromJson(Map<String, dynamic> j) {
    final itemsJson = j['items'] as List?;
    return GhnShippingFeeRequestDTO(
      serviceTypeId: _parseNullableInt(j['service_type_id']) ?? 0,
      fromDistrictId: _parseNullableInt(j['from_district_id']) ?? 0,
      fromWardCode: (j['from_ward_code'] ?? '').toString(),
      toDistrictId: _parseNullableInt(j['to_district_id']) ?? 0,
      toWardCode: (j['to_ward_code'] ?? '').toString(),
      length: _parseNullableInt(j['length']),
      width: _parseNullableInt(j['width']),
      height: _parseNullableInt(j['height']),
      weight: _parseNullableInt(j['weight']),
      insuranceValue: _parseNullableInt(j['insurance_value']),
      coupon: j['coupon']?.toString(),
      codFailedAmount: _parseNullableInt(j['codFailedAmount']),
      codValue: _parseNullableInt(j['codValue']),
      items: itemsJson?.map((i) => GhnItemDTO.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'service_type_id': serviceTypeId,
    'from_district_id': fromDistrictId,
    'from_ward_code': fromWardCode,
    'to_district_id': toDistrictId,
    'to_ward_code': toWardCode,
    if (length != null) 'length': length,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (insuranceValue != null) 'insurance_value': insuranceValue,
    if (coupon != null && coupon!.isNotEmpty) 'coupon': coupon,
    if (codFailedAmount != null) 'codFailedAmount': codFailedAmount,
    if (codValue != null) 'codValue': codValue,
    if (items != null && items!.isNotEmpty) 'items': items!.map((i) => i.toJson()).toList(),
  };
}