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

  final String? userId;
  final String? bookId;
  final String? tagFamily; // e.g. tag36h11
  final int? tagId;        // AprilTag numeric id

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

    this.userId,
    this.bookId,
    this.tagFamily,
    this.tagId,
  });

  factory MarkerModel.fromJson(Map<String, dynamic> j) {
    double _double(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '0') ?? 0;
    }

    int? _int(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
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
      userId: j['userId']?.toString(),
      bookId: j['bookId']?.toString(),
      tagFamily: j['tagFamily']?.toString(),
      tagId: _int(j['tagId']),
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
    if (userId != null) 'userId': userId,
    if (bookId != null) 'bookId': bookId,
    if (tagFamily != null) 'tagFamily': tagFamily,
    if (tagId != null) 'tagId': tagId,
  };
}
