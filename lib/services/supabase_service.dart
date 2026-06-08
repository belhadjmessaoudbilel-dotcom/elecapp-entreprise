import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient get _db => SupabaseConfig.client;
  static SupabaseStorageClient get _storage => _db.storage;

  static String? get currentUserId => _db.auth.currentUser?.id;

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<AuthResponse> signIn(String email, String password) =>
      _db.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) => _db.auth.signUp(
    email: email,
    password: password,
    data: {'name': name, 'role': 'manager'},
  );

  static Future<void> signOut() => _db.auth.signOut();

  // ── Profil manager ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      return await _db.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (e) {
      debugPrint('[Entreprise] fetchProfile error: $e');
      return null;
    }
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _db.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      debugPrint('[Entreprise] updateProfile error: $e');
    }
  }

  // ── Company ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> fetchCompany(String id) async {
    try {
      return await _db.from('companies').select().eq('id', id).maybeSingle();
    } catch (e) {
      debugPrint('[Entreprise] fetchCompany error: $e');
      return null;
    }
  }

  static Future<String?> createCompany(String userId, Map<String, dynamic> data) async {
    try {
      final row = await _db.from('companies').insert({...data, 'created_by': userId}).select('id').single();
      return row['id'] as String?;
    } catch (e) {
      debugPrint('[Entreprise] createCompany error: $e');
      return null;
    }
  }

  static Future<void> updateCompany(String id, Map<String, dynamic> data) async {
    try {
      await _db.from('companies').update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (e) {
      debugPrint('[Entreprise] updateCompany error: $e');
    }
  }

  static Future<String?> generateInviteCode(String companyId) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng   = Random.secure();
    final code  = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    try {
      await _db.from('companies').update({'invite_code': code}).eq('id', companyId);
      return code;
    } catch (e) {
      debugPrint('[Entreprise] generateInviteCode error: $e');
      return null;
    }
  }

  static Future<String?> uploadCompanyLogo(String companyId, Uint8List bytes, String ext) async {
    try {
      final path = '$companyId/logo.$ext';
      await _storage.from('company-logos').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      return _storage.from('company-logos').getPublicUrl(path);
    } catch (e) {
      debugPrint('[Entreprise] uploadCompanyLogo error: $e');
      return null;
    }
  }

  // ── Techniciens ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchCompanyTechs(String companyId) async {
    try {
      final rows = await _db.rpc('get_company_techs_with_status', params: {'cid': companyId});
      if (rows == null) return [];
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      debugPrint('[Entreprise] fetchCompanyTechs error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchInterventionsByTechIds(
      List<String> techIds) async {
    if (techIds.isEmpty) return [];
    try {
      return await _db
          .from('interventions')
          .select()
          .inFilter('tech_id', techIds)
          .order('date', ascending: false);
    } catch (e) {
      debugPrint('[Entreprise] fetchInterventionsByTechIds error: $e');
      return [];
    }
  }

  static Future<void> inviteTechnician(String email, String name, String companyId) async {
    try {
      await _db.functions.invoke('invite-technician', body: {
        'email': email, 'name': name, 'company_id': companyId,
      });
    } catch (e) {
      debugPrint('[Entreprise] inviteTechnician error: $e');
    }
  }

  // ── Demandes clients ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchDemandes(String companyId) async {
    try {
      final rows = await _db
          .from('demande_companies')
          .select('vu, demande_id, demandes(*)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);
      return rows.map((r) {
        final d = Map<String, dynamic>.from(r['demandes'] as Map? ?? {});
        d['vu'] = r['vu'] as bool? ?? false;
        d['id'] ??= r['demande_id'];
        return d;
      }).toList();
    } catch (e) {
      debugPrint('[Entreprise] fetchDemandes error: $e');
      return [];
    }
  }

  static Future<void> marquerDemandeVue(String demandeId, String companyId) async {
    try {
      await _db.from('demande_companies')
          .update({'vu': true})
          .eq('demande_id', demandeId)
          .eq('company_id', companyId);
    } catch (e) {
      debugPrint('[Entreprise] marquerDemandeVue error: $e');
    }
  }

  static RealtimeChannel subscribeToDevis(String companyId, void Function(Map<String, dynamic>) onUpdate) {
    return _db
        .channel('manager:devis:$companyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'devis',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'company_id', value: companyId),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToDemandes(String companyId, void Function(Map<String, dynamic>) onInsert) {
    return _db
        .channel('manager:demandes:$companyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'demande_companies',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'company_id', value: companyId),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  // ── Devis ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchDevis(String companyId) async {
    try {
      return await _db.from('devis').select().eq('company_id', companyId).order('created_at', ascending: false);
    } catch (e) {
      debugPrint('[Entreprise] fetchDevis error: $e');
      return [];
    }
  }

  static Future<String?> createDevis(String companyId, Map<String, dynamic> data) async {
    try {
      final row = await _db.from('devis').insert({...data, 'company_id': companyId}).select('id').single();
      return row['id'] as String?;
    } catch (e) {
      debugPrint('[Entreprise] createDevis error: $e');
      return null;
    }
  }

  // ── Interventions ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchCompanyInterventions(String companyId) async {
    try {
      final techIds = await _db.from('profiles').select('id').eq('company_id', companyId).eq('role', 'technicien');
      if (techIds.isEmpty) return [];
      final ids = techIds.map((r) => r['id'] as String).toList();
      return await _db.from('interventions').select().inFilter('tech_id', ids).order('date', ascending: false);
    } catch (e) {
      debugPrint('[Entreprise] fetchCompanyInterventions error: $e');
      return [];
    }
  }

  static Future<void> assignTech(String interventionId, String techId) async {
    try {
      await _db.from('interventions')
          .update({'tech_id': techId, 'statut': 'planifie'})
          .eq('id', interventionId);
    } catch (e) {
      debugPrint('[Entreprise] assignTech error: $e');
    }
  }

  static Future<String?> createIntervention(Map<String, dynamic> data) async {
    try {
      final row = await _db.from('interventions').insert(data).select('id').single();
      return row['id'] as String?;
    } catch (e) {
      debugPrint('[Entreprise] createIntervention error: $e');
      return null;
    }
  }

  // ── Messagerie directe Manager ↔ Tech (Canal 1) ───────────────────────────

  static String convId(String companyId, String techId) =>
      '${companyId}_$techId';

  static Future<List<Map<String, dynamic>>> fetchDirectMessages(
      String conversationId) async {
    try {
      return await _db
          .from('direct_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
    } catch (e) {
      debugPrint('[Entreprise] fetchDirectMessages error: $e');
      return [];
    }
  }

  static Future<void> sendDirectMessage({
    required String conversationId,
    required String senderRole,
    required String senderName,
    String? content,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _db.from('direct_messages').insert({
        'conversation_id': conversationId,
        'sender_id':       userId,
        'sender_role':     senderRole,
        'sender_name':     senderName,
        if (content != null)        'content':         content,
        if (attachmentUrl != null)  'attachment_url':  attachmentUrl,
        if (attachmentType != null) 'attachment_type': attachmentType,
      });
    } catch (e) {
      debugPrint('[Entreprise] sendDirectMessage error: $e');
    }
  }

  static Future<void> markDirectMessagesRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _db
          .from('direct_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('[Entreprise] markDirectMessagesRead error: $e');
    }
  }

  static RealtimeChannel subscribeToDirectMessages(
      String conversationId, void Function(Map<String, dynamic>) onNew) {
    return _db
        .channel('direct:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onNew(payload.newRecord),
        )
        .subscribe();
  }

  // ── Canal 2 : messagerie mission Client ↔ Tech ↔ Manager ────────────────────

  static Future<List<Map<String, dynamic>>> fetchInterventionMessages(
      String interventionId) async {
    try {
      return await _db
          .from('messages')
          .select()
          .eq('conversation_id', interventionId)
          .order('created_at', ascending: true);
    } catch (e) {
      debugPrint('[Entreprise] fetchInterventionMessages error: $e');
      return [];
    }
  }

  static Future<void> sendInterventionMessage({
    required String interventionId,
    required String managerName,
    required String content,
  }) async {
    try {
      await _db.from('messages').insert({
        'conversation_id': interventionId,
        'from_role':       'manager',
        'from_name':       managerName,
        'text':            content,
      });
    } catch (e) {
      debugPrint('[Entreprise] sendInterventionMessage error: $e');
    }
  }

  static RealtimeChannel subscribeToInterventionMessages(
      String interventionId, void Function(Map<String, dynamic>) onNew) {
    return _db
        .channel('manager:canal2:$interventionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: interventionId,
          ),
          callback: (payload) => onNew(payload.newRecord),
        )
        .subscribe();
  }

  static Future<String?> uploadMessageAttachment(
      String path, List<int> bytes, String mime) async {
    try {
      await _storage.from('message-attachments').uploadBinary(
        path, Uint8List.fromList(bytes),
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );
      return _storage.from('message-attachments').getPublicUrl(path);
    } catch (e) {
      debugPrint('[Entreprise] uploadMessageAttachment error: $e');
      return null;
    }
  }
}
