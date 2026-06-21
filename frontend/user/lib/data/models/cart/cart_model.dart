import 'package:json_annotation/json_annotation.dart';
import 'cart_detail_model.dart';

part 'cart_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'cart_details')
  final List<CartDetailModel> cartDetails;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  @JsonKey(name: 'can_checkout')
  final bool canCheckout;

  CartModel({
    required this.id,
    required this.userId,
    required this.cartDetails,
    required this.totalPrice,
    required this.canCheckout,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) =>
      _$CartModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartModelToJson(this);
}
