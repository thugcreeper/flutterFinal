# APP名稱
RideVoyage

# 專案架構圖
```readme
lib/
├── api/
│   ├── auth_api.dart            # 帳號登入 / 註冊 / Google 登入 API
│   ├── directions_api.dart      # 路線導航 API
│   ├── elevation_api.dart       # 高度資訊 API
│   └── user_profile_api.dart    # 使用者資訊 / 登出 API
├── firebase_options.dart        # Firebase 初始化設定
├── main.dart                    # App 進入點
├── map_Initializer.dart         # Google Map 初始化
├── models/
│   ├── directions_route.dart    # 路線資料模型
│   └── elevation_summary.dart   # 高度摘要模型
├── pages/
│   ├── account_management_page.dart # 帳號管理頁
│   ├── auth_gate.dart               # 登入閘道
│   ├── home_page.dart               # 首頁
│   ├── login_page.dart              # 登入頁
│   ├── register_page.dart           # 註冊頁
│   ├── register_success_page.dart   # 註冊成功頁
│   ├── setting_page.dart            # 設定頁
│   └── user_profile_page.dart       # 個人資料頁
├── providers/
│   └── theme_provider.dart      # 主題切換狀態
├── repositories/
│   └── (目前空白)
├── services/
│   └── (目前空白)
└── widgets/
    ├── app_bar.dart             # 自訂 AppBar
    ├── custom_text_field.dart   # 通用輸入框
    ├── primary_button.dart      # 主按鈕
    ├── route_map_view.dart      # 地圖與路線顯示
    ├── safe_asset_image.dart    # 安全載入資源圖片
    └── social_login_section.dart # Google / FB / LINE 區塊
```
