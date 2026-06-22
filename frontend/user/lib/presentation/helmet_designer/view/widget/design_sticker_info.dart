import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/helmet_designer/get_design_detail_usecase.dart';

class DesignStickerInfo extends StatefulWidget {
  final int? designId;
  final String? designName;
  final String? designPreviewImageUrl;
  final List<String> stickerImageUrls;
  final double imageSize;
  final String label;

  const DesignStickerInfo({
    super.key,
    required this.designId,
    this.designName,
    this.designPreviewImageUrl,
    this.stickerImageUrls = const [],
    this.imageSize = 32,
    this.label = "Thiết kế",
  });

  @override
  State<DesignStickerInfo> createState() => _DesignStickerInfoState();
}

class _DesignStickerInfoState extends State<DesignStickerInfo> {
  Future<List<String>>? _stickerUrlFuture;

  @override
  void initState() {
    super.initState();
    _stickerUrlFuture = _createStickerFuture();
  }

  @override
  void didUpdateWidget(covariant DesignStickerInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.designId != widget.designId ||
        oldWidget.designPreviewImageUrl != widget.designPreviewImageUrl ||
        !_sameUrls(oldWidget.stickerImageUrls, widget.stickerImageUrls)) {
      _stickerUrlFuture = _createStickerFuture();
    }
  }

  bool _sameUrls(List<String> first, List<String> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  Future<List<String>>? _createStickerFuture() {
    final providedUrls = _normalizeUrls(widget.stickerImageUrls);
    if (providedUrls.isNotEmpty) {
      return Future.value(providedUrls);
    }

    final fallbackUrl = _normalizeUrl(widget.designPreviewImageUrl);
    final designId = widget.designId;
    if (designId == null || designId <= 0) {
      if (fallbackUrl == null) return null;
      return Future.value([fallbackUrl]);
    }

    return (() async {
      final urls = <String>[];
      final seen = <String>{};
      try {
        final result = await di.getIt<GetDesignDetailUseCase>()(designId);
        final design = result.fold((_) => null, (d) => d);
        if (design == null) return <String>[];
        for (final sticker in design.stickers) {
          final url = _normalizeUrl(sticker.imageUrl);
          if (url == null || !seen.add(url)) continue;
          urls.add(url);
        }
      } catch (_) {}

      if (urls.isNotEmpty) return urls;
      return fallbackUrl == null ? const <String>[] : [fallbackUrl];
    })();
  }

  String? _normalizeUrl(String? value) {
    final text = value?.trim() ?? "";
    if (text.isEmpty) return null;
    return text;
  }

  List<String> _normalizeUrls(List<String> values) {
    final urls = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final url = _normalizeUrl(value);
      if (url == null || !seen.add(url)) continue;
      urls.add(url);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final fallbackUrl = _normalizeUrl(widget.designPreviewImageUrl);
    final providedUrls = _normalizeUrls(widget.stickerImageUrls);
    final hasDesignId = (widget.designId ?? 0) > 0;
    if (!hasDesignId && providedUrls.isEmpty && fallbackUrl == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final title = (widget.designName?.trim().isNotEmpty ?? false)
        ? widget.designName!.trim()
        : "Thiết kế riêng";

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: FutureBuilder<List<String>>(
        future: _stickerUrlFuture,
        builder: (context, snapshot) {
          final urls = snapshot.data ?? providedUrls;
          final displayUrls = urls.isNotEmpty
              ? urls
              : fallbackUrl == null
              ? const <String>[]
              : [fallbackUrl];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: colorScheme.onSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: displayUrls.isEmpty
                    ? [_StickerThumb(url: null, size: widget.imageSize)]
                    : displayUrls
                          .map(
                            (url) =>
                                _StickerThumb(url: url, size: widget.imageSize),
                          )
                          .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StickerThumb extends StatelessWidget {
  final String? url;
  final double size;

  const _StickerThumb({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = url?.trim() ?? "";
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.auto_awesome,
          size: size * 0.55,
          color: colorScheme.secondary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image_outlined,
            size: size * 0.55,
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }
}
