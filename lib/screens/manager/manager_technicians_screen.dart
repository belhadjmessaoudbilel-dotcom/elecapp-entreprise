import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerTechniciansScreen extends StatelessWidget {
  const ManagerTechniciansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final techs = app.techs;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/manager')),
        title: Text('Techniciens (${techs.length})'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteModal(context),
        backgroundColor: EM.primary,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Inviter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: techs.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.people_outline, size: 64, color: EM.border),
              const SizedBox(height: 16),
              const Text('Aucun technicien', style: TextStyle(color: EM.textMuted, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Invitez vos techniciens par email', style: TextStyle(color: EM.textMuted, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showInviteModal(context),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Inviter un technicien'),
                style: ElevatedButton.styleFrom(backgroundColor: EM.primary, foregroundColor: Colors.white, minimumSize: const Size(200, 46)),
              ),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: techs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _TechCard(tech: techs[i]),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: EM.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Inviter un technicien', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EM.text)),
            const SizedBox(height: 6),
            const Text('Le technicien recevra un email pour créer son compte et rejoindre votre entreprise.', style: TextStyle(fontSize: 13, color: EM.textMuted)),
            const SizedBox(height: 20),
            _modalField(nameCtrl, 'Nom complet', Icons.person_outline),
            const SizedBox(height: 12),
            _modalField(emailCtrl, 'Email', Icons.email_outlined, kb: TextInputType.emailAddress),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: sending ? null : () async {
                  if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                  setModal(() => sending = true);
                  await context.read<AppProvider>().inviterTechnicien(emailCtrl.text.trim(), nameCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation envoyée !'), backgroundColor: EM.success));
                },
                child: sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer l\'invitation', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    ).whenComplete(() { nameCtrl.dispose(); emailCtrl.dispose(); });
  }

  Widget _modalField(TextEditingController ctrl, String label, IconData icon, {TextInputType kb = TextInputType.text}) =>
    TextFormField(
      controller: ctrl, keyboardType: kb,
      style: const TextStyle(color: EM.text),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: EM.textMuted),
        prefixIcon: Icon(icon, color: EM.textMuted, size: 18),
        filled: true, fillColor: EM.surface2,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.primary, width: 1.8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

class _TechCard extends StatelessWidget {
  final Map<String, dynamic> tech;
  const _TechCard({required this.tech});

  @override
  Widget build(BuildContext context) {
    final statut = tech['statut'] as String? ?? 'inactif';
    final dispo = statut == 'actif';
    final name = tech['name'] as String? ?? '';
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: EM.border)),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [EM.primary, EM.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Center(child: Text(initials.isEmpty ? '?' : initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: EM.text)),
          Text(tech['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: EM.textMuted)),
          if ((tech['specialite'] as String? ?? '').isNotEmpty)
            Text(tech['specialite'] as String, style: const TextStyle(fontSize: 12, color: EM.accent)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: dispo ? EM.success.withValues(alpha: 0.1) : EM.textMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dispo ? EM.success : EM.textMuted)),
            const SizedBox(width: 4),
            Text(dispo ? 'Disponible' : 'Indisponible', style: TextStyle(fontSize: 11, color: dispo ? EM.success : EM.textMuted, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}
