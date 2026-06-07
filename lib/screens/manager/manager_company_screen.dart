import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/supabase_service.dart';

class ManagerCompanyScreen extends StatefulWidget {
  const ManagerCompanyScreen({super.key});
  @override State<ManagerCompanyScreen> createState() => _State();
}

class _State extends State<ManagerCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _siret;
  late final TextEditingController _rcs;
  late final TextEditingController _tvaNumber;
  late final TextEditingController _capitalSocial;
  late final TextEditingController _ape;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _siteWeb;
  late final TextEditingController _iban;
  late final TextEditingController _tvRate;
  late final TextEditingController _insurance;
  late final TextEditingController _garantie;

  String? _formeJuridique;
  String? _logoUrl;
  bool _saving        = false;
  bool _uploadingLogo = false;

  static const _formes = ['EI', 'Auto-entrepreneur', 'SARL', 'SAS', 'EURL', 'SNC'];

  @override
  void initState() {
    super.initState();
    final c = context.read<AppProvider>().company;
    _name          = TextEditingController(text: c['name']           as String? ?? '');
    _siret         = TextEditingController(text: c['siret']          as String? ?? '');
    _rcs           = TextEditingController(text: c['rcs']            as String? ?? '');
    _tvaNumber     = TextEditingController(text: c['tva_number']     as String? ?? '');
    _capitalSocial = TextEditingController(text: c['capital_social'] as String? ?? '');
    _ape           = TextEditingController(text: c['ape']            as String? ?? '');
    _address       = TextEditingController(text: c['address']        as String? ?? '');
    _phone         = TextEditingController(text: c['phone']          as String? ?? '');
    _email         = TextEditingController(text: c['email']          as String? ?? '');
    _siteWeb       = TextEditingController(text: c['site_web']       as String? ?? '');
    _iban          = TextEditingController(text: c['iban']           as String? ?? '');
    _tvRate        = TextEditingController(text: (c['tva_rate'] ?? '20.0').toString());
    _insurance     = TextEditingController(text: c['insurance']      as String? ?? '');
    _garantie      = TextEditingController(text: c['garantie']       as String? ?? '');
    _formeJuridique = c['forme_juridique'] as String?;
    if (_formeJuridique != null && !_formes.contains(_formeJuridique)) {
      _formeJuridique = null;
    }
    _logoUrl = c['logo_url'] as String?;
  }

  @override
  void dispose() {
    for (final c in [_name, _siret, _rcs, _tvaNumber, _capitalSocial, _ape,
        _address, _phone, _email, _siteWeb, _iban, _tvRate, _insurance, _garantie]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _uploadingLogo = true);
    try {
      final bytes     = await picked.readAsBytes();
      final ext       = picked.name.split('.').last.toLowerCase();
      final companyId = context.read<AppProvider>().company['id'] as String?
          ?? SupabaseService.currentUserId ?? 'temp';
      final url = await SupabaseService.uploadCompanyLogo(companyId, bytes, ext);
      if (url != null && mounted) setState(() => _logoUrl = url);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ok = await context.read<AppProvider>().saveCompany({
        'name':            _name.text.trim(),
        'forme_juridique': _formeJuridique ?? '',
        'siret':           _siret.text.trim(),
        'rcs':             _rcs.text.trim(),
        'tva_number':      _tvaNumber.text.trim(),
        'capital_social':  _capitalSocial.text.trim(),
        'ape':             _ape.text.trim(),
        'address':         _address.text.trim(),
        'phone':           _phone.text.trim(),
        'email':           _email.text.trim(),
        'site_web':        _siteWeb.text.trim(),
        'iban':            _iban.text.trim(),
        'tva_rate':        double.tryParse(_tvRate.text) ?? 20.0,
        'insurance':       _insurance.text.trim(),
        'garantie':        _garantie.text.trim(),
        if (_logoUrl != null && _logoUrl!.isNotEmpty) 'logo_url': _logoUrl!,
      });
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Entreprise enregistrée'),
          backgroundColor: EM.success,
        ));
        context.go('/manager/profil');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur : impossible de sauvegarder. Vérifiez votre connexion.'),
          backgroundColor: EM.danger,
          duration: Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: EM.bg,
    appBar: AppBar(
      backgroundColor: EM.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => context.go('/manager/profil'),
      ),
      title: const Text('Mon entreprise'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: EM.primary))
                : const Text('Enregistrer',
                    style: TextStyle(color: EM.primary, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ],
    ),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Logo ───────────────────────────────────────────────────────────
          Center(child: GestureDetector(
            onTap: _uploadingLogo ? null : _pickLogo,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: EM.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: EM.border),
              ),
              child: _uploadingLogo
                  ? const Center(child: CircularProgressIndicator(color: EM.primary, strokeWidth: 2))
                  : _logoUrl != null && _logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(_logoUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.business_outlined, color: EM.textMuted, size: 48)))
                      : const Icon(Icons.business_outlined, color: EM.textMuted, size: 48),
            ),
          )),
          const SizedBox(height: 8),
          const Center(child: Text('Appuyer pour changer le logo',
              style: TextStyle(fontSize: 12, color: EM.textMuted))),
          const SizedBox(height: 28),

          // ── Identité légale ────────────────────────────────────────────────
          _Section('Identité légale'),
          _Field(ctrl: _name, label: 'Raison sociale', icon: Icons.business_outlined, required: true),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Forme juridique',
            icon: Icons.account_balance_outlined,
            value: _formeJuridique,
            items: _formes,
            onChanged: (v) => setState(() => _formeJuridique = v),
          ),
          const SizedBox(height: 12),
          _Field(ctrl: _siret, label: 'SIRET', icon: Icons.badge_outlined, kb: TextInputType.number),
          const SizedBox(height: 12),
          _Field(ctrl: _rcs, label: 'N° RCS', icon: Icons.account_balance_outlined),
          const SizedBox(height: 12),
          _Field(ctrl: _tvaNumber, label: 'N° TVA intracommunautaire', icon: Icons.receipt_outlined),
          const SizedBox(height: 12),
          _Field(ctrl: _capitalSocial, label: 'Capital social', icon: Icons.euro_outlined),
          const SizedBox(height: 12),
          _Field(ctrl: _ape, label: 'Code APE / NAF', icon: Icons.category_outlined),
          const SizedBox(height: 28),

          // ── Coordonnées ────────────────────────────────────────────────────
          _Section('Coordonnées'),
          _Field(ctrl: _address, label: 'Adresse du siège', icon: Icons.location_on_outlined,
              required: true, maxLines: 2),
          const SizedBox(height: 12),
          _Field(ctrl: _phone, label: 'Téléphone professionnel', icon: Icons.phone_outlined,
              kb: TextInputType.phone),
          const SizedBox(height: 12),
          _Field(ctrl: _email, label: 'Email professionnel', icon: Icons.email_outlined,
              kb: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _Field(ctrl: _siteWeb, label: 'Site web', icon: Icons.language_outlined,
              kb: TextInputType.url),
          const SizedBox(height: 28),

          // ── Finance ────────────────────────────────────────────────────────
          _Section('Finance'),
          _Field(ctrl: _iban, label: 'IBAN', icon: Icons.account_balance_wallet_outlined),
          const SizedBox(height: 12),
          _Field(ctrl: _tvRate, label: 'Taux TVA (%)', icon: Icons.percent_outlined,
              kb: TextInputType.number),
          const SizedBox(height: 28),

          // ── Assurance ──────────────────────────────────────────────────────
          _Section('Assurance & Garanties'),
          _Field(ctrl: _insurance, label: 'Assurance décennale', icon: Icons.security_outlined),
          const SizedBox(height: 12),
          _Field(ctrl: _garantie, label: 'Garanties', icon: Icons.verified_outlined, maxLines: 2),
          const SizedBox(height: 40),
        ]),
      ),
    ),
  );
}

// ── Widgets locaux ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(title, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w800,
      color: EM.primary, letterSpacing: 0.5,
    )),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool required;
  final TextInputType kb;
  final int maxLines;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.required = false,
    this.kb = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: kb,
    maxLines: maxLines,
    style: const TextStyle(color: EM.text, fontSize: 14),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
        : null,
    decoration: InputDecoration(
      labelText: label + (required ? ' *' : ''),
      labelStyle: const TextStyle(color: EM.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: EM.textMuted, size: 18),
      filled: true,
      fillColor: EM.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EM.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EM.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EM.primary, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EM.danger)),
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    dropdownColor: EM.surface,
    style: const TextStyle(color: EM.text, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: EM.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: EM.textMuted, size: 18),
      filled: true,
      fillColor: EM.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EM.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EM.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EM.primary, width: 1.8)),
    ),
    hint: const Text('Sélectionner', style: TextStyle(color: EM.textMuted)),
    items: items.map((f) => DropdownMenuItem(
      value: f,
      child: Text(f, style: const TextStyle(color: EM.text)),
    )).toList(),
    onChanged: onChanged,
  );
}
