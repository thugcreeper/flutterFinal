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

## 技術棧

### Frontend
| 技術 | 說明 |
|------|------|
| Flutter | 跨平台 UI 框架 |
| Provider | 全域狀態管理 |
| Google Maps Flutter | 地圖顯示與互動 |

### 認證
| 套件 | 說明 |
|------|------|
| firebase_auth | Firebase 身份驗證 |
| firebase_ui_auth | Firebase 登入 UI 元件 |
| google_sign_in | Google OAuth 登入 |
| flutter_facebook_auth | Facebook 登入 |
| flutter_line_sdk | LINE 登入 |

### 資料儲存
| 服務 | 用途 |
|------|------|
| Cloud Firestore | 使用者資料、應用程式資料 |
| Cloudinary | 使用者頭像、圖片儲存 |

### 外部 API
| API | 用途 |
|-----|------|
| Google Directions API | 路線規劃 |
| Google Elevation API | 高度資訊 |

### 其他套件
| 套件 | 版本 | 說明 |
|------|------|------|
| image_picker | ^1.2.2 | 相片選取 |
| shared_preferences | ^2.2.3 | 本地輕量儲存 |
| flutter_dotenv | ^5.1.0 | 環境變數管理 |
| http | ^1.6.0 | HTTP 請求 |
| sign_in_button | ^5.0.0 | 標準社群登入按鈕 |

---

## 環境設定

在專案根目錄建立 `.env`：

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

