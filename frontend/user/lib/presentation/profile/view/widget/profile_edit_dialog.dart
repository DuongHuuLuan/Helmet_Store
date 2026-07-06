import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ProfileEditValue {
  final String name;
  final String phone;
  final String gender;
  final DateTime? birthday;
  final String avatar;
  final String? avatarFilePath;
  final String? avatarFileName;

  const ProfileEditValue({
    required this.name,
    required this.phone,
    required this.gender,
    required this.birthday,
    required this.avatar,
    this.avatarFilePath,
    this.avatarFileName,
  });
}

class ProfileEditDialog extends StatefulWidget {
  final Profile? profile;
  final String fallbackName;
  final bool isSubmitting;
  final bool isUploadingAvatar;
  final Future<XFile?> Function()? onPickAvatarFromGallery;
  final Future<XFile?> Function()? onCaptureAvatar;

  const ProfileEditDialog({
    super.key,
    required this.profile,
    required this.fallbackName,
    required this.isSubmitting,
    required this.isUploadingAvatar,
    this.onPickAvatarFromGallery,
    this.onCaptureAvatar,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  DateTime? _birthday;
  String _gender = "";
  XFile? _pendingAvatarFile;
  Uint8List? _pendingAvatarBytes;

  bool get _isBusy => widget.isSubmitting || widget.isUploadingAvatar;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(
      text: (p?.name ?? widget.fallbackName).trim(),
    );
    _phoneController = TextEditingController(text: (p?.phone ?? "").trim());
    _avatarController = TextEditingController(text: (p?.avatar ?? "").trim());
    _birthday = p?.birthday;
    final rawGender = (p?.gender ?? "").trim().toLowerCase();
    _gender = _isValidGender(rawGender) ? rawGender : "";
  }

  @override
  void didUpdateWidget(covariant ProfileEditDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldAvatar = (oldWidget.profile?.avatar ?? "").trim();
    final newAvatar = (widget.profile?.avatar ?? "").trim();
    if (oldAvatar != newAvatar) {
      _avatarController.text = newAvatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final birthdayText = _birthday == null ? "" : _formatDateLabel(_birthday!);
    final avatarUrl = _resolveAvatar(_avatarController.text);

    return AlertDialog(
      title: Text(
        "Chỉnh sửa thông tin cá nhân",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AvatarPickerCard(
                avatarUrl: avatarUrl,
                isUploading: widget.isUploadingAvatar,
                pendingAvatarName: _pendingAvatarFile?.name,
                pendingAvatarBytes: _pendingAvatarBytes,
                onPickFromGallery: _isBusy ? null : _handlePickFromGallery,
                onCaptureFromCamera: _isBusy ? null : _handleCaptureAvatar,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Họ và tên",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = (value ?? "").trim();
                  if (text.isEmpty) return "Vui lòng nhập họ tên";
                  if (text.length > 50) return "Tên tối đa 50 ký tự";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Số điện thoại",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = (value ?? "").trim();
                  if (text.isEmpty) return null;
                  final phonePattern = RegExp(r"^\+?1?\d{9,15}$");
                  if (!phonePattern.hasMatch(text)) {
                    return "Số điện thoại không hợp lệ";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                items: const [
                  DropdownMenuItem(value: "", child: Text("Không chọn")),
                  DropdownMenuItem(value: "male", child: Text("Nam")),
                  DropdownMenuItem(value: "female", child: Text("Nữ")),
                  DropdownMenuItem(value: "other", child: Text("Khác")),
                ],
                onChanged: _isBusy
                    ? null
                    : (value) => setState(() => _gender = value ?? ""),
                decoration: const InputDecoration(
                  labelText: "Giới tính",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _isBusy ? null : _pickBirthday,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Ngày sinh",
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Chọn ngày sinh",
                          onPressed: _isBusy ? null : _pickBirthday,
                          icon: const Icon(Icons.calendar_today_outlined),
                        ),
                        IconButton(
                          tooltip: "Xóa ngày sinh",
                          onPressed: _isBusy
                              ? null
                              : () => setState(() => _birthday = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      birthdayText.isEmpty
                          ? "Chưa chọn ngày sinh"
                          : birthdayText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
          child: Text(
            "Hủy",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        ElevatedButton(
          onPressed: _isBusy ? null : _submit,
          child: widget.isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text("Lưu"),
        ),
      ],
    );
  }

  Future<void> _handlePickFromGallery() async {
    final callback = widget.onPickAvatarFromGallery;
    if (callback == null) return;
    final file = await callback();
    if (!mounted || file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pendingAvatarFile = file;
      _pendingAvatarBytes = bytes;
    });
  }

  Future<void> _handleCaptureAvatar() async {
    final callback = widget.onCaptureAvatar;
    if (callback == null) return;
    final file = await callback();
    if (!mounted || file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pendingAvatarFile = file;
      _pendingAvatarBytes = bytes;
    });
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate =
        _birthday ?? DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(1900, 1, 1);
    final lastDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    setState(() => _birthday = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ProfileEditValue(
        name: _nameController.text,
        phone: _phoneController.text,
        gender: _gender,
        birthday: _birthday,
        avatar: _avatarController.text,
        avatarFilePath: _pendingAvatarFile?.path,
        avatarFileName: _pendingAvatarFile?.name,
      ),
    );
  }

  String _formatDateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, "0");
    final month = value.month.toString().padLeft(2, "0");
    final year = value.year.toString();
    return "$day/$month/$year";
  }

  bool _isValidGender(String value) {
    return value == "male" || value == "female" || value == "other";
  }

  String? _resolveAvatar(String? avatar) {
    if (avatar == null || avatar.trim().isEmpty) return null;
    final raw = avatar.trim();
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/")) return "${AppConstants.baseUrl}$raw";
    return "${AppConstants.baseUrl}/$raw";
  }
}

class _AvatarPickerCard extends StatelessWidget {
  final String? avatarUrl;
  final bool isUploading;
  final String? pendingAvatarName;
  final Uint8List? pendingAvatarBytes;
  final Future<void> Function()? onPickFromGallery;
  final Future<void> Function()? onCaptureFromCamera;

  const _AvatarPickerCard({
    required this.avatarUrl,
    required this.isUploading,
    required this.pendingAvatarName,
    required this.pendingAvatarBytes,
    required this.onPickFromGallery,
    required this.onCaptureFromCamera,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: pendingAvatarBytes != null
                    ? MemoryImage(pendingAvatarBytes!)
                    : (avatarUrl != null ? NetworkImage(avatarUrl!) : null),
                child: pendingAvatarBytes == null && avatarUrl == null
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUploading
                      ? "Đang tải ảnh..."
                      : pendingAvatarName != null
                      ? "Đã chọn ảnh mới: $pendingAvatarName"
                      : "Chọn ảnh từ thư viện hoặc máy ảnh",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isUploading || onPickFromGallery == null
                        ? null
                        : () => onPickFromGallery!.call(),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text(
                      "Thư viện",
                      style: TextStyle(
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isUploading || onCaptureFromCamera == null
                        ? null
                        : () => onCaptureFromCamera!.call(),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text(
                      "Máy ảnh",
                      style: TextStyle(
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
