import 'package:flutter/material.dart';
import '../../models/horario_profissional.dart';
import '../../models/profissional.dart';
import '../../services/api_service.dart';

class HorariosProfissionalScreen extends StatefulWidget {
  final Profissional profissional;
  const HorariosProfissionalScreen({super.key, required this.profissional});

  @override
  State<HorariosProfissionalScreen> createState() =>
      _HorariosProfissionalScreenState();
}

class _HorariosProfissionalScreenState
    extends State<HorariosProfissionalScreen> {
  static const _diasAbrev = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _diasNome = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
  ];

  Map<int, HorarioProfissional> _horarios = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list =
          await ApiService.getHorariosProfissional(widget.profissional.id!);
      setState(() {
        _horarios = {for (final h in list) h.diaSemana: h};
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editDay(int dia) async {
    final existing = _horarios[dia];
    TimeOfDay inicio = existing != null
        ? _parseTime(existing.horaInicio)
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay fim = existing != null
        ? _parseTime(existing.horaFim)
        : const TimeOfDay(hour: 18, minute: 0);
    int intervalo = existing?.intervaloMin ?? 60;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _HorarioForm(
        diaNome: _diasNome[dia],
        inicialInicio: inicio,
        inicialFim: fim,
        inicialIntervalo: intervalo,
        onSave: (ini, f, inv) async {
          final fmt = (TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          final h = HorarioProfissional(
            idProfissional: widget.profissional.id!,
            diaSemana: dia,
            horaInicio: fmt(ini),
            horaFim: fmt(f),
            intervaloMin: inv,
          );
          await ApiService.saveHorarioProfissional(widget.profissional.id!, h);
          await _load();
        },
      ),
    );
  }

  Future<void> _deleteDay(int dia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover horário'),
        content: Text('Remover horário de ${_diasNome[dia]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteHorarioProfissional(
            widget.profissional.id!, dia);
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horários – ${widget.profissional.nome}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (ctx, i) {
                final h = _horarios[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        h != null ? Colors.orange : Colors.grey.shade300,
                    child: Text(
                      _diasAbrev[i],
                      style: TextStyle(
                        color: h != null ? Colors.white : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(_diasNome[i]),
                  subtitle: h != null
                      ? Text(
                          '${h.horaInicio} – ${h.horaFim}  •  ${h.intervaloMin} min/slot',
                          style: const TextStyle(color: Colors.orange),
                        )
                      : const Text('Não configurado',
                          style: TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          h != null
                              ? Icons.edit_outlined
                              : Icons.add_circle_outline,
                          color: Colors.orange,
                        ),
                        tooltip: h != null ? 'Editar' : 'Adicionar',
                        onPressed: () => _editDay(i),
                      ),
                      if (h != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Remover',
                          onPressed: () => _deleteDay(i),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─── Bottom sheet form ────────────────────────────────────────────────────────

class _HorarioForm extends StatefulWidget {
  final String diaNome;
  final TimeOfDay inicialInicio;
  final TimeOfDay inicialFim;
  final int inicialIntervalo;
  final Future<void> Function(TimeOfDay inicio, TimeOfDay fim, int intervalo)
      onSave;

  const _HorarioForm({
    required this.diaNome,
    required this.inicialInicio,
    required this.inicialFim,
    required this.inicialIntervalo,
    required this.onSave,
  });

  @override
  State<_HorarioForm> createState() => _HorarioFormState();
}

class _HorarioFormState extends State<_HorarioForm> {
  late TimeOfDay _inicio;
  late TimeOfDay _fim;
  late int _intervalo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _inicio = widget.inicialInicio;
    _fim = widget.inicialFim;
    _intervalo = widget.inicialIntervalo;
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isInicio ? _inicio : _fim,
    );
    if (picked != null)
      setState(() => isInicio ? _inicio = picked : _fim = picked);
  }

  Future<void> _save() async {
    final startMin = _inicio.hour * 60 + _inicio.minute;
    final endMin = _fim.hour * 60 + _fim.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hora fim deve ser posterior à hora início.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_inicio, _fim, _intervalo);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.diaNome,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(true),
                  icon: const Icon(Icons.access_time),
                  label: Text('Início: ${_fmt(_inicio)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(false),
                  icon: const Icon(Icons.access_time),
                  label: Text('Fim: ${_fmt(_fim)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _intervalo,
            decoration: const InputDecoration(
              labelText: 'Duração de cada slot',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 30, child: Text('30 minutos')),
              DropdownMenuItem(value: 45, child: Text('45 minutos')),
              DropdownMenuItem(value: 60, child: Text('60 minutos')),
              DropdownMenuItem(value: 90, child: Text('90 minutos')),
            ],
            onChanged: (v) => setState(() => _intervalo = v!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}
