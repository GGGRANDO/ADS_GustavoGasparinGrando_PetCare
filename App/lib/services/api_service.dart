import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cliente.dart';
import '../models/profissional.dart';
import '../models/horario_profissional.dart';
import '../models/servico.dart';
import '../models/agendamento.dart';
import '../models/pagamento.dart';
import '../models/categoria_servico.dart';

class ApiService {
  // kIsWeb → browser uses localhost; Android emulator uses 10.0.2.2
  static String get _base =>
      kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

  // ─── Token helpers ─────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Erro desconhecido (${res.statusCode})');
    }
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    _checkStatus(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await saveToken(data['token'] as String);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(data['usuario']));
    return data;
  }

  static Future<void> register(
    String nome,
    String email,
    String senha,
    String perfil, {
    String? telefone,
    String? especialidade,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'perfil': perfil,
        if (telefone != null) 'telefone': telefone,
        if (especialidade != null) 'especialidade': especialidade,
      }),
    );
    _checkStatus(res);
  }

  static Future<void> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$_base/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    _checkStatus(res);
  }

  static Future<void> resetPassword(
      String email, String token, String novaSenha) async {
    final res = await http.post(
      Uri.parse('$_base/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body:
          jsonEncode({'email': email, 'token': token, 'novaSenha': novaSenha}),
    );
    _checkStatus(res);
  }

  // ─── Clientes ──────────────────────────────────────────────────────────────

  static Future<List<Cliente>> getClientes() async {
    final res = await http.get(
      Uri.parse('$_base/clientes'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Cliente> getCliente(int id) async {
    final res = await http.get(
      Uri.parse('$_base/clientes/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Cliente> getMeuPerfil() async {
    final res = await http.get(
      Uri.parse('$_base/clientes/meu-perfil'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Cliente> createCliente(Cliente c) async {
    final res = await http.post(
      Uri.parse('$_base/clientes'),
      headers: await _authHeaders(),
      body: jsonEncode(c.toJson()),
    );
    _checkStatus(res);
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Cliente> updateCliente(Cliente c) async {
    final res = await http.put(
      Uri.parse('$_base/clientes/${c.id}'),
      headers: await _authHeaders(),
      body: jsonEncode(c.toJson()),
    );
    _checkStatus(res);
    return Cliente.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteCliente(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/clientes/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
  }

  // ─── Profissionais ─────────────────────────────────────────────────────────

  static Future<List<Profissional>> getProfissionais() async {
    final res = await http.get(
      Uri.parse('$_base/profissionais'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Profissional.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Profissional> getMeuPerfilProfissional() async {
    final res = await http.get(
      Uri.parse('$_base/profissionais/meu-perfil'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    return Profissional.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Profissional> createProfissional(Profissional p) async {
    final res = await http.post(
      Uri.parse('$_base/profissionais'),
      headers: await _authHeaders(),
      body: jsonEncode(p.toJson()),
    );
    _checkStatus(res);
    return Profissional.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Profissional> updateProfissional(Profissional p) async {
    final res = await http.put(
      Uri.parse('$_base/profissionais/${p.id}'),
      headers: await _authHeaders(),
      body: jsonEncode(p.toJson()),
    );
    _checkStatus(res);
    return Profissional.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteProfissional(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/profissionais/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
  }

  // ─── Horários de Profissional ──────────────────────────────────────────────

  static Future<List<HorarioProfissional>> getHorariosProfissional(
      int id) async {
    final res = await http.get(
      Uri.parse('$_base/profissionais/$id/horarios'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => HorarioProfissional.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveHorarioProfissional(
      int idProfissional, HorarioProfissional h) async {
    final res = await http.post(
      Uri.parse('$_base/profissionais/$idProfissional/horarios'),
      headers: await _authHeaders(),
      body: jsonEncode(h.toJson()),
    );
    _checkStatus(res);
  }

  static Future<void> deleteHorarioProfissional(
      int idProfissional, int diaSemana) async {
    final res = await http.delete(
      Uri.parse('$_base/profissionais/$idProfissional/horarios/$diaSemana'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
  }

  static Future<List<Map<String, dynamic>>> getSlotsDisponiveis(
    int idProfissional,
    String data, {
    int? exceptId,
    int? idServico,
  }) async {
    final params = <String, String>{'data': data};
    if (exceptId != null) params['except_id'] = exceptId.toString();
    if (idServico != null) params['id_servico'] = idServico.toString();
    final uri = Uri.parse('$_base/profissionais/$idProfissional/slots')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders());
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return ((body['slots'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  // ─── Serviços ──────────────────────────────────────────────────────────────

  static Future<List<Servico>> getServicos({int? idProfissional}) async {
    final params = idProfissional != null
        ? {'id_profissional': idProfissional.toString()}
        : null;
    final uri = Uri.parse('$_base/servicos').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders());
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Servico.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Servico> createServico(Servico s) async {
    final res = await http.post(
      Uri.parse('$_base/servicos'),
      headers: await _authHeaders(),
      body: jsonEncode(s.toJson()),
    );
    _checkStatus(res);
    return Servico.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Servico> updateServico(Servico s) async {
    final res = await http.put(
      Uri.parse('$_base/servicos/${s.id}'),
      headers: await _authHeaders(),
      body: jsonEncode(s.toJson()),
    );
    _checkStatus(res);
    return Servico.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteServico(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/servicos/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
  }

  // ─── Agendamentos ──────────────────────────────────────────────────────────

  static Future<List<Agendamento>> getAgendamentos({
    String? data,
    int? idProfissional,
    int? idCliente,
    String? status,
  }) async {
    final params = <String, String>{};
    if (data != null) params['data'] = data;
    if (idProfissional != null)
      params['id_profissional'] = idProfissional.toString();
    if (idCliente != null) params['id_cliente'] = idCliente.toString();
    if (status != null) params['status'] = status;

    final uri =
        Uri.parse('$_base/agendamentos').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders());
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Agendamento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Agendamento> createAgendamento(Agendamento a) async {
    final res = await http.post(
      Uri.parse('$_base/agendamentos'),
      headers: await _authHeaders(),
      body: jsonEncode(a.toJson()),
    );
    _checkStatus(res);
    return Agendamento.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Agendamento> updateAgendamento(Agendamento a) async {
    final res = await http.put(
      Uri.parse('$_base/agendamentos/${a.id}'),
      headers: await _authHeaders(),
      body: jsonEncode(a.toJson()),
    );
    _checkStatus(res);
    return Agendamento.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteAgendamento(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/agendamentos/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
  }

  static Future<Agendamento> confirmarAgendamento(int id) async {
    final res = await http.patch(
      Uri.parse('$_base/agendamentos/$id/confirmar'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    return Agendamento.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Agendamento> recusarAgendamento(int id,
      {String? motivo}) async {
    final res = await http.patch(
      Uri.parse('$_base/agendamentos/$id/cancelar'),
      headers: await _authHeaders(),
      body: jsonEncode({'motivo': motivo}),
    );
    _checkStatus(res);
    return Agendamento.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── Pagamentos (Asaas) ────────────────────────────────────────────────────

  static Future<Pagamento> criarPagamento(
      int idAgendamento, String formaPagamento) async {
    final res = await http.post(
      Uri.parse('$_base/pagamentos'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'id_agendamento': idAgendamento,
        'forma_pagamento': formaPagamento,
      }),
    );
    _checkStatus(res);
    return Pagamento.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Registra pagamento manual (dinheiro ou transferência) sem passar pelo Asaas.
  static Future<Pagamento> registrarPagamentoManual(
      int idAgendamento, String formaPagamento) async {
    return criarPagamento(idAgendamento, formaPagamento);
  }

  static Future<List<Pagamento>> getPagamentosAgendamento(
      int idAgendamento) async {
    final res = await http.get(
      Uri.parse('$_base/pagamentos/agendamento/$idAgendamento'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Pagamento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Pagamento> getPagamento(int id) async {
    final res = await http.get(
      Uri.parse('$_base/pagamentos/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    return Pagamento.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> cancelarPagamento(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/pagamentos/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
  }

  // ─── Categorias de serviço ────────────────────────────────────────────────

  static Future<List<CategoriaServico>> getCategorias() async {
    final res = await http.get(
      Uri.parse('$_base/categorias'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => CategoriaServico.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<CategoriaServico> createCategoria(CategoriaServico c) async {
    final res = await http.post(
      Uri.parse('$_base/categorias'),
      headers: await _authHeaders(),
      body: jsonEncode(c.toJson()),
    );
    _checkStatus(res);
    return CategoriaServico.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<CategoriaServico> updateCategoria(CategoriaServico c) async {
    final res = await http.put(
      Uri.parse('$_base/categorias/${c.id}'),
      headers: await _authHeaders(),
      body: jsonEncode(c.toJson()),
    );
    _checkStatus(res);
    return CategoriaServico.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteCategoria(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/categorias/$id'),
      headers: await _authHeaders(),
    );
    _checkStatus(res);
  }
}
