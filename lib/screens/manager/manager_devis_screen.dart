import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ManagerDevisScreen extends StatefulWidget {
  final String demandeId;
  final Map<String, dynamic>? demande;
  const ManagerDevisScreen({super.key, required this.demandeId, this.demande});
  @override State<ManagerDevisScreen> createState() => _State();
}

class _State extends State<ManagerDevisScreen> {
  final _objet      = TextEditingController();
  final _delai      = TextEditingController();
  final _validite   = TextEditingController();
  final _conditions = TextEditingController();
  final _notes      = TextEditingController();

  final List<Map<String, dynamic>> _lignes = [];
  bool _saving = false;
  double _tvaRate = 20.0;

  double get _totalHT => _lignes.fold(0, (sum, l) {
    final qte  = (l['quantite'] as double? ?? 0);
    final prix = (l['prix_unitaire'] as double? ?? 0);
    return sum + (qte * prix);
  });
  double get _tva   => _totalHT * (_tvaRate / 100);
  double get _totalTTC => _totalHT + _tva;

  @override
  void initState() {
    super.initState();
    final d = widget.demande;
    if (d != null) {
      _objet.text = 'Devis pour ${d['type'] ?? 'intervention'} - ${d['adresse'] ?? ''}';
    }
    _tvaRate = context.read<AppProvider>().company['tva_rate'] as double? ?? 20.0;
    _ajouterLigne();
  }

  void _ajouterLigne() {
    setState(() => _lignes.add({
      'description': TextEditingController(),
      'quantite': TextEditingController(text: '1'),
      'unite': TextEditingController(text: 'u'),
      'prix_unitaire': TextEditingController(),
    }));
  }

  void _supprimerLigne(int i) {
    if (_lignes.length <= 1) return;
    setState(() => _lignes.removeAt(i));
  }

  Future<void> _envoyer() async {
    if (_objet.text.trim().isEmpty) return _snack('Objet requis');
    if (_lignes.isEmpty) return _snack('Ajoutez au moins une ligne');
    setState(() => _saving = true);

    final lignesData = _lignes.map((l) => {
      'description':   (l['description'] as TextEditingController).text,
      'quantite':      double.tryParse((l['quantite'] as TextEditingController).text) ?? 1,
      'unite':         (l['unite'] as TextEditingController).text,
      'prix_unitaire': double.tryParse((l['prix_unitaire'] as TextEditingController).text) ?? 0,
    }).toList();

    final now = DateTime.now();
    final ok = await context.read<AppProvider>().envoyerDevis(widget.demandeId, {
      'objet':               _objet.text.trim(),
      'lignes':              lignesData,
      'montant':             _totalTTC,
      'tva_rate':            _tvaRate,
      'delai_execution':     _delai.text.trim(),
      'date_validite':       _validite.text.trim(),
      'conditions_paiement': _conditions.text.trim(),
      'notes':               _notes.text.trim(),
      'statut':              'envoye',
      'client_name':         widget.demande?['client_name'] ?? '',
      'client_email':        widget.demande?['client_email'] ?? '',
      'date_emission':       '${now.day}/${now.month}/${now.year}',
    });

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devis envoyé !'), backgroundColor: EM.success));
      context.go('/manager/demandes');
    } else {
      _snack('Erreur lors de l\'envoi');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: EM.danger));

  @override
  void dispose() {
    _objet.dispose(); _delai.dispose(); _validite.dispose();
    _conditions.dispose(); _notes.dispose();
    for (final l in _lignes) {
      (l['description'] as TextEditingController).dispose();
      (l['quantite'] as TextEditingController).dispose();
      (l['unite'] as TextEditingController).dispose();
      (l['prix_unitaire'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: EM.bg,
    appBar: AppBar(
      backgroundColor: EM.surface,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
      title: const Text('Créer un devis'),
      actions: [
        Padding(padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: _saving ? null : _envoyer,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: EM.primary))
                : const Text('Envoyer', style: TextStyle(color: EM.primary, fontWeight: FontWeight.w800, fontSize: 15)),
          )),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Infos demande
        if (widget.demande != null) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: EM.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: EM.primary.withValues(alpha: 0.2))),
          child: Row(children: [
            const Icon(Icons.info_outline, color: EM.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Pour : ${widget.demande!['type']} — ${widget.demande!['adresse']}',
              style: const TextStyle(fontSize: 13, color: EM.primary))),
          ]),
        ),
        const SizedBox(height: 16),

        _section('Informations générales'),
        _field(_objet, 'Objet du devis', Icons.subject_outlined, required: true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _field(_delai, 'Délai d\'exécution', Icons.schedule_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _field(_validite, 'Validité jusqu\'au', Icons.event_outlined)),
        ]),
        const SizedBox(height: 20),

        _section('Prestations'),
        ..._lignes.asMap().entries.map((e) => _LigneWidget(
          ligne: e.value, index: e.key,
          onDelete: () => _supprimerLigne(e.key),
          onChanged: () => setState(() {}),
        )),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _ajouterLigne,
          icon: const Icon(Icons.add, color: EM.primary),
          label: const Text('Ajouter une ligne', style: TextStyle(color: EM.primary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),

        // Total
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: EM.border)),
          child: Column(children: [
            _totalRow('Total HT', '${_totalHT.toStringAsFixed(2)} €'),
            const SizedBox(height: 6),
            _totalRow('TVA (${_tvaRate.toStringAsFixed(0)}%)', '${_tva.toStringAsFixed(2)} €'),
            const Divider(height: 16, color: EM.border),
            _totalRow('Total TTC', '${_totalTTC.toStringAsFixed(2)} €', bold: true),
          ]),
        ),
        const SizedBox(height: 20),

        _section('Conditions'),
        _field(_conditions, 'Conditions de paiement', Icons.payments_outlined),
        const SizedBox(height: 10),
        _field(_notes, 'Notes', Icons.notes_outlined, maxLines: 3),
        const SizedBox(height: 40),
      ]),
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EM.primary, letterSpacing: 0.3)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool required = false, int maxLines = 1}) =>
    TextFormField(
      controller: ctrl, maxLines: maxLines,
      style: const TextStyle(color: EM.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: const TextStyle(color: EM.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: EM.textMuted, size: 18),
        filled: true, fillColor: EM.surface,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: EM.primary, width: 1.8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

  Widget _totalRow(String label, String value, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: bold ? EM.text : EM.textMuted, fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
      Text(value, style: TextStyle(color: bold ? EM.primary : EM.text, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 16 : 14)),
    ],
  );
}

class _LigneWidget extends StatelessWidget {
  final Map<String, dynamic> ligne;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  const _LigneWidget({required this.ligne, required this.index, required this.onDelete, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: EM.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: EM.border)),
    child: Column(children: [
      Row(children: [
        Text('Ligne ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: EM.text, fontSize: 13)),
        const Spacer(),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline, color: EM.danger, size: 18)),
      ]),
      const SizedBox(height: 8),
      _input(ligne['description'] as TextEditingController, 'Description', onChanged: onChanged),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(flex: 2, child: _input(ligne['quantite'] as TextEditingController, 'Qté', kb: TextInputType.number, onChanged: onChanged)),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: _input(ligne['unite'] as TextEditingController, 'Unité', onChanged: onChanged)),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _input(ligne['prix_unitaire'] as TextEditingController, 'Prix unit. (€)', kb: TextInputType.number, onChanged: onChanged)),
      ]),
    ]),
  );

  Widget _input(TextEditingController ctrl, String hint, {TextInputType kb = TextInputType.text, VoidCallback? onChanged}) =>
    TextFormField(
      controller: ctrl, keyboardType: kb,
      style: const TextStyle(color: EM.text, fontSize: 13),
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: EM.textMuted, fontSize: 13),
        filled: true, fillColor: EM.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: EM.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: EM.primary, width: 1.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
}
