import 'package:flutter/material.dart';
import '../../models/servico.dart';
import '../../services/api_service.dart';
import 'servico_form_screen.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  List<Servico> _lista = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getServicos();
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

  Future<void> _delete(Servico s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir serviço'),
        content: Text('Deseja excluir "${s.descricao}"?'),
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
      await ApiService.deleteServico(s.id!);
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
        title: const Text('Serviços'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _lista.isEmpty
                  ? const Center(child: Text('Nenhum serviço cadastrado.'))
                  : ListView.builder(
                      itemCount: _lista.length,
                      itemBuilder: (_, i) {
                        final s = _lista[i];
                        return ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.miscellaneous_services)),
                          title: Text(s.descricao),
                          subtitle: s.valor != null
                              ? Text('R\$ ${s.valor!.toStringAsFixed(2)}')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(s.status,
                                    style: const TextStyle(fontSize: 11)),
                                backgroundColor: s.status == 'ativo'
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.purple),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ServicoFormScreen(servico: s)),
                                  );
                                  _load();
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _delete(s),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServicoFormScreen()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
