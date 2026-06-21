import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';
import 'package:equatable/equatable.dart';

class HelmetDesignerState extends Equatable {
  final List<StickerTemplate> stickerCatalog;
  final List<StickerLayer> stickerLayers;
  final List<ProductImage> designViews;
  final HelmetDesign currentDesign;
  final bool isLoadingCatalog;
  final bool isLoadingDesign;
  final bool isTranscribingSticker;
  final bool isGeneratingSticker;
  final bool isSavingDesign;
  final bool isSharingDesign;
  final bool isOrderingDesign;
  final String? errorMessage;
  final String? shareUrl;
  final int? selectedLayerId;
  final int? selectedProductDetailId;
  final int orderQuantity;

  const HelmetDesignerState({
    this.stickerCatalog = const [],
    this.stickerLayers = const [],
    this.designViews = const [],
    required this.currentDesign,
    this.isLoadingCatalog = false,
    this.isLoadingDesign = false,
    this.isTranscribingSticker = false,
    this.isGeneratingSticker = false,
    this.isSavingDesign = false,
    this.isSharingDesign = false,
    this.isOrderingDesign = false,
    this.errorMessage,
    this.shareUrl,
    this.selectedLayerId,
    this.selectedProductDetailId,
    this.orderQuantity = 1,
  });

  bool get hasLayers => stickerLayers.isNotEmpty;
  bool get hasDesignViews => designViews.isNotEmpty;
  bool get hasMultipleDesignViews => designViews.length > 1;
  bool get hasOrderTarget => (selectedProductDetailId ?? 0) > 0 && orderQuantity > 0;

  String get currentPreviewImageUrl {
    return designViews.isNotEmpty
        ? designViews.first.url
        : currentDesign.helmetBaseImageUrl;
  }

  HelmetDesignerState copyWith({
    List<StickerTemplate>? stickerCatalog,
    List<StickerLayer>? stickerLayers,
    List<ProductImage>? designViews,
    HelmetDesign? currentDesign,
    bool? isLoadingCatalog,
    bool? isLoadingDesign,
    bool? isTranscribingSticker,
    bool? isGeneratingSticker,
    bool? isSavingDesign,
    bool? isSharingDesign,
    bool? isOrderingDesign,
    String? errorMessage,
    String? shareUrl,
    int? selectedLayerId,
    int? selectedProductDetailId,
    int? orderQuantity,
    bool clearStickerCatalog = false,
    bool clearStickerLayers = false,
    bool clearDesignViews = false,
    bool clearError = false,
    bool clearShareUrl = false,
    bool clearSelectedLayerId = false,
    bool clearSelectedProductDetailId = false,
  }) {
    return HelmetDesignerState(
      stickerCatalog: clearStickerCatalog ? const [] : (stickerCatalog ?? this.stickerCatalog),
      stickerLayers: clearStickerLayers ? const [] : (stickerLayers ?? this.stickerLayers),
      designViews: clearDesignViews ? const [] : (designViews ?? this.designViews),
      currentDesign: currentDesign ?? this.currentDesign,
      isLoadingCatalog: isLoadingCatalog ?? this.isLoadingCatalog,
      isLoadingDesign: isLoadingDesign ?? this.isLoadingDesign,
      isTranscribingSticker: isTranscribingSticker ?? this.isTranscribingSticker,
      isGeneratingSticker: isGeneratingSticker ?? this.isGeneratingSticker,
      isSavingDesign: isSavingDesign ?? this.isSavingDesign,
      isSharingDesign: isSharingDesign ?? this.isSharingDesign,
      isOrderingDesign: isOrderingDesign ?? this.isOrderingDesign,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      shareUrl: clearShareUrl ? null : (shareUrl ?? this.shareUrl),
      selectedLayerId: clearSelectedLayerId ? null : (selectedLayerId ?? this.selectedLayerId),
      selectedProductDetailId: clearSelectedProductDetailId ? null : (selectedProductDetailId ?? this.selectedProductDetailId),
      orderQuantity: orderQuantity ?? this.orderQuantity,
    );
  }

  @override
  List<Object?> get props => [
    stickerCatalog,
    stickerLayers,
    designViews,
    currentDesign,
    isLoadingCatalog,
    isLoadingDesign,
    isTranscribingSticker,
    isGeneratingSticker,
    isSavingDesign,
    isSharingDesign,
    isOrderingDesign,
    errorMessage,
    shareUrl,
    selectedLayerId,
    selectedProductDetailId,
    orderQuantity,
  ];
}
