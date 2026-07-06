import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HeroCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const HeroCarousel({super.key, required this.imageUrls, this.height = 360});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _pageController = PageController();
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (widget.imageUrls.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _current = (_current + 1) % widget.imageUrls.length;
      _pageController.animateToPage(
        _current,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          //anh nen
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (value) => setState(() => _current = value),
            itemBuilder: (context, index) {
              final url = widget.imageUrls[index];
              final isAsset = url.startsWith("assets/");
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: isAsset
                        ? AssetImage(url) as ImageProvider
                        : CachedNetworkImageProvider(url),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          //Indicator
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
