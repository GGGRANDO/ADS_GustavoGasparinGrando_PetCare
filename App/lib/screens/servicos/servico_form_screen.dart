import 'package:flutter/material.dart';
import '../../models/servico.dart';
import '../../services/api_service.dart';

class ServicoFormScreen extends StatefulWidget {
  final Servico? servico;
  const ServicoFormScreen({super.key, this.servico});

  @override
  State<ServicoFormScreen> createState() => _ServicoFormScreenState();
}

class _ServicoFormScreenState extends State<ServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  late final TextEditingController _obs;
  String _status = 'ativo';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.servico;
    _descricao = TextEditingController(text: s?.descricao ?? '');
    _valor = TextEditingController(
        text: s?.valor != null ? s!.valor!.toStringAsFixed(2) : '');
    _obs = TextEditingController(text: s?.observacao ?? '');
    _status = s?.status ?? 'ativo';
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final s = Servico(
        id: widget.servico?.id,
        descricao: _descricao.text.trim(),
        valor: _valor.text.trim().isEmpty
            ? null
            : double.tryParse(_valor.text.trim()),
        observacao: _obs.text.trim().isEmpty ? null : _obs.text.trim(),
        status: _status,
      );
      if (s.id == null) {
        await ApiService.createServico(s);
      } else {
        await ApiService.updateServico(s);
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
    final isEdit = widget.servico != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Serviço' : 'Novo Serviço'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descricao,
                decoration: const InputDecoration(
                    labelText: 'Descrição *', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Descrição obrigatória' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valor,
                decoration: const InputDecoration(
                    labelText: 'Valor (R\$)', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obs,
                decoration: const InputDecoration(
                    labelText: 'Observação', border: OutlineInputBorder()),
                maxLines: 3,
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
                    backgroundColor: Colors.purple,
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
            ],
          ),
        ),
      ),
    );
  }
}
