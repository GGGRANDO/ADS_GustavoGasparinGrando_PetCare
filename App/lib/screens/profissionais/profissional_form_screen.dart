import 'package:flutter/material.dart';
import '../../models/profissional.dart';
import '../../services/api_service.dart';
import 'horarios_profissional_screen.dart';

class ProfissionalFormScreen extends StatefulWidget {
  final Profissional? profissional;
  const ProfissionalFormScreen({super.key, this.profissional});

  @override
  State<ProfissionalFormScreen> createState() => _ProfissionalFormScreenState();
}

class _ProfissionalFormScreenState extends State<ProfissionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _especialidade;
  late final TextEditingController _disponibilidade;
  String _status = 'ativo';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profissional;
    _nome = TextEditingController(text: p?.nome ?? '');
    _telefone = TextEditingController(text: p?.telefone ?? '');
    _especialidade = TextEditingController(text: p?.especialidade ?? '');
    _disponibilidade = TextEditingController(text: p?.disponibilidade ?? '');
    _status = p?.status ?? 'ativo';
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _especialidade.dispose();
    _disponibilidade.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final p = Profissional(
        id: widget.profissional?.id,
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
        especialidade: _especialidade.text.trim().isEmpty
            ? null
            : _especialidade.text.trim(),
        disponibilidade: _disponibilidade.text.trim().isEmpty
            ? null
            : _disponibilidade.text.trim(),
        status: _status,
      );
      if (p.id == null) {
        await ApiService.createProfissional(p);
      } else {
        await ApiService.updateProfissional(p);
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
    final isEdit = widget.profissional != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Profissional' : 'Novo Profissional'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(
                    labelText: 'Nome *', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefone,
                decoration: const InputDecoration(
                    labelText: 'Telefone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _especialidade,
                decoration: const InputDecoration(
                    labelText: 'Especialidade', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _disponibilidade,
                decoration: const InputDecoration(
                    labelText: 'Disponibilidade', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                    labelText: 'Status', border: OutlineInputBorder()),
                items: ['ativo', 'inativo']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Salvar' : 'Cadastrar'),
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HorariosProfissionalScreen(
                            profissional: widget.profissional!),
                      ),
                    ),
                    icon: const Icon(Icons.schedule, color: Colors.orange),
                    label: const Text(
                      'Gerenciar Horários de Atendimento',
                      style: TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
