import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerStatsScreen extends StatelessWidget {
  const ManagerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final interventions = app.interventions;
    final devis = app.devis;

    final terminees  = interventions.where((i) => i['statut'] == 'termine').length;
    final enCours    = interventions.where((i) => i['statut'] == 'en_cours').length;
    final planifiees = interventions.where((i) => i['statut'] == 'assigne' || i['statut'] == 'planifie').length;
    final total      = interventions.length;

    final devisEnvoyes  = devis.length;
    final devisAcceptes = devis.where((d) => d['statut'] == 'accepte' || d['statut'] == 'payee').length;
    final tauxConv      = devisEnvoyes > 0 ? (devisAcceptes / devisEnvoyes * 100).toStringAsFixed(0) : '0';

    final ca = devis.where((d) => d['statut'] == 'payee').fold<double>(0, (s, d) => s + ((d['montant'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/manager')),
        title: const Text('Statistiques'),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // CA
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: EM.primary, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Chiffre d\'affaires total', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text('${ca.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Sur $devisAcceptes devis acceptés', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats dévis
        Row(children: [
          Expanded(child: _StatBox(label: 'Devis envoyés', value: '$devisEnvoyes', color: EM.accent)),
          const SizedBox(width: 12),
          Expanded(child: _StatBox(label: 'Taux conversion', value: '$tauxConv%', color: EM.primary)),
        ]),
        const SizedBox(height: 12),

        // Interventions
        const Text('Interventions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EM.text)),
        const SizedBox(height: 10),
        _MissionBar(label: 'Terminées', count: terminees, total: total, color: EM.success),
        const SizedBox(height: 8),
        _MissionBar(label: 'En cours', count: enCours, total: total, color: EM.primary),
        const SizedBox(height: 8),
        _MissionBar(label: 'Planifiées', count: planifiees, total: total, color: EM.warning),
        const SizedBox(height: 24),

        // Techs
        const Text('Techniciens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EM.text)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatBox(label: 'Total', value: '${app.techs.length}', color: EM.text)),
          const SizedBox(width: 12),
          Expanded(child: _StatBox(label: 'Disponibles', value: '${app.techsDisponibles}', color: EM.success)),
        ]),
        const SizedBox(height: 80),
      ])),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: EM.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: EM.textMuted)),
    ]),
  );
}

class _MissionBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _MissionBar({required this.label, required this.count, required this.total, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: EM.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: EM.text)),
          const Spacer(),
          Text('$count', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
          value: pct, minHeight: 6,
          backgroundColor: EM.border,
          valueColor: AlwaysStoppedAnimation(color),
        )),
      ]),
    );
  }
}
