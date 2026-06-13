import 'package:flutter/material.dart';
import '../controller/ai_chat_controller.dart';
import '../models/chat_message.dart';
import '../widgets/error_snack_bar.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../widgets/safe_asset_image.dart';
import '../widgets/show_agent_info.dart';

class AiChatPage extends StatefulWidget {
  final AiChatController controller;

  const AiChatPage({super.key, required this.controller});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
    // 有錯誤時顯示 SnackBar
    if (widget.controller.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(ErrorSnackBar(message: widget.controller.errorMessage!));
      });
    }
    // 新訊息後自動滾到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await widget.controller.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RideVoyage AI',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF6B7280)),
            tooltip: '清除對話',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('清除對話'),
                  content: const Text('確定要清除所有對話記錄嗎？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('清除'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await controller.clearHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          //顯示擷取到的目前城市資訊、景點、餐廳數量等等
          if (controller.currentCity != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${controller.currentCity} ${controller.currentArea ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.nearbyScenics.length} 景點・'
                    '${controller.nearbyRestaurants.length} 餐廳・'
                    '${controller.nearbyStores.length} 超商',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // ── 對話列表 ──────────────────────────────────────
          Expanded(
            child: controller.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount:
                        controller.messages.length +
                        (controller.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(controller.messages[index]);
                    },
                  ),
          ),

          // ── 錯誤訊息 ──────────────────────────────────────
          if (controller.errorMessage != null)
            Container(
              color: const Color(0xFFFEF2F2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // ── 輸入區 ────────────────────────────────────────
          _buildInputArea(controller),
        ],
      ),
    );
  }

  // ── 空狀態提示 ─────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              showAgentProfileModal(context);
            },
            child: Container(
              //padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const SafeAssetImage(
                assetPath: 'assets/images/agent_image.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '你好！我是你的路線助手',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '問我任何關於腳踏車路線的問題\n或點下方按鈕讓我幫你規劃路線',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            GestureDetector(
              onTap: () {
                showAgentProfileModal(context);
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SafeAssetImage(
                  assetPath: 'assets/images/agent_image.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? SelectableText(
                      message.content,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white, // 使用者氣泡底色是藍色，字體固定為白
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      // AI 的回覆在白色底色上，直接用預設 Markdown 樣式就極度漂亮
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF111827), // AI 回覆的字體顏色
                              height: 1.5,
                            ),
                            // 確保 AI 吐出的粗體字也是正確的深色，且不會過大
                            strong: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            // 移除 Markdown 內部多餘的肥大邊距，緊貼你的白氣泡
                            pPadding: EdgeInsets.zero,
                            blockSpacing: 8,
                          ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea(AiChatController controller) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        children: [
          // 推薦路線按鈕
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isLoading ? null : controller.suggestRoute,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('幫我推薦路線'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 輸入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !controller.isLoading,
                  decoration: InputDecoration(
                    hintText: '輸入問題...',
                    hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: controller.isLoading ? null : _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: controller.isLoading
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: controller.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

// 這個小元件用來顯示 AI 正在回應的動畫
class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SafeAssetImage(
              assetPath: 'assets/images/agent_image.png',
              width: 40,
              height: 40,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  // 每個點的動畫延遲不同，做出波浪感
                  final delay = i / 3;
                  final t = (_controller.value - delay) % 1.0;
                  final bounce = t < 0.5 ? 2 * t : 2 * (1 - t);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    transform: Matrix4.translationValues(0, -6 * bounce, 0),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(0xFFD1D5DB),
                        const Color(0xFF3B82F6),
                        bounce,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildTypingIndicator() {
  return const _TypingIndicator();
}
