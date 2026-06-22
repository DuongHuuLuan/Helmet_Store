import 'dart:async';
import 'package:flutter/material.dart';

class ProductPromoCarousel extends StatefulWidget {
  final List<ProductPromoItem> items;
  final double height;
  final Duration autoPlayDuration;
  final ValueChanged<int>? onProductTap;

  const ProductPromoCarousel({
    super.key,
    required this.items,
    this.height = 200,
    this.autoPlayDuration = const Duration(seconds: 3),
    this.onProductTap,
  });

  @override
  State<ProductPromoCarousel> createState() => _ProductPromoCarouselState();
}

class _ProductPromoCarouselState extends State<ProductPromoCarousel>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 1);

  Timer? _timer;
  int _currentIndex = 0;

  late final AnimationController _introController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-0.18, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));

    _introController.forward();

    if (widget.items.length > 1) {
      _timer = Timer.periodic(widget.autoPlayDuration, (_) {
        if (!mounted || !_pageController.hasClients) return;

        _currentIndex = (_currentIndex + 1) % widget.items.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              SizedBox(
                height: widget.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return InkWell(
                        onTap: () => widget.onProductTap?.call(item.productId),
                        child: Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (widget.items.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.items.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductPromoItem {
  final String imagePath;
  final int productId;

  const ProductPromoItem({required this.imagePath, required this.productId});
}
