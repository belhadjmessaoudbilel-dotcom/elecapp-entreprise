import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _showPass = false, _loading = false;

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      _snack('Veuillez remplir tous les champs');
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AppProvider>().login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      _snack('Email ou mot de passe incorrect');
      return;
    }
    final app = context.read<AppProvider>();
    context.go(app.isPending ? '/pending' : '/manager');
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: EM.danger));

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 32),
        Image.asset('assets/images/logo1.png', width: 120, height: 120),
        const SizedBox(height: 24),
        const Text('Espace Gérant', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EM.text)),
        const SizedBox(height: 6),
        const Text('Connectez-vous à votre espace entreprise', style: TextStyle(color: EM.textMuted)),
        const SizedBox(height: 40),

        _field(ctrl: _email, label: 'Email', icon: Icons.email_outlined, kb: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _field(
          ctrl: _pass, label: 'Mot de passe', icon: Icons.lock_outlined,
          obscure: !_showPass,
          suffix: IconButton(
            icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: EM.textMuted),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Pas encore de compte ? ', style: TextStyle(color: EM.textMuted)),
          GestureDetector(
            onTap: () => context.go('/register'),
            child: const Text('Créer un compte', style: TextStyle(color: EM.primary, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    )),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType kb = TextInputType.text,
  }) => TextFormField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: kb,
    style: const TextStyle(color: EM.text),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: EM.textMuted),
      prefixIcon: Icon(icon, color: EM.textMuted, size: 20),
      suffixIcon: suffix,
      filled: true, fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EM.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EM.primary, width: 1.8)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
