import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/auth_interceptor.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/auth_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/auth_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/local/auth_local_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/auth/auth_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/auth/auth_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/cart_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/cart_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/cart/cart_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/cart/cart_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/category_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/category_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/category/category_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/category/category_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/chat_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/chat_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/chat/chat_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/discount_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/discount_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/discount/discount_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/discount/discount_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/evaluate_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/evaluate_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/evaluate/evaluate_reponsitory_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/evaluate/evaluate_reponsitory.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/helmet_designer_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/helmet_designer_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/helmet_designer/helmet_designer_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/order_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/order_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/order/order_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/product_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/product_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/product/product_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/product/product_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/profile_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/profile_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/profile/profile_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/profile/profile_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/warehouse_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/warehouse_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/repository/warehouse/warehouse_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/warehouse/warehouse_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/check_auth_status_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/get_current_user_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/login_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/logout_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/register_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/add_to_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/get_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/remove_from_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/update_cart_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/category/get_categories_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/category/get_category_by_id_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/add_to_cart_action_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/create_or_get_conversation_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/get_conversations_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/get_messages_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/mark_conversation_read_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/recall_message_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/send_message_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/discount/get_discounts_for_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/create_evaluate_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_evaluate_by_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_evaluate_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_my_evaluates_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_product_evaluates_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/create_share_link_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/generate_ai_sticker_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/get_design_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/get_my_designs_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/get_sticker_catalog_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/order_design_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/save_design_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/transcribe_ai_sticker_voice_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/calculate_fee_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/cancel_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/confirm_delivery_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_delivery_info_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_ghn_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_vnpay_payment_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_delivery_infos_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_districts_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_order_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_order_history_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_payment_methods_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_provinces_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_services_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_wards_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/product/get_product_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/product/get_products_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/profile/get_profile_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/profile/update_profile_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/profile/upload_avatar_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/warehouse/get_total_stock_usecase.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // Core
  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => prefs);
  getIt.registerLazySingleton(() {
    final baseUrl = AppConstants.baseUrl;
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (baseUrl.contains('ngrok-free.app')) {
      headers['ngrok-skip-browser-warning'] = '69420';
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: headers,
      ),
    );
    dio.interceptors.add(AuthInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }
    return dio;
  });

  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<Dio>()));
  getIt.registerLazySingleton<CategoryService>(() => CategoryService(getIt<Dio>()));
  getIt.registerLazySingleton<ProductService>(() => ProductService(getIt<Dio>()));
  getIt.registerLazySingleton<WarehouseService>(() => WarehouseService(getIt<Dio>()));
  getIt.registerLazySingleton<CartService>(() => CartService(getIt<Dio>()));
  getIt.registerLazySingleton<DiscountService>(() => DiscountService(getIt<Dio>()));
  getIt.registerLazySingleton<ChatService>(() => ChatService(getIt<Dio>()));
  getIt.registerLazySingleton<OrderService>(() => OrderService(getIt<Dio>()));
  getIt.registerLazySingleton<ProfileService>(() => ProfileService(getIt<Dio>()));
  getIt.registerLazySingleton<EvaluateService>(() => EvaluateService(getIt<Dio>()));
  getIt.registerLazySingleton<HelmetDesignerService>(() => HelmetDesignerService(getIt<Dio>()));

  // Local DataSources
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(getIt<SharedPreferences>()),
  );

  // Remote DataSources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<AuthService>()),
  );
  getIt.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSource(getIt<CategoryService>()),
  );
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(getIt<ProductService>()),
  );
  getIt.registerLazySingleton<WarehouseRemoteDataSource>(
    () => WarehouseRemoteDataSource(getIt<WarehouseService>()),
  );
  getIt.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSource(getIt<CartService>()),
  );
  getIt.registerLazySingleton<DiscountRemoteDataSource>(
    () => DiscountRemoteDataSource(getIt<DiscountService>()),
  );
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSource(getIt<ChatService>()),
  );
  getIt.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSource(getIt<OrderService>()),
  );
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(getIt<ProfileService>()),
  );
  getIt.registerLazySingleton<EvaluateRemoteDataSource>(
    () => EvaluateRemoteDataSource(getIt<EvaluateService>()),
  );
  getIt.registerLazySingleton<HelmetDesignerRemoteDataSource>(
    () => HelmetDesignerRemoteDataSource(getIt<HelmetDesignerService>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<AuthLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt<CategoryRemoteDataSource>()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt<ProductRemoteDataSource>()),
  );
  getIt.registerLazySingleton<WarehouseRepository>(
    () => WarehouseRepositoryImpl(getIt<WarehouseRemoteDataSource>()),
  );
  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(getIt<CartRemoteDataSource>()),
  );
  getIt.registerLazySingleton<DiscountRepository>(
    () => DiscountRepositoryImpl(getIt<DiscountRemoteDataSource>()),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(getIt<ChatRemoteDataSource>()),
  );
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(getIt<OrderRemoteDataSource>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileRemoteDataSource>()),
  );
  getIt.registerLazySingleton<EvaluateRepository>(
    () => EvaluateRepositoryImpl(getIt<EvaluateRemoteDataSource>()),
  );
  getIt.registerLazySingleton<HelmetDesignerRepository>(
    () => HelmetDesignerRepositoryImpl(getIt<HelmetDesignerRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerFactory<LoginUseCase>(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerFactory<RegisterUseCase>(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerFactory<LogoutUseCase>(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerFactory<CheckAuthStatusUseCase>(() => CheckAuthStatusUseCase(getIt<AuthRepository>()));
  getIt.registerFactory<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(getIt<AuthRepository>()));

  getIt.registerFactory<AddToCartUseCase>(() => AddToCartUseCase(getIt<CartRepository>()));
  getIt.registerFactory<GetCartUseCase>(() => GetCartUseCase(getIt<CartRepository>()));
  getIt.registerFactory<RemoveFromCartUseCase>(() => RemoveFromCartUseCase(getIt<CartRepository>()));
  getIt.registerFactory<UpdateCartDetailUseCase>(() => UpdateCartDetailUseCase(getIt<CartRepository>()));

  getIt.registerFactory<GetCategoriesUseCase>(() => GetCategoriesUseCase(getIt<CategoryRepository>()));
  getIt.registerFactory<GetCategoryByIdUseCase>(() => GetCategoryByIdUseCase(getIt<CategoryRepository>()));

  getIt.registerFactory<AddToCartActionUseCase>(() => AddToCartActionUseCase(getIt<ChatRepository>()));
  getIt.registerFactory<CreateOrGetConversationUseCase>(() => CreateOrGetConversationUseCase(getIt<ChatRepository>()));
  getIt.registerFactory<GetConversationsUseCase>(() => GetConversationsUseCase(getIt<ChatRepository>()));
  getIt.registerFactory<GetMessagesUseCase>(() => GetMessagesUseCase(getIt<ChatRepository>()));
  getIt.registerFactory<MarkConversationReadUseCase>(() => MarkConversationReadUseCase(getIt<ChatRepository>()));
  getIt.registerFactory<RecallMessageUseCase>(() => RecallMessageUseCase(getIt<ChatRepository>()));
  getIt.registerFactory<SendMessageUseCase>(() => SendMessageUseCase(getIt<ChatRepository>()));

  getIt.registerFactory<GetDiscountsForCartUseCase>(() => GetDiscountsForCartUseCase(getIt<DiscountRepository>()));

  getIt.registerFactory<CreateEvaluateUseCase>(() => CreateEvaluateUseCase(getIt<EvaluateRepository>()));
  getIt.registerFactory<GetEvaluateByOrderUseCase>(() => GetEvaluateByOrderUseCase(getIt<EvaluateRepository>()));
  getIt.registerFactory<GetEvaluateDetailUseCase>(() => GetEvaluateDetailUseCase(getIt<EvaluateRepository>()));
  getIt.registerFactory<GetMyEvaluatesUseCase>(() => GetMyEvaluatesUseCase(getIt<EvaluateRepository>()));
  getIt.registerFactory<GetProductEvaluatesUseCase>(() => GetProductEvaluatesUseCase(getIt<EvaluateRepository>()));

  getIt.registerFactory<CreateShareLinkUseCase>(() => CreateShareLinkUseCase(getIt<HelmetDesignerRepository>()));
  getIt.registerFactory<GenerateAiStickerUseCase>(() => GenerateAiStickerUseCase(getIt<HelmetDesignerRepository>()));
  getIt.registerFactory<GetDesignDetailUseCase>(() => GetDesignDetailUseCase(getIt<HelmetDesignerRepository>()));
  getIt.registerFactory<GetMyDesignsUseCase>(() => GetMyDesignsUseCase(getIt<HelmetDesignerRepository>()));
  getIt.registerFactory<GetStickerCatalogUseCase>(() => GetStickerCatalogUseCase(getIt<HelmetDesignerRepository>()));
  getIt.registerFactory<OrderDesignUseCase>(() => OrderDesignUseCase(getIt<HelmetDesignerRepository>()));
  getIt.registerFactory<SaveDesignUseCase>(() => SaveDesignUseCase(getIt<HelmetDesignerRepository>()));
  getIt.registerFactory<TranscribeAiStickerVoiceUseCase>(() => TranscribeAiStickerVoiceUseCase(getIt<HelmetDesignerRepository>()));

  getIt.registerFactory<CalculateFeeUseCase>(() => CalculateFeeUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<CancelOrderUseCase>(() => CancelOrderUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<ConfirmDeliveryUseCase>(() => ConfirmDeliveryUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<CreateDeliveryInfoUseCase>(() => CreateDeliveryInfoUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<CreateGhnOrderUseCase>(() => CreateGhnOrderUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<CreateOrderUseCase>(() => CreateOrderUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<CreateVnpayPaymentUseCase>(() => CreateVnpayPaymentUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetDeliveryInfosUseCase>(() => GetDeliveryInfosUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetDistrictsUseCase>(() => GetDistrictsUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetOrderDetailUseCase>(() => GetOrderDetailUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetOrderHistoryUseCase>(() => GetOrderHistoryUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetPaymentMethodsUseCase>(() => GetPaymentMethodsUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetProvincesUseCase>(() => GetProvincesUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetServicesUseCase>(() => GetServicesUseCase(getIt<OrderRepository>()));
  getIt.registerFactory<GetWardsUseCase>(() => GetWardsUseCase(getIt<OrderRepository>()));

  getIt.registerFactory<GetProductsUseCase>(() => GetProductsUseCase(getIt<ProductRepository>()));
  getIt.registerFactory<GetProductDetailUseCase>(() => GetProductDetailUseCase(getIt<ProductRepository>()));

  getIt.registerFactory<GetProfileUseCase>(() => GetProfileUseCase(getIt<ProfileRepository>()));
  getIt.registerFactory<UpdateProfileUseCase>(() => UpdateProfileUseCase(getIt<ProfileRepository>()));
  getIt.registerFactory<UploadAvatarUseCase>(() => UploadAvatarUseCase(getIt<ProfileRepository>()));

  getIt.registerFactory<GetTotalStockUseCase>(() => GetTotalStockUseCase(getIt<WarehouseRepository>()));

  // Cubits
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      getIt<CheckAuthStatusUseCase>(),
      getIt<GetCurrentUserUseCase>(),
      getIt<LogoutUseCase>(),
    ),
  );
  getIt.registerFactory<LoginCubit>(
    () => LoginCubit(getIt<LoginUseCase>(), getIt<AuthCubit>()),
  );
  getIt.registerFactory<RegisterCubit>(
    () => RegisterCubit(getIt<RegisterUseCase>()),
  );
  getIt.registerFactory<CategoryCubit>(
    () => CategoryCubit(
      getIt<GetCategoriesUseCase>(),
      getIt<GetCategoryByIdUseCase>(),
    ),
  );
  getIt.registerFactory<ProductCubit>(
    () => ProductCubit(
      getIt<GetProductsUseCase>(),
      getIt<GetProductDetailUseCase>(),
      getIt<GetTotalStockUseCase>(),
    ),
  );
  getIt.registerFactory<CartCubit>(
    () => CartCubit(
      getIt<GetCartUseCase>(),
      getIt<AddToCartUseCase>(),
      getIt<UpdateCartDetailUseCase>(),
      getIt<RemoveFromCartUseCase>(),
      getIt<GetProductsUseCase>(),
      getIt<GetDiscountsForCartUseCase>(),
    ),
  );
  getIt.registerLazySingleton<ChatCubit>(
    () => ChatCubit(
      getIt<GetConversationsUseCase>(),
      getIt<CreateOrGetConversationUseCase>(),
      getIt<GetMessagesUseCase>(),
      getIt<SendMessageUseCase>(),
      getIt<RecallMessageUseCase>(),
      getIt<MarkConversationReadUseCase>(),
      getIt<AddToCartActionUseCase>(),
    ),
  );
  getIt.registerFactory<OrderCubit>(
    () => OrderCubit(
      getIt<GetPaymentMethodsUseCase>(),
      getIt<GetDeliveryInfosUseCase>(),
      getIt<GetProvincesUseCase>(),
      getIt<GetDistrictsUseCase>(),
      getIt<GetWardsUseCase>(),
      getIt<GetServicesUseCase>(),
      getIt<CalculateFeeUseCase>(),
      getIt<CreateOrderUseCase>(),
      getIt<CreateDeliveryInfoUseCase>(),
      getIt<CreateGhnOrderUseCase>(),
      getIt<CreateVnpayPaymentUseCase>(),
    ),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      getIt<GetProfileUseCase>(),
      getIt<GetOrderHistoryUseCase>(),
      getIt<ConfirmDeliveryUseCase>(),
      getIt<CancelOrderUseCase>(),
      getIt<UpdateProfileUseCase>(),
      getIt<UploadAvatarUseCase>(),
      getIt<GetCategoriesUseCase>(),
      getIt<GetDiscountsForCartUseCase>(),
    ),
  );
  getIt.registerFactory<EvaluateCubit>(
    () => EvaluateCubit(
      getIt<GetMyEvaluatesUseCase>(),
      getIt<GetEvaluateByOrderUseCase>(),
      getIt<GetEvaluateDetailUseCase>(),
      getIt<CreateEvaluateUseCase>(),
    ),
  );
  getIt.registerFactory<HelmetDesignerCubit>(
    () => HelmetDesignerCubit(
      getIt<GetStickerCatalogUseCase>(),
      getIt<GetDesignDetailUseCase>(),
      getIt<GenerateAiStickerUseCase>(),
      getIt<SaveDesignUseCase>(),
      getIt<CreateShareLinkUseCase>(),
      getIt<TranscribeAiStickerVoiceUseCase>(),
      getIt<OrderDesignUseCase>(),
      getIt<GetProductDetailUseCase>(),
    ),
  );
}
