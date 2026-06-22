import 'dart:async';

import 'package:b2205946_duonghuuluan_luanvan/core/navigation/app_route_transitions.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/view/login_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/view/register_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/cart_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/chat_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/helmet_designer_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/profile_designs_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/home/view/home_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/order_detail_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/order_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/order_result_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/order_success_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/others/about/presentation/view/about_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/product_catagory_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/product_detail_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/product_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/profile_addresses_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/profile_orders_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/profile_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/profile_reviews_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/profile_vouchers_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    final SharedPreferences storage = di.getIt<SharedPreferences>();

    final router = GoRouter(
      initialLocation: "/",
      redirect: (context, state) {
        final String location = state.matchedLocation;
        final String fullLocation = state.uri.toString();
        final authState = authCubit.state;

        final bool isPaymentFlow =
            location == "/order-result" ||
            location == "/payment-result" ||
            location == "/order-success";

        if (isPaymentFlow) return null;

        if (!authState.isInitialized) {
          return (location == "/splash") ? null : "/splash";
        }

        final bool loggedIn = authState.isAuthenticated;
        final bool isAtAuthPage =
            location == "/login" || location == "/register";

        if (!loggedIn) {
          return isAtAuthPage ? null : "/login";
        }

        if (isAtAuthPage || location == "/splash") {
          return "/";
        }

        if (fullLocation.isNotEmpty && fullLocation != "/" && !isPaymentFlow) {
          unawaited(
            storage.setString("last_route", fullLocation),
          );
        }

        return null;
      },
      routes: [
        GoRoute(
          path: "/login",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: "/register",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const RegisterPage(),
          ),
        ),
        GoRoute(
          path: "/",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: "/splash",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            style: AppRouteTransitionStyle.fade,
            child: Scaffold(
              backgroundColor: AppColors.light.background,
              body: Center(child: AppLogoLoader(size: 96, strokeWidth: 4.5)),
            ),
          ),
        ),
        GoRoute(
          path: "/products/categories",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: ProductCatagoryPage(
              initialKeyword: state.uri.queryParameters["q"] ?? "",
            ),
          ),
        ),
        GoRoute(
          path: "/products/categories/:id",
          pageBuilder: (context, state) {
            final categoryId = int.parse(state.pathParameters["id"]!);
            return AppRouteTransitions.buildPage(
              state: state,
              child: ProductCatagoryPage(
                categoryId: categoryId,
                initialKeyword: state.uri.queryParameters["q"] ?? "",
              ),
            );
          },
        ),
        GoRoute(
          path: "/products",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: ProductPage(
              initialKeyword: state.uri.queryParameters["q"] ?? "",
            ),
          ),
        ),
        GoRoute(
          path: "/products/:id",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: ProductDetailPage(
              productId: int.parse(state.pathParameters["id"]!),
            ),
          ),
        ),
        GoRoute(
          path: "/cart",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const CartPage(),
          ),
        ),
        GoRoute(
          path: "/order",
          pageBuilder: (context, state) {
            final extra = state.extra;
            if (extra is Map) {
              final details =
                  (extra["details"] as List<CartDetail>?) ?? const [];
              final appliedDiscounts =
                  (extra["appliedDiscounts"] as List<Discount>?) ?? const [];
              return AppRouteTransitions.buildPage(
                state: state,
                child: OrderPage(
                  cartDetails: details,
                  appliedDiscounts: appliedDiscounts,
                ),
              );
            }
            final details = (extra as List<CartDetail>?) ?? const [];
            return AppRouteTransitions.buildPage(
              state: state,
              child: OrderPage(cartDetails: details),
            );
          },
        ),
        GoRoute(
          path: "/orders/:orderId",
          pageBuilder: (context, state) {
            final orderId =
                int.tryParse(state.pathParameters["orderId"] ?? "") ?? 0;
            return AppRouteTransitions.buildPage(
              state: state,
              child: OrderDetailPage(orderId: orderId),
            );
          },
        ),
        GoRoute(
          path: "/order-success",
          pageBuilder: (context, state) {
            final extra = state.extra;
            if (extra is Map) {
              final orderId = extra["orderId"] as int? ?? 0;
              return AppRouteTransitions.buildPage(
                state: state,
                child: OrderSuccessPage(orderId: orderId),
              );
            }
            final orderId =
                int.tryParse(state.uri.queryParameters["orderId"] ?? "") ?? 0;
            return AppRouteTransitions.buildPage(
              state: state,
              child: OrderSuccessPage(orderId: orderId),
            );
          },
        ),
        GoRoute(
          path: "/order-result",
          pageBuilder: (context, state) {
            final queryOrderId =
                int.tryParse(state.uri.queryParameters["orderId"] ?? "") ?? 0;
            final queryPaymentUrl =
                state.uri.queryParameters["paymentUrl"] ?? "";
            final queryStatus = state.uri.queryParameters["status"] ?? "";
            final queryValid = state.uri.queryParameters["valid"] ?? "";
            final extra = state.extra;
            if (extra is Map) {
              final orderId = extra["orderId"] as int? ?? 0;
              final paymentUrl = extra["paymentUrl"] as String? ?? "";
              final callbackStatus = extra["status"] as String? ?? queryStatus;
              final callbackValid = extra["valid"] as String? ?? queryValid;
              return AppRouteTransitions.buildPage(
                state: state,
                child: OrderResultPage(
                  orderId: orderId,
                  paymentUrl: paymentUrl,
                  callbackStatus: callbackStatus,
                  callbackValid: callbackValid,
                ),
              );
            }
            return AppRouteTransitions.buildPage(
              state: state,
              child: OrderResultPage(
                orderId: queryOrderId,
                paymentUrl: queryPaymentUrl,
                callbackStatus: queryStatus,
                callbackValid: queryValid,
              ),
            );
          },
        ),

        GoRoute(
          path: "/payment-result",
          redirect: (context, state) {
            final orderId = state.uri.queryParameters["orderId"];
            final status = state.uri.queryParameters["status"];
            final valid = state.uri.queryParameters["valid"];
            final qp = <String>[];
            if (orderId != null) qp.add("orderId=$orderId");
            if (status != null) qp.add("status=$status");
            if (valid != null) qp.add("valid=$valid");
            final tail = qp.isEmpty ? "" : "?${qp.join("&")}";
            return "/order-result$tail";
          },
        ),

        GoRoute(
          path: "/about",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const AboutPage(),
          ),
        ),

        GoRoute(
          path: "/helmet-designer",
          pageBuilder: (context, state) {
            final designId = int.tryParse(
              state.uri.queryParameters["designId"] ?? "",
            );
            final extra = state.extra;
            final payload = extra is Map ? extra : const <Object?, Object?>{};
            final helmetProductId = payload["helmetProductId"];
            final productDetailId = payload["productDetailId"];
            final quantity = payload["quantity"];
            final rawDesignViews = payload["helmetDesignViews"];
            final designViews = rawDesignViews is List
                ? rawDesignViews.whereType<ProductImage>().toList()
                : const <ProductImage>[];

            return AppRouteTransitions.buildPage(
              state: state,
              child: HelmetDesignerPage(
                designId: designId,
                initialHelmetProductId: helmetProductId is int
                    ? helmetProductId
                    : int.tryParse("$helmetProductId"),
                initialProductDetailId: productDetailId is int
                    ? productDetailId
                    : int.tryParse("$productDetailId"),
                initialQuantity: quantity is int
                    ? quantity
                    : int.tryParse("$quantity"),
                initialHelmetName: payload["helmetName"]?.toString(),
                initialHelmetBaseImageUrl: payload["helmetBaseImageUrl"]
                    ?.toString(),
                initialHelmetDesignViews: designViews,
              ),
            );
          },
        ),
        GoRoute(
          path: "/profile/my-designs",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const ProfileDesignsPage(),
          ),
        ),

        GoRoute(
          path: "/profile",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const ProfilePage(),
          ),
        ),
        GoRoute(
          path: "/profile/orders",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: ProfileOrdersPage(
              initialFilter: state.uri.queryParameters["tab"] ?? "all",
            ),
          ),
        ),
        GoRoute(
          path: "/profile/reviews",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const ProfileReviewsPage(),
          ),
        ),
        GoRoute(
          path: "/profile/addresses",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const ProfileAddressesPage(),
          ),
        ),
        GoRoute(
          path: "/profile/vouchers",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const ProfileVouchersPage(),
          ),
        ),
        GoRoute(
          path: "/chat",
          pageBuilder: (context, state) => AppRouteTransitions.buildPage(
            state: state,
            child: const ChatPage(),
          ),
        ),
      ],
    );

    authCubit.stream.listen((_) => router.refresh());

    return router;
  }
}
