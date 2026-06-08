//用在result panel顯示每個城市資訊的card
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_point.dart';
import '../models/restaurant.dart';
import 'error_snack_bar.dart';
import 'detail_dialog.dart';

class ResultCard extends StatelessWidget {
  final MapPoint point;
  final VoidCallback onTap;
  final Future<void> Function(MapPoint) onAddToRoute;

  const ResultCard({
    super.key,
    required this.point,
    required this.onTap,
    required this.onAddToRoute,
  });

  Color get _typeColor {
    switch (point.typeLabel) {
      case '餐廳':
        return const Color(0xFFEF4444);
      case '7-11':
        return const Color(0xFFF97316);
      case '全家':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _typeIcon {
    switch (point.typeLabel) {
      case '餐廳':
        return Icons.restaurant_outlined;
      case '7-11':
      case '全家':
        return Icons.store_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  Widget _buildImage() {
    if (point.pictureUrl.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_typeIcon, color: _typeColor, size: 32),
      );
    }

    if (point.pictureUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          point.pictureUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        point.pictureUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon, color: _typeColor, size: 32),
        ),
      ),
    );
  }

  String get _subtitle {
    if (point is Restaurant) {
      final r = point as Restaurant;
      return r.address.isNotEmpty ? r.address : r.description;
    }
    return point.description;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 名稱
                        Text(
                          point.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 描述或地址
                        Text(
                          _subtitle,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 標籤列
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Chip(
                              label: point.typeLabel,
                              color: _typeColor,
                              icon: _typeIcon,
                            ),
                            if (point.city.isNotEmpty)
                              _Chip(
                                label: point.city,
                                color: const Color(0xFF64748B),
                                icon: Icons.location_city_outlined,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              // 按鈕列
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //查看詳細介紹按鈕
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () => PointDetailDialog.show(context, point),
                      icon: const Icon(Icons.article_outlined, size: 18),
                      label: const Text('詳細介紹'),
                    ),
                  ),
                  //前往網頁按鈕（如果有的話）
                  if (point.webUrl != null && point.webUrl!.isNotEmpty)
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: () async {
                          final uri = Uri.tryParse(point.webUrl!);
                          if (uri == null) return;
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.open_in_browser_outlined,
                          size: 20,
                        ),
                        label: const Text('前往網頁'),
                      ),
                    ),
                  //接到路線按鈕
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await onAddToRoute(point);
                        } catch (e) {
                          messenger.showSnackBar(
                            ErrorSnackBar(message: '接到路線發生錯誤：$e'),
                          );
                        }
                      },
                      icon: const Icon(Icons.route_outlined, size: 18),
                      label: const Text('接到路線'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Chip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
