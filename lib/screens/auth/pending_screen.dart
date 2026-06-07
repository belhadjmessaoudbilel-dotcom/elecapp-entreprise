import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: EM.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.hourglass_top_rounded, color: EM.primary, size: 48),
        ),
        const SizedBox(height: 32),
        const Text('Compte en cours de validation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EM.text), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('Notre équipe examine votre demande d\'accès. Vous recevrez un email de confirmation sous 24h.', style: TextStyle(color: EM.textMuted, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: EM.surface2, borderRadius: BorderRadius.circular(16), border: Border.all(color: EM.border)),
          child: Column(children: [
            _step('1', 'Votre compte a été créé', true),
            const SizedBox(height: 12),
            _step('2', 'Validation par notre équipe', false),
            const SizedBox(height: 12),
            _step('3', 'Accès à votre espace gérant', false),
          ]),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () async {
            await context.read<AppProvider>().logout();
            if (context.mounted) context.go('/login');
          },
          child: const Text('Se déconnecter', style: TextStyle(color: EM.textMuted)),
        ),
      ]),
    )),
  );

  Widget _step(String num, String label, bool done) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? EM.primary : EM.border,
      ),
      child: Center(child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(num, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EM.textMuted))),
    ),
    const SizedBox(width: 12),
    Text(label, style: TextStyle(color: done ? EM.text : EM.textMuted, fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
  ]);
}
