import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
    if (message != null) ...[const SizedBox(height: 16), Text(message!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))],
  ]));
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.error_outline, size: 40, color: AppTheme.danger)),
    const SizedBox(height: 16), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
    if (onRetry != null) ...[const SizedBox(height: 16), OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة'))],
  ])));
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.textSecondary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 40, color: AppTheme.textSecondary)),
    const SizedBox(height: 16), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
    if (actionLabel != null && onAction != null) ...[const SizedBox(height: 16), ElevatedButton(onPressed: onAction, child: Text(actionLabel!))],
  ])));
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;
  const StatusBadge({super.key, required this.status, this.small = false});
  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    final label = statusLabelAr(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 3 : 5),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: c, fontSize: small ? 10 : 12, fontWeight: FontWeight.w700)),
    );
  }
}

class HotelNetworkImage extends StatelessWidget {
  final String? url;
  final double? aspectRatio;
  final BorderRadius? radius;
  final BoxFit fit;
  const HotelNetworkImage({super.key, this.url, this.aspectRatio, this.radius, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) {
    final r = radius ?? BorderRadius.circular(16);
    if (url == null || url!.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: r),
        child: const Center(child: Icon(Icons.hotel_outlined, size: 48, color: AppTheme.textSecondary)),
      );
    }
    final img = CachedNetworkImage(imageUrl: url!, fit: fit, placeholder: (_, __) => Container(color: AppTheme.background), errorWidget: (_, __, ___) => Container(color: AppTheme.background, child: const Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary)));
    if (aspectRatio != null) {
      return ClipRRect(borderRadius: r, child: AspectRatio(aspectRatio: aspectRatio!, child: img));
    }
    return ClipRRect(borderRadius: r, child: img);
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle({super.key, required this.title, this.subtitle, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))],
    ])),
    if (actionLabel != null && onAction != null) TextButton(onPressed: onAction, child: Text(actionLabel!, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
  ]);
}

Widget statCard({required String label, required String value, required IconData icon, Color? color, VoidCallback? onTap}) {
  return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (color ?? AppTheme.primary).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color ?? AppTheme.primary))]),
    const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
    const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
  ]))));
}
