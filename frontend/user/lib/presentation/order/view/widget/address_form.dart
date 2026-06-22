import 'package:flutter/material.dart';

class AddressForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  const AddressForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextField(controller: nameController, label: "Họ tên"),
        _TextField(
          controller: phoneController,
          label: "Số điện thoại",
          keyboardType: TextInputType.phone,
        ),
        _TextField(
          controller: addressController,
          label: "Địa chỉ chi tiết",
          maxLines: 3,
          keyboardType: TextInputType.streetAddress,
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
