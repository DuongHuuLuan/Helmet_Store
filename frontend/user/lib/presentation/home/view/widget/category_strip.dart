import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/arrow_button.dart';

class CategoryStrip extends StatefulWidget {
  final List<Category> categories;
  final Map<int, String> thumbnails;
  final void Function(Category c)? onTap;

  const CategoryStrip({
    super.key,
    required this.categories,
    required this.thumbnails,
    this.onTap,
  });

  @override
  State<CategoryStrip> createState() => _CategoryStripState();
}

class _CategoryStripState extends State<CategoryStrip> {
  final ScrollController _controller = ScrollController();
  bool _showLeft = false;
  bool _showRight = false;

  void _updateArrows() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final offset = _controller.offset;
    final canScroll = max > 0;
    final showLeftNow = canScroll && offset > 2;
    final showRightNow = canScroll && offset < max - 2;

    if (showLeftNow != _showLeft || showRightNow != _showRight) {
      setState(() {
        _showLeft = showLeftNow;
        _showRight = showRightNow;
      });
    }
  }

  void _scrollBy(double dx) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + dx).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: widget.categories.map((c) {
                  final thumb = widget.thumbnails[c.id];

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => widget.onTap?.call(c),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: (thumb != null && thumb.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: thumb,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: colorScheme.surfaceVariant,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.image,
                                          size: 32,
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: colorScheme.surfaceVariant,
                                            alignment: Alignment.center,
                                          ),
                                    )
                                  : Container(
                                      color: colorScheme.surfaceVariant
                                          .withOpacity(0.5),
                                      child: Icon(
                                        Icons.image,
                                        size: 40,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.5),
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: colorScheme.secondary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Text(
                              c.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Left arrow
            _buildArrow(
              isVisible: _showLeft,
              icon: Icons.chevron_left,
              onTap: () => _scrollBy(-220),
              alignment: Alignment.centerLeft,
            ),

            // Right arrow
            _buildArrow(
              isVisible: _showRight,
              icon: Icons.chevron_right,
              onTap: () => _scrollBy(220),
              alignment: Alignment.centerRight,
            ),
          ],
        ),
      ),
    );
  }

  // Hàm helper để xây dựng nút mũi tên đồng bộ Theme
  Widget _buildArrow({
    required bool isVisible,
    required IconData icon,
    required VoidCallback onTap,
    required Alignment alignment,
  }) {
    return Positioned(
      left: alignment == Alignment.centerLeft ? 6 : null,
      right: alignment == Alignment.centerRight ? 6 : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: ArrowButton(icon: icon, onTap: onTap),
          ),
        ),
      ),
    );
  }
}
