import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/gemini_api.dart';
import '../models/chat_message.dart';
import 'dart:io';
import 'dart:async';

class AiChatController extends ChangeNotifier {
  static const String _storageKey = 'ai_chat_history';

  final GeminiApi _geminiApi = GeminiApi();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  String? errorMessage;

  // 目前城市資訊，從外部設定
  String? currentCity;
  String? currentArea;

  // 附近的景點、餐廳、超商資料，從外部設定
  List<String> nearbyScenics = [];
  List<String> nearbyRestaurants = [];
  List<String> nearbyStores = [];

  AiChatController() {
    _loadHistory();
  }

  // ── 系統提示 ──────────────────────────────────────────────
  String get _systemPrompt {
    final city = currentCity ?? '未知城市';
    final area = currentArea ?? '';

    final scenicsText = nearbyScenics.isEmpty
        ? '暫無景點資料'
        : nearbyScenics.join('、');
    final restaurantsText = nearbyRestaurants.isEmpty
        ? '暫無餐廳資料'
        : nearbyRestaurants.join('、');
    final storesText = nearbyStores.isEmpty ? '暫無超商資料' : nearbyStores.join('、');

    return '''
      你是 RideVoyage 的腳踏車路線助手，專門幫助使用者規劃台灣的自行車旅遊路線。
      目前使用者位於 $city $area。

      附近的景點：$scenicsText
      附近的餐廳：$restaurantsText
      附近的超商（補給站）：$storesText

      請用繁體中文回答，語氣友善親切。
      規劃路線時請考慮腳踏車的適合度、距離合理性，以及補給點的安排。
      回答盡量簡潔，重點清楚。
      ''';
  }

  // ── 傳送訊息 ──────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    messages = [...messages, userMessage];
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final reply = await _geminiApi.sendMessage(
        messages: messages,
        systemPrompt: _systemPrompt,
      );

      if (reply == null) {
        errorMessage = 'AI 回應失敗，請稍後再試';
      } else {
        final modelMessage = ChatMessage(
          role: 'model',
          content: reply,
          timestamp: DateTime.now(),
        );
        messages = [...messages, modelMessage];
        await _saveHistory();
      }
    } on GeminiException catch (e) {
      errorMessage = e.message; // 已知的 AI 錯誤
    } on TimeoutException {
      errorMessage = '請求逾時，請檢查網路連線';
    } on SocketException {
      errorMessage = '網路連線失敗';
    } catch (e) {
      errorMessage = '發生未知錯誤：$e'; // 其他意外錯誤
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 幫我推薦路線 ──────────────────────────────────────────
  Future<void> suggestRoute() async {
    final city = currentCity ?? '目前城市';
    await sendMessage(
      '請根據我目前在 $city 的位置，以及附近的景點、餐廳和超商，幫我規劃一條適合腳踏車的半日路線，包含出發點、途經景點、用餐建議和補給點。',
    );
  }

  // ── 清除對話 ──────────────────────────────────────────────
  Future<void> clearHistory() async {
    messages = [];
    errorMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // ── 持久化 ────────────────────────────────────────────────
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(messages.map((m) => m.toJson()).toList());
      debugPrint('AiChatController: 儲存對話 ${messages.length} 筆');
      await prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('AiChatController: 儲存對話失敗：$e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      debugPrint('AiChatController: 讀取對話，結果=$json');
      if (json == null) return;
      final list = jsonDecode(json) as List<dynamic>;
      messages = list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('AiChatController: 載入對話失敗：$e');
    }
  }
}
