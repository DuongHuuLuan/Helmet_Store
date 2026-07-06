import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/cubit/profile_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/widget/voucher_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileVouchersPage extends StatefulWidget {
  const ProfileVouchersPage({super.key});

  @override
  State<ProfileVouchersPage> createState() => _ProfileVouchersPageState();
}

class _ProfileVouchersPageState extends State<ProfileVouchersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ProfileCubit>();
      if (!cubit.state.isLoading &&
          cubit.state.profile == null &&
          cubit.state.orders.isEmpty &&
          cubit.state.availableDiscounts.isEmpty) {
        cubit.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    final vouchers = state.availableDiscounts
        .map(
          (discount) => VoucherItemData(
            code: discount.name,
            description: discount.description.trim().isNotEmpty
                ? discount.description.trim()
                : "Giảm ${_formatPercent(discount.percent)}% cho đơn hàng phù hợp",
            expiry: "HSD: ${_formatDate(discount.endAt)}",
            longDescription:
                "Sử dụng mã này để được giảm ngay ${_formatPercent(discount.percent)}% tổng giá trị đơn hàng. Áp dụng đến hết ngày ${_formatDate(discount.endAt)}.",
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        title: const Text("Kho voucher"),
        actions: [
          IconButton(
            tooltip: "Làm mới",
            onPressed: state.isLoading ? null : context.read<ProfileCubit>().refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading && vouchers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VoucherSection(items: vouchers),
                    const SizedBox(height: 12),
                    Text(
                      "Hiển thị các mã giảm giá còn hiệu lực để bạn áp dụng khi mua hàng.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatPercent(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, "0");
    final month = date.month.toString().padLeft(2, "0");
    final year = date.year.toString();
    return "$day/$month/$year";
  }
}
