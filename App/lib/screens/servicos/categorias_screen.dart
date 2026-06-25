import 'package:flutter/material.dart';
import '../../models/categoria_servico.dart';
import '../../services/api_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<CategoriaServico> _lista = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getCategorias();
      setState(() => _lista = list);
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

  Future<void> _showForm([CategoriaServico? cat]) async {
    final nomeCtrl = TextEditingController(text: cat?.nome ?? '');
    final descCtrl = TextEditingController(text: cat?.descricao ?? '');
    String status = cat?.status ?? 'ativo';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(cat == null ? 'Nova Categoria' : 'Editar Categoria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                if (cat != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['ativo', 'inativo']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDlg(() => status = v!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  if (nomeCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    try {
      final nova = CategoriaServico(
        id: cat?.id,
        nome: nomeCtrl.text.trim(),
        descricao: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        status: status,
      );
      if (cat == null) {
        await ApiService.createCategoria(nova);
      } else {
        await ApiService.updateCategoria(nova);
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _delete(CategoriaServico cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text('Deseja excluir "${cat.nome}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteCategoria(cat.id!);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias de Serviço'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _lista.isEmpty
                  ? const Center(child: Text('Nenhuma categoria cadastrada.'))
                  : ListView.builder(
                      itemCount: _lista.length,
                      itemBuilder: (_, i) {
                        final cat = _lista[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF7B6FAB).withOpacity(0.15),
                              child: const Icon(Icons.category_outlined,
                                  color: Color(0xFF7B6FAB)),
                            ),
                            title: Text(cat.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: cat.descricao != null
                                ? Text(cat.descricao!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(cat.status,
                                      style: const TextStyle(fontSize: 11)),
                                  backgroundColor: cat.status == 'ativo'
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFF7B6FAB)),
                                  onPressed: () => _showForm(cat),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _delete(cat),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
