import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum AiStickerVoiceScreenStep {
  opening,
  listening,
  transcribing,
  generating,
  result,
  error,
}

class AiStickerVoiceScreenState {
  final AiStickerVoiceScreenStep step;
  final String title;
  final String subtitle;
  final String? prompt;
  final StickerTemplate? sticker;
  final String? errorMessage;

  const AiStickerVoiceScreenState._({
    required this.step,
    required this.title,
    required this.subtitle,
    this.prompt,
    this.sticker,
    this.errorMessage,
  });

  const AiStickerVoiceScreenState.opening()
    : this._(
        step: AiStickerVoiceScreenStep.opening,
        title: 'Đang mở microphone...',
        subtitle: 'Chuẩn bị ghi âm mô tả sticker của bạn.',
      );

  const AiStickerVoiceScreenState.listening()
    : this._(
        step: AiStickerVoiceScreenStep.listening,
        title: 'Tôi đang nghe đây...',
        subtitle:
            'Hãy nói mô tả sticker. Khi bạn im lặng, ứng dụng sẽ tự xử lý.',
      );

  const AiStickerVoiceScreenState.transcribing()
    : this._(
        step: AiStickerVoiceScreenStep.transcribing,
        title: 'Đang xử lý giọng nói...',
        subtitle: 'Ứng dụng đang chuyển đoạn ghi âm thành mô tả sticker.',
      );

  const AiStickerVoiceScreenState.generating({required String prompt})
    : this._(
        step: AiStickerVoiceScreenStep.generating,
        title: 'Đang tạo sticker...',
        subtitle: 'Đang dựng sticker từ mô tả bạn vừa nói.',
        prompt: prompt,
      );

  const AiStickerVoiceScreenState.result({
    required StickerTemplate sticker,
    required String prompt,
  }) : this._(
         step: AiStickerVoiceScreenStep.result,
         title: 'Sticker của bạn đã sẵn sàng',
         subtitle: 'Bạn có thể thêm sticker này ngay vào nón.',
         prompt: prompt,
         sticker: sticker,
       );

  const AiStickerVoiceScreenState.error({required String message})
    : this._(
        step: AiStickerVoiceScreenStep.error,
        title: 'Không thể tạo sticker',
        subtitle: 'Bạn có thể đóng màn hình này rồi thử lại.',
        errorMessage: message,
      );

  bool get isListening =>
      step == AiStickerVoiceScreenStep.opening ||
      step == AiStickerVoiceScreenStep.listening;

  bool get isWorking =>
      step == AiStickerVoiceScreenStep.transcribing ||
      step == AiStickerVoiceScreenStep.generating;

  bool get isResult => step == AiStickerVoiceScreenStep.result;

  bool get isError => step == AiStickerVoiceScreenStep.error;
}

class AiStickerVoiceScreen extends StatelessWidget {
  final AiStickerVoiceScreenState state;
  final VoidCallback? onClose;
  final VoidCallback? onStopRecording;
  final VoidCallback? onUseSticker;

  const AiStickerVoiceScreen({
    super.key,
    required this.state,
    this.onClose,
    this.onStopRecording,
    this.onUseSticker,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: const Color(0xCC07111D),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F4F1), Color(0xFFEDE4D6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -40,
                child: _AmbientGlow(
                  size: 220,
                  color: AppColors.secondary.withOpacity(0.18),
                ),
              ),
              Positioned(
                left: -70,
                bottom: 80,
                child: _AmbientGlow(
                  size: 210,
                  color: AppColors.primary.withOpacity(0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Voice Sticker AI',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (state.isListening ||
                            state.isResult ||
                            state.isError)
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Đóng',
                          ),
                      ],
                    ),
                    const Spacer(),
                    _buildBody(context),
                    const Spacer(),
                    _buildActions(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (state.isResult && state.sticker != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.light.textSecondary,
            ),
          ),
          if ((state.prompt ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.light.border),
              ),
              child: Text(
                'Mô tả: ${state.prompt}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.light.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: state.sticker!.imageUrl,
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state.isError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 72,
            color: AppColors.error,
          ),
          const SizedBox(height: 20),
          Text(
            state.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.errorMessage ?? state.subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.light.textSecondary,
            ),
          ),
        ],
      );
    }

    final icon = state.step == AiStickerVoiceScreenStep.listening
        ? Icons.mic_rounded
        : state.step == AiStickerVoiceScreenStep.opening
        ? Icons.settings_voice_rounded
        : Icons.auto_awesome_rounded;

    final bubbleColor = state.step == AiStickerVoiceScreenStep.listening
        ? AppColors.secondary
        : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VoicePulseOrb(
          color: bubbleColor,
          icon: icon,
          isActive: state.isListening || state.isWorking,
        ),
        const SizedBox(height: 28),
        Text(
          state.title,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          state.subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.light.textSecondary,
            height: 1.45,
          ),
        ),
        if ((state.prompt ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.76),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.light.border),
            ),
            child: Text(
              state.prompt!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    if (state.step == AiStickerVoiceScreenStep.listening) {
      return FilledButton.icon(
        onPressed: onStopRecording,
        icon: const Icon(Icons.stop_circle_outlined),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        label: const Text('Dừng và xử lý'),
      );
    }

    if (state.isResult) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Đóng'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onUseSticker,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thiết kế ngay'),
            ),
          ),
        ],
      );
    }

    if (state.isError) {
      return OutlinedButton(
        onPressed: onClose,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Đóng'),
      );
    }

    return const SizedBox(
      height: 52,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }
}

class _VoicePulseOrb extends StatefulWidget {
  final Color color;
  final IconData icon;
  final bool isActive;

  const _VoicePulseOrb({
    required this.color,
    required this.icon,
    required this.isActive,
  });

  @override
  State<_VoicePulseOrb> createState() => _VoicePulseOrbState();
}

class _VoicePulseOrbState extends State<_VoicePulseOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _VoicePulseOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) {
      return;
    }
    if (widget.isActive) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224,
      height: 224,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = widget.isActive ? _controller.value : 0;
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRing(scale: 1 + (pulse * 0.28), opacity: 0.10),
              _buildRing(
                scale: 1 + (((pulse + 0.35) % 1) * 0.24),
                opacity: 0.16,
              ),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withOpacity(0.92),
                      AppColors.primary.withOpacity(0.94),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 58, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRing({required double scale, required double opacity}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(opacity),
        ),
      ),
    );
  }
}
