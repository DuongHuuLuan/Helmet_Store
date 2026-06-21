import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/cubit/profile_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/category/get_categories_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/discount/get_discounts_for_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/cancel_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/confirm_delivery_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_order_history_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/profile/get_profile_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/profile/update_profile_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/profile/upload_avatar_usecase.dart';
import 'package:bloc/bloc.dart';


class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfile;
  final GetOrderHistoryUseCase _getOrderHistory;
  final ConfirmDeliveryUseCase _confirmDelivery;
  final CancelOrderUseCase _cancelOrder;
  final UpdateProfileUseCase _updateProfile;
  final UploadAvatarUseCase _uploadAvatar;
  final GetCategoriesUseCase _getCategories;
  final GetDiscountsForCartUseCase _getDiscountsForCart;

  ProfileCubit(
    this._getProfile,
    this._getOrderHistory,
    this._confirmDelivery,
    this._cancelOrder,
    this._updateProfile,
    this._uploadAvatar,
    this._getCategories,
    this._getDiscountsForCart,
  ) : super(const ProfileState());

  final Set<int> _confirmingOrderIds = {};
  final Set<int> _cancellingOrderIds = {};

  Set<int> get confirmingOrderIds => Set.unmodifiable(_confirmingOrderIds);
  Set<int> get cancellingOrderIds => Set.unmodifiable(_cancellingOrderIds);

  Future<void> load() async {
    if (state.isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final profileResult = await _getProfile();
    await profileResult.fold(
      (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (profile) async {
        final ordersResult = await _getOrderHistory();
        await ordersResult.fold(
          (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
          (orders) async {
            final discounts = await _loadAvailableDiscounts();
            emit(state.copyWith(isLoading: false, profile: profile, orders: orders, availableDiscounts: discounts));
          },
        );
      },
    );
  }

  Future<void> confirmOrderReceived(int orderId) async {
    if (_confirmingOrderIds.contains(orderId)) return;
    _confirmingOrderIds.add(orderId);
    emit(state.copyWith());
    final result = await _confirmDelivery(orderId);
    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message));
        _confirmingOrderIds.remove(orderId);
        emit(state.copyWith());
        throw failure;
      },
      (updatedOrder) async {
        final orders = [...state.orders];
        final index = orders.indexWhere((o) => o.id == orderId);
        if (index >= 0) {
          orders[index] = updatedOrder;
          emit(state.copyWith(orders: orders));
        } else {
          final ordersResult = await _getOrderHistory();
          await ordersResult.fold(
            (failure) async => emit(state.copyWith(errorMessage: failure.message)),
            (newOrders) async => emit(state.copyWith(orders: newOrders)),
          );
        }
        _confirmingOrderIds.remove(orderId);
        emit(state.copyWith());
      },
    );
  }

  Future<void> cancelOrder(int orderId) async {
    if (_cancellingOrderIds.contains(orderId)) return;
    _cancellingOrderIds.add(orderId);
    emit(state.copyWith());
    final cancelResult = await _cancelOrder(orderId);
    await cancelResult.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message));
        _cancellingOrderIds.remove(orderId);
        emit(state.copyWith());
        throw failure;
      },
      (_) async {
        final ordersResult = await _getOrderHistory();
        await ordersResult.fold(
          (failure) async => emit(state.copyWith(errorMessage: failure.message)),
          (orders) async => emit(state.copyWith(orders: orders)),
        );
        _cancellingOrderIds.remove(orderId);
        emit(state.copyWith());
      },
    );
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String gender,
    required DateTime? birthday,
    required String avatar,
  }) async {
    if (state.isUpdatingProfile) return;
    emit(state.copyWith(isUpdatingProfile: true, errorMessage: null));
    final payload = <String, dynamic>{
      "name": _normalizeOptionalText(name),
      "phone": _normalizeOptionalText(phone),
      "gender": _normalizeGender(gender),
      "birthday": birthday == null ? null : _formatBirthdayForApi(birthday),
      "avatar": _normalizeOptionalText(avatar),
    };
    final result = await _updateProfile(payload);
    result.fold(
      (failure) {
        emit(state.copyWith(isUpdatingProfile: false, errorMessage: failure.message));
        throw failure;
      },
      (profile) => emit(state.copyWith(isUpdatingProfile: false, profile: profile)),
    );
  }

  Future<void> uploadAvatar({required String filePath, String? fileName}) async {
    if (state.isUploadingAvatar) return;
    emit(state.copyWith(isUploadingAvatar: true, errorMessage: null));
    final result = await _uploadAvatar(filePath: filePath, fileName: fileName);
    result.fold(
      (failure) {
        emit(state.copyWith(isUploadingAvatar: false, errorMessage: failure.message));
        throw failure;
      },
      (profile) => emit(state.copyWith(isUploadingAvatar: false, profile: profile)),
    );
  }

  Future<List<Discount>> _loadAvailableDiscounts() async {
    final catResult = await _getCategories();
    return catResult.fold(
      (_) async => const <Discount>[],
      (categories) async {
        final categoryIds = categories.map((c) => c.id).toSet().toList();
        if (categoryIds.isEmpty) return const <Discount>[];
        final discResult = await _getDiscountsForCart(categoryIds: categoryIds);
        return discResult.fold(
          (_) async => const <Discount>[],
          (discounts) {
            final uniqueById = <int, Discount>{};
            for (final d in discounts) {
              uniqueById[d.id] = d;
            }
            final result = uniqueById.values.toList()..sort((a, b) => a.endAt.compareTo(b.endAt));
            return result;
          },
        );
      },
    );
  }

  List<OrderOut> ordersByStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return state.orders.where((o) => o.normalizedStatus == normalized).toList();
  }

  String? _normalizeOptionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _normalizeGender(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == "male" || normalized == "female" || normalized == "other") return normalized;
    return null;
  }

  String _formatBirthdayForApi(DateTime birthday) {
    final date = birthday.toLocal();
    return "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}";
  }
}
