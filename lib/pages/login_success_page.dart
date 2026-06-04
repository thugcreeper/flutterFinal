// File path: lib/pages/login_success_page.dart
// Purpose: 登入成功後的動畫跳轉頁面，藉由路線延伸與打勾動畫帶給使用者流暢儀式感後，自動跳轉至首頁。
// Author: Antigravity
// Date: 2026-06-04

import 'dart:math';
import 'package:flutter/material.dart';
import 'home_page.dart';

/// 登入成功動畫頁面，負責展示單車路線延伸並繪製打勾標記的動態過渡效果。
class LoginSuccessPage extends StatefulWidget {
  /// 建立一個 [LoginSuccessPage]。
  const LoginSuccessPage({super.key});

  @override
  State<LoginSuccessPage> createState() => _LoginSuccessPageState();
}

class _LoginSuccessPageState extends State<LoginSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 建立 1.8 秒的動畫控制器，用於流暢播放路線延伸與打勾效果
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // 動畫完成後，使用漸淡轉場導航至首頁 (HomePage)
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 定義背景漸層與文字色彩
    final backgroundColor = isDark
        ? const Color(0xFF1E1B29)
        : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? Colors.grey[400]! : const Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 動態線條背景裝飾，突顯 RideVoyage 單車意象
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.04 : 0.08,
                child: CustomPaint(painter: _BackgroundGridPainter()),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 路線延伸與打勾 CustomPaint 動畫組件
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      // 動畫快結束時 (0.85 ~ 1.0)，產生微幅的彈性縮放回饋
                      double scale = 1.0;
                      if (_animation.value > 0.85) {
                        final t = (_animation.value - 0.85) / 0.15;
                        scale = 1.0 + sin(t * pi) * 0.10;
                      }

                      return Transform.scale(
                        scale: scale,
                        child: CustomPaint(
                          size: const Size(220, 180),
                          painter: RouteCheckmarkPainter(
                            animationValue: _animation.value,
                            activeColor: isDark
                                ? const Color(0xFF34D399) // 亮綠色
                                : const Color(0xFF10B981), // 翠綠色
                            roadColor: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // 登入成功文字標題
                  Text(
                    '登入成功',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 副標題
                  Text(
                    '正在為您規劃專屬的自行車路線...',
                    style: TextStyle(
                      fontSize: 15,
                      color: subtitleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自訂的 CustomPainter，負責繪製延伸路線與打勾符號。
class RouteCheckmarkPainter extends CustomPainter {
  /// 動畫進度值 (0.0 至 1.0)
  final double animationValue;

  /// 延伸路線已前進區域與打勾的顏色
  final Color activeColor;

  /// 未前進路線（背景虛線路徑）的顏色
  final Color roadColor;

  /// 建立一個 [RouteCheckmarkPainter]。
  RouteCheckmarkPainter({
    required this.animationValue,
    required this.activeColor,
    required this.roadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 定義畫筆樣式
    final roadPaint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // 建立一條代表單車路線與打勾的完整路徑
    final path = Path();
    path.moveTo(20, 110);
    // 繪製起伏的單車路線
    path.cubicTo(60, 60, 90, 150, 130, 110);
    // 連接至打勾起點
    path.lineTo(150, 130);
    // 打勾終點
    path.lineTo(195, 80);

    // 計算路徑指標以擷取特定長度
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;
    final metric = pathMetrics.first;
    final totalLength = metric.length;

    // 1. 繪製尚未前進的「虛線背景路線」
    final dashPath = Path();
    double distance = 0.0;
    const dashLength = 6.0;
    const spaceLength = 4.0;
    bool draw = true;
    while (distance < totalLength) {
      final nextDistance = distance + (draw ? dashLength : spaceLength);
      if (draw) {
        dashPath.addPath(
          metric.extractPath(distance, min(nextDistance, totalLength)),
          Offset.zero,
        );
      }
      distance = nextDistance;
      draw = !draw;
    }
    canvas.drawPath(dashPath, roadPaint);

    // 2. 根據目前動畫進度，擷取並繪製實線延伸路線
    final currentLength = totalLength * animationValue;
    final activeSegmentPath = metric.extractPath(0.0, currentLength);
    canvas.drawPath(activeSegmentPath, activePaint);

    // 3. 於延伸路徑的前端繪製一個代表單車或前進點的「發光指示點」
    final tangent = metric.getTangentForOffset(currentLength);
    if (tangent != null) {
      final position = tangent.position;

      // 外圈發光陰影效果
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(position, 10, glowPaint);

      // 內圈實體中心點
      final dotPaint = Paint()..color = activeColor;
      canvas.drawCircle(position, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RouteCheckmarkPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.roadColor != roadColor;
  }
}

/// 用於繪製背景幾何網格與裝飾點線的 Painter。
class _BackgroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 繪製格線
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
