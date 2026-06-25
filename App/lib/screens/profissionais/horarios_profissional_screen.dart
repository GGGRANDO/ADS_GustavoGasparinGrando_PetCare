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

  int _countSlots(String inicio, String fim, int intervalo) {
    final ini = _toMinutes(inicio);
    final end = _toMinutes(fim);
    if (end <= ini || intervalo <= 0) return 0;
    return ((end - ini) / intervalo).floor();
  }

  int _toMinutes(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _editDay(int dia) async {
    final existing = _horarios[dia];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _HorarioForm(
        diaNome: _diasNome[dia],
        inicialInicio: existing != null
            ? _parseTime(existing.horaInicio)
            : const TimeOfDay(hour: 8, minute: 0),
        inicialFim: existing != null
            ? _parseTime(existing.horaFim)
            : const TimeOfDay(hour: 17, minute: 0),
        inicialIntervalo: existing?.intervaloMin ?? 60,
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

  Future<void> _copyToWeekdays(int diaOrigem) async {
    final origem = _horarios[diaOrigem];
    if (origem == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copiar para dias úteis'),
        content: const Text('Copiar este horário para Segunda a Sexta-feira?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Copiar')),
        ],
      ),
    );
    if (confirm != true) return;
    for (int d = 1; d <= 5; d++) {
      final h = HorarioProfissional(
        idProfissional: widget.profissional.id!,
        diaSemana: d,
        horaInicio: origem.horaInicio,
        horaFim: origem.horaFim,
        intervaloMin: origem.intervaloMin,
      );
      await ApiService.saveHorarioProfissional(widget.profissional.id!, h);
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Horário copiado para todos os dias úteis!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDias = _horarios.length;
    final totalSlots = _horarios.values.fold<int>(
        0, (s, h) => s + _countSlots(h.horaInicio, h.horaFim, h.intervaloMin));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Horários de Atendimento'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Resumo ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: Colors.orange,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      _SummaryChip(
                          label: 'Dias ativos',
                          value: '$totalDias',
                          icon: Icons.calendar_today),
                      const SizedBox(width: 12),
                      _SummaryChip(
                          label: 'Slots/semana',
                          value: '$totalSlots',
                          icon: Icons.event_available),
                    ],
                  ),
                ),
                // ── Lista ─────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 7,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final h = _horarios[i];
                        final slots = h != null
                            ? _countSlots(
                                h.horaInicio, h.horaFim, h.intervaloMin)
                            : 0;
                        return Card(
                          elevation: h != null ? 2 : 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          color: h != null ? Colors.white : Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: h != null
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _diasAbrev[i],
                                    style: TextStyle(
                                      color: h != null
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _diasNome[i],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: h != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (h != null) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time,
                                                size: 13, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${h.horaInicio} – ${h.horaFim}',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.orange),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${h.intervaloMin} min',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Colors.orange.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$slots atendimento${slots == 1 ? '' : 's'} disponíveis',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600),
                                        ),
                                      ] else
                                        Text(
                                          'Não configurado — toque ⋮ para adicionar',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade400),
                                        ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.grey),
                                  onSelected: (v) {
                                    if (v == 'edit') _editDay(i);
                                    if (v == 'delete') _deleteDay(i);
                                    if (v == 'copy') _copyToWeekdays(i);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(
                                          h != null
                                              ? Icons.edit_outlined
                                              : Icons.add_circle_outline,
                                          size: 18,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(h != null
                                            ? 'Editar'
                                            : 'Configurar'),
                                      ]),
                                    ),
                                    if (h != null) ...[
                                      const PopupMenuItem(
                                        value: 'copy',
                                        child: Row(children: [
                                          Icon(Icons.copy_outlined,
                                              size: 18, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Copiar p/ dias úteis'),
                                        ]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          Icon(Icons.delete_outline,
                                              size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Remover',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ]),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Summary chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 15),
          const SizedBox(width: 6),
          Text('$value $label',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
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

  static const _presets = [
    ['Manhã', 8, 0, 12, 0],
    ['Tarde', 13, 0, 18, 0],
    ['Dia todo', 8, 0, 18, 0],
    ['Noite', 18, 0, 22, 0],
  ];

  @override
  void initState() {
    super.initState();
    _inicio = widget.inicialInicio;
    _fim = widget.inicialFim;
    _intervalo = widget.inicialIntervalo;
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  List<String> get _slotList {
    final slots = <String>[];
    int cur = _toMin(_inicio);
    final end = _toMin(_fim);
    while (cur + _intervalo <= end) {
      final h = cur ~/ 60;
      final m = cur % 60;
      slots.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      cur += _intervalo;
    }
    return slots;
  }

  Future<void> _pickTime(bool isInicio) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isInicio ? _inicio : _fim,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isInicio ? _inicio = picked : _fim = picked);
    }
  }

  Future<void> _save() async {
    if (_toMin(_fim) <= _toMin(_inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hora fim deve ser posterior à hora início.')),
      );
      return;
    }
    if (_slotList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Período muito curto para o intervalo selecionado.')),
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
    final slots = _slotList;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(widget.diaNome,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${slots.length} horário${slots.length == 1 ? '' : 's'} disponíveis',
              style: TextStyle(
                  color: slots.isNotEmpty ? Colors.orange.shade700 : Colors.red,
                  fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Presets rápidos
            const Text('Presets rápidos',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _presets.map((p) {
                final label = p[0] as String;
                final ini = TimeOfDay(hour: p[1] as int, minute: p[2] as int);
                final fim = TimeOfDay(hour: p[3] as int, minute: p[4] as int);
                return ChoiceChip(
                  label: Text(label),
                  selected: _inicio == ini && _fim == fim,
                  selectedColor: Colors.orange.shade100,
                  onSelected: (_) => setState(() {
                    _inicio = ini;
                    _fim = fim;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Período
            const Text('Período de atendimento',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _TimeTile(
                        label: 'Início',
                        time: _fmt(_inicio),
                        onTap: () => _pickTime(true))),
                const SizedBox(width: 12),
                Expanded(
                    child: _TimeTile(
                        label: 'Fim',
                        time: _fmt(_fim),
                        onTap: () => _pickTime(false))),
              ],
            ),
            const SizedBox(height: 20),

            // Duração por slot
            const Text('Duração por atendimento',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [30, 45, 60, 90, 120].map((min) {
                final label = min < 60
                    ? '$min min'
                    : min == 60
                        ? '1h'
                        : '${min ~/ 60}h${min % 60 > 0 ? '${min % 60}min' : ''}';
                return ChoiceChip(
                  label: Text(label),
                  selected: _intervalo == min,
                  selectedColor: Colors.orange.shade100,
                  onSelected: (_) => setState(() => _intervalo = min),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Preview dos slots
            if (slots.isNotEmpty) ...[
              const Text('Horários gerados',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: slots
                    .take(20)
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(s,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade800)),
                        ))
                    .toList(),
              ),
              if (slots.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+ ${slots.length - 20} horários...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Botão salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Salvando…' : 'Salvar horário'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time tile ────────────────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeTile(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
            const SizedBox(height: 4),
            Text(time,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
