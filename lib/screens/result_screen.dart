// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/detection_result.dart';
import '../utils/app_theme.dart';

class ResultScreen extends StatefulWidget {
  /// Live result notifier — starts as defaultResult() and gets updated
  /// when AI finishes. Pass a simple DetectionResult for static display.
  final ValueNotifier<DetectionResult> resultNotifier;

  const ResultScreen({
    super.key,
    required this.resultNotifier,
  });

  /// Convenience constructor for static (history) display
  static ResultScreen fromResult(DetectionResult result) => ResultScreen(
        resultNotifier: ValueNotifier(result),
      );

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DetectionResult>(
      valueListenable: widget.resultNotifier,
      builder: (context, result, _) {
        final isLoading = result.id == 'loading';
        final sColor = isLoading ? Colors.grey : severityColor(result.severity);
        final sEmoji = isLoading ? '⏳' : severityEmoji(result.severity);

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: CustomScrollView(
            slivers: [
              // ── Hero image header ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    isLoading ? 'AI Analysis in Progress' : result.diseaseName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  background: result.imageUrl.isNotEmpty
                      ? Image.network(result.imageUrl, fit: BoxFit.cover)
                      : _buildHeroBackground(isLoading, sColor),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Loading banner ──────────────────────────────────
                    if (isLoading) _LoadingBanner(pulseCtrl: _pulseCtrl),

                    // ── Severity badge ──────────────────────────────────
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _maybeShimmer(
                          isLoading: isLoading,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: sColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sColor),
                            ),
                            child: Text(
                              '$sEmoji  ${result.severity.toUpperCase()}',
                              style: TextStyle(
                                  color: sColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        _maybeShimmer(
                          isLoading: isLoading,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.skyBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.skyBlue.withOpacity(0.4)),
                            ),
                            child: Text(
                              isLoading
                                  ? '${result.cropType} · Calculating…'
                                  : '${result.cropType} · ${(result.confidenceScore * 100).toStringAsFixed(1)}% confident',
                              style: const TextStyle(
                                  color: AppTheme.skyBlue, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 400.ms),
                    const SizedBox(height: 20),

                    // ── Severity gauge ──────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Leaf Area Affected',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            Center(
                              child: CircularPercentIndicator(
                                radius: 80,
                                lineWidth: 14,
                                percent: isLoading
                                    ? 0.0
                                    : result.severityPercent / 100,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    isLoading
                                        ? AnimatedBuilder(
                                            animation: _pulseCtrl,
                                            builder: (_, __) => Text(
                                              '…',
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.withOpacity(
                                                    0.4 +
                                                        _pulseCtrl.value *
                                                            0.5),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            '${result.severityPercent.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                                color: sColor),
                                          ),
                                    const Text('affected',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ],
                                ),
                                progressColor:
                                    isLoading ? Colors.grey.shade300 : sColor,
                                backgroundColor: isLoading
                                    ? Colors.grey.shade100
                                    : sColor.withOpacity(0.1),
                                circularStrokeCap: CircularStrokeCap.round,
                                animation: true,
                                animationDuration: 1200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slideY(begin: 0.2, duration: 500.ms).fade(),
                    const SizedBox(height: 16),

                    // ── Description ─────────────────────────────────────
                    _SectionCard(
                      title: '🔬 About this Disease',
                      isLoading: isLoading,
                      child: Text(result.description,
                          style: const TextStyle(
                              fontSize: 14, height: 1.6, color: Colors.black87)),
                    ),
                    const SizedBox(height: 12),

                    // ── Symptoms ────────────────────────────────────────
                    _SectionCard(
                      title: '🩺 Observed Symptoms',
                      isLoading: isLoading,
                      child: _BulletList(items: result.symptoms),
                    ),
                    const SizedBox(height: 12),

                    // ── Treatments ──────────────────────────────────────
                    _SectionCard(
                      title: '💊 Recommended Treatments',
                      isLoading: isLoading,
                      child: _NumberedList(items: result.treatments),
                    ),
                    const SizedBox(height: 12),

                    // ── Prevention ──────────────────────────────────────
                    _SectionCard(
                      title: '🛡️ Preventive Measures',
                      isLoading: isLoading,
                      child: _BulletList(items: result.preventions),
                    ),
                    const SizedBox(height: 12),

                    // ── Weather note ────────────────────────────────────
                    if (result.weatherNote.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.skyBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.skyBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🌦 ',
                                style: TextStyle(fontSize: 20)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Weather Impact',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(result.weatherNote,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Share / Save button ─────────────────────────────
                    if (!isLoading)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share Result'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Share feature coming soon!')),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _maybeShimmer({required bool isLoading, required Widget child}) {
    return isLoading ? Opacity(opacity: 0.5, child: child) : child;
  }

  Widget _buildHeroBackground(bool isLoading, Color sColor) {
    if (isLoading) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen
                    .withOpacity(0.6 + _pulseCtrl.value * 0.3),
                AppTheme.primaryGreen.withOpacity(0.3),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.8),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI Scanning Image…',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(color: sColor);
  }
}

// ── Loading Banner ──────────────────────────────────────────────────────────
class _LoadingBanner extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _LoadingBanner({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen
                    .withOpacity(0.1 + pulseCtrl.value * 0.08),
                AppTheme.skyBlue
                    .withOpacity(0.08 + pulseCtrl.value * 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 1.5),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI is analyzing your crop image… Results will update automatically.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}


class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isLoading;
  const _SectionCard(
      {required this.title, required this.child, this.isLoading = false});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              isLoading ? Opacity(opacity: 0.6, child: child) : child,
            ],
          ),
        ),
      ).animate().slideY(begin: 0.15, duration: 400.ms).fade();
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.5))),
                    ],
                  ),
                ))
            .toList(),
      );
}

class _NumberedList extends StatelessWidget {
  final List<String> items;
  const _NumberedList({required this.items});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text('${e.key + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(e.value,
                        style: const TextStyle(
                            fontSize: 13, height: 1.5))),
              ],
            ),
          );
        }).toList(),
      );
}
