import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_delivery_info_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_delivery_infos_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_districts_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_provinces_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_wards_usecase.dart';
import 'package:flutter/material.dart';

class ProfileAddressesPage extends StatefulWidget {
  const ProfileAddressesPage({super.key});

  @override
  State<ProfileAddressesPage> createState() => _ProfileAddressesPageState();
}

class _ProfileAddressesPageState extends State<ProfileAddressesPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showCreateForm = false;
  String? _errorMessage;

  List<DeliveryInfo> _deliveries = [];
  List<GhnProvince> _provinces = [];
  List<GhnDistrict> _districts = [];
  List<GhnWard> _wards = [];

  GhnProvince? _selectedProvince;
  GhnDistrict? _selectedDistrict;
  GhnWard? _selectedWard;

  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        di.getIt<GetDeliveryInfosUseCase>()(),
        di.getIt<GetProvincesUseCase>()(),
      ]);

      if (!mounted) return;

      setState(() {
        _deliveries = results[0] as List<DeliveryInfo>;
        _provinces = results[1] as List<GhnProvince>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectProvince(GhnProvince? province) async {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = [];
      _wards = [];
      _errorMessage = null;
    });

    if (province == null) return;

    final districtsResult = await di.getIt<GetDistrictsUseCase>()(province.provinceId);
    districtsResult.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _errorMessage = failure.message;
        });
      },
      (districtList) {
        if (!mounted || _selectedProvince?.provinceId != province.provinceId) {
          return;
        }
        setState(() {
          _districts = districtList;
        });
      },
    );
  }

  Future<void> _selectDistrict(GhnDistrict? district) async {
    setState(() {
      _selectedDistrict = district;
      _selectedWard = null;
      _wards = [];
      _errorMessage = null;
    });

    if (district == null) return;

    final wardsResult = await di.getIt<GetWardsUseCase>()(district.districtId);
    wardsResult.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _errorMessage = failure.message;
        });
      },
      (wardList) {
        if (!mounted || _selectedDistrict?.districtId != district.districtId) {
          return;
        }
        setState(() {
          _wards = wardList;
        });
      },
    );
  }

  void _selectWard(GhnWard? ward) {
    setState(() {
      _selectedWard = ward;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ họ tên, số điện thoại và địa chỉ.");
      return;
    }

    if (_selectedDistrict == null || _selectedWard == null) {
      _showMessage("Vui lòng chọn đầy đủ tỉnh/thành, quận/huyện và phường/xã.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final deliveryResult = await di.getIt<CreateDeliveryInfoUseCase>()(
      name: name,
      phone: phone,
      address: address,
      districtId: _selectedDistrict!.districtId,
      wardCode: _selectedWard!.wardCode,
    );
    deliveryResult.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _errorMessage = failure.message;
        });
      },
      (delivery) {
        if (!mounted) return;
        setState(() {
          _deliveries = [
            delivery,
            ..._deliveries.where((item) => item.id != delivery.id),
          ];
          _showCreateForm = false;
        });
        _resetForm();
        _showMessage("Đã tạo địa chỉ giao hàng mới.");
      },
    );
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedProvince = null;
    _selectedDistrict = null;
    _selectedWard = null;
    _districts = [];
    _wards = [];
  }

  void _toggleCreateForm() {
    setState(() {
      _showCreateForm = !_showCreateForm;
      _errorMessage = null;
      if (!_showCreateForm) {
        _resetForm();
      }
    });
  }

  void _showDetails(DeliveryInfo item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Địa chỉ giao hàng",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _AddressDetailRow(label: "Người nhận", value: item.name),
              const SizedBox(height: 12),
              _AddressDetailRow(label: "Số điện thoại", value: item.phone),
              const SizedBox(height: 12),
              _AddressDetailRow(label: "Địa chỉ", value: item.address),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        title: const Text("Địa chỉ giao hàng"),
        actions: [
          IconButton(
            tooltip: "Làm mới",
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _deliveries.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CreateAddressPanel(
                        isExpanded: _showCreateForm,
                        isSubmitting: _isSubmitting,
                        provinces: _provinces,
                        districts: _districts,
                        wards: _wards,
                        selectedProvince: _selectedProvince,
                        selectedDistrict: _selectedDistrict,
                        selectedWard: _selectedWard,
                        nameController: _nameController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        onToggle: _toggleCreateForm,
                        onSubmit: _submit,
                        onProvinceChanged: _selectProvince,
                        onDistrictChanged: _selectDistrict,
                        onWardChanged: _selectWard,
                      ),
                      const SizedBox(height: 12),
                      _AddressBookSection(
                        items: _deliveries,
                        onTap: _showDetails,
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _CreateAddressPanel extends StatelessWidget {
  final bool isExpanded;
  final bool isSubmitting;
  final List<GhnProvince> provinces;
  final List<GhnDistrict> districts;
  final List<GhnWard> wards;
  final GhnProvince? selectedProvince;
  final GhnDistrict? selectedDistrict;
  final GhnWard? selectedWard;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;
  final ValueChanged<GhnProvince?> onProvinceChanged;
  final ValueChanged<GhnDistrict?> onDistrictChanged;
  final ValueChanged<GhnWard?> onWardChanged;

  const _CreateAddressPanel({
    required this.isExpanded,
    required this.isSubmitting,
    required this.provinces,
    required this.districts,
    required this.wards,
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.selectedWard,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.onToggle,
    required this.onSubmit,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onWardChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thêm địa chỉ mới",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tạo nhanh một địa chỉ giao hàng mới cho tài khoản của bạn.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF657184),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    isExpanded ? Icons.close_rounded : Icons.add_rounded,
                  ),
                  label: Text(isExpanded ? "Ẩn form" : "Mở form"),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _TextField(
                controller: nameController,
                label: "Họ tên người nhận",
              ),
              const SizedBox(height: 12),
              _TextField(controller: phoneController, label: "Số điện thoại"),
              const SizedBox(height: 12),
              _TextField(
                controller: addressController,
                label: "Địa chỉ chi tiết",
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _DropdownField<GhnProvince>(
                label: "Tỉnh/Thành",
                value: selectedProvince,
                items: provinces,
                itemLabel: (value) => value.provinceName,
                onChanged: onProvinceChanged,
              ),
              const SizedBox(height: 12),
              _DropdownField<GhnDistrict>(
                label: "Quận/Huyện",
                value: selectedDistrict,
                items: districts,
                itemLabel: (value) => value.districtName,
                onChanged: onDistrictChanged,
              ),
              const SizedBox(height: 12),
              _DropdownField<GhnWard>(
                label: "Phường/Xã",
                value: selectedWard,
                items: wards,
                itemLabel: (value) => value.wardName,
                onChanged: onWardChanged,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Lưu địa chỉ"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddressBookSection extends StatelessWidget {
  final List<DeliveryInfo> items;
  final ValueChanged<DeliveryInfo> onTap;

  const _AddressBookSection({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          "Bạn chưa có địa chỉ giao hàng nào.",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: items
          .map((item) => _AddressCard(item: item, onTap: () => onTap(item)))
          .toList(),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final DeliveryInfo item;
  final VoidCallback onTap;

  const _AddressCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.name} • ${item.phone}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.address,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _AddressDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: const Color(0xFF657184)),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
