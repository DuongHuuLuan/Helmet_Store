import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/evaluate/evaluate_image_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/evaluate/evaluate_item_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/evaluate/evaluate_page_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/evaluate/product_evaluate_page_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';

class EvaluateMapper {
  static EvaluateImage imageFromModel(EvaluateImageModel model) {
    return EvaluateImage(
      id: model.id,
      imageUrl: _resolveUrl(model.imageUrl),
      sortOrder: model.sortOrder,
    );
  }

  static EvaluateItem fromModel(EvaluateItemModel model) {
    return EvaluateItem(
      id: model.id,
      orderId: model.orderId,
      userId: model.userId,
      rate: model.rate,
      content: model.content,
      adminReply: model.adminReply,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      adminRepliedAt: model.adminRepliedAt,
      images: (model.images ?? [])
          .map(imageFromModel)
          .toList(),
      evaluaterName: model.evaluaterName,
      evaluaterNameMasked: model.evaluaterNameMasked,
      matchedVariants: model.matchedVariants ?? [],
      hasImages: model.hasImages ?? model.images?.isNotEmpty ?? false,
    );
  }

  static EvaluatePage pageFromModel(EvaluatePageModel model) {
    return EvaluatePage(
      items: (model.items ?? []).map(fromModel).toList(),
      page: model.page ?? 1,
      perPage: model.perPage ?? 10,
      total: model.total ?? 0,
      totalPages: model.totalPages ?? 0,
    );
  }

  static ProductEvaluatePage productPageFromModel(ProductEvaluatePageModel model) {
    final summary = model.summary;
    return ProductEvaluatePage(
      summary: ProductEvaluateSummary(
        productId: summary?.productId ?? 0,
        averageRate: summary?.averageRate ?? 0,
        totalEvaluates: summary?.totalEvaluates ?? 0,
        totalWithImages: summary?.totalWithImages ?? 0,
        summaryText: summary?.summaryText,
        rateCounts: (summary?.rateCounts ?? [])
            .map((e) => EvaluateRateCount(star: e.star ?? 0, count: e.count ?? 0))
            .toList(),
      ),
      items: (model.items ?? []).map(fromModel).toList(),
      page: model.page ?? 1,
      perPage: model.perPage ?? 10,
      total: model.total ?? 0,
      totalPages: model.totalPages ?? 0,
    );
  }

  static String _resolveUrl(String raw) {
    if (raw.isEmpty) return raw;
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    final base = AppConstants.baseUrl.replaceAll(RegExp(r"/+$"), "");
    return "$base${raw.startsWith("/") ? "" : "/"}$raw";
  }
}
