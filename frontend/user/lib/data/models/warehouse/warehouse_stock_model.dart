import 'package:json_annotation/json_annotation.dart';

part 'warehouse_stock_model.g.dart';

@JsonSerializable()
class WarehouseStockModel {
  @JsonKey(name: 'product_id')
  final int productId;
  @JsonKey(name: 'color_id')
  final int colorId;
  @JsonKey(name: 'size_id')
  final int sizeId;
  @JsonKey(name: 'total_quantity')
  final int quantity;

  WarehouseStockModel({
    required this.productId,
    required this.colorId,
    required this.sizeId,
    required this.quantity,
  });

  factory WarehouseStockModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseStockModelFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseStockModelToJson(this);
}
