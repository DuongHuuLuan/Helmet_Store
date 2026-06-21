import 'package:flutter/material.dart';

class CartActions extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onRefresh;
  final bool isLoading;
  const CartActions({
    super.key,
    required this.isLoading,
    required this.onContinue,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onContinue,
            label: const Text("TIẾP TỤC XEM SẢN PHẨM"),
            icon: const Icon(Icons.arrow_back),
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            // onPressed: isLoading ? null : onRefresh,
            onPressed: onRefresh,
            child: Text("CẬP NHẬT GIỎ HÀNG"),
          ),
        ),
      ],
    );
  }
}
