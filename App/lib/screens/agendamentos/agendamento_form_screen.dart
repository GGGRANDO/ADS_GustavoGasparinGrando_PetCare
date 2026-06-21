import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/agendamento.dart';
import '../../models/cliente.dart';
import '../../models/profissional.dart';
import '../../models/servico.dart';
import '../../services/api_service.dart';
import '../pagamento/pagamento_screen.dart';

class AgendamentoFormScreen extends StatefulWidget {
  final Agendamento? agendamento;
  final bool modoCliente;
  final int? idClientePre;
  final int? idProfissionalPre;
  final int? idServicoPre;

  const AgendamentoFormScreen({
    super.key,
    this.agendamento,
    this.modoCliente = false,
    this.idClientePre,
    this.idProfissionalPre,
    this.idServicoPre,
  });

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
  String? _horaSlot;
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
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
      _horaSlot = '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      _status = a.status;
      _obsCtrl.text = a.observacao ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots());
    } else {
      // Pre-fill from client-mode params
      _idCliente = widget.idClientePre;
      _idProfissional = widget.idProfissionalPre;
      _idServico = widget.idServicoPre;
      if (_idProfissional != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadServicos(_idProfissional!);
          _loadSlots();
        });
      }
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
      // If editing, also load the scoped services for that professional
      if (_idProfissional != null) {
        _loadServicos(_idProfissional!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _loadingData = false);
      }
    }
  }

  Future<void> _loadServicos(int idProfissional) async {
    try {
      final scoped =
          await ApiService.getServicos(idProfissional: idProfissional);
      final all = scoped.isNotEmpty ? scoped : await ApiService.getServicos();
      setState(() {
        _servicos = all;
        // Reset selected service if it is not in the new list
        if (_idServico != null && !_servicos.any((s) => s.id == _idServico)) {
          _idServico = null;
        }
      });
    } catch (_) {
      // silently ignore; existing list remains
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
    if (picked != null) {
      setState(() => _data = picked);
      _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    if (_idProfissional == null || _data == null) return;
    final prevSlot = _horaSlot;
    setState(() => _loadingSlots = true);
    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(_data!);
      final slots = await ApiService.getSlotsDisponiveis(
        _idProfissional!,
        dataStr,
        exceptId: widget.agendamento?.id,
      );
      setState(() {
        _slots = slots;
        _loadingSlots = false;
        _horaSlot =
            (prevSlot != null && slots.any((s) => s['horario'] == prevSlot))
                ? prevSlot
                : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _loadingSlots = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione a data.')));
      return;
    }
    if (_horaSlot == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione o horário.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(_data!);
      final horaStr = _horaSlot!;

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
        final criado = await ApiService.createAgendamento(a);
        if (mounted) {
          // Perguntar se quer pagar agora
          final pagar = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Agendamento criado!'),
              content: const Text('Deseja efetuar o pagamento agora?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Depois'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Pagar agora'),
                ),
              ],
            ),
          );
          if (mounted) Navigator.pop(context);
          if (pagar == true && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PagamentoScreen(agendamento: criado),
              ),
            );
          }
        }
      } else {
        await ApiService.updateAgendamento(a);
        if (mounted) Navigator.pop(context);
      }
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
                    // Cliente dropdown — hidden in modoCliente
                    if (!widget.modoCliente) ...[
                      DropdownButtonFormField<int>(
                        value: _idCliente,
                        decoration: const InputDecoration(
                            labelText: 'Cliente *',
                            border: OutlineInputBorder()),
                        items: _clientes
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.nome)))
                            .toList(),
                        onChanged: (v) => setState(() => _idCliente = v),
                        validator: (v) =>
                            v == null ? 'Selecione um cliente' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    DropdownButtonFormField<int>(
                      value: _idProfissional,
                      decoration: const InputDecoration(
                          labelText: 'Profissional *',
                          border: OutlineInputBorder()),
                      items: _profissionais
                          .map((p) => DropdownMenuItem(
                              value: p.id, child: Text(p.nome)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _idProfissional = v;
                          _horaSlot = null;
                          _slots = [];
                          _idServico = null;
                        });
                        if (v != null) _loadServicos(v);
                        _loadSlots();
                      },
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
                              value: s.id,
                              child: Text(s.valor != null
                                  ? '${s.descricao}  •  R\$ ${s.valor!.toStringAsFixed(2)}'
                                  : s.descricao)))
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
                    if (_idProfissional == null || _data == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Selecione o profissional e a data para ver os horários disponíveis.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    else ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Horário *',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingSlots)
                        const Center(child: CircularProgressIndicator())
                      else if (_slots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Profissional não atende nesse dia.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _slots.map((slot) {
                            final h = slot['horario'] as String;
                            final disp = slot['disponivel'] as bool;
                            final sel = _horaSlot == h;
                            return ChoiceChip(
                              label: Text(h),
                              selected: sel,
                              onSelected: disp
                                  ? (v) =>
                                      setState(() => _horaSlot = v ? h : null)
                                  : null,
                              selectedColor: Colors.teal,
                              disabledColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : (disp ? Colors.black87 : Colors.grey),
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                    const SizedBox(height: 16),
                    // Status dropdown — hidden in modoCliente
                    if (!widget.modoCliente) ...[
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
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
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
