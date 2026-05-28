import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:math';

//註冊成功頁面
class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: RibbonAnimation(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 圓圈 + 打勾動畫
                  _AnimatedCheckCircle(),
                  const SizedBox(height: 36),

                  // 文字淡入
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut, // 慢慢淡入
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)), //
                        child: child,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '恭喜註冊成功！',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 按鈕淡入（延遲）
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (_, value, child) =>
                        Opacity(opacity: value, child: child),
                    child: SizedBox(
                      width: 200,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '前往登入',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 打勾動畫 widget ─────────────────────────────────────────
class _AnimatedCheckCircle extends StatefulWidget {
  @override
  State<_AnimatedCheckCircle> createState() => _AnimatedCheckCircleState();
}

class _AnimatedCheckCircleState extends State<_AnimatedCheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 圓圈從小放大
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );

    // 打勾在圓圈出現後才畫
    _checkAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _checkAnim,
            builder: (_, __) => CustomPaint(
              size: const Size(48, 48),
              painter: _CheckPainter(progress: _checkAnim.value),
            ),
          ),
        ),
      ),
    );
  }
}

// 手繪打勾效果
class _CheckPainter extends CustomPainter {
  final double progress;
  const _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.75)
      ..lineTo(size.width * 0.85, size.height * 0.25);

    final totalLength = _pathLength(path);
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, totalLength * progress);
    canvas.drawPath(drawn, paint);
  }

  double _pathLength(Path path) {
    return path.computeMetrics().fold(0.0, (sum, m) => sum + m.length);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

//彩帶動畫相關
class Ribbon {
  double x;
  double y;
  double vx; // x 方向初速度
  double vy; // y 方向初速度（向上為負）
  final double speed;
  final double size;
  double angle;
  final Color color;

  Ribbon({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    required this.speed,
    required this.size,
    required this.angle,
    required this.color,
  });
}

class RibbonAnimation extends StatefulWidget {
  final Widget child;
  const RibbonAnimation({super.key, required this.child});

  @override
  State<RibbonAnimation> createState() => _RibbonAnimationState();
}

class _RibbonAnimationState extends State<RibbonAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Ribbon> _ribbons;
  final _random = Random();
  static const List<Color> _ribbonColors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFFFFFFF),
  ];
  @override
  void initState() {
    super.initState();
    _ribbons = [];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 999),
    )..addListener(_updateRibbons);

    // 等第一幀完成後才能拿到 context.size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ribbons.addAll(List.generate(60, (_) => _makeRibbon(randomY: true)));
      _controller.forward();
    });
  }

  Ribbon _makeRibbon({bool randomY = false}) {
    final screenW = context.size?.width ?? 400;
    final screenH = context.size?.height ?? 800;
    final angle = _random.nextDouble() * 2 * pi; // 隨機方向
    final speed = 3 + _random.nextDouble() * 8; // 初速度大小
    return Ribbon(
      x: screenW * 0.5,
      y: screenH * 0.1,
      vx: cos(angle) * speed, // x 分速度
      vy: sin(angle) * speed - 5, // y 分速度，減 5 讓大部分往上噴
      speed: speed,
      size: 6 + _random.nextDouble() * 4, // 隨機
      angle: angle,
      color: _ribbonColors[_random.nextInt(_ribbonColors.length)],
    );
  }

  void _updateRibbons() {
    const double gravity = 0.3;
    for (final r in _ribbons) {
      r.vy = r.vy + gravity;
      r.x += r.vx;
      r.y += r.vy;
      r.angle = r.vx * 0.05;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _RibbonPainter(_ribbons),
            child: const SizedBox.expand(),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final List<Ribbon> ribbons;
  _RibbonPainter(this.ribbons);

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in ribbons) {
      final paint = Paint()..color = r.color;
      canvas.save();
      canvas.translate(r.x, r.y);
      canvas.rotate(r.angle);
      canvas.drawRect(
        //長寬比 8:1 的矩形
        Rect.fromCenter(
          center: Offset.zero,
          width: r.size,
          height: r.size * 10,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => true;
}
