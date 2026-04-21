import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_designer_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_repository.dart';

class HelmetDesignerViewModel extends ChangeNotifier {
  final HelmetDesignerRepository _repository;
  final ProductRepository _productRepository;

  HelmetDesignerViewModel(this._repository, this._productRepository);

  final List<StickerTemplate> _stickerCatalog = [];
  final List<StickerLayer> _stickerLayers = [];
  final List<ProductImage> _designViews = [];

  HelmetDesign _currentDesign = HelmetDesign(
    id: 0,
    helmetProductId: 0,
    productDetailId: null,
    helmetName: "",
    helmetBaseImageUrl: "",
    stickers: const [],
    isShared: false,
  );

  bool isLoadingCatalog = false;
  bool isLoadingDesign = false;
  bool isTranscribingSticker = false;
  bool isGeneratingSticker = false;
  bool isSavingDesign = false;
  bool isSharingDesign = false;
  bool isOrderingDesign = false;
  String? errorMessage;
  String? shareUrl;
  int? selectedLayerId;
  String? _activeViewImageKey;
  int _nextLayerId = 1;
  int? _selectedProductDetailId;
  int _orderQuantity = 1;

  List<StickerTemplate> get stickerCatalog =>
      List.unmodifiable(_stickerCatalog);
  List<StickerLayer> get stickerLayers => List.unmodifiable(_sortedLayers());
  List<ProductImage> get designViews => List.unmodifiable(_designViews);
  List<StickerLayer> get visibleStickerLayers {
    final layers = _sortedLayers();
    if (_designViews.isEmpty) return layers;
    final activeKey = (_activeViewImageKey ?? '').trim();
    return layers
        .where((layer) => (layer.viewImageKey ?? '').trim() == activeKey)
        .toList();
  }

  HelmetDesign get currentDesign => _currentDesign;
  StickerLayer? get selectedLayer => _findLayerById(selectedLayerId);
  ProductImage? get activeDesignView {
    final activeKey = (_activeViewImageKey ?? '').trim();
    for (final item in _designViews) {
      if ((item.viewImageKey ?? '').trim() == activeKey) {
        return item;
      }
    }
    return _designViews.isNotEmpty ? _designViews.first : null;
  }

  bool get hasLayers => _stickerLayers.isNotEmpty;
  bool get hasDesignViews => _designViews.isNotEmpty;
  bool get hasMultipleDesignViews => _designViews.length > 1;
  int? get selectedProductDetailId => _selectedProductDetailId;
  int get orderQuantity => _orderQuantity;
  String? get activeViewImageKey => _activeViewImageKey;
  String get currentPreviewImageUrl =>
      activeDesignView?.url ?? _currentDesign.helmetBaseImageUrl;
  bool get hasOrderTarget =>
      (_selectedProductDetailId ?? 0) > 0 && _orderQuantity > 0;

  Future<void> loadStickerCatalog() async {
    if (isLoadingCatalog) return;
    isLoadingCatalog = true;
    errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.getStickerCatalog();
      _stickerCatalog
        ..clear()
        ..addAll(items);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoadingCatalog = false;
      notifyListeners();
    }
  }

  void startNewDesign({
    required int helmetProductId,
    required String helmetName,
    required String helmetBaseImageUrl,
    List<ProductImage> designViews = const [],
    int? productDetailId,
    int orderQuantity = 1,
  }) {
    _designViews
      ..clear()
      ..addAll(_sortedDesignViews(designViews));
    _activeViewImageKey = _resolveInitialViewImageKey(
      fallbackImageUrl: helmetBaseImageUrl,
    );
    _currentDesign = HelmetDesign(
      id: 0,
      helmetProductId: helmetProductId,
      productDetailId: productDetailId,
      helmetName: helmetName,
      helmetBaseImageUrl: _resolvePreviewImageUrl(
        fallbackImageUrl: helmetBaseImageUrl,
      ),
      stickers: const [],
      isShared: false,
    );
    _stickerLayers.clear();
    selectedLayerId = null;
    shareUrl = null;
    errorMessage = null;
    _nextLayerId = 1;
    _selectedProductDetailId = productDetailId != null && productDetailId > 0
        ? productDetailId
        : null;
    _orderQuantity = orderQuantity < 1 ? 1 : orderQuantity;
    notifyListeners();
  }

  void setOrderTarget({
    int? productDetailId,
    int quantity = 1,
    bool notify = true,
  }) {
    _selectedProductDetailId = productDetailId != null && productDetailId > 0
        ? productDetailId
        : null;
    _orderQuantity = quantity < 1 ? 1 : quantity;
    _syncCurrentDesign();
    if (notify) {
      notifyListeners();
    }
  }

  void updateHelmetInfo({
    int? helmetProductId,
    String? helmetName,
    String? helmetBaseImageUrl,
  }) {
    _currentDesign = _currentDesign.copyWith(
      helmetProductId: helmetProductId,
      helmetName: helmetName,
      helmetBaseImageUrl: helmetBaseImageUrl ?? _resolvePreviewImageUrl(),
      stickers: _sortedLayers(),
    );
    notifyListeners();
  }

  Future<void> loadDesign(int designId) async {
    if (isLoadingDesign) return;
    isLoadingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      final design = await _repository.getDesignDetail(designId);
      _currentDesign = await _restoreDesignContext(design);
      _selectedProductDetailId = (_currentDesign.productDetailId ?? 0) > 0
          ? _currentDesign.productDetailId
          : null;
      _stickerLayers
        ..clear()
        ..addAll(design.stickers);
      _normalizeLayerOrder(notify: false);
      selectedLayerId = _resolveInitialSelectedLayerId();
      shareUrl = null;
      _reseedNextLayerId();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoadingDesign = false;
      notifyListeners();
    }
  }

  Future<StickerTemplate?> generateAiSticker(
    AiStickerRequest request, {
    bool addToCanvas = true,
  }) async {
    if (isGeneratingSticker) return null;
    isGeneratingSticker = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sticker = await _repository.generateAiSticker(request);
      _upsertStickerTemplate(sticker);
      if (addToCanvas) {
        addStickerFromTemplate(sticker);
      } else {
        notifyListeners();
      }
      return sticker;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isGeneratingSticker = false;
      notifyListeners();
    }
  }

  Future<String?> transcribeAiStickerVoice(String audioPath) async {
    if (isTranscribingSticker) return null;
    isTranscribingSticker = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await _repository.transcribeAiStickerVoice(audioPath);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isTranscribingSticker = false;
      notifyListeners();
    }
  }

  void addStickerFromTemplate(
    StickerTemplate template, {
    double x = 0.5,
    double y = 0.5,
    double scale = 0.65,
    double rotation = 0,
  }) {
    final layer = StickerLayer(
      id: _nextLayerId++,
      stickerId: template.id,
      imageUrl: template.imageUrl,
      x: _unitValue(x),
      y: _unitValue(y),
      scale: _scaleValue(scale),
      rotation: rotation,
      zIndex: _stickerLayers.length,
      viewImageKey: _designViews.isEmpty ? null : _activeViewImageKey,
      crop: StickerCrop(),
    );

    _stickerLayers.add(layer);
    _normalizeLayerOrder(notify: false);
    selectedLayerId = layer.id;
    _syncCurrentDesign();
    notifyListeners();
  }

  void selectLayer(int? layerId) {
    if (layerId == null) {
      selectedLayerId = null;
      notifyListeners();
      return;
    }
    final layer = _findLayerById(layerId);
    if (layer == null) return;
    if (_designViews.isNotEmpty) {
      final nextViewKey = (layer.viewImageKey ?? '').trim();
      if (nextViewKey.isNotEmpty && nextViewKey != _activeViewImageKey) {
        _setActiveViewImageKey(nextViewKey, notify: false);
      }
    }
    selectedLayerId = layerId;
    notifyListeners();
  }

  void selectDesignView(String? viewImageKey) {
    if (_designViews.isEmpty) return;
    _setActiveViewImageKey(viewImageKey);
  }

  void updateSelectedLayerPosition({required double x, required double y}) {
    _updateSelectedLayer(x: x, y: y);
  }

  void updateSelectedLayerTransform({
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    _updateSelectedLayer(x: x, y: y, scale: scale, rotation: rotation);
  }

  void rotateSelectedLayerBy(double delta) {
    final layer = selectedLayer;
    if (layer == null) return;
    _updateSelectedLayer(rotation: layer.rotation + delta);
  }

  void resizeSelectedLayerBy(double factor) {
    final layer = selectedLayer;
    if (layer == null) return;
    _updateSelectedLayer(scale: layer.scale * factor);
  }

  void updateSelectedLayerTint(int? tintColorValue) {
    _updateSelectedLayer(
      tintColorValue: tintColorValue,
      clearTintColor: tintColorValue == null,
    );
  }

  void updateSelectedLayerCrop(StickerCrop crop) {
    final normalized = StickerCrop(
      left: _unitValue(crop.left),
      top: _unitValue(crop.top),
      right: _unitValue(crop.right),
      bottom: _unitValue(crop.bottom),
    );
    _updateSelectedLayer(crop: normalized);
  }

  void bringSelectedLayerForward() {
    _moveSelectedLayerBy(1);
  }

  void sendSelectedLayerBackward() {
    _moveSelectedLayerBy(-1);
  }

  void bringSelectedLayerToFront() {
    _moveSelectedLayerTo(_sortedLayers().length - 1);
  }

  void sendSelectedLayerToBack() {
    _moveSelectedLayerTo(0);
  }

  void removeSelectedLayer() {
    final layerId = selectedLayerId;
    if (layerId == null) return;

    _stickerLayers.removeWhere((layer) => layer.id == layerId);
    _normalizeLayerOrder(notify: false);
    selectedLayerId = _stickerLayers.isNotEmpty
        ? _sortedLayers().last.id
        : null;
    _syncCurrentDesign();
    notifyListeners();
  }

  Future<HelmetDesign?> saveCurrentDesign() async {
    if (isSavingDesign) return null;
    isSavingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      final localLayers = _sortedLayers();
      final localDesignViews = List<ProductImage>.from(_designViews);
      final localActiveViewImageKey = _activeViewImageKey;
      final saved = await _repository.saveDesign(_buildCurrentDesign());
      _designViews
        ..clear()
        ..addAll(localDesignViews);
      _activeViewImageKey = localActiveViewImageKey;
      _currentDesign = saved.copyWith(
        helmetBaseImageUrl: _resolvePreviewImageUrl(
          fallbackImageUrl: saved.helmetBaseImageUrl,
        ),
      );
      _stickerLayers
        ..clear()
        ..addAll(_mergeSavedLayers(saved.stickers, localLayers));
      _normalizeLayerOrder(notify: false);
      _reseedNextLayerId();
      return saved;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isSavingDesign = false;
      notifyListeners();
    }
  }

  Future<String?> shareCurrentDesign() async {
    if (isSharingDesign) return shareUrl;
    isSharingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (_currentDesign.id <= 0) {
        final saved = await saveCurrentDesign();
        if (saved == null) return null;
      }
      final url = await _repository.createShareLink(_currentDesign.id);
      shareUrl = url;
      _currentDesign = _currentDesign.copyWith(isShared: true);
      return url;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isSharingDesign = false;
      notifyListeners();
    }
  }

  Future<bool> orderCurrentDesign() async {
    if (isOrderingDesign) return false;
    if (!hasOrderTarget) {
      errorMessage = "Chưa có biến thể sản phẩm để đặt mua thiết kế này.";
      notifyListeners();
      return false;
    }
    isOrderingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (_currentDesign.id <= 0) {
        final saved = await saveCurrentDesign();
        if (saved == null) return false;
      }
      await _repository.orderDesign(
        _currentDesign.id,
        productDetailId: _selectedProductDetailId!,
        quantity: _orderQuantity,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isOrderingDesign = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  List<ProductImage> _sortedDesignViews(List<ProductImage> items) {
    final views = List<ProductImage>.from(items);
    views.sort((left, right) {
      final priority = viewImageKeyPriority(
        left.viewImageKey,
      ).compareTo(viewImageKeyPriority(right.viewImageKey));
      if (priority != 0) return priority;
      return left.id.compareTo(right.id);
    });
    return views;
  }

  String? _resolveInitialViewImageKey({String? fallbackImageUrl}) {
    if (_designViews.isEmpty) return null;
    for (final item in _designViews) {
      if ((item.viewImageKey ?? '').trim() == 'front') {
        return item.viewImageKey?.trim();
      }
    }
    final fallback = (fallbackImageUrl ?? '').trim();
    if (fallback.isNotEmpty) {
      for (final item in _designViews) {
        if (item.url.trim() == fallback) {
          return item.viewImageKey?.trim();
        }
      }
    }
    return _designViews.first.viewImageKey?.trim();
  }

  String? _resolveLoadedViewImageKey({
    required List<StickerLayer> stickers,
    String? fallbackImageUrl,
  }) {
    final byImage = _resolveInitialViewImageKey(
      fallbackImageUrl: fallbackImageUrl,
    );
    if ((byImage ?? '').isNotEmpty) return byImage;

    for (final sticker in stickers) {
      final key = (sticker.viewImageKey ?? '').trim();
      if (key.isEmpty) continue;
      final exists = _designViews.any(
        (item) => (item.viewImageKey ?? '').trim() == key,
      );
      if (exists) return key;
    }
    return null;
  }

  String _resolvePreviewImageUrl({String? fallbackImageUrl}) {
    return activeDesignView?.url ??
        fallbackImageUrl ??
        _currentDesign.helmetBaseImageUrl;
  }

  Future<HelmetDesign> _restoreDesignContext(HelmetDesign design) async {
    _designViews.clear();
    _activeViewImageKey = null;

    final productId = design.helmetProductId;
    if (productId <= 0) {
      return design;
    }

    try {
      final product = await _productRepository.productDetail(productId);
      final resolvedViews = product.resolveDesignViewsForBaseImage(
        design.helmetBaseImageUrl,
      );
      if (resolvedViews.isNotEmpty) {
        _designViews.addAll(_sortedDesignViews(resolvedViews));
      }

      final currentBaseImageUrl =
          product.resolveCurrentImageUrl(design.helmetBaseImageUrl) ??
          design.helmetBaseImageUrl;

      _activeViewImageKey = _resolveLoadedViewImageKey(
        stickers: design.stickers,
        fallbackImageUrl: currentBaseImageUrl,
      );

      final resolvedImageUrl = currentBaseImageUrl.isNotEmpty
          ? currentBaseImageUrl
          : activeDesignView?.url ??
                product.pickPrimaryImageUrl() ??
                design.helmetBaseImageUrl;

      return design.copyWith(
        helmetName: design.helmetName.isNotEmpty
            ? design.helmetName
            : product.name,
        helmetBaseImageUrl: resolvedImageUrl,
      );
    } catch (_) {
      _activeViewImageKey = _resolveLoadedViewImageKey(
        stickers: design.stickers,
        fallbackImageUrl: design.helmetBaseImageUrl,
      );
      return design;
    }
  }

  void _setActiveViewImageKey(String? viewImageKey, {bool notify = true}) {
    if (_designViews.isEmpty) return;
    final normalized = (viewImageKey ?? '').trim();
    final matched = _designViews.where(
      (item) => (item.viewImageKey ?? '').trim() == normalized,
    );
    final nextView = matched.isNotEmpty ? matched.first : _designViews.first;
    _activeViewImageKey = (nextView.viewImageKey ?? '').trim();
    if (selectedLayer != null &&
        (selectedLayer!.viewImageKey ?? '').trim() != _activeViewImageKey) {
      selectedLayerId = null;
    }
    _syncCurrentDesign();
    if (notify) {
      notifyListeners();
    }
  }

  List<StickerLayer> _mergeSavedLayers(
    List<StickerLayer> savedLayers,
    List<StickerLayer> localLayers,
  ) {
    final merged = <StickerLayer>[];
    for (var index = 0; index < savedLayers.length; index++) {
      final localLayer = index < localLayers.length ? localLayers[index] : null;
      merged.add(
        savedLayers[index].copyWith(
          viewImageKey: localLayer?.viewImageKey,
          clearViewImageKey: localLayer == null,
        ),
      );
    }
    return merged;
  }

  int? _resolveInitialSelectedLayerId() {
    final visible = visibleStickerLayers;
    if (visible.isNotEmpty) {
      return visible.last.id;
    }
    final ordered = _sortedLayers();
    if (ordered.isNotEmpty) {
      return ordered.last.id;
    }
    return null;
  }

  void _updateSelectedLayer({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? tintColorValue,
    bool clearTintColor = false,
    StickerCrop? crop,
  }) {
    final layerId = selectedLayerId;
    if (layerId == null) return;

    final index = _stickerLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) return;

    _stickerLayers[index] = _stickerLayers[index].copyWith(
      x: x == null ? null : _unitValue(x),
      y: y == null ? null : _unitValue(y),
      scale: scale == null ? null : _scaleValue(scale),
      rotation: rotation,
      tintColorValue: tintColorValue,
      clearTintColor: clearTintColor,
      crop: crop,
    );
    _syncCurrentDesign();
    notifyListeners();
  }

  void _moveSelectedLayerBy(int delta) {
    final ordered = _sortedLayers();
    final layerId = selectedLayerId;
    if (layerId == null || ordered.isEmpty) return;

    final currentIndex = ordered.indexWhere((layer) => layer.id == layerId);
    if (currentIndex < 0) return;

    _moveSelectedLayerTo(currentIndex + delta);
  }

  void _moveSelectedLayerTo(int targetIndex) {
    final ordered = _sortedLayers();
    final layerId = selectedLayerId;
    if (layerId == null || ordered.isEmpty) return;

    final currentIndex = ordered.indexWhere((layer) => layer.id == layerId);
    if (currentIndex < 0) return;

    final layer = ordered.removeAt(currentIndex);
    final safeIndex = targetIndex.clamp(0, ordered.length).toInt();
    ordered.insert(safeIndex, layer);

    _stickerLayers
      ..clear()
      ..addAll([
        for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(zIndex: i),
      ]);
    _syncCurrentDesign();
    notifyListeners();
  }

  void _normalizeLayerOrder({bool notify = true}) {
    final ordered = _sortedLayers();
    _stickerLayers
      ..clear()
      ..addAll([
        for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(zIndex: i),
      ]);
    _syncCurrentDesign();
    if (notify) {
      notifyListeners();
    }
  }

  void _syncCurrentDesign() {
    _currentDesign = _currentDesign.copyWith(
      helmetBaseImageUrl: _resolvePreviewImageUrl(),
      productDetailId: _selectedProductDetailId,
      clearProductDetailId: _selectedProductDetailId == null,
      stickers: _sortedLayers(),
    );
  }

  void _reseedNextLayerId() {
    var maxId = 0;
    for (final layer in _stickerLayers) {
      if (layer.id > maxId) {
        maxId = layer.id;
      }
    }
    _nextLayerId = maxId + 1;
  }

  void _upsertStickerTemplate(StickerTemplate template) {
    final index = _stickerCatalog.indexWhere((item) => item.id == template.id);
    if (index >= 0) {
      _stickerCatalog[index] = template;
      return;
    }
    _stickerCatalog.insert(0, template);
  }

  List<StickerLayer> _sortedLayers() {
    final items = List<StickerLayer>.from(_stickerLayers);
    items.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return items;
  }

  StickerLayer? _findLayerById(int? id) {
    if (id == null) return null;
    for (final layer in _stickerLayers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  HelmetDesign _buildCurrentDesign() {
    return _currentDesign.copyWith(stickers: _sortedLayers());
  }

  double _unitValue(double value) {
    return value.clamp(0.0, 1.0).toDouble();
  }

  double _scaleValue(double value) {
    return value.clamp(0.1, 4.0).toDouble();
  }
}
