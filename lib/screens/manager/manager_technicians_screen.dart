import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerTechniciansScreen extends StatelessWidget {
  const ManagerTechniciansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final techs = app.techs;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.go('/manager')),
        title: Text('Techniciens (${techs.length})'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteModal(context),
        backgroundColor: EM.primary,
        icon: const Icon(Icons.email_outlined, color: Colors.white),
        label: const Text('Inviter par email',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InviteCodeCard(app: app),
          const SizedBox(height: 20),
          if (techs.isEmpty) ...[
            const SizedBox(height: 40),
            const Center(child: Column(children: [
              Icon(Icons.people_outline, size: 64, color: EM.border),
              SizedBox(height: 16),
              Text('Aucun technicien', style: TextStyle(color: EM.textMuted, fontSize: 16)),
              SizedBox(height: 8),
              Text('Partagez le code ci-dessus pour inviter vos techniciens.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: EM.textMuted, fontSize: 13)),
            ])),
          ] else ...[
            Text('Techniciens (${techs.length})',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: EM.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ...techs.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: e.key < techs.length - 1 ? 10 : 0),
              child: _TechCard(tech: e.value),
            )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showInviteModal(BuildContext context) {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EM.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: EM.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Inviter par email', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: EM.text)),
            const SizedBox(height: 6),
            const Text(
                'Le technicien recevra un email avec un lien pour créer son compte.',
                style: TextStyle(fontSize: 13, color: EM.textMuted)),
            const SizedBox(height: 20),
            _modalField(nameCtrl, 'Nom complet', Icons.person_outline),
            const SizedBox(height: 12),
            _modalField(emailCtrl, 'Email', Icons.email_outlined,
                kb: TextInputType.emailAddress),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: sending ? null : () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      emailCtrl.text.trim().isEmpty) return;
                  setModal(() => sending = true);
                  await context.read<AppProvider>().inviterTechnicien(
                      emailCtrl.text.trim(), nameCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invitation envoyée !'),
                        backgroundColor: EM.success));
                },
                child: sending
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text("Envoyer l'invitation",
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      emailCtrl.dispose();
    });
  }

  Widget _modalField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType kb = TextInputType.text}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: kb,
        style: const TextStyle(color: EM.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: EM.textMuted),
          prefixIcon: Icon(icon, color: EM.textMuted, size: 18),
          filled: true, fillColor: EM.surface2,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EM.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EM.primary, width: 1.8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
      content: Text('Code copié !'),
      duration: Duration(seconds: 2),
      backgroundColor: EM.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.app.company['invite_code'] as String?;
    final hasCode = code != null && code.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6C), Color(0xFF0D2147)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EM.primary.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.vpn_key_outlined, color: EM.accent, size: 20),
          SizedBox(width: 8),
          Text('Code d\'invitation',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        const SizedBox(height: 6),
        const Text(
            'Partagez ce code avec vos techniciens. Ils le saisiront lors de leur inscription.',
            style: TextStyle(fontSize: 12, color: EM.textMuted)),
        const SizedBox(height: 18),

        if (hasCode) ...[
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EM.accent.withValues(alpha: 0.4)),
                ),
                child: Text(code,
                    style: const TextStyle(
                        color: EM.accent, fontSize: 26,
                        fontWeight: FontWeight.w900, letterSpacing: 6)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _copy(code),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: EM.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EM.accent.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.copy_outlined, color: EM.accent, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: EM.textMuted))
                : const Icon(Icons.refresh, size: 16, color: EM.textMuted),
            label: const Text('Générer un nouveau code',
                style: TextStyle(fontSize: 12, color: EM.textMuted)),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.generating_tokens_outlined, size: 18),
              label: const Text('Générer le code',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: EM.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ── Tech card ─────────────────────────────────────────────────────────────────

class _TechCard extends StatelessWidget {
  final Map<String, dynamic> tech;
  const _TechCard({required this.tech});

  @override
  Widget build(BuildContext context) {
    final statut   = tech['statut'] as String? ?? 'inactif';
    final isPending = statut == 'en_attente';
    final isActive  = statut == 'actif';
    final name     = tech['name'] as String? ?? '';
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join()
        .toUpperCase();

    Color statusColor = isActive
        ? EM.success
        : isPending
            ? EM.accent
            : EM.textMuted;
    String statusLabel = isActive
        ? 'Disponible'
        : isPending
            ? 'En attente'
            : 'Indisponible';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: EM.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isPending
                  ? EM.accent.withValues(alpha: 0.4)
                  : EM.border)),
      child: Row(children: [
        Container(
          width: 46, height: 46,
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
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(
              fontWeight: FontWeight.w700, color: EM.text)),
          Text(tech['email'] as String? ?? '',
              style: const TextStyle(fontSize: 12, color: EM.textMuted)),
          if ((tech['specialite'] as String? ?? '').isNotEmpty)
            Text(tech['specialite'] as String,
                style: const TextStyle(fontSize: 12, color: EM.accent)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(
                shape: BoxShape.circle, color: statusColor)),
            const SizedBox(width: 4),
            Text(statusLabel, style: TextStyle(
                fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}
