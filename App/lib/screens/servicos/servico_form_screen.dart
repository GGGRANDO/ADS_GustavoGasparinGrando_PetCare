import 'package:flutter/material.dart';
import '../../models/categoria_servico.dart';
import '../../models/servico.dart';
import '../../services/api_service.dart';

class ServicoFormScreen extends StatefulWidget {
  final Servico? servico;
  final int? idProfissional;
  const ServicoFormScreen({super.key, this.servico, this.idProfissional});

  @override
  State<ServicoFormScreen> createState() => _ServicoFormScreenState();
}

class _ServicoFormScreenState extends State<ServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  late final TextEditingController _obs;
  late final TextEditingController _duracao;
  String _status = 'ativo';
  int? _idCategoria;
  List<CategoriaServico> _categorias = [];
  bool _loading = false;
  bool _loadingCats = true;

  @override
  void initState() {
    super.initState();
    final s = widget.servico;
    _descricao = TextEditingController(text: s?.descricao ?? '');
    _valor = TextEditingController(
        text: s?.valor != null ? s!.valor!.toStringAsFixed(2) : '');
    _obs = TextEditingController(text: s?.observacao ?? '');
    _duracao = TextEditingController(text: (s?.duracaoMin ?? 60).toString());
    _status = s?.status ?? 'ativo';
    _idCategoria = s?.idCategoria;
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    try {
      final list = await ApiService.getCategorias();
      setState(() {
        _categorias = list.where((c) => c.status == 'ativo').toList();
        _loadingCats = false;
      });
    } catch (_) {
      setState(() => _loadingCats = false);
    }
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _obs.dispose();
    _duracao.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final duracaoMin = int.tryParse(_duracao.text.trim()) ?? 60;
      final s = Servico(
        id: widget.servico?.id,
        idProfissional: widget.servico?.idProfissional ?? widget.idProfissional,
        descricao: _descricao.text.trim(),
        valor: _valor.text.trim().isEmpty
            ? null
            : double.tryParse(_valor.text.trim()),
        duracaoMin: duracaoMin,
        observacao: _obs.text.trim().isEmpty ? null : _obs.text.trim(),
        status: _status,
        idCategoria: _idCategoria,
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
      ),
      body: _loadingCats
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<int?>(
                      value: _idCategoria,
                      decoration: const InputDecoration(
                          labelText: 'Categoria', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null, child: Text('— Sem categoria —')),
                        ..._categorias.map((c) => DropdownMenuItem<int?>(
                            value: c.id, child: Text(c.nome))),
                      ],
                      onChanged: (v) => setState(() => _idCategoria = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricao,
                      decoration: const InputDecoration(
                          labelText: 'Nome / Descrição *',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valor,
                      decoration: const InputDecoration(
                          labelText: 'Valor (R\$) *',
                          border: OutlineInputBorder()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Valor obrigatório';
                        if (double.tryParse(v.trim()) == null)
                          return 'Valor inválido';
                        if (double.parse(v.trim()) <= 0)
                          return 'Informe um valor maior que zero';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _duracao,
                      decoration: const InputDecoration(
                          labelText: 'Duração (minutos)',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: 60'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0)
                          return 'Informe a duração em minutos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _obs,
                      decoration: const InputDecoration(
                          labelText: 'Observação',
                          border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                          labelText: 'Status', border: OutlineInputBorder()),
                      items: ['ativo', 'inativo']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
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
