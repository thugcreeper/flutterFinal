import 'package:flutter/material.dart';
import 'safe_asset_image.dart';

/// 顯示 Agent 個人簡介與大圖檢視的 Modal
void showAgentProfileModal(BuildContext context) {
  //showModalBottomSheet 會自動處理鍵盤彈出時的高度調整
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 頂部小灰條
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Agent 大圖檢視區（帶點擊放大效果）
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      body: Center(
                        //InteractiveViewer 讓圖片可以縮放和平移
                        child: InteractiveViewer(
                          child: SafeAssetImage(
                            assetPath: 'assets/images/agent_image.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const ClipOval(
                  child: SafeAssetImage(
                    assetPath: 'assets/images/agent_image.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 名字與標籤
            const Text(
              'RideVoyage AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '專屬單車路線專家',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 20),

            // 簡介內文
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '助理簡介',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '我是您的智慧單車導航與路線規劃助手。無論您是想挑戰陡峭的山路、漫遊沿海自行車道，還是尋找周邊隱藏的景點與美味餐廳並規劃超商補給站，我都能為您打造最舒適的騎行體驗！',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      );
    },
  );
}
