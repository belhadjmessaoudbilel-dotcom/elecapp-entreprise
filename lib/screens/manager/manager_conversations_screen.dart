import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerConversationsScreen extends StatefulWidget {
  const ManagerConversationsScreen({super.key});
  @override State<ManagerConversationsScreen> createState() => _State();
}

class _State extends State<ManagerConversationsScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await context.read<AppProvider>().reloadTechs();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final convs = app.canal2Conversations;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/manager'),
        ),
        title: Text('Conversations (${convs.length})'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 22),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
      body: convs.isEmpty
          ? _EmptyState(onRefresh: _refresh)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: convs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ConvCard(conv: convs[i]),
            ),
    );
  }
}

// ── Carte conversation ────────────────────────────────────────────────────────

class _ConvCard extends StatelessWidget {
  final Map<String, dynamic> conv;
  const _ConvCard({required this.conv});

  @override
  Widget build(BuildContext context) {
    final interventionId = conv['id']          as String? ?? '';
    final clientName     = conv['client_name'] as String? ?? 'Client';
    final techName       = conv['tech_name']   as String? ?? 'Technicien';
    final type           = conv['type']        as String? ?? '';
    final adresse        = conv['adresse']     as String? ?? '';
    final statut         = conv['statut']      as String? ?? '';
    final date           = conv['date']        as String? ?? '';

    final statusColor = statut == 'en_cours'  ? EM.primary
                      : statut == 'termine'   ? EM.textMuted
                      : EM.accent;
    final statusLabel = statut == 'en_cours'  ? 'En cours'
                      : statut == 'termine'   ? 'Terminée'
                      : statut == 'planifie'  ? 'Planifiée'
                      : statut;

    return GestureDetector(
      onTap: () => context.go(
        '/manager/conversations/$interventionId'
        '?client=${Uri.encodeComponent(clientName)}'
        '&tech=${Uri.encodeComponent(techName)}',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EM.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EM.border),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: EM.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_alt_outlined,
                color: EM.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(clientName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: EM.text))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ]),
            if (type.isNotEmpty)
              Text(type, style: const TextStyle(fontSize: 12, color: EM.accent)),
            Row(children: [
              const Icon(Icons.person_outline, size: 12, color: EM.textMuted),
              const SizedBox(width: 3),
              Text('Tech: $techName',
                  style: const TextStyle(fontSize: 11, color: EM.textMuted)),
              if (date.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today_outlined,
                    size: 11, color: EM.textMuted),
                const SizedBox(width: 3),
                Text(date.length >= 10 ? date.substring(0, 10) : date,
                    style: const TextStyle(fontSize: 11, color: EM.textMuted)),
              ],
            ]),
            if (adresse.isNotEmpty)
              Text(adresse,
                  style: const TextStyle(fontSize: 11, color: EM.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right, color: EM.border, size: 20),
        ]),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.forum_outlined, size: 56, color: EM.border),
        const SizedBox(height: 16),
        const Text('Aucune conversation active',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: EM.text)),
        const SizedBox(height: 8),
        const Text(
          'Les conversations s\'ouvrent lorsqu\'un\ntechnicien est assigné et le devis est payé.',
          style: TextStyle(color: EM.textMuted, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          onPressed: onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: EM.primary,
            side: const BorderSide(color: EM.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    ),
  );
}
