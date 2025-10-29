class VnProvince {
  final String code;
  final String name;
  final List<VnDistrict> districts;
  VnProvince({required this.code, required this.name, required this.districts});
  factory VnProvince.fromJson(Map<String,dynamic> j) => VnProvince(
    code: j['code'].toString(),
    name: j['name'] as String,
    districts: (j['districts'] as List? ?? [])
        .map((d)=>VnDistrict.fromJson(d as Map<String,dynamic>)).toList(),
  );
}

class VnDistrict {
  final String code;
  final String name;
  final List<VnWard> wards;
  VnDistrict({required this.code, required this.name, required this.wards});
  factory VnDistrict.fromJson(Map<String,dynamic> j) => VnDistrict(
    code: j['code'].toString(),
    name: j['name'] as String,
    wards: (j['wards'] as List? ?? [])
        .map((w)=>VnWard.fromJson(w as Map<String,dynamic>)).toList(),
  );
}

class VnWard {
  final String code;
  final String name;
  VnWard({required this.code, required this.name});
  factory VnWard.fromJson(Map<String,dynamic> j) => VnWard(
    code: j['code'].toString(),
    name: j['name'] as String,
  );
}
