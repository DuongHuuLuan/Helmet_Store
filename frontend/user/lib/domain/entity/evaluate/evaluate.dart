class EvaluateImage {
  final int id;
  final String imageUrl;
  final int? sortOrder;

  const EvaluateImage({
    required this.id,
    required this.imageUrl,
    this.sortOrder,
  });
}

class EvaluateItem {
  final int id;
  final int orderId;
  final int userId;
  final int rate;
  final String? content;
  final String? adminReply;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? adminRepliedAt;
  final List<EvaluateImage> images;
  final String? evaluaterName;
  final String? evaluaterNameMasked;
  final List<String> matchedVariants;
  final bool hasImages;

  const EvaluateItem({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rate,
    this.content,
    this.adminReply,
    this.createdAt,
    this.updatedAt,
    this.adminRepliedAt,
    this.images = const [],
    this.evaluaterName,
    this.evaluaterNameMasked,
    this.matchedVariants = const [],
    this.hasImages = false,
  });
}

class EvaluatePage {
  final List<EvaluateItem> items;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  const EvaluatePage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
}

class EvaluateRateCount {
  final int star;
  final int count;

  const EvaluateRateCount({required this.star, required this.count});
}

class ProductEvaluateSummary {
  final int productId;
  final double averageRate;
  final int totalEvaluates;
  final int totalWithImages;
  final String? summaryText;
  final List<EvaluateRateCount> rateCounts;

  const ProductEvaluateSummary({
    required this.productId,
    required this.averageRate,
    required this.totalEvaluates,
    required this.totalWithImages,
    this.summaryText,
    this.rateCounts = const [],
  });
}

class ProductEvaluatePage {
  final ProductEvaluateSummary summary;
  final List<EvaluateItem> items;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  const ProductEvaluatePage({
    required this.summary,
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
}
