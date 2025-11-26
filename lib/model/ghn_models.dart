
class GhnProvince {
  final int provinceID;
  final String provinceName;
  final List<String> nameExtension;

  GhnProvince({
    required this.provinceID,
    required this.provinceName,
    required this.nameExtension,
  });

  factory GhnProvince.fromJson(Map<String, dynamic> json) {
    final nameExt = json['NameExtension'] ?? json['nameExtension'];
    return GhnProvince(
      provinceID: json['ProvinceID'] ?? json['provinceID'] ?? 0,
      provinceName: json['ProvinceName'] ?? json['provinceName'] ?? '',
      nameExtension: nameExt is List
          ? List<String>.from(nameExt)
          : <String>[],
    );
  }

  @override
  String toString() => provinceName;
}

class GhnDistrict {
  final int districtID;
  final String districtName;
  final int provinceID;
  final List<String> nameExtension;

  GhnDistrict({
    required this.districtID,
    required this.districtName,
    required this.provinceID,
    required this.nameExtension,
  });

  factory GhnDistrict.fromJson(Map<String, dynamic> json) {
    final nameExt = json['NameExtension'] ?? json['nameExtension'];
    return GhnDistrict(
      districtID: json['DistrictID'] ?? json['districtID'] ?? 0,
      districtName: json['DistrictName'] ?? json['districtName'] ?? '',
      provinceID: json['ProvinceID'] ?? json['provinceID'] ?? 0,
      nameExtension: nameExt is List
          ? List<String>.from(nameExt)
          : <String>[],
    );
  }

  @override
  String toString() => districtName;
}

class GhnWard {
  final String wardCode;
  final String wardName;
  final int districtID;
  final List<String> nameExtension;

  GhnWard({
    required this.wardCode,
    required this.wardName,
    required this.districtID,
    required this.nameExtension,
  });

  factory GhnWard.fromJson(Map<String, dynamic> json) {
    final nameExt = json['NameExtension'] ?? json['nameExtension'];
    return GhnWard(
      wardCode: json['WardCode'] ?? json['wardCode'] ?? '',
      wardName: json['WardName'] ?? json['wardName'] ?? '',
      districtID: json['DistrictID'] ?? json['districtID'] ?? 0,
      nameExtension: nameExt is List
          ? List<String>.from(nameExt)
          : <String>[],
    );
  }

  @override
  String toString() => wardName;
}