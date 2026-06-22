import 'dart:io';

import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/cubit/evaluate_cubit.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EvaluateCreatePage extends StatefulWidget {
  final int orderId;

  const EvaluateCreatePage({super.key, required this.orderId});

  @override
  State<EvaluateCreatePage> createState() => _EvaluateCreatePageState();
}

class _EvaluateCreatePageState extends State<EvaluateCreatePage> {
  static const _maxImages = 5;
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  int _rate = 5;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EvaluateCubit>().state;
    final isSubmitting = state.creatingOrderIds.contains(widget.orderId);

        return Scaffold(
          appBar: AppBar(title: Text("Đánh giá đơn #DH-${widget.orderId}")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Số sao",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: List.generate(5, (idx) {
                    final value = idx + 1;
                    final selected = _rate == value;
                    return ChoiceChip(
                      label: Text("⭐ $value"),
                      selected: selected,
                      onSelected: isSubmitting
                          ? null
                          : (_) => setState(() => _rate = value),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Text(
                  "Nội dung",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  enabled: !isSubmitting,
                  maxLines: 4,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Chia sẻ trải nghiệm của bạn về đơn hàng...",
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : _pickImages,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text("Chọn ảnh (tối đa 5)"),
                      ),
                    ),
                  ],
                ),
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text("Đã chọn ${_images.length}/$_maxImages ảnh"),
                ],
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_images.length, (index) {
                      final file = _images[index];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(file.path),
                              width: 74,
                              height: 74,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: InkWell(
                              onTap: isSubmitting
                                  ? null
                                  : () =>
                                        setState(() => _images.removeAt(index)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 18),
                if ((state.errorMessage ?? "").trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(context).maybePop(false),
                        child: const Text("Hủy"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                        ),
                        child: Text(
                          isSubmitting ? "Đang gửi..." : "Gửi đánh giá",
                        ),
                      ),
                    ),
                  ],
        ),
      ],
    ),
          ),
        );
  }

  Future<void> _pickImages() async {
    try {
      final remainingSlots = _maxImages - _images.length;
      if (remainingSlots <= 0) {
        return;
      }

      final selected = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1400,
        limit: remainingSlots,
      );
      if (!mounted || selected.isEmpty) return;

      final existingPaths = _images.map((e) => e.path).toSet();
      final newImages = selected
          .where((file) => !existingPaths.contains(file.path))
          .take(remainingSlots)
          .toList();
      if (newImages.isEmpty) return;

      setState(() {
        _images.addAll(newImages);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không thể chọn ảnh.")));
    }
  }

  Future<void> _submit() async {
    final cubit = context.read<EvaluateCubit>();
    try {
      await cubit.createEvaluate(
        orderId: widget.orderId,
        rate: _rate,
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        imagePaths: _images.map((e) => e.path).toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gửi đánh giá thành công.")));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      final msg = cubit.state.errorMessage ?? "Gửi đánh giá thất bại.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
