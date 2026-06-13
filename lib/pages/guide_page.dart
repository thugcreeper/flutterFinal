//這個頁面是操作指南，提供使用者如何使用APP的說明
import 'package:flutter/material.dart';
import '../widgets/guide_card.dart';
import '../widgets/gradient_scaffold.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('操作指南'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GuideCard(
            title: '搜尋功能',
            leadingColor: const Color(0xFFF59E0B),
            icon: Icons.search,
            content:
                '• 搜尋欄可切換 3 種模式\n'
                '• 未輸入關鍵字按 Enter：顯示目前縣市所有景點/餐廳\n'
                '• 超商模式：顯示目前行政區所有門市\n'
                '• 搜尋結果點擊後會移動到地圖中心\n'
                '• 可選擇「加入路線」',
          ),
          GuideCard(
            leadingColor: const Color(0xFF059669),
            title: '地圖操作',
            icon: Icons.map,
            content:
                '• 點擊地圖可放置 marker\n'
                '• 自動計算路線距離與預估時間\n'
                '• 顯示海拔變化（上升 / 下降）\n'
                '• 支援：返回上一點、刪除、儲存路線、查看路線\n'
                '• 右下角提供縮放控制',
          ),
          GuideCard(
            leadingColor: const Color(0xFFEC4899),
            title: '個人資料',
            icon: Icons.person,
            content:
                '• 點擊頭像可查看詳細資料\n'
                '• 顯示帳號 / Email / 簡介\n'
                '• 可編輯個人資訊\n'
                '• 支援上傳大頭貼\n'
                '• 可查看已儲存路線',
          ),
          GuideCard(
            leadingColor: const Color(0xFF1E40AF),
            title: '設定',
            icon: Icons.settings,
            content:
                '• 語言切換（中 / 英）\n'
                '• 深色模式切換\n'
                '• 帳號管理（修改密碼 / 刪除帳號）\n'
                '• 推播通知設定\n'
                '• 應用程式資訊',
          ),
          GuideCard(
            leadingColor: const Color(0xFF3B82F6),
            title: 'AI 聊天助理',
            icon: Icons.auto_awesome,
            content:
                '• 自動讀取目前位置行政區(如基隆市中正區)的景點、餐廳與超商數量\n'
                '• 點擊「幫我推薦路線」按鈕，快速生成專屬單車行程\n'
                '• 點擊 AI 助理的大頭貼，可查看詳細個人簡介與大圖檢視\n'
                '• 右上角提供「清除對話」按鈕',
          ),
        ],
      ),
    );
  }
}
