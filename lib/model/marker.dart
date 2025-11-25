import 'package:flutter/foundation.dart';
import '../util/model.dart';

@immutable
class MarkerModel {
  final String markerId;
  final String markerCode;
  final String markerType;
  final String? imageUrl;
  final double physicalWidthM;
  final String? printablePdfUrl;
  final String isActived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MarkerModel({
    required this.markerId,
    required this.markerCode,
    required this.markerType,
    this.imageUrl,
    required this.physicalWidthM,
    this.printablePdfUrl,
    required this.isActived,
    this.createdAt,
    this.updatedAt,
  });

  factory MarkerModel.fromJson(Map<String, dynamic> j) {
    double _double(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '0') ?? 0;
    }

    return MarkerModel(
      markerId: (j['markerId'] ?? '').toString(),
      markerCode: (j['markerCode'] ?? '').toString(),
      markerType: (j['markerType'] ?? '').toString(),
      imageUrl: j['imageUrl']?.toString(),
      physicalWidthM: _double(j['physicalWidthM']),
      printablePdfUrl: j['printablePdfUrl']?.toString(),
      isActived: (j['isActived'] ?? '').toString(),
      createdAt: parseInstant(j['createdAt']),
      updatedAt: parseInstant(j['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'markerId': markerId,
    'markerCode': markerCode,
    'markerType': markerType,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'physicalWidthM': physicalWidthM,
    if (printablePdfUrl != null) 'printablePdfUrl': printablePdfUrl,
    'isActived': isActived,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}
