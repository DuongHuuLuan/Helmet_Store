import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';

String _imageReference(String? url) {
  final text = (url ?? "").trim();
  if (text.isEmpty) return "";
  final uri = Uri.tryParse(text);
  final path = uri?.path.trim().toLowerCase() ?? "";
  return path.isNotEmpty ? path : text.toLowerCase();
}

int _imagePriority(ProductImage image) {
  final key = (image.viewImageKey ?? "").trim();
  if (key == "front_left") return 0;
  if (key.isEmpty) return 1;
  return 2 + viewImageKeyPriority(key);
}

List<ProductImage> _orderedImages(Iterable<ProductImage> source) {
  final items = source.toList();
  items.sort((left, right) {
    final priority = _imagePriority(left).compareTo(_imagePriority(right));
    if (priority != 0) return priority;
    return left.id.compareTo(right.id);
  });
  return items;
}

String _viewIdentity(ProductImage image) {
  final key = (image.viewImageKey ?? "").trim().toLowerCase();
  if (key.isNotEmpty) return "view:$key";
  final ref = _imageReference(image.url);
  if (ref.isNotEmpty) return "url:$ref";
  return "id:${image.id}";
}

int _sizePriority(String size) {
  switch (size.trim().toUpperCase()) {
    case "M":
      return 0;
    case "L":
      return 1;
    case "XL":
      return 2;
    default:
      return 999;
  }
}

extension ProductX on Product {
  List<ProductImage> _imagesForColor(int? colorId) {
    final byColor = images
        .where((element) => element.colorId == colorId)
        .toList();
    if (byColor.isNotEmpty) return byColor;

    final commons = images.where((element) => element.colorId == null).toList();
    if (commons.isNotEmpty) return commons;

    return images;
  }

  int _colorViewCoverage(int colorId) {
    final identities = <String>{};

    for (final image in images) {
      if (image.colorId == colorId) {
        identities.add(_viewIdentity(image));
      }
    }

    for (final image in designViews) {
      if (image.colorId == colorId) {
        identities.add(_viewIdentity(image));
      }
    }

    return identities.length;
  }

  List<ProductDetail> get uniqueColors {
    final seen = <int>{};
    final indexedColors = <({int index, ProductDetail detail})>[];

    for (var index = 0; index < productDetails.length; index++) {
      final detail = productDetails[index];
      if (seen.add(detail.colorId)) {
        indexedColors.add((index: index, detail: detail));
      }
    }

    final coverageByColor = <int, int>{
      for (final entry in indexedColors)
        entry.detail.colorId: _colorViewCoverage(entry.detail.colorId),
    };

    indexedColors.sort((left, right) {
      final coverage = (coverageByColor[right.detail.colorId] ?? 0).compareTo(
        coverageByColor[left.detail.colorId] ?? 0,
      );
      if (coverage != 0) return coverage;
      return left.index.compareTo(right.index);
    });

    return indexedColors.map((entry) => entry.detail).toList();
  }

  List<ProductDetail> getUniqueSizesByColor(int? colorId) {
    if (productDetails.isEmpty) return [];

    final cId = colorId ?? uniqueColors.first.colorId;
    final seen = <int>{};
    final indexedSizes = <({int index, ProductDetail detail})>[];

    for (var index = 0; index < productDetails.length; index++) {
      final detail = productDetails[index];
      if (detail.colorId == cId && seen.add(detail.sizeId)) {
        indexedSizes.add((index: index, detail: detail));
      }
    }

    indexedSizes.sort((left, right) {
      final priority = _sizePriority(
        left.detail.size,
      ).compareTo(_sizePriority(right.detail.size));
      if (priority != 0) return priority;
      return left.index.compareTo(right.index);
    });

    return indexedSizes.map((entry) => entry.detail).toList();
  }

  ProductDetail? findProductDetail(int? colorId, int? sizeId) {
    final vs = productDetails.cast<ProductDetail>();
    if (vs.isEmpty) return null;

    final cId = colorId ?? uniqueColors.first.colorId;
    final sId = sizeId ?? vs.first.sizeId;

    final exact = vs.where((e) => e.colorId == cId && e.sizeId == sId);
    if (exact.isNotEmpty) return exact.first;

    final byColor = vs.where((e) => e.colorId == cId);
    if (byColor.isNotEmpty) return byColor.first;

    return vs.first;
  }

  List<ProductImage> galleryImagesForColor([int? colorId]) {
    return _orderedImages(_imagesForColor(colorId));
  }

  ProductImage? pickPrimaryImage([int? colorId]) {
    final filtered = galleryImagesForColor(colorId);
    if (filtered.isNotEmpty) return filtered.first;
    return null;
  }

  String? pickPrimaryImageUrl([int? colorId]) {
    return pickPrimaryImage(colorId)?.url;
  }

  List<ProductImage> filterDesignViews(int? colorId) {
    final byColor = designViews
        .where((element) => element.colorId == colorId)
        .toList();
    final source = byColor.isNotEmpty
        ? byColor
        : designViews.where((element) => element.colorId == null).toList();
    source.sort((left, right) {
      final priority = viewImageKeyPriority(
        left.viewImageKey,
      ).compareTo(viewImageKeyPriority(right.viewImageKey));
      if (priority != 0) return priority;
      return left.id.compareTo(right.id);
    });
    return source;
  }

  ProductImage? matchImageByUrl(String? imageUrl) {
    final reference = _imageReference(imageUrl);
    if (reference.isEmpty) return null;

    for (final image in designViews) {
      if (_imageReference(image.url) == reference) return image;
    }
    for (final image in images) {
      if (_imageReference(image.url) == reference) return image;
    }
    return null;
  }

  String? resolveCurrentImageUrl(String? imageUrl) {
    return matchImageByUrl(imageUrl)?.url;
  }

  List<ProductImage> resolveDesignViewsForBaseImage(String? baseImageUrl) {
    final matchedImage = matchImageByUrl(baseImageUrl);
    final matchedViews = filterDesignViews(matchedImage?.colorId);
    if (matchedViews.isNotEmpty) return matchedViews;

    final commonViews = filterDesignViews(null);
    if (commonViews.isNotEmpty) return commonViews;

    final knownColorIds = designViews.map((image) => image.colorId).toSet();
    if (designViews.isNotEmpty && knownColorIds.length == 1) {
      return filterDesignViews(designViews.first.colorId);
    }

    return const [];
  }
}
