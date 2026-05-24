//儲存有關路線的海拔資訊摘要
class ElevationSummary {
  const ElevationSummary({
    required this.startElevation,
    required this.endElevation,
    required this.totalAscent,
    required this.totalDescent,
    required this.sampleCount,
    this.samples,
  });

  final double startElevation;
  final double endElevation;
  final double totalAscent; //總爬升高度
  final double totalDescent; //總下降高度
  final int sampleCount;
  final List<double>? samples;
}
