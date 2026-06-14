# RideVoyage

RideVoyage 是一款專為單車愛好者打造的智能單車路線規劃與導航應用程式。本專案結合了地圖導航、高度分析、周邊景點搜尋以及 AI 智慧行程推薦，旨在為單車騎士提供一站式的騎行旅程規劃解決方案。透過串接多項第三方專業 API 與 Firebase 雲端服務，系統能針對單車騎行的特殊需求，提供精準的坡度數據與客製化路線建議。

---

## 核心功能

### 1. 智能單車路線規劃
* **路徑與導航**：整合 Google Directions API，專為單車騎行設計路線導航，即時計算行車距離與預估時間。
* **高度與坡度分析**：串接 Google Elevation API，動態生成路線的海拔高度摘要，幫助騎士在出發前掌握路段的上坡與下坡起伏。
* **自訂路線儲存**：提供完整的路線收藏功能，騎士可將規劃好的私房路線儲存至雲端，隨時隨地一鍵讀取。

### 2. 即時周邊動態搜尋
* **觀光與餐飲探索**：對接交通部 TDX 觀光資料服務，能依據地圖中心或當前定位，動態檢索全台觀光景點與周邊餐廳資訊。
* **騎士補給站定位**：整合超商門市資料 API，協助騎士快速尋找沿途的便利商店，確保飲水與物資補給無虞。
* **詳細資訊彈窗**：點擊地圖標記即可彈出詳細對話框，完整呈現景點、餐廳或超商的具體資訊。

### 3. AI 單車行程助理
* **智慧推薦導航**：整合 OpenRouter AI 模型，騎士只需輸入特定需求或目標，AI 助理即可推薦合適的單車騎行路線。
* **豐富資訊渲染**：AI 生成的推薦內容採用 Markdown 格式顯示，結構清晰、易於閱讀。

### 4. 多平台安全認證與帳號管理
* **多方社群登入**：支援 Google、Facebook 社群平台快捷登入，並整合 Firebase Auth

* **個人化檔案與頭像**：提供完善的個人資料頁面與帳號管理功能，支援透過相簿選取照片，並上傳至 Firebase Storage 作為個人頭像。

---


# 專案架構圖

```readme
lib/
├── api/
│   ├── auth_api               # 帳號登入 / 註冊 / 驗證 API
│   ├── city_lookup_api        # 縣市與行政區代碼查詢 API
│   ├── convenience_store_api  # 超商門市資料 API
│   ├── directions_api         # Google Maps 路線導航 API
│   ├── elevation_api          # Google Maps 海拔資訊 API
│   ├── ai_assistant_api             # Gemini / OpenRouter AI 模型對接 API
│   ├── restaurant_api         # 周邊餐廳資料 API
│   ├── saved_route_api        # 使用者儲存/讀取路線 API
│   ├── scenic_spot_api        # 周邊觀光景點資料 API
│   ├── tourism_search_api     # TDX 觀光資料搜尋核心 API
│   └── user_profile_api       # 使用者資訊 / 帳號管理 API
│ 
├── controller/
│   ├── ai_chat_controller     # AI 聊天助理業務邏輯控制器
│   └── nearby_search_controller  # 地圖周邊景點/餐廳/超商搜尋控制器
│ 
├── models/
│   ├── chat_message           # AI 聊天訊息資料模型
│   ├── convenience_store      # 超商門市資料模型
│   ├── directions_route       # 導航路線與距離資料模型
│   ├── elevation_summary      # 海拔高度摘要模型
│   ├── map_point              # 地圖標記點位（Marker）資料模型
│   ├── resolved_city          # 解析後的縣市行政區資料模型
│   ├── restaurant             # 餐廳資訊資料模型
│   ├── saved_route            # 已儲存單車路線資料模型
│   └── scenic_spot            # 觀光景點資訊資料模型
│ 
├── pages/
│   ├── account_management_page  # 帳號管理頁
│   ├── ai_chat_page             # AI聊天頁面
│   ├── auth_gate                # 登入狀態閘道
│   ├── edit_profile_page        # 個人資料編輯頁面
│   ├── guide_page               # 操作指南頁面
│   ├── home_page                # App 主頁（地圖互動核心）
│   ├── login_page               # 登入頁
│   ├── login_success_page       # 登入成功後動畫頁面
│   ├── register_page            # 註冊頁
│   ├── register_success_page    # 註冊成功引導頁
│   ├── saved_routes_page        # 查看儲存路線頁
│   ├── setting_page             # 設定頁
│   └── user_profile_page        # 個人資料與歷史路線頁
│ 
├── providers/
│   ├── route_provider         # 路線資訊狀態管理
│   └── theme_provider         # 主題切換狀態管理
│ 
└── widgets/
    ├── action_buttons         # 地圖操作按鈕組（如返回上一點、刪除等）
    ├── custom_app_bar         # 自訂通用 AppBar
    ├── custom_text_field      # 通用樣式輸入框
    ├── detail_dialog          # 景點/餐廳詳細資訊對話框
    ├── error_snack_bar        # 錯誤提示快顯通知
    ├── gradient_scaffold      # 漸層背景基礎頁面結構
    ├── guide_card             # 操作指南卡片元件
    ├── nearby_search_results_panel  # 周邊搜尋結果面板
    ├── primary_button         # 專案主視覺按鈕
    ├── result_card            # 搜尋結果清單卡片
    ├── route_info_card        # 路線距離與海拔資訊顯示卡片
    ├── safe_asset_image       # 本地資源圖片安全載入元件
    ├── show_agent_info        # AI 助理詳細資料彈窗
    ├── social_login_section   # 第三方社群登入按鈕區塊
    ├── success_snack_bar      # 成功提示快顯通知
    └── user_profile_dialog    # 快速查看/編輯使用者資料對話框
│
├── firebase_options           # Firebase 初始化設定
├── main                       # App 進入點
└── map_Initializer            # Google Map 初始化設定

## 技術棧

### Frontend
| 技術 | 說明 |
|------|------|
| Flutter | 跨平台 UI 框架 |
| Provider | 全域狀態管理 |
| Google Maps Flutter | 地圖顯示與互動 (`Maps_flutter` 系列套件) |

### 認證
| 套件 | 說明 |
|------|------|
| firebase_auth | Firebase 身份驗證 |
| firebase_ui_auth | Firebase 登入 UI 元件 |
| firebase_ui_oauth_google | Firebase Google OAuth 整合支援 |
| google_sign_in | Google OAuth 登入功能 |
| flutter_facebook_auth | Facebook 登入功能 |
| flutter_line_sdk | LINE SDK 登入功能 |

### 資料儲存
| 服務 / 套件 | 用途 |
|------|------|
| Cloud Firestore | 使用者資料、應用程式路線資料管理 |
| Firebase Storage | 使用者大頭貼與圖片檔案儲存 |

### 外部 API
| API | 用途 |
|-----|------|
| Google Directions API | 路線規劃與導航資訊 |
| Google Elevation API | 高度資訊與上升/下降值計算 |

### 其他工具與 UI 套件
| 套件 | 版本 | 說明 |
|------|------|------|
| provider | ^6.1.5+1 | 專案全域狀態管理（主題、路線等） |
| flutter_markdown_plus | ^1.0.7 | 渲染 AI 推薦路線的精美 Markdown 格式 |
| scrollable_positioned_list | ^0.3.8 | 搜尋結果列表定位與地圖連動滾動 |
| image_picker | ^1.2.2 | 相機與相簿相片選取（用於大頭貼） |
| url_launcher | ^6.3.2 | 開啟外部網頁連結或系統撥號 |
| shared_preferences | ^2.2.3 | 本地端輕量資料快取（儲存路線點位） |
| http | ^1.6.0 | 發送網路請求至 Google API 服務 |
| sign_in_button | ^5.0.0 | 提供標準的社群第三方登入按鈕 UI |
| flutter_dotenv | ^5.1.0 | 本地環境變數管理（載入 `.env` 金鑰） |

---

```
## 環境設定

在專案根目錄建立 `.env`,詳見example.env：

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET
GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID
MAPS_PLATFORM_API_KEY=YOUR_MAPS_PLATFORM_API_KEY
API_BASE_URL=YOUR_BACKEND_API_URL
TDX_CLIENT_ID=YOUR_TDX_CLIENT_ID
TDX_CLIENT_SECRET=YOUR_TDX_CLIENT_SECRET
AI_API_KEY=YOUR_AI_API_KEY
```

