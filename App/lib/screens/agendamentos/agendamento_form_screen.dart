import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/agendamento.dart';
import '../../models/cliente.dart';
import '../../models/profissional.dart';
import '../../models/servico.dart';
import '../../services/api_service.dart';

class AgendamentoFormScreen extends StatefulWidget {
  final Agendamento? agendamento;
  const AgendamentoFormScreen({super.key, this.agendamento});

  @override
  State<AgendamentoFormScreen> createState() => _AgendamentoFormScreenState();
}

class _AgendamentoFormScreenState extends State<AgendamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Cliente> _clientes = [];
  List<Profissional> _profissionais = [];
  List<Servico> _servicos = [];

  int? _idCliente;
  int? _idProfissional;
  int? _idServico;
  DateTime? _data;
  TimeOfDay? _hora;
  String _status = 'agendado';
  final _obsCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    if (widget.agendamento != null) {
      final a = widget.agendamento!;
      _idCliente = a.idCliente;
      _idProfissional = a.idProfissional;
      _idServico = a.idServico;
      _data = DateTime.tryParse(a.dataAtendimento);
      final parts = a.horario.split(':');
      _hora = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      _status = a.status;
      _obsCtrl.text = a.observacao ?? '';
    }
  }

  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        ApiService.getClientes(),
        ApiService.getProfissionais(),
        ApiService.getServicos(),
      ]);
      setState(() {
        _clientes = (results[0] as List).cast<Cliente>();
        _profissionais = (results[1] as List).cast<Profissional>();
        _servicos = (results[2] as List).cast<Servico>();
        _loadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _loadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione a data.')));
      return;
    }
    if (_hora == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione o horário.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(_data!);
      final horaStr =
          '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}';

      final a = Agendamento(
        id: widget.agendamento?.id,
        idCliente: _idCliente!,
        idProfissional: _idProfissional!,
        idServico: _idServico!,
        dataAtendimento: dataStr,
        horario: horaStr,
        status: _status,
        observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      );

      if (a.id == null) {
        await ApiService.createAgendamento(a);
      } else {
        await ApiService.updateAgendamento(a);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.agendamento != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Agendamento' : 'Novo Agendamento'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _idCliente,
                      decoration: const InputDecoration(
                          labelText: 'Cliente *', border: OutlineInputBorder()),
                      items: _clientes
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.nome)))
                          .toList(),
                      onChanged: (v) => setState(() => _idCliente = v),
                      validator: (v) =>
                          v == null ? 'Selecione um cliente' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _idProfissional,
                      decoration: const InputDecoration(
                          labelText: 'Profissional *',
                          border: OutlineInputBorder()),
                      items: _profissionais
                          .map((p) => DropdownMenuItem(
                              value: p.id, child: Text(p.nome)))
                          .toList(),
                      onChanged: (v) => setState(() => _idProfissional = v),
                      validator: (v) =>
                          v == null ? 'Selecione um profissional' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _idServico,
                      decoration: const InputDecoration(
                          labelText: 'Serviço *', border: OutlineInputBorder()),
                      items: _servicos
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.descricao)))
                          .toList(),
                      onChanged: (v) => setState(() => _idServico = v),
                      validator: (v) =>
                          v == null ? 'Selecione um serviço' : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_data == null
                          ? 'Selecionar data *'
                          : DateFormat('dd/MM/yyyy').format(_data!)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_hora == null
                          ? 'Selecionar horário *'
                          : _hora!.format(context)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                          labelText: 'Status', border: OutlineInputBorder()),
                      items: [
                        'agendado',
                        'confirmado',
                        'cancelado',
                        'concluido'
                      ]
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _obsCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Observação',
                          border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(isEdit ? 'Salvar' : 'Agendar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
