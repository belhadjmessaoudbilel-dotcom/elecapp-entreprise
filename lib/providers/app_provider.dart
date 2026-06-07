import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userStatut;  // 'en_attente' | 'actif' | 'inactif'
  String? _userRole;

  Map<String, dynamic> _company    = {};
  String?              _companyId;

  List<Map<String, dynamic>> _demandes      = [];
  List<Map<String, dynamic>> _devis         = [];
  List<Map<String, dynamic>> _techs         = [];
  List<Map<String, dynamic>> _interventions = [];

  RealtimeChannel? _demandesChannel;
  RealtimeChannel? _devisChannel;

  // Getters
  bool    get isLoggedIn  => _userId != null;
  bool    get isPending   => _userStatut == 'en_attente';
  bool    get isActive    => _userStatut == 'actif';
  String  get userName    => _userName ?? '';
  String  get userEmail   => _userEmail ?? '';
  String? get companyId   => _companyId;
  bool    get hasCompany  => _companyId != null && (_company['name'] as String? ?? '').isNotEmpty;

  Map<String, dynamic>       get company       => Map.unmodifiable(_company);
  List<Map<String, dynamic>> get demandes      => List.unmodifiable(_demandes);
  List<Map<String, dynamic>> get devis         => List.unmodifiable(_devis);
  List<Map<String, dynamic>> get techs         => List.unmodifiable(_techs);
  List<Map<String, dynamic>> get interventions => List.unmodifiable(_interventions);

  int get demandesNonVues  => _demandes.where((d) => d['vu'] == false).length;
  int get techsDisponibles => _techs.where((t) =>
      t['statut'] == 'actif' && (t['missions_actives'] as num? ?? 0) == 0).length;

  List<Map<String, dynamic>> get techsDisponiblesList => _techs.where((t) =>
      t['statut'] == 'actif' && (t['missions_actives'] as num? ?? 0) == 0).toList();

  List<Map<String, dynamic>> get techsEnMission => _techs.where((t) =>
      (t['missions_actives'] as num? ?? 0) > 0).toList();

  List<Map<String, dynamic>> get interventionsNonAssignees => _interventions
      .where((i) => i['tech_id'] == null && i['statut'] != 'termine').toList();
  List<Map<String, dynamic>> get devisAcceptes =>
      _devis.where((d) => d['statut'] == 'accepte').toList();

  AppProvider() { _init(); }

  Future<void> _init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _loadUser(user.id);
      if (isActive) await _loadData();
    }
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null && _userId == null) {
        await _loadUser(user.id);
        if (isActive) await _loadData();
      } else if (user == null) {
        _clear();
      }
    });
  }

  Future<void> _loadUser(String userId) async {
    _userId = userId;
    final profile = await SupabaseService.fetchProfile(userId);
    if (profile != null) {
      _userName   = profile['name']   as String? ?? '';
      _userEmail  = profile['email']  as String? ?? '';
      _userStatut = profile['statut'] as String? ?? 'en_attente';
      _userRole   = profile['role']   as String? ?? 'manager';
      final companyId = profile['company_id'] as String?;
      if (companyId != null) {
        _companyId = companyId;
        _company   = await SupabaseService.fetchCompany(companyId) ?? {};
      }
    }
    notifyListeners();
  }

  Future<void> _loadData() async {
    if (_companyId == null) return;
    final baseResults = await Future.wait([
      SupabaseService.fetchDemandes(_companyId!),
      SupabaseService.fetchDevis(_companyId!),
      SupabaseService.fetchCompanyTechs(_companyId!),
    ]);
    _demandes = baseResults[0];
    _devis    = baseResults[1];
    _techs    = baseResults[2];
    // Charge les interventions en utilisant les IDs des techs déjà chargés
    final techIds = _techs.map((t) => t['id'] as String? ?? '').where((id) => id.isNotEmpty).toList();
    _interventions = await SupabaseService.fetchInterventionsByTechIds(techIds);
    notifyListeners();
    _subscribeToDemandes();
    _subscribeToDevis();
  }

  void _subscribeToDemandes() {
    if (_companyId == null) return;
    _demandesChannel?.unsubscribe();
    _demandesChannel = SupabaseService.subscribeToDemandes(_companyId!, (row) async {
      final demandes = await SupabaseService.fetchDemandes(_companyId!);
      _demandes = demandes;
      notifyListeners();
    });
  }

  void _subscribeToDevis() {
    if (_companyId == null) return;
    _devisChannel?.unsubscribe();
    _devisChannel = SupabaseService.subscribeToDevis(_companyId!, (row) async {
      final devis = await SupabaseService.fetchDevis(_companyId!);
      _devis = devis;
      notifyListeners();
    });
  }

  void _clear() {
    _demandesChannel?.unsubscribe();
    _devisChannel?.unsubscribe();
    _userId = _userName = _userEmail = _userStatut = _userRole = _companyId = null;
    _company = {};
    _demandes = _devis = _techs = _interventions = [];
    notifyListeners();
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    try {
      final res = await SupabaseService.signIn(email, password);
      if (res.user != null) {
        await _loadUser(res.user!.id);
        if (isActive) await _loadData();
        return true;
      }
    } catch (e) {
      debugPrint('[Entreprise] login error: $e');
    }
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      final res = await SupabaseService.signUp(email: email, password: password, name: name);
      if (res.user != null) {
        await _loadUser(res.user!.id);
        // Mettre statut en_attente dans profiles
        await SupabaseService.updateProfile(res.user!.id, {'statut': 'en_attente', 'role': 'manager'});
        _userStatut = 'en_attente';
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[Entreprise] register error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    try { await SupabaseService.signOut(); } catch (_) {}
    _clear();
  }

  // ── Company ───────────────────────────────────────────────────────────────

  Future<bool> saveCompany(Map<String, dynamic> data) async {
    if (_userId == null) return false;
    if (_companyId == null) {
      final newId = await SupabaseService.createCompany(_userId!, data);
      if (newId == null) return false;
      _companyId = newId;
      await SupabaseService.updateProfile(_userId!, {'company_id': newId});
    } else {
      await SupabaseService.updateCompany(_companyId!, data);
    }
    _company = {...data, 'id': _companyId};
    notifyListeners();
    return true;
  }

  // ── Devis ─────────────────────────────────────────────────────────────────

  Future<bool> envoyerDevis(String demandeId, Map<String, dynamic> data) async {
    if (_companyId == null) return false;
    final companyName = _company['name'] as String? ?? '';
    final id = await SupabaseService.createDevis(_companyId!, {
      ...data,
      'demande_id':   demandeId,
      'company_name': companyName,
    });
    if (id == null) return false;
    _devis = [{
      ...data,
      'id':           id,
      'company_id':   _companyId,
      'company_name': companyName,
      'demande_id':   demandeId,
    }, ..._devis];
    notifyListeners();
    return true;
  }

  // ── Techs ─────────────────────────────────────────────────────────────────

  Future<String?> generateInviteCode() async {
    if (_companyId == null) return null;
    final code = await SupabaseService.generateInviteCode(_companyId!);
    if (code != null) {
      _company = {..._company, 'invite_code': code};
      notifyListeners();
    }
    return code;
  }

  Future<void> inviterTechnicien(String email, String name) async {
    if (_companyId == null) return;
    await SupabaseService.inviteTechnician(email, name, _companyId!);
    // Recharger la liste après invitation
    _techs = await SupabaseService.fetchCompanyTechs(_companyId!);
    notifyListeners();
  }

  Future<void> reloadTechs() async {
    if (_companyId == null) return;
    _techs = await SupabaseService.fetchCompanyTechs(_companyId!);
    final techIds = _techs.map((t) => t['id'] as String? ?? '').where((id) => id.isNotEmpty).toList();
    _interventions = await SupabaseService.fetchInterventionsByTechIds(techIds);
    notifyListeners();
  }

  Future<bool> assignerTech(String interventionId, String techId) async {
    try {
      await SupabaseService.assignTech(interventionId, techId);
      await reloadTechs();
      return true;
    } catch (e) {
      debugPrint('[Entreprise] assignerTech error: $e');
      return false;
    }
  }

  Future<bool> creerMission({
    required String demandeId,
    required String techId,
    required Map<String, dynamic> demande,
    required String date,
    required String heure,
  }) async {
    if (_companyId == null) return false;
    final id = await SupabaseService.createIntervention({
      'client_name': demande['client_name'] ?? '',
      'client_phone': demande['client_phone'] ?? '',
      'type':        demande['type']        ?? '',
      'adresse':     demande['adresse']     ?? '',
      'description': demande['description'] ?? '',
      'date':        date,
      'heure':       heure,
      'statut':      'assigne',
      'urgence':     demande['urgence']     ?? false,
      'tech_id':     techId,
    });
    if (id == null) return false;
    _interventions = await SupabaseService.fetchCompanyInterventions(_companyId!);
    notifyListeners();
    return true;
  }

  Future<void> reloadDevis() async {
    if (_companyId == null) return;
    _devis = await SupabaseService.fetchDevis(_companyId!);
    notifyListeners();
  }

  @override
  void dispose() {
    _demandesChannel?.unsubscribe();
    super.dispose();
  }
}
