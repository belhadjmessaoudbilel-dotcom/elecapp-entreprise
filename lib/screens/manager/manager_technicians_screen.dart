import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerTechniciansScreen extends StatefulWidget {
  const ManagerTechniciansScreen({super.key});
  @override State<ManagerTechniciansScreen> createState() => _State();
}

class _State extends State<ManagerTechniciansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().reloadTechs();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await context.read<AppProvider>().reloadTechs();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final tous = app.techs;
    final dispo  = app.techsDisponiblesList;
    final enMission = app.techsEnMission;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.go('/manager')),
        title: Text('Techniciens (${tous.length})'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 22),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: EM.primary,
          unselectedLabelColor: EM.textMuted,
          indicatorColor: EM.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Disponibles (${dispo.length})'),
            Tab(text: 'En mission (${enMission.length})'),
            Tab(text: 'Tous (${tous.length})'),
          ],
        ),
      ),
      body: Column(children: [
        _InviteCodeCard(app: app),
        Expanded(child: TabBarView(
          controller: _tabs,
          children: [
            _TechList(techs: dispo,     mode: _TechMode.disponible, onAssign: _showAssignModal),
            _TechList(techs: enMission, mode: _TechMode.enMission,  onAssign: null),
            _TechList(techs: tous,      mode: _TechMode.tous,       onAssign: _showAssignModal),
          ],
        )),
      ]),
    );
  }

  void _showAssignModal(BuildContext ctx, Map<String, dynamic> tech) {
    final app = ctx.read<AppProvider>();
    final interventions = app.interventionsNonAssignees;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: EM.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AssignModal(
        tech: tech,
        interventions: interventions,
        onAssign: (interventionId) async {
          Navigator.pop(ctx);
          final ok = await app.assignerTech(interventionId, tech['id'] as String);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(ok
                  ? '${tech['name']} assigné avec succès'
                  : 'Erreur lors de l\'assignation'),
              backgroundColor: ok ? EM.success : EM.danger,
            ));
          }
        },
      ),
    );
  }
}

// ── Liste de techs ────────────────────────────────────────────────────────────

enum _TechMode { disponible, enMission, tous }

class _TechList extends StatelessWidget {
  final List<Map<String, dynamic>> techs;
  final _TechMode mode;
  final void Function(BuildContext, Map<String, dynamic>)? onAssign;

  const _TechList({required this.techs, required this.mode, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    if (techs.isEmpty) {
      final msg = mode == _TechMode.disponible
          ? 'Aucun technicien disponible'
          : mode == _TechMode.enMission
              ? 'Aucun technicien en mission'
              : 'Aucun technicien dans cette entreprise';
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline, size: 56, color: EM.border),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: EM.textMuted, fontSize: 14)),
        if (mode == _TechMode.disponible || mode == _TechMode.tous) ...[
          const SizedBox(height: 8),
          const Text('Partagez le code d\'invitation ci-dessus.',
              style: TextStyle(color: EM.textMuted, fontSize: 12)),
        ],
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: techs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _TechCard(
        tech: techs[i], mode: mode,
        onAssign: onAssign != null ? () => onAssign!(ctx, techs[i]) : null,
      ),
    );
  }
}

// ── Tech card ─────────────────────────────────────────────────────────────────

class _TechCard extends StatelessWidget {
  final Map<String, dynamic> tech;
  final _TechMode mode;
  final VoidCallback? onAssign;
  const _TechCard({required this.tech, required this.mode, this.onAssign});

  @override
  Widget build(BuildContext context) {
    final name           = tech['name']            as String? ?? '';
    final email          = tech['email']           as String? ?? '';
    final specialite     = tech['specialite']      as String? ?? '';
    final zone           = tech['zone']            as String? ?? '';
    final missionsActives = (tech['missions_actives'] as num?)?.toInt() ?? 0;
    final missionClient  = tech['mission_client']  as String? ?? '';
    final missionAdresse = tech['mission_adresse'] as String? ?? '';
    final initials       = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    final isDisponible = missionsActives == 0;
    final statusColor  = isDisponible ? EM.success : EM.accent;
    final statusLabel  = isDisponible ? 'Disponible' : 'En mission ($missionsActives)';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: EM.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDisponible
              ? EM.success.withValues(alpha: 0.25)
              : EM.accent.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [EM.primary, EM.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Center(child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(
                fontWeight: FontWeight.w700, color: EM.text, fontSize: 14)),
            if (email.isNotEmpty)
              Text(email, style: const TextStyle(fontSize: 11, color: EM.textMuted)),
          ])),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
              const SizedBox(width: 4),
              Text(statusLabel, style: TextStyle(
                  fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),

        if (specialite.isNotEmpty || zone.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: [
            if (specialite.isNotEmpty) _Chip(specialite, Icons.bolt_outlined, EM.accent),
            if (zone.isNotEmpty)       _Chip(zone, Icons.location_on_outlined, EM.textMuted),
          ]),
        ],

        // Mission en cours
        if (!isDisponible && (missionClient.isNotEmpty || missionAdresse.isNotEmpty)) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: EM.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EM.accent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.build_outlined, size: 14, color: EM.accent),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (missionClient.isNotEmpty)
                  Text(missionClient, style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: EM.text)),
                if (missionAdresse.isNotEmpty)
                  Text(missionAdresse, style: const TextStyle(
                      fontSize: 11, color: EM.textMuted)),
              ])),
            ]),
          ),
        ],

        // Actions : Assigner + Message
        const SizedBox(height: 12),
        Row(children: [
          // Bouton Message (toujours visible)
          Expanded(
            child: SizedBox(height: 38,
              child: OutlinedButton.icon(
                onPressed: () {
                  final techId = tech['id'] as String? ?? '';
                  context.go('/manager/chat/$techId?name=${Uri.encodeComponent(name)}');
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 15),
                label: const Text('Message',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EM.accent,
                  side: BorderSide(color: EM.accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          // Bouton Assigner (seulement pour techs disponibles)
          if (isDisponible && onAssign != null) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(height: 38,
                child: ElevatedButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.assignment_ind_outlined, size: 15),
                  label: const Text('Assigner',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EM.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Chip(this.text, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 3),
    Text(text, style: TextStyle(fontSize: 11, color: color)),
  ]);
}

// ── Modal assignation ─────────────────────────────────────────────────────────

class _AssignModal extends StatelessWidget {
  final Map<String, dynamic> tech;
  final List<Map<String, dynamic>> interventions;
  final void Function(String) onAssign;
  const _AssignModal({required this.tech, required this.interventions, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    final name = tech['name'] as String? ?? '';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: EM.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Assigner $name', style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: EM.text)),
        const SizedBox(height: 4),
        const Text('Choisissez une intervention à assigner',
            style: TextStyle(fontSize: 13, color: EM.textMuted)),
        const SizedBox(height: 16),
        if (interventions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: EM.surface2, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text(
                'Aucune intervention en attente d\'assignation.',
                style: TextStyle(color: EM.textMuted, fontSize: 13),
                textAlign: TextAlign.center)),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: interventions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final iv     = interventions[i];
                final client = iv['client_name'] as String? ?? '—';
                final adresse= iv['adresse']     as String? ?? '';
                final date   = iv['date']        as String? ?? '';
                final type   = iv['type']        as String? ?? '';
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onAssign(iv['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EM.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EM.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: EM.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.build_outlined, size: 18, color: EM.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(client, style: const TextStyle(
                            fontWeight: FontWeight.w700, color: EM.text, fontSize: 13)),
                        if (type.isNotEmpty)
                          Text(type, style: const TextStyle(
                              fontSize: 11, color: EM.accent)),
                        if (adresse.isNotEmpty)
                          Text(adresse, style: const TextStyle(
                              fontSize: 11, color: EM.textMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      if (date.isNotEmpty)
                        Text(date.length >= 10 ? date.substring(0, 10) : date,
                            style: const TextStyle(fontSize: 11, color: EM.textMuted)),
                    ]),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 46,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: EM.textMuted,
              side: const BorderSide(color: EM.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Annuler'),
          ),
        ),
      ]),
    );
  }
}

// ── Invite code card ──────────────────────────────────────────────────────────

class _InviteCodeCard extends StatefulWidget {
  final AppProvider app;
  const _InviteCodeCard({required this.app});
  @override State<_InviteCodeCard> createState() => _InviteCodeCardState();
}

class _InviteCodeCardState extends State<_InviteCodeCard> {
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);
    await widget.app.generateInviteCode();
    if (mounted) setState(() => _generating = false);
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Code copié !'), duration: Duration(seconds: 2),
        backgroundColor: EM.success));
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.app.company['invite_code'] as String?;
    final hasCode = code != null && code.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A3A6C), Color(0xFF0D2147)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EM.primary.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.vpn_key_outlined, color: EM.accent, size: 18),
        const SizedBox(width: 10),
        Expanded(child: hasCode
            ? Text(code, style: const TextStyle(
                color: EM.accent, fontSize: 22,
                fontWeight: FontWeight.w900, letterSpacing: 5))
            : const Text('Aucun code — génère-en un',
                style: TextStyle(color: EM.textMuted, fontSize: 13))),
        if (hasCode) ...[
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: EM.accent, size: 20),
            tooltip: 'Copier',
            onPressed: () => _copy(code),
          ),
        ],
        _generating
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: EM.accent))
            : IconButton(
                icon: Icon(
                    hasCode ? Icons.refresh : Icons.generating_tokens_outlined,
                    color: EM.accent, size: 20),
                tooltip: hasCode ? 'Nouveau code' : 'Générer',
                onPressed: _generate,
              ),
      ]),
    );
  }
}
