import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerDemandesScreen extends StatelessWidget {
  const ManagerDemandesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final demandes = app.demandes;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        title: Row(children: [
          const Text('Demandes clients'),
          if (app.demandesNonVues > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: EM.danger, borderRadius: BorderRadius.circular(100)),
              child: Text('${app.demandesNonVues} new', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/manager')),
      ),
      body: demandes.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inbox_outlined, size: 64, color: EM.border),
              SizedBox(height: 16),
              Text('Aucune demande reçue', style: TextStyle(color: EM.textMuted, fontSize: 16)),
              SizedBox(height: 8),
              Text('Les demandes des clients apparaîtront ici', style: TextStyle(color: EM.textMuted, fontSize: 13)),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: demandes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _DemandeCard(
                demande: demandes[i],
                onTap: () => context.go('/manager/demandes/${demandes[i]['id']}'),
              ),
            ),
    );
  }
}

class _DemandeCard extends StatelessWidget {
  final Map<String, dynamic> demande;
  final VoidCallback onTap;
  const _DemandeCard({required this.demande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nonVu = demande['vu'] == false;
    final urgence = demande['urgence'] == true;
    final statut = demande['statut'] as String? ?? 'nouvelle';

    Color statutColor;
    String statutLabel;
    switch (statut) {
      case 'nouvelle':    statutColor = EM.primary; statutLabel = 'Nouveau'; break;
      case 'en_attente':  statutColor = EM.warning; statutLabel = 'En attente'; break;
      case 'traitee':     statutColor = EM.success; statutLabel = 'Traité'; break;
      default:            statutColor = EM.textMuted; statutLabel = statut;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: nonVu ? EM.primary.withValues(alpha: 0.04) : EM.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: nonVu ? EM.primary.withValues(alpha: 0.3) : EM.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(demande['type'] as String? ?? 'Intervention',
              style: const TextStyle(fontWeight: FontWeight.w700, color: EM.text, fontSize: 15))),
            if (urgence) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: EM.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
              child: const Text('URGENT', style: TextStyle(fontSize: 10, color: EM.danger, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statutColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
              child: Text(statutLabel, style: TextStyle(fontSize: 11, color: statutColor, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: EM.textMuted),
            const SizedBox(width: 4),
            Expanded(child: Text(demande['adresse'] as String? ?? '', style: const TextStyle(fontSize: 13, color: EM.textMuted))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: EM.textMuted),
            const SizedBox(width: 4),
            Text('${demande['date'] ?? ''} ${demande['heure'] ?? ''}', style: const TextStyle(fontSize: 13, color: EM.textMuted)),
          ]),
          if ((demande['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(demande['description'] as String, style: const TextStyle(fontSize: 13, color: EM.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Envoyer mon devis', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: EM.primary, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
