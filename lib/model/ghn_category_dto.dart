import 'package:meta/meta.dart';

@immutable
class GhnCategoryDTO {
  final String level1;

  const GhnCategoryDTO({required this.level1});

  factory GhnCategoryDTO.fromJson(Map<String, dynamic> j) {
    return GhnCategoryDTO(
      level1: (j['level1'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'level1': level1,
  };

  @override
  String toString() => 'GhnCategoryDTO(level1: $level1)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is GhnCategoryDTO && other.level1 == level1);
  }

  @override
  int get hashCode => level1.hashCode;
}