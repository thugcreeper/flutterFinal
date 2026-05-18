import 'package:flutter/material.dart';

//取代原本的Image.asset組件，當圖片載入失敗時會顯示預設的替代圖片，避免應用崩潰
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  static const String fallbackUrl =
      'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=original';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          fallbackUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.broken_image),
            );
          },
        );
      },
    );
  }
}
