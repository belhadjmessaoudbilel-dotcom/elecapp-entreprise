import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerProfilScreen extends StatelessWidget {
  const ManagerProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final company = app.company;

    return Scaffold(
      backgroundColor: EM.bg,
      appBar: AppBar(
        backgroundColor: EM.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/manager')),
        title: const Text('Mon profil'),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [

        // Avatar
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [EM.primary, EM.primaryLight])),
          child: Center(child: Text(
            app.userName.isNotEmpty ? app.userName.split(' ').map((w) => w[0]).join().toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          )),
        ),
        const SizedBox(height: 12),
        Text(app.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EM.text)),
        Text(app.userEmail, style: const TextStyle(color: EM.textMuted)),
        const SizedBox(height: 24),

        // Entreprise
        if (app.hasCompany) Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: EM.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mon entreprise', style: TextStyle(fontWeight: FontWeight.w700, color: EM.text, fontSize: 15)),
            const SizedBox(height: 10),
            _infoRow(Icons.business_outlined, company['name'] as String? ?? ''),
            if ((company['siret'] as String? ?? '').isNotEmpty)
              _infoRow(Icons.badge_outlined, 'SIRET : ${company['siret']}'),
            if ((company['address'] as String? ?? '').isNotEmpty)
              _infoRow(Icons.location_on_outlined, company['address'] as String),
            if ((company['phone'] as String? ?? '').isNotEmpty)
              _infoRow(Icons.phone_outlined, company['phone'] as String),
          ]),
        ),
        const SizedBox(height: 12),

        // Bouton entreprise
        _MenuTile(icon: Icons.business_outlined, label: 'Gérer mon entreprise', onTap: () => context.go('/manager/company')),
        const SizedBox(height: 32),

        // Déconnexion
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () async {
            await app.logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout, color: EM.danger),
          label: const Text('Se déconnecter', style: TextStyle(color: EM.danger, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: EM.danger),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        )),
      ])),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 16, color: EM.textMuted),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: EM.textMuted))),
    ]),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: EM.border)),
      child: Row(children: [
        Icon(icon, size: 20, color: EM.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: EM.text))),
        const Icon(Icons.chevron_right, color: EM.textMuted, size: 20),
      ]),
    ),
  );
}
