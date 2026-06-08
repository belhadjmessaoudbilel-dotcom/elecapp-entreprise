import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/supabase_service.dart';

class ManagerMissionChatScreen extends StatefulWidget {
  final String interventionId;
  final String clientName;
  final String techName;
  const ManagerMissionChatScreen({
    super.key,
    required this.interventionId,
    required this.clientName,
    required this.techName,
  });
  @override State<ManagerMissionChatScreen> createState() => _State();
}

class _State extends State<ManagerMissionChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool  _sending = false;
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final msgs = await SupabaseService.fetchInterventionMessages(widget.interventionId);
    if (!mounted) return;
    setState(() => _messages = msgs);
    _scrollToBottom();
    _channel = SupabaseService.subscribeToInterventionMessages(
      widget.interventionId,
      (row) {
        if (mounted) {
          setState(() => _messages = [..._messages, row]);
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      },
    );
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    final managerName = context.read<AppProvider>().userName;
    await SupabaseService.sendInterventionMessage(
      interventionId: widget.interventionId,
      managerName:    managerName.isNotEmpty ? managerName : 'Manager',
      content:        text,
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/manager/conversations'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.clientName} & ${widget.techName}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          const Text('Client · Tech · Manager',
              style: TextStyle(fontSize: 10, color: EM.textMuted)),
        ]),
      ),
      body: Column(children: [
        // Participants legend
        Container(
          color: EM.surface2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Legend(color: EM.textMuted, label: 'Client'),
            const SizedBox(width: 16),
            _Legend(color: EM.accent, label: 'Tech'),
            const SizedBox(width: 16),
            _Legend(color: EM.primary, label: 'Manager (moi)'),
          ]),
        ),

        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: EM.border),
                  const SizedBox(height: 12),
                  Text(
                    'Conversation avec ${widget.clientName} et ${widget.techName}',
                    style: const TextStyle(color: EM.textMuted, fontSize: 13),
                    textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg  = _messages[i];
                    final prev = i > 0 ? _messages[i - 1] : null;
                    final showDate = prev == null ||
                        !_sameDay(prev['created_at'], msg['created_at']);
                    return Column(children: [
                      if (showDate) _DateSeparator(msg['created_at'] as String),
                      _Bubble(msg: msg,
                          clientName: widget.clientName,
                          techName:   widget.techName),
                    ]);
                  },
                ),
        ),

        // Saisie
        Container(
          color: EM.surface,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 14, color: EM.text),
                decoration: InputDecoration(
                  hintText: 'Votre message…',
                  hintStyle: const TextStyle(color: EM.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: EM.surface2,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _sending ? EM.border : EM.primary,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  bool _sameDay(String a, String b) {
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.year == db.year && da.month == db.month && da.day == db.day;
    } catch (_) { return false; }
  }
}

// ── Légende participants ──────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  ]);
}

// ── Bulle de message ──────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final String clientName;
  final String techName;
  const _Bubble({
    required this.msg,
    required this.clientName,
    required this.techName,
  });

  @override
  Widget build(BuildContext context) {
    final fromRole = msg['from_role'] as String? ?? 'client';
    final fromName = msg['from_name'] as String? ?? '';
    final text     = msg['text']      as String? ?? '';
    final time     = _formatTime(msg['created_at'] as String? ?? '');

    final isMe     = fromRole == 'manager';
    final isTech   = fromRole == 'technician';

    final bubbleColor = isMe    ? EM.primary
                      : isTech  ? EM.accent.withValues(alpha: 0.15)
                      : EM.surface;
    final textColor   = isMe    ? Colors.white
                      : EM.text;

    final avatarColor = isTech ? EM.accent : EM.textMuted;
    final avatarLabel = fromName.isNotEmpty ? fromName[0].toUpperCase() : '?';
    final senderLabel = isMe ? '' : (isTech ? 'Tech · $fromName' : 'Client · $fromName');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: avatarColor.withValues(alpha: 0.2),
              child: Text(avatarLabel, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: avatarColor)),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isTech
                    ? Border.all(color: EM.accent.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (senderLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(senderLabel, style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: avatarColor)),
                  ),
                Text(text, style: TextStyle(fontSize: 14, color: textColor)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white54 : EM.textMuted)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }
}

// ── Séparateur de date ────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String raw;
  const _DateSeparator(this.raw);
  @override
  Widget build(BuildContext context) {
    String label = '';
    try {
      final d    = DateTime.parse(raw).toLocal();
      final now  = DateTime.now();
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(d.year, d.month, d.day)).inDays;
      label = diff == 0 ? "Aujourd'hui"
            : diff == 1 ? 'Hier'
            : '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) {}
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: EM.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: const TextStyle(
              fontSize: 11, color: EM.textMuted, fontWeight: FontWeight.w600)),
        ),
        const Expanded(child: Divider(color: EM.border)),
      ]),
    );
  }
}
