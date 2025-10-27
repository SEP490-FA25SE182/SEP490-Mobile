import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../model/user_address.dart';
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

T? _firstOrNull<T>(Iterable<T> it, bool Function(T) test) {
  for (final x in it) {
    if (test(x)) return x;
  }
  return null;
}

class _EditAddressPageState extends ConsumerState<EditAddressPage> {
  static const _trashIconGs =
      'gs://sep490-fa25se182.firebasestorage.app/icon/trash-can.png';
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _streetCtrl;

  String? _province;
  String? _district;
  String? _ward;
  String _type = 'Home';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.args.address;

    _nameCtrl   = TextEditingController(text: a.fullName);
    _phoneCtrl  = TextEditingController(text: a.phoneNumber ?? '');
    _streetCtrl = TextEditingController();

    // Parse addressInfor -> street, ward, district, province
    if (a.addressInfor.trim().isNotEmpty) {
      final parts = a.addressInfor.split(',').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) _streetCtrl.text = parts[0];
      if (parts.length >= 2) _ward     = parts[1].isEmpty ? null : parts[1];
      if (parts.length >= 3) _district = parts[2].isEmpty ? null : parts[2];
      if (parts.length >= 4) _province = parts[3].isEmpty ? null : parts[3];
    }

    final t = (a.type ?? '').toLowerCase();
    _type = t == 'office' ? 'Office' : 'Home';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSelect({
    required String title,
    required List<String> options,
    required void Function(String) onPicked,
    String? current,
  }) async {
    final ctx = context;
    final v = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141B29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final h = MediaQuery.of(ctx).size.height;
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
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
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
                          e,
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
                        onTap: () => Navigator.pop(ctx, e),
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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _streetCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Họ tên và Địa chỉ.')),
      );
      return;
    }

    final addressInfor = [
      _streetCtrl.text.trim(),
      if ((_ward ?? '').isNotEmpty) _ward!,
      if ((_district ?? '').isNotEmpty) _district!,
      if ((_province ?? '').isNotEmpty) _province!,
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
      );

      // Làm mới cache danh sách địa chỉ của user
      invalidateAddressesCache(ref, widget.args.userId);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lưu địa chỉ thất bại: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
    final locationsAsync = ref.watch(vnLocationsProvider);

    return locationsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Không tải được danh mục địa chỉ: $e')),
      ),
      data: (provincesData) {
        final provinceNames = provincesData.map((p) => p.name).toList();

        // ---- Tra cứu an toàn, không dùng firstWhere "trần" ----
        final province = (_province == null)
            ? null
            : _firstOrNull(
          provincesData,
              (p) => p.name.trim() == _province!.trim(),
        );

        final districtNames = (province == null)
            ? <String>[]
            : province.districts.map((d) => d.name).toList();

        final district = (province == null || _district == null)
            ? null
            : _firstOrNull(
          province.districts,
              (d) => d.name.trim() == _district!.trim(),
        );

        final wardNames = (district == null)
            ? <String>[]
            : district.wards.map((w) => w.name).toList();

        final canPickDistrict = province != null && districtNames.isNotEmpty;
        final canPickWard = district != null && wardNames.isNotEmpty;

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
                  // Khối thông tin địa chỉ
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
                          'Địa chỉ (dùng thông tin trước sáp nhập)',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),

                        const Text('Họ và Tên',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: TextField(
                            controller: _nameCtrl,
                            decoration:
                            const InputDecoration(border: InputBorder.none),
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
                            decoration:
                            const InputDecoration(border: InputBorder.none),
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
                              _province ?? 'Chọn Tỉnh/Thành phố',
                              style: TextStyle(
                                  color: _province == null
                                      ? Colors.white38
                                      : Colors.white),
                            ),
                            trailing: const Icon(Icons.expand_more,
                                color: Colors.white70),
                            onTap: () => _pickSelect(
                              title: 'Tỉnh/Thành phố',
                              options: provinceNames,
                              current: _province,
                              onPicked: (v) => setState(() {
                                _province = v;
                                _district = null;
                                _ward = null;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Quận/Huyện',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _province == null
                                  ? 'Chọn Tỉnh/Thành trước'
                                  : (_district ?? 'Chọn Quận/Huyện'),
                              style: TextStyle(
                                  color: (_district == null)
                                      ? Colors.white38
                                      : Colors.white),
                            ),
                            trailing: const Icon(Icons.expand_more,
                                color: Colors.white70),
                            onTap: !canPickDistrict
                                ? null
                                : () => _pickSelect(
                              title: 'Quận/Huyện',
                              options: districtNames,
                              current: _district,
                              onPicked: (v) => setState(() {
                                _district = v;
                                _ward = null;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Phường/Xã',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _district == null
                                  ? 'Chọn Quận/Huyện trước'
                                  : (_ward ?? 'Chọn Phường/Xã'),
                              style: TextStyle(
                                  color: (_ward == null)
                                      ? Colors.white38
                                      : Colors.white),
                            ),
                            trailing: const Icon(Icons.expand_more,
                                color: Colors.white70),
                            onTap: !canPickWard
                                ? null
                                : () => _pickSelect(
                              title: 'Phường/Xã',
                              options: wardNames,
                              current: _ward,
                              onPicked: (v) =>
                                  setState(() => _ward = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text('Tên đường, Tòa nhà, Số nhà',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        InputFieldBox(
                          child: TextField(
                            controller: _streetCtrl,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            enableSuggestions: true,
                            autocorrect: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(
                                  RegExp(r'[\r\n]')),
                            ],
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

                  // Loại địa chỉ
                  Container(
                    padding:
                    const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
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
              color:
              selected ? const Color(0xFF5B6CF3) : Colors.white30),
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
