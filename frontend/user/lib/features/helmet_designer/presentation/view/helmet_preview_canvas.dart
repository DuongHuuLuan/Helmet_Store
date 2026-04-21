import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

typedef LayerTransformCallback =
    void Function(
      int layerId,
      double x,
      double y,
      double scale,
      double rotation,
    );

class HelmetPreviewCanvas extends StatelessWidget {
  final List<StickerLayer> layers;
  final int? selectedLayerId;
  final ValueChanged<int>? onLayerTap;
  final LayerTransformCallback? onLayerTransform;
  final VoidCallback? onBackgroundTap;
  final String helmetBaseImageUrl;
  final bool showGuides;
  final String emptyMessage;

  const HelmetPreviewCanvas({
    super.key,
    required this.layers,
    this.selectedLayerId,
    this.onLayerTap,
    this.onLayerTransform,
    this.onBackgroundTap,
    this.helmetBaseImageUrl = "",
    this.showGuides = true,
    this.emptyMessage = "Chọn sticker để bắt đầu thiết kế.",
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFF7F1E8), Color(0xFFE8EEF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBackgroundTap,
                    child: _HelmetCanvasBackground(
                      imageUrl: helmetBaseImageUrl,
                      showGuides: showGuides,
                    ),
                  ),
                ),
                for (final layer in layers)
                  _InteractiveStickerLayer(
                    layer: layer,
                    selectedLayerId: selectedLayerId,
                    onLayerTap: onLayerTap,
                    onLayerTransform: onLayerTransform,
                    width: width,
                    height: height,
                  ),
                if (layers.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        emptyMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InteractiveStickerLayer extends StatefulWidget {
  final StickerLayer layer;
  final int? selectedLayerId;
  final ValueChanged<int>? onLayerTap;
  final LayerTransformCallback? onLayerTransform;
  final double width;
  final double height;

  const _InteractiveStickerLayer({
    required this.layer,
    required this.selectedLayerId,
    required this.onLayerTap,
    required this.onLayerTransform,
    required this.width,
    required this.height,
  });

  @override
  State<_InteractiveStickerLayer> createState() =>
      _InteractiveStickerLayerState();
}

class _InteractiveStickerLayerState extends State<_InteractiveStickerLayer> {
  Offset? _gestureStartPoint;
  late double _startX;
  late double _startY;
  late double _startScale;
  late double _startRotation;

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    final size = _visualSize(layer.scale);
    final left = (layer.x * widget.width - size / 2).clamp(
      0.0,
      widget.width - size,
    );
    final top = (layer.y * widget.height - size / 2).clamp(
      0.0,
      widget.height - size,
    );
    final isSelected = layer.id == widget.selectedLayerId;
    final isInteractive = widget.onLayerTransform != null;

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onLayerTap == null
            ? null
            : () => widget.onLayerTap!(layer.id),
        onScaleStart: !isInteractive ? null : _onScaleStart,
        onScaleUpdate: !isInteractive ? null : _onScaleUpdate,
        child: Transform.rotate(
          angle: layer.rotation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: size.toDouble(),
            height: size.toDouble(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? AppColors.secondary : Colors.transparent,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
              color: Colors.white.withOpacity(0.12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _StickerImage(
                    crop: layer.crop,
                    imageUrl: layer.imageUrl,
                    tintColorValue: layer.tintColorValue,
                  ),
                ),
                if (isSelected && isInteractive)
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_with,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartPoint = details.focalPoint;
    _startX = widget.layer.x;
    _startY = widget.layer.y;
    _startScale = widget.layer.scale;
    _startRotation = widget.layer.rotation;
    widget.onLayerTap?.call(widget.layer.id);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_gestureStartPoint == null || widget.onLayerTransform == null) return;

    final deltaX =
        (details.focalPoint.dx - _gestureStartPoint!.dx) / widget.width;
    final deltaY =
        (details.focalPoint.dy - _gestureStartPoint!.dy) / widget.height;
    final nextScale = (_startScale * details.scale).clamp(0.1, 4.0).toDouble();
    final nextSize = _visualSize(nextScale);
    final minX = (nextSize / 2) / widget.width;
    final maxX = 1 - minX;
    final minY = (nextSize / 2) / widget.height;
    final maxY = 1 - minY;

    final nextX = (_startX + deltaX).clamp(minX, maxX).toDouble();
    final nextY = (_startY + deltaY).clamp(minY, maxY).toDouble();
    final nextRotation = _startRotation + details.rotation;

    widget.onLayerTransform!(
      widget.layer.id,
      nextX,
      nextY,
      nextScale,
      nextRotation,
    );
  }

  double _visualSize(double scale) {
    return (widget.width * 0.24 * scale)
        .clamp(34.0, widget.width * 0.52)
        .toDouble();
  }
}

class _StickerImage extends StatelessWidget {
  final StickerCrop crop;
  final String imageUrl;
  final int? tintColorValue;

  const _StickerImage({
    required this.crop,
    required this.imageUrl,
    this.tintColorValue,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      // Hiệu ứng mờ dần khi ảnh hiện ra (tùy chọn, mặc định là 1000ms)
      fadeInDuration: const Duration(milliseconds: 300),

      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),

      errorWidget: (context, url, error) =>
          const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
    );

    if (tintColorValue != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color(tintColorValue!),
          BlendMode.modulate,
        ),
        child: child,
      );
    }

    final widthFactor = (crop.right - crop.left).clamp(0.12, 1.0).toDouble();
    final heightFactor = (crop.bottom - crop.top).clamp(0.12, 1.0).toDouble();
    final alignX = (((crop.left + crop.right) / 2) * 2 - 1).clamp(-1.0, 1.0);
    final alignY = (((crop.top + crop.bottom) / 2) * 2 - 1).clamp(-1.0, 1.0);

    child = ClipRect(
      child: Align(
        alignment: Alignment(alignX.toDouble(), alignY.toDouble()),
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        child: child,
      ),
    );

    return Padding(padding: const EdgeInsets.all(6), child: child);
  }
}

class _HelmetCanvasBackground extends StatelessWidget {
  final String imageUrl;
  final bool showGuides;

  const _HelmetCanvasBackground({
    required this.imageUrl,
    required this.showGuides,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return CustomPaint(painter: _HelmetCanvasPainter(showGuides: showGuides));
    }

    Widget child = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      fadeInDuration: const Duration(milliseconds: 500),

      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 3.0),
        ),
      ),

      errorWidget: (context, url, error) =>
          const CustomPaint(painter: _HelmetCanvasPainter(showGuides: false)),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 0.98, child: child),
        if (showGuides) const CustomPaint(painter: _HelmetGuidePainter()),
      ],
    );
  }
}

class _HelmetCanvasPainter extends CustomPainter {
  final bool showGuides;

  const _HelmetCanvasPainter({required this.showGuides});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1B3550), Color(0xFF0C1628)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final visorPaint = Paint()
      ..color = const Color(0xFFB4C9E8).withOpacity(0.28);
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final shell = Path()
      ..moveTo(size.width * 0.18, size.height * 0.63)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.23,
        size.width * 0.50,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width * 0.84,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.74,
        size.width * 0.62,
        size.height * 0.80,
      )
      ..lineTo(size.width * 0.34, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.77,
        size.width * 0.18,
        size.height * 0.63,
      )
      ..close();

    final visor = Path()
      ..moveTo(size.width * 0.51, size.height * 0.31)
      ..quadraticBezierTo(
        size.width * 0.71,
        size.height * 0.35,
        size.width * 0.73,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.62,
        size.width * 0.52,
        size.height * 0.57,
      )
      ..close();

    final stripe = Paint()
      ..color = AppColors.secondary.withOpacity(0.86)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(shell, bodyPaint);
    canvas.drawPath(shell, strokePaint);
    canvas.drawPath(visor, visorPaint);
    canvas.drawLine(
      Offset(size.width * 0.27, size.height * 0.36),
      Offset(size.width * 0.62, size.height * 0.28),
      stripe,
    );

    if (!showGuides) return;

    final guidePaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final guideRect = Rect.fromCenter(
      center: Offset(size.width * 0.49, size.height * 0.50),
      width: size.width * 0.54,
      height: size.height * 0.50,
    );
    canvas.drawOval(guideRect, guidePaint);
  }

  @override
  bool shouldRepaint(covariant _HelmetCanvasPainter oldDelegate) {
    return oldDelegate.showGuides != showGuides;
  }
}

class _HelmetGuidePainter extends CustomPainter {
  const _HelmetGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final guideRect = Rect.fromCenter(
      center: Offset(size.width * 0.49, size.height * 0.50),
      width: size.width * 0.54,
      height: size.height * 0.50,
    );
    canvas.drawOval(guideRect, guidePaint);
  }

  @override
  bool shouldRepaint(covariant _HelmetGuidePainter oldDelegate) => false;
}
