import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/supabase_service.dart';

class ManagerDirectChatScreen extends StatefulWidget {
  final String techId;
  final String techName;
  const ManagerDirectChatScreen({
    super.key,
    required this.techId,
    required this.techName,
  });
  @override State<ManagerDirectChatScreen> createState() => _State();
}

class _State extends State<ManagerDirectChatScreen> {
  final _ctrl     = TextEditingController();
  final _scroll   = ScrollController();
  bool  _sending  = false;
  List<Map<String, dynamic>> _messages = [];

  String get _convId => SupabaseService.convId(
      context.read<AppProvider>().companyId ?? '', widget.techId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final msgs = await context.read<AppProvider>().loadDirectMessages(widget.techId);
    if (!mounted) return;
    setState(() => _messages = msgs);
    _scrollToBottom();
    await context.read<AppProvider>().markDirectRead(widget.techId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app  = context.watch<AppProvider>();
    final msgs = app.directMessages[_convId];
    if (msgs != null && msgs.length != _messages.length) {
      setState(() => _messages = msgs);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
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
    await context.read<AppProvider>().sendDirectMessage(widget.techId, text);
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AppProvider>().userId;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/manager/technicians'),
        ),
        title: Row(children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: EM.primary.withValues(alpha: 0.15),
            child: Text(
              widget.techName.isNotEmpty ? widget.techName[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: EM.primary),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.techName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Text('Technicien',
                style: TextStyle(fontSize: 11, color: EM.textMuted)),
          ]),
        ]),
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: EM.border),
                  const SizedBox(height: 12),
                  Text('Début de la conversation avec ${widget.techName}',
                      style: const TextStyle(color: EM.textMuted, fontSize: 13),
                      textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg    = _messages[i];
                    final isMe   = msg['sender_id'] == myId;
                    final prev   = i > 0 ? _messages[i - 1] : null;
                    final showDate = prev == null ||
                        !_sameDay(prev['created_at'], msg['created_at']);
                    return Column(children: [
                      if (showDate) _DateSeparator(msg['created_at'] as String),
                      _MessageBubble(msg: msg, isMe: isMe),
                    ]);
                  },
                ),
        ),

        // Messages prédéfinis
        _QuickReplies(onTap: (text) {
          _ctrl.text = text;
          _ctrl.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length));
        }),

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

// ── Bulle de message ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final content    = msg['content']        as String? ?? '';
    final attachUrl  = msg['attachment_url'] as String?;
    final attachType = msg['attachment_type'] as String?;
    final time       = _formatTime(msg['created_at'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: EM.accent.withValues(alpha: 0.15),
              child: Text(
                (msg['sender_name'] as String? ?? '?').isNotEmpty
                    ? (msg['sender_name'] as String)[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: EM.accent),
              ),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? EM.primary : EM.surface,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(color: EM.shadow, blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(msg['sender_name'] as String? ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isMe ? Colors.white70 : EM.accent)),
                  ),
                if (attachUrl != null && attachType == 'image')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(attachUrl, width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                  ),
                if (attachUrl != null && attachType == 'file')
                  Row(children: [
                    Icon(Icons.attach_file, size: 16,
                        color: isMe ? Colors.white70 : EM.textMuted),
                    const SizedBox(width: 4),
                    Text('Fichier joint', style: TextStyle(
                        fontSize: 13,
                        color: isMe ? Colors.white : EM.text)),
                  ]),
                if (content.isNotEmpty)
                  Text(content, style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : EM.text)),
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

// ── Messages prédéfinis ───────────────────────────────────────────────────────

class _QuickReplies extends StatelessWidget {
  final void Function(String) onTap;
  const _QuickReplies({required this.onTap});

  static const _replies = [
    'En route 🚗',
    'Mission terminée ✅',
    'Besoin de matériel 🔧',
    'Retard prévu ⏱',
    'Appelle-moi 📞',
  ];

  @override
  Widget build(BuildContext context) => Container(
    color: EM.surface,
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
    child: SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(_replies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EM.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EM.primary.withValues(alpha: 0.2)),
            ),
            child: Text(_replies[i], style: const TextStyle(
                fontSize: 12, color: EM.primary, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    ),
  );
}
