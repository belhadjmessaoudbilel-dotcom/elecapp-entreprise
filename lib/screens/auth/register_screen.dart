import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _State();
}

class _State extends State<RegisterScreen> {
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _showPass = false, _loading = false;

  Future<void> _register() async {
    if (_name.text.trim().isEmpty) return _snack('Nom requis');
    if (_email.text.trim().isEmpty) return _snack('Email requis');
    if (_pass.text.length < 8) return _snack('Mot de passe : 8 caractères minimum');
    setState(() => _loading = true);
    final ok = await context.read<AppProvider>().register(_email.text.trim(), _pass.text, _name.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) return _snack('Erreur lors de l\'inscription. Cet email est peut-être déjà utilisé.');
    context.go('/pending');
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: EM.danger));

  @override
  void dispose() { _name.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: EM.text),
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 16),
        const Text('Créer votre compte', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EM.text)),
        const SizedBox(height: 6),
        const Text('Rejoignez elecapp en tant que gérant d\'entreprise', style: TextStyle(color: EM.textMuted, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: EM.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: EM.primary.withValues(alpha: 0.2))),
          child: const Row(children: [
            Icon(Icons.info_outline, color: EM.primary, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('Votre compte sera validé par notre équipe sous 24h avant activation.', style: TextStyle(fontSize: 12, color: EM.primary))),
          ]),
        ),
        const SizedBox(height: 24),

        _field(ctrl: _name,  label: 'Nom complet',   icon: Icons.person_outline),
        const SizedBox(height: 14),
        _field(ctrl: _email, label: 'Email',          icon: Icons.email_outlined, kb: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(
          ctrl: _pass, label: 'Mot de passe (8 car. min.)', icon: Icons.lock_outlined,
          obscure: !_showPass,
          suffix: IconButton(
            icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: EM.textMuted),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _register,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Déjà un compte ? ', style: TextStyle(color: EM.textMuted)),
          GestureDetector(onTap: () => context.go('/login'),
            child: const Text('Se connecter', style: TextStyle(color: EM.primary, fontWeight: FontWeight.w700))),
        ])),
      ]),
    )),
  );

  Widget _field({required TextEditingController ctrl, required String label, required IconData icon, bool obscure = false, Widget? suffix, TextInputType kb = TextInputType.text}) =>
    TextFormField(
      controller: ctrl, obscureText: obscure, keyboardType: kb,
      style: const TextStyle(color: EM.text),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: EM.textMuted),
        prefixIcon: Icon(icon, color: EM.textMuted, size: 20), suffixIcon: suffix,
        filled: true, fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EM.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EM.primary, width: 1.8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}
