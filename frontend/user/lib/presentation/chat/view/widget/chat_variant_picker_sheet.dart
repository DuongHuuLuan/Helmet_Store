import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_payload.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_variant_picker.dart';
import 'package:flutter/material.dart';

class ChatVariantPickerSheet extends StatefulWidget {
  final String productName;
  final List<ChatProductVariantData> variants;

  const ChatVariantPickerSheet({
    super.key,
    required this.productName,
    required this.variants,
  });

  @override
  State<ChatVariantPickerSheet> createState() => _ChatVariantPickerSheetState();
}

class _ChatVariantPickerSheetState extends State<ChatVariantPickerSheet> {
  int? _selectedProductDetailId;

  List<ChatProductVariantData> get _availableVariants =>
      widget.variants.where((variant) => variant.isAvailable).toList();

  @override
  void initState() {
    super.initState();
    if (_availableVariants.length == 1) {
      _selectedProductDetailId = _availableVariants.first.productDetailId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Chọn biến thể",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              widget.productName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            ChatVariantPicker(
              variants: widget.variants,
              selectedProductDetailId: _selectedProductDetailId,
              onVariantTap: (variant) {
                setState(() {
                  _selectedProductDetailId = variant.productDetailId;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedProductDetailId == null
                    ? null
                    : () => Navigator.of(context).pop(_selectedProductDetailId),
                child: const Text("Thêm vào giỏ"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
