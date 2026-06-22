import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/register_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final vm = context.read<RegisterCubit>();

      final success = await vm.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng ký thành công. Hãy đăng nhập.")),
          );
          context.go("/login");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vm.state.errorMessage ?? "Đăng ký thất bại"),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterCubit>().state;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "TẠO TÀI KHOẢN",
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Email",
                              floatingLabelStyle: TextStyle(
                                color: colorScheme.secondary,
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: colorScheme.primary,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Vui lòng nhập email";
                              }
                              if (!value.contains("@")) {
                                return "Email không hợp lệ";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: "Tên người dùng",
                              floatingLabelStyle: TextStyle(
                                color: colorScheme.secondary,
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: colorScheme.primary,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Vui lòng nhập tên người dùng";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: "Mật khẩu",
                              floatingLabelStyle: TextStyle(
                                color: colorScheme.secondary,
                              ),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: _isObscured,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Vui lòng nhập mật khẩu";
                              }
                              if (value.length < 6) {
                                return "Mật khẩu phải từ 6 ký tự";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: "Xác nhận mật khẩu",
                              floatingLabelStyle: TextStyle(
                                color: colorScheme.secondary,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_reset,
                                color: colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: _isObscured,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Vui lòng nhập lại mật khẩu";
                              }
                              if (value != _passwordController.text) {
                                return "Mật khẩu không khớp";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          if (vm.isLoading)
                            AppLogoLoader(size: 36, strokeWidth: 2.5)
                          else
                            ElevatedButton(
                              onPressed: _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onPrimary,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "ĐĂNG KÝ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => context.go("/login"),
                            child: Text(
                              "Đã có tài khoản? Đăng nhập",
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
