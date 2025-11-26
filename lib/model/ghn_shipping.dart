import 'package:meta/meta.dart';

import 'ghn_category_dto.dart';

@immutable
class GhnItemDTO {
  final String name;
  final String? code;
  final int quantity;
  final int price;
  final int? length;
  final int? width;
  final int? height;
  final int? weight;
  final GhnCategoryDTO? category;

  const GhnItemDTO({
    required this.name,
    this.code,
    required this.quantity,
    required this.price,
    this.length,
    this.width,
    this.height,
    this.weight,
    this.category,
  });

  // Safe parsers
  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory GhnItemDTO.fromJson(Map<String, dynamic> j) {
    final categoryJson = j['category'] as Map<String, dynamic>?;
    return GhnItemDTO(
      name: (j['name'] ?? '').toString(),
      code: j['code']?.toString(),
      quantity: _parseInt(j['quantity']),
      price: _parseInt(j['price']),
      length: _parseNullableInt(j['length']),
      width: _parseNullableInt(j['width']),
      height: _parseNullableInt(j['height']),
      weight: _parseNullableInt(j['weight']),
      category: categoryJson != null ? GhnCategoryDTO.fromJson(categoryJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (code != null) 'code': code,
    'quantity': quantity,
    'price': price,
    if (length != null) 'length': length,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (category != null) 'category': category!.toJson(),
  };

  @override
  String toString() {
    return 'GhnItemDTO(name: $name, quantity: $quantity, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GhnItemDTO &&
        other.name == name &&
        other.code == code &&
        other.quantity == quantity &&
        other.price == price &&
        other.length == length &&
        other.width == width &&
        other.height == height &&
        other.weight == weight &&
        other.category == category;
  }

  @override
  int get hashCode {
    return Object.hash(
      name, code, quantity, price, length, width, height, weight, category,
    );
  }
}