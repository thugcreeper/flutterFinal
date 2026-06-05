//顯示路線資訊卡
import 'package:flutter/material.dart';

class RouteInfoCard extends StatelessWidget {
  final String? routeDistanceText;
  final String? routeDurationText;
  final double? startElevation;
  final double? endElevation;
  final double? totalAscent;
  final double? totalDescent;
  final String? elevationErrorText;
  const RouteInfoCard({
    super.key,
    required this.routeDistanceText,
    required this.routeDurationText,
    required this.startElevation,
    required this.endElevation,
    required this.totalAscent,
    required this.totalDescent,
    required this.elevationErrorText,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (routeDistanceText != null || routeDurationText != null) ...[
              const SizedBox(height: 8),
              Text(
                '距離：${routeDistanceText ?? 'N/A'}  |  預估時間：${routeDurationText ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (startElevation != null || elevationErrorText != null) ...[
              const SizedBox(height: 8),
              Text(
                elevationErrorText != null
                    ? elevationErrorText!
                    : '起點高度：${startElevation!.toStringAsFixed(1)} m  |  終點高度：${endElevation!.toStringAsFixed(1)} m',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (totalAscent != null && totalDescent != null) ...[
              const SizedBox(height: 4),
              Text(
                '總爬升：${totalAscent!.toStringAsFixed(1)} m  |  總下降：${totalDescent!.toStringAsFixed(1)} m',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
