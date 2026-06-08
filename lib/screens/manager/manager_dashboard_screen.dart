import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final demandesAttente = app.demandes.where((d) => d['statut'] == 'nouvelle' || d['statut'] == 'en_attente').length;
    final devisEnvoyes    = app.devis.length;
    final missionsEnCours = app.interventions.where((i) => i['statut'] == 'en_cours').length;
    final techsDispo      = app.techsDisponibles;
    final nonVues         = app.demandesNonVues;

    return Scaffold(
      backgroundColor: EM.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: EM.surface,
          pinned: true,
          elevation: 0,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bonjour ${app.userName.split(' ').first} !',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EM.text)),
            if (app.hasCompany)
              Text(app.company['name'] as String? ?? '',
                  style: const TextStyle(fontSize: 12, color: EM.textMuted)),
          ]),
          actions: [
            IconButton(
              icon: Stack(children: [
                const Icon(Icons.notifications_outlined, color: EM.text),
                if (nonVues > 0) Positioned(top: 0, right: 0,
                  child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: EM.danger, shape: BoxShape.circle))),
              ]),
              onPressed: () => context.go('/manager/demandes'),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // Stats 2×2
            GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _StatCard(label: 'Demandes reçues', value: '$demandesAttente', icon: Icons.inbox_outlined, color: EM.primary, badge: nonVues > 0 ? nonVues : null),
                _StatCard(label: 'Devis envoyés', value: '$devisEnvoyes', icon: Icons.description_outlined, color: EM.accent),
                _StatCard(label: 'Interventions', value: '$missionsEnCours', icon: Icons.build_outlined, color: EM.warning),
                _StatCard(label: 'Techs disponibles', value: '$techsDispo', icon: Icons.people_outline, color: EM.success),
              ],
            ),
            const SizedBox(height: 24),

            // Dernières demandes
            if (app.demandes.isNotEmpty) ...[
              Row(children: [
                const Text('Dernières demandes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EM.text)),
                const Spacer(),
                GestureDetector(onTap: () => context.go('/manager/demandes'),
                  child: const Text('Voir tout', style: TextStyle(fontSize: 13, color: EM.primary, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 12),
              ...app.demandes.take(3).map((d) => _DemandeTile(
                demande: d,
                onTap: () => context.go('/manager/demandes'),
              )),
              const SizedBox(height: 16),
            ],

            // Accès rapides
            const Text('Accès rapide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EM.text)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickAction(icon: Icons.inbox_outlined, label: 'Demandes', badge: nonVues, onTap: () => context.go('/manager/demandes'))),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(icon: Icons.people_outline, label: 'Techniciens', onTap: () => context.go('/manager/technicians'))),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(icon: Icons.bar_chart_outlined, label: 'Statistiques', onTap: () => context.go('/manager/stats'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickAction(icon: Icons.forum_outlined, label: 'Conversations', badge: app.canal2Conversations.length, onTap: () => context.go('/manager/conversations'))),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
            ]),
            const SizedBox(height: 80),
          ])),
        ),
      ]),
      bottomNavigationBar: _BottomNav(index: 0),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final int? badge;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.badge});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: EM.border)),
    child: Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: EM.textMuted)),
      ]),
      if (badge != null) Positioned(top: 0, right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: EM.danger, borderRadius: BorderRadius.circular(100)),
          child: Text('$badge', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
        )),
    ]),
  );
}

class _DemandeTile extends StatelessWidget {
  final Map<String, dynamic> demande;
  final VoidCallback onTap;
  const _DemandeTile({required this.demande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nonVu = demande['vu'] == false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: nonVu ? EM.primary.withValues(alpha: 0.05) : EM.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: nonVu ? EM.primary.withValues(alpha: 0.3) : EM.border),
        ),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: nonVu ? EM.primary : EM.border)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(demande['type'] as String? ?? 'Intervention', style: const TextStyle(fontWeight: FontWeight.w600, color: EM.text)),
            Text(demande['adresse'] as String? ?? '', style: const TextStyle(fontSize: 12, color: EM.textMuted)),
          ])),
          if (demande['urgence'] == true)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: EM.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
              child: const Text('URGENT', style: TextStyle(fontSize: 10, color: EM.danger, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 80,
      decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: EM.border)),
      child: Stack(alignment: Alignment.center, children: [
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: EM.primary, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EM.text)),
        ]),
        if (badge > 0) Positioned(top: 8, right: 8,
          child: Container(width: 18, height: 18,
            decoration: const BoxDecoration(color: EM.danger, shape: BoxShape.circle),
            child: Center(child: Text('$badge', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800))))),
      ]),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  final int index;
  const _BottomNav({required this.index});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: EM.surface, border: Border(top: BorderSide(color: EM.border))),
    child: SafeArea(child: Row(children: [
      _NavItem(icon: Icons.home_outlined,       label: 'Accueil',  selected: index == 0, onTap: () => context.go('/manager')),
      _NavItem(icon: Icons.inbox_outlined,      label: 'Demandes', selected: index == 1, onTap: () => context.go('/manager/demandes')),
      _NavItem(icon: Icons.assignment_outlined, label: 'Interven.', selected: index == 2, onTap: () => context.go('/manager/missions')),
      _NavItem(icon: Icons.people_outline,      label: 'Techs',    selected: index == 3, onTap: () => context.go('/manager/technicians')),
      _NavItem(icon: Icons.person_outline,      label: 'Profil',   selected: index == 4, onTap: () => context.go('/manager/profil')),
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
