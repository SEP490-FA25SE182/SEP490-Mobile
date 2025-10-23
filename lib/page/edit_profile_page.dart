import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';

import '../widget/gs_image.dart';
import '../provider.dart';
import '../model/user.dart';
import '../style/input_text.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final User? user;
  const EditProfilePage({super.key, this.user});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  static const _bannerGs = 'gs://sep490-fa25se182.firebasestorage.app/banner/profile.webp';
  static const _saveIcon = 'gs://sep490-fa25se182.firebasestorage.app/icon/complete.png';
  static const _avatarSample = 'gs://sep490-fa25se182.firebasestorage.app/avatar/sample_avatar.png';
  static const _bucket = 'sep490-fa25se182.firebasestorage.app';

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _genderCtrl;
  DateTime? _birthDate;
  String? _email;

  String? _avatarGs;
  String? _userId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.user;
    if (initial != null) {
      _bindFromUser(initial);
    } else {
      _nameCtrl     = TextEditingController();
      _phoneCtrl    = TextEditingController();
      _genderCtrl   = TextEditingController();
    }
  }

  void _bindFromUser(User u) {
    _userId     = u.userId;
    _email      = u.email;
    _avatarGs   = (u.avatarUrl ?? '').trim().isNotEmpty ? u.avatarUrl : _avatarSample;
    _birthDate  = u.birthDate;
    _nameCtrl   = TextEditingController(text: u.fullName);
    _phoneCtrl  = TextEditingController(text: u.phoneNumber ?? '');
    _genderCtrl = TextEditingController(text: u.gender ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (x == null) return;

      final file = File(x.path);
      final fileName = '${_userId ?? DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload lên Firebase Storage -> path: avatar/{userId}.jpg
      final ref = FirebaseStorage.instance.ref().child('avatar/$fileName');
      await ref.putFile(file);

      // Lưu gs:// vào state (để gửi DB)
      setState(() {
        _avatarGs = 'gs://$_bucket/avatar/$fileName';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tải ảnh lên, nhấn Lưu để cập nhật hồ sơ.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải ảnh thất bại: $e')),
      );
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final init = _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _editGender() async {
    final options = ['Nam', 'Nữ', 'Khác'];
    final cur = _genderCtrl.text.trim();
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((s) {
            return ListTile(
              title: Text(s),
              trailing: cur == s ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, s),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _genderCtrl.text = selected);
    }
  }

  Future<void> _save() async {
    if (_userId == null || _userId!.isEmpty) return;
    setState(() => _saving = true);

    try {
      final updated = await ref.read(userRepoProvider).updateProfile(
        userId: _userId!,
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        gender: _genderCtrl.text.trim().isEmpty ? null : _genderCtrl.text.trim(),
        birthDate: _birthDate,
        avatarUrl: _avatarGs,
      );

      // invalidate cache để Profile/VM refresh
      invalidateUserCache(ref, updated.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hồ sơ.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? u = widget.user;
    if (u == null) {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null || uid.isEmpty) {
        return const Scaffold(
          body: Center(child: Text('Bạn chưa đăng nhập')),
        );
      }
      final async = ref.watch(userByIdProvider(uid));
      return async.when(
        data: (user) {
          if (_userId == null) _bindFromUser(user);
          return _buildScaffold();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
      );
    }

    return _buildScaffold();
  }

  Widget _buildScaffold() {
    final avatarUrl = (_avatarGs ?? _avatarSample);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Sửa hồ sơ'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: SizedBox(
              width: 22, height: 22,
              child: GsImage(url: _saveIcon, fit: BoxFit.contain),
            ),
            tooltip: 'Lưu',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0E2A47), Color(0xFF09121F)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              // Banner + avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 16/6,
                      child: GsImage(url: _bannerGs, fit: BoxFit.cover),
                    ),
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.black26,
                        child: ClipOval(
                          child: SizedBox(
                            width: 78, height: 78,
                            child: GsImage(url: avatarUrl, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _EditableRow(
                label: 'Tên',
                value: _nameCtrl.text,
                onTap: () async {
                  final v = await _editText('Tên', _nameCtrl.text, maxLen: 50);
                  if (v != null) setState(() => _nameCtrl.text = v);
                },
              ),
              const Divider(color: Colors.white12, height: 1),

              _EditableRow(
                label: 'Giới tính',
                value: (_genderCtrl.text.isEmpty ? '—' : _genderCtrl.text),
                onTap: _editGender,
              ),
              const Divider(color: Colors.white12, height: 1),

              _EditableRow(
                label: 'Ngày sinh',
                value: _birthDate == null
                    ? '—'
                    : _fmtDate(_birthDate!),
                onTap: _pickBirthDate,
              ),
              const Divider(color: Colors.white12, height: 1),

              _EditableRow(
                label: 'Số điện thoại',
                value: _phoneCtrl.text.isEmpty ? '—' : _phoneCtrl.text,
                onTap: () async {
                  final v = await _editText('Số điện thoại', _phoneCtrl.text,
                      keyboardType: TextInputType.phone, maxLen: 20);
                  if (v != null) setState(() => _phoneCtrl.text = v);
                },
              ),
              const Divider(color: Colors.white12, height: 1),

              _EditableRow(
                label: 'Email',
                value: _email ?? '—',
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2,'0');
    final mm = d.month.toString().padLeft(2,'0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  Future<String?> _editText(
      String title,
      String initial, {
        TextInputType keyboardType = TextInputType.text,
        int? maxLen,
      }) async {
    final ctrl = TextEditingController(text: initial);
    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLength: maxLen,
          decoration: const InputDecoration(hintText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
    return v;
  }
}

/// Hàng thông tin (label - value), bấm để chỉnh sửa
class _EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool enabled;
  const _EditableRow({
    required this.label,
    required this.value,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            if (enabled) const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.edit, size: 16, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
