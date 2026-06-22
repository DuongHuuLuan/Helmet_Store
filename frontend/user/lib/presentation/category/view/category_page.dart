import 'package:b2205946_duonghuuluan_luanvan/presentation/category/cubit/category_cubit.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryCubit>().state;

    if (vm.isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    if (vm.errorMessage != null) {
      return Center(child: Text(vm.errorMessage!));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.builder(
        itemCount: vm.categories.length,
        itemBuilder: (context, index) {
          final c = vm.categories[index];
          return ListTile(title: Text(c.name), onTap: () {});
        },
      ),
    );
  }
}
