import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/get_my_designs_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileDesignsPage extends StatefulWidget {
  const ProfileDesignsPage({super.key});

  @override
  State<ProfileDesignsPage> createState() => _ProfileDesignsPageState();
}

class _ProfileDesignsPageState extends State<ProfileDesignsPage> {
  List<HelmetDesign>? _designs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDesigns();
  }

  Future<void> _loadDesigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await di.getIt<GetMyDesignsUseCase>()();
    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = failure.message;
        });
      },
      (designs) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _designs = designs;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        title: const Text("Thiết kế của tôi"),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/");
            }
          },
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Lỗi: $_error"))
              : _designs == null || _designs!.isEmpty
                  ? const Center(child: Text("Chưa có thiết kế nào"))
                  : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.75,
            ),
            itemCount: _designs!.length,
            itemBuilder: (context, index) {
              final design = _designs![index];

              return _DesignCard(
                design: design,
                onTap: () {
                  context.push("/helmet-designer?designId=${design.id}");
                },
              );
            },
          ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final HelmetDesign design;
  final VoidCallback onTap;

  const _DesignCard({required this.design, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  design.helmetBaseImageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.helmetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ngày lưu: ${design.createdAt}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
