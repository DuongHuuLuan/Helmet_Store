import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';
import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final bool isLoading;
  final bool isUpdatingProfile;
  final bool isUploadingAvatar;
  final String? errorMessage;
  final Profile? profile;
  final List<OrderOut> orders;
  final List<Discount> availableDiscounts;

  const ProfileState({
    this.isLoading = false,
    this.isUpdatingProfile = false,
    this.isUploadingAvatar = false,
    this.errorMessage,
    this.profile,
    this.orders = const [],
    this.availableDiscounts = const [],
  });

  int get pendingCount => orders.where((o) => o.normalizedStatus == "pending").length;
  int get shippingCount => orders.where((o) => o.normalizedStatus == "shipping").length;
  int get completedCount => orders.where((o) => o.normalizedStatus == "completed").length;
  int get cancelledCount => orders.where((o) => o.normalizedStatus == "cancelled").length;

  ProfileState copyWith({
    bool? isLoading,
    bool? isUpdatingProfile,
    bool? isUploadingAvatar,
    String? errorMessage,
    Profile? profile,
    List<OrderOut>? orders,
    List<Discount>? availableDiscounts,
    bool clearProfile = false,
    bool clearOrders = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      errorMessage: errorMessage,
      profile: clearProfile ? null : (profile ?? this.profile),
      orders: orders ?? this.orders,
      availableDiscounts: availableDiscounts ?? this.availableDiscounts,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isUpdatingProfile,
    isUploadingAvatar,
    errorMessage,
    profile,
    orders,
    availableDiscounts,
  ];
}
