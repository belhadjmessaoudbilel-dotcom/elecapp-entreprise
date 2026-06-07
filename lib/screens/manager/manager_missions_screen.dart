import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerMissionsScreen extends StatelessWidget {
  const ManagerMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final devisAcceptes  = app.devisAcceptes;
    final interventions  = app.interventions;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/manager')),
        title: const Text('Interventions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: () async {
              await context.read<AppProvider>().reloadDevis();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Devis acceptés ───────────────────────────────────────────────
          if (devisAcceptes.isNotEmpty) ...[
            Row(children: [
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: EM.success, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Devis acceptés — à planifier (${devisAcceptes.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EM.text)),
            ]),
            const SizedBox(height: 10),
            ...devisAcceptes.map((d) => _DevisAccepteCard(
              devis: d,
              techs: app.techs,
              onAssigner: (techId, date, heure) async {
                final ok = await context.read<AppProvider>().creerMission(
                  demandeId: d['demande_id'] as String? ?? '',
                  techId:    techId,
                  demande:   d,
                  date:      date,
                  heure:     heure,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Intervention créée et assignée !' : 'Erreur lors de la création'),
                    backgroundColor: ok ? EM.success : EM.danger,
                  ));
                }
              },
            )),
            const SizedBox(height: 24),
          ],

          // ── Missions en cours ─────────────────────────────────────────────
          Row(children: [
            const Icon(Icons.build_outlined, size: 16, color: EM.primary),
            const SizedBox(width: 8),
            Text('Interventions (${interventions.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: EM.text)),
          ]),
          const SizedBox(height: 10),

          if (interventions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: EM.border)),
              child: const Column(children: [
                Icon(Icons.assignment_outlined, size: 48, color: EM.border),
                SizedBox(height: 12),
                Text('Aucune intervention en cours', style: TextStyle(color: EM.textMuted, fontSize: 14)),
                SizedBox(height: 4),
                Text('Les interventions apparaîtront ici une fois un technicien assigné', style: TextStyle(color: EM.textMuted, fontSize: 12), textAlign: TextAlign.center),
              ]),
            )
          else
            ...interventions.map((i) => _MissionCard(intervention: i, techs: app.techs)),

          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _BottomNav(index: 2),
    );
  }
}

// ── Devis accepté card ────────────────────────────────────────────────────────

class _DevisAccepteCard extends StatelessWidget {
  final Map<String, dynamic> devis;
  final List<Map<String, dynamic>> techs;
  final Future<void> Function(String techId, String date, String heure) onAssigner;

  const _DevisAccepteCard({required this.devis, required this.techs, required this.onAssigner});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: EM.success.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: EM.success.withValues(alpha: 0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.check_circle_outline, color: EM.success, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(
          devis['objet'] as String? ?? devis['type'] as String? ?? 'Devis accepté',
          style: const TextStyle(fontWeight: FontWeight.w700, color: EM.text, fontSize: 14),
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: EM.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
          child: const Text('Accepté', style: TextStyle(fontSize: 11, color: EM.success, fontWeight: FontWeight.w700)),
        ),
      ]),
      if ((devis['adresse'] as String? ?? '').isNotEmpty) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 13, color: EM.textMuted),
          const SizedBox(width: 4),
          Expanded(child: Text(devis['adresse'] as String, style: const TextStyle(fontSize: 12, color: EM.textMuted))),
        ]),
      ],
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.euro_outlined, size: 13, color: EM.textMuted),
        const SizedBox(width: 4),
        Text('${(devis['montant'] as num?)?.toStringAsFixed(2) ?? '0.00'} € TTC',
            style: const TextStyle(fontSize: 12, color: EM.textMuted, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: techs.isEmpty
              ? null
              : () => _showAssignerModal(context),
          icon: const Icon(Icons.person_add_outlined, size: 16),
          label: Text(techs.isEmpty ? 'Aucun technicien disponible' : 'Assigner un technicien',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: EM.primary, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ]),
  );

  void _showAssignerModal(BuildContext context) {
    String? selectedTechId;
    final dateCtrl  = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final heureCtrl = TextEditingController(text: '09:00');
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
            const Text('Assigner un technicien', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EM.text)),
            const SizedBox(height: 6),
            Text(devis['objet'] as String? ?? '', style: const TextStyle(fontSize: 13, color: EM.textMuted)),
            const SizedBox(height: 20),

            // Sélecteur tech
            DropdownButtonFormField<String>(
              value: selectedTechId,
              dropdownColor: EM.surface,
              decoration: InputDecoration(
                labelText: 'Technicien *',
                labelStyle: const TextStyle(color: EM.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.person_outline, color: EM.textMuted, size: 18),
                filled: true, fillColor: EM.surface2,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.primary, width: 1.8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              hint: const Text('Choisir un technicien', style: TextStyle(color: EM.textMuted)),
              items: techs.map((t) => DropdownMenuItem<String>(
                value: t['id'] as String?,
                child: Row(children: [
                  Text(t['name'] as String? ?? '', style: const TextStyle(color: EM.text)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t['statut'] == 'actif' ? EM.success.withValues(alpha: 0.1) : EM.textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(t['statut'] == 'actif' ? 'Dispo' : 'Indispo',
                        style: TextStyle(fontSize: 10, color: t['statut'] == 'actif' ? EM.success : EM.textMuted)),
                  ),
                ]),
              )).toList(),
              onChanged: (v) => setModal(() => selectedTechId = v),
            ),
            const SizedBox(height: 12),

            // Date et heure
            Row(children: [
              Expanded(child: _modalField(dateCtrl, 'Date', Icons.calendar_today_outlined, kb: TextInputType.datetime)),
              const SizedBox(width: 10),
              Expanded(child: _modalField(heureCtrl, 'Heure', Icons.schedule_outlined)),
            ]),
            const SizedBox(height: 20),

            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: (sending || selectedTechId == null) ? null : () async {
                  setModal(() => sending = true);
                  await onAssigner(selectedTechId!, dateCtrl.text.trim(), heureCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: EM.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Créer l'intervention", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    ).whenComplete(() { dateCtrl.dispose(); heureCtrl.dispose(); });
  }

  Widget _modalField(TextEditingController ctrl, String label, IconData icon, {TextInputType kb = TextInputType.text}) =>
    TextFormField(
      controller: ctrl, keyboardType: kb,
      style: const TextStyle(color: EM.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: EM.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: EM.textMuted, size: 18),
        filled: true, fillColor: EM.surface2,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.primary, width: 1.8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

// ── Mission card ──────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final Map<String, dynamic> intervention;
  final List<Map<String, dynamic>> techs;
  const _MissionCard({required this.intervention, required this.techs});

  @override
  Widget build(BuildContext context) {
    final statut = intervention['statut'] as String? ?? 'assigne';
    final techId = intervention['tech_id'] as String?;
    final tech   = techs.where((t) => t['id'] == techId).firstOrNull;

    Color statutColor;
    String statutLabel;
    switch (statut) {
      case 'assigne':   statutColor = EM.primary;   statutLabel = 'Assigné';    break;
      case 'en_cours':  statutColor = EM.warning;   statutLabel = 'En cours';   break;
      case 'termine':   statutColor = EM.success;   statutLabel = 'Terminé';    break;
      default:          statutColor = EM.textMuted; statutLabel = statut;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: EM.border)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: statutColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.build_outlined, color: statutColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(intervention['type'] as String? ?? 'Intervention',
              style: const TextStyle(fontWeight: FontWeight.w700, color: EM.text, fontSize: 14)),
          Text(intervention['adresse'] as String? ?? '',
              style: const TextStyle(fontSize: 12, color: EM.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (tech != null) Row(children: [
            const Icon(Icons.person_outline, size: 12, color: EM.textMuted),
            const SizedBox(width: 3),
            Text(tech['name'] as String? ?? '', style: const TextStyle(fontSize: 11, color: EM.textMuted)),
          ]),
          Text('${intervention['date'] ?? ''} ${intervention['heure'] ?? ''}',
              style: const TextStyle(fontSize: 11, color: EM.textMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statutColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
          child: Text(statutLabel, style: TextStyle(fontSize: 11, color: statutColor, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── Bottom Nav (dupliqué localement pour éviter import circulaire) ────────────

class _BottomNav extends StatelessWidget {
  final int index;
  const _BottomNav({required this.index});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: EM.surface, border: Border(top: BorderSide(color: EM.border))),
    child: SafeArea(child: Row(children: [
      _NavItem(icon: Icons.home_outlined,      label: 'Accueil',   selected: index == 0, onTap: () => context.go('/manager')),
      _NavItem(icon: Icons.inbox_outlined,     label: 'Demandes',  selected: index == 1, onTap: () => context.go('/manager/demandes')),
      _NavItem(icon: Icons.assignment_outlined, label: 'Interven.',  selected: index == 2, onTap: () => context.go('/manager/missions')),
      _NavItem(icon: Icons.people_outline,     label: 'Techs',     selected: index == 3, onTap: () => context.go('/manager/technicians')),
      _NavItem(icon: Icons.person_outline,     label: 'Profil',    selected: index == 4, onTap: () => context.go('/manager/profil')),
    ])),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22, color: selected ? EM.primary : EM.textMuted),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: selected ? EM.primary : EM.textMuted, fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      ])),
  ));
}
