import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/login_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/register_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/category/cubit/category_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/cubit/chat_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/cubit/evaluate_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/cubit/helmet_designer_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/cubit/order_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/cubit/product_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/cubit/profile_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

import 'injection_container.dart' as di;

final List<SingleChildWidget> Providers = [
  BlocProvider(create: (_) => di.getIt<AuthCubit>()),
  BlocProvider(create: (_) => di.getIt<LoginCubit>()),
  BlocProvider(create: (_) => di.getIt<RegisterCubit>()),
  BlocProvider(create: (_) => di.getIt<CategoryCubit>()),
  BlocProvider(create: (_) => di.getIt<ProductCubit>()),
  BlocProvider(create: (_) => di.getIt<CartCubit>()),
  BlocProvider(create: (_) => di.getIt<OrderCubit>()),
  BlocProvider(create: (_) => di.getIt<ProfileCubit>()),
  BlocProvider(create: (_) => di.getIt<ChatCubit>()),
  BlocProvider(create: (_) => di.getIt<EvaluateCubit>()),
  BlocProvider(create: (_) => di.getIt<HelmetDesignerCubit>()),
];
