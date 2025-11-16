import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/user_address.dart';
import '../../model/ghn_models.dart'; // GHN models
import '../../provider.dart';
import '../../style/button.dart';
import '../../style/input_text.dart';
import '../../widget/gs_image.dart';

class EditAddressArgs {
  final String userId;
  final UserAddress address;
  const EditAddressArgs({required this.userId, required this.address});
}

class EditAddressPage extends ConsumerStatefulWidget {
  final EditAddressArgs args;
  const EditAddressPage({super.key, required this.args});

  @override
  ConsumerState<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends ConsumerState<EditAddressPage> {
  static const _trashIconGs =
      'gs://sep490-fa25se182.firebasestorage.app/icon/trash-can.png';

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _streetCtrl;

  GhnProvince? _selectedProvince;
  GhnDistrict? _selectedDistrict;
  GhnWard? _selectedWard;

  String _type = 'Home';
  bool _isDefault = false;
  bool _saving = false;

  String? _provinceId;
  String? _districtId;
  String? _wardCode;

  @override
  void initState() {
    super.initState();
    final a = widget.args.address;

    _nameCtrl = TextEditingController(text: a.fullName);
    _phoneCtrl = TextEditingController(text: a.phoneNumber ?? '');
    _streetCtrl = TextEditingController();

    if (a.addressInfor.trim().isNotEmpty) {
      final parts = a.addressInfor.split(',').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) _streetCtrl.text = parts[0];
    }

    final t = (a.type ?? '').toLowerCase();
    _type = t == 'office' ? 'Office' : 'Home';
    _isDefault = a.isDefault;

    _provinceId = a.provinceId;
    _districtId = a.districtId;
    _wardCode = a.wardCode;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  /// Bottom‑sheet picker chung
  Future<void> _pickSelect<T>({
    required String title,
    required List<T> options,
    required void Function(T) onPicked,
    T? current,
    required String Function(T) display,
  }) async {
    final v = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141B29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final h = MediaQuery.of(context).size.height;
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: h * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (_, i) {
                      final e = options[i];
                      final selected = e == current;
                      return ListTile(
                        title: Text(
                          display(e),
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(selected ? 1 : 0.9),
                            fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check, color: Colors.white70)
                            : null,
                        onTap: () => Navigator.pop(context, e),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (v != null) onPicked(v);
  }

  /// Lưu địa chỉ
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _streetCtrl.text.trim().isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final addressInfor = [
      _streetCtrl.text.trim(),
      _selectedWard!.wardName,
      _selectedDistrict!.districtName,
      _selectedProvince!.provinceName,
    ].join(', ');

    setState(() => _saving = true);
    try {
      await ref.read(addressRepoProvider).update(
        widget.args.address.userAddressId,
        fullName: _nameCtrl.text.trim(),
        addressInfor: addressInfor,
        phoneNumber:
        _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        type: _type,
        provinceId: _selectedProvince!.provinceID.toString(),
        districtId: _selectedDistrict!.districtID.toString(),
        wardCode: _selectedWard!.wardCode,
      );

      invalidateAddressesCache(ref, widget.args.userId);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu địa chỉ thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Xác nhận xoá
  Future<void> _confirmDelete() async {
    final ctx = context;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Xoá địa chỉ?'),
        content: const Text('Bạn có chắc muốn xoá địa chỉ này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xoá')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(addressRepoProvider)
          .remove(widget.args.address.userAddressId);
      invalidateAddressesCache(ref, widget.args.userId);
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Đã xoá địa chỉ.')),
        );
        ctx.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Xoá thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(ghnProvincesProvider);

    return provincesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Lỗi tải tỉnh: $e')),
      ),
      data: (provinces) {

        if (_selectedProvince == null && _provinceId != null) {
          _selectedProvince = provinces.cast<GhnProvince?>().firstWhere(
                (p) => p?.provinceID.toString() == _provinceId,
            orElse: () => null,
          );
          if (_selectedProvince != null) {
            ref.invalidate(
                ghnDistrictsProvider(_selectedProvince!.provinceID));
          }
        }

        final districtsAsync = _selectedProvince != null
            ? ref.watch(ghnDistrictsProvider(_selectedProvince!.provinceID))
            : null;

        final wardsAsync = _selectedDistrict != null
            ? ref.watch(ghnWardsProvider(_selectedDistrict!.districtID))
            : null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Chỉnh sửa địa chỉ'),
            actions: [
              IconButton(
                tooltip: 'Xoá địa chỉ',
                onPressed: _saving ? null : _confirmDelete,
                icon: SizedBox(
                  width: 24,
                  height: 24,
                  child: GsImage(url: _trashIconGs, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0E2A47), Color(0xFF09121F)],
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Địa chỉ giao hàng',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),

                        const Text('Họ và Tên',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                                border: InputBorder.none),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Số điện thoại',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                border: InputBorder.none),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Tỉnh/Thành phố',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _selectedProvince?.provinceName ??
                                  'Chọn Tỉnh/Thành phố',
                              style: TextStyle(
                                color: _selectedProvince == null
                                    ? Colors.white38
                                    : Colors.white,
                              ),
                            ),
                            trailing: const Icon(Icons.expand_more,
                                color: Colors.white70),
                            onTap: () => _pickSelect(
                              title: 'Tỉnh/Thành phố',
                              options: provinces,
                              current: _selectedProvince,
                              display: (p) => p.provinceName,
                              onPicked: (v) {
                                setState(() {
                                  _selectedProvince = v;
                                  _selectedDistrict = null;
                                  _selectedWard = null;
                                });
                                ref.invalidate(ghnDistrictsProvider);
                                ref.invalidate(ghnWardsProvider);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Quận/Huyện',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: districtsAsync == null
                              ? const ListTile(
                            title: Text('Chọn Tỉnh/Thành trước',
                                style:
                                TextStyle(color: Colors.white38)),
                          )
                              : districtsAsync.when(
                            loading: () => const ListTile(
                              title: Text('Đang tải...',
                                  style:
                                  TextStyle(color: Colors.white38)),
                            ),
                            error: (_, __) => const ListTile(
                              title: Text('Lỗi tải quận',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            data: (districts) {
                              if (_selectedDistrict == null &&
                                  _districtId != null) {
                                _selectedDistrict = districts
                                    .cast<GhnDistrict?>()
                                    .firstWhere(
                                      (d) => d?.districtID.toString() ==
                                      _districtId,
                                  orElse: () => null,
                                );
                                if (_selectedDistrict != null) {
                                  ref.invalidate(ghnWardsProvider(
                                      _selectedDistrict!.districtID));
                                }
                              }

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  _selectedDistrict?.districtName ??
                                      'Chọn Quận/Huyện',
                                  style: TextStyle(
                                    color: _selectedDistrict == null
                                        ? Colors.white38
                                        : Colors.white,
                                  ),
                                ),
                                trailing: const Icon(Icons.expand_more,
                                    color: Colors.white70),
                                onTap: () => _pickSelect(
                                  title: 'Quận/Huyện',
                                  options: districts,
                                  current: _selectedDistrict,
                                  display: (d) => d.districtName,
                                  onPicked: (v) {
                                    setState(() {
                                      _selectedDistrict = v;
                                      _selectedWard = null;
                                    });
                                    ref.invalidate(ghnWardsProvider);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Phường/Xã',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: wardsAsync == null
                              ? const ListTile(
                            title: Text('Chọn Quận/Huyện trước',
                                style:
                                TextStyle(color: Colors.white38)),
                          )
                              : wardsAsync.when(
                            loading: () => const ListTile(
                              title: Text('Đang tải...',
                                  style:
                                  TextStyle(color: Colors.white38)),
                            ),
                            error: (_, __) => const ListTile(
                              title: Text('Lỗi tải phường',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            data: (wards) {
                              if (_selectedWard == null &&
                                  _wardCode != null) {
                                _selectedWard = wards
                                    .cast<GhnWard?>()
                                    .firstWhere(
                                      (w) => w?.wardCode == _wardCode,
                                  orElse: () => null,
                                );
                              }

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  _selectedWard?.wardName ??
                                      'Chọn Phường/Xã',
                                  style: TextStyle(
                                    color: _selectedWard == null
                                        ? Colors.white38
                                        : Colors.white,
                                  ),
                                ),
                                trailing: const Icon(Icons.expand_more,
                                    color: Colors.white70),
                                onTap: () => _pickSelect(
                                  title: 'Phường/Xã',
                                  options: wards,
                                  current: _selectedWard,
                                  display: (w) => w.wardName,
                                  onPicked: (v) =>
                                      setState(() => _selectedWard = v),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Tên đường, Số nhà',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: TextField(
                            controller: _streetCtrl,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'VD: 123 Lưu Hữu Phước',
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Đặt làm địa chỉ mặc định',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                            Checkbox(
                              value: _isDefault,
                              onChanged: (v) =>
                                  setState(() => _isDefault = v ?? false),
                              side: const BorderSide(color: Colors.white54),
                              checkColor: Colors.white,
                              activeColor: const Color(0xFF5B6CF3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Loại địa chỉ',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                            _TypeChip(
                              text: 'Văn phòng',
                              selected: _type == 'Office',
                              onTap: () => setState(() => _type = 'Office'),
                            ),
                            const SizedBox(width: 8),
                            _TypeChip(
                              text: 'Nhà riêng',
                              selected: _type == 'Home',
                              onTap: () => setState(() => _type = 'Home'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  ButtonPrimary(
                    text: _saving ? 'Đang lưu...' : 'HOÀN THÀNH',
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0x335B6CF3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF5B6CF3) : Colors.white30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}