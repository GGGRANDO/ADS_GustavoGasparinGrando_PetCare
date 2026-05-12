import 'package:flutter/material.dart';
import '../../models/profissional.dart';
import '../../services/api_service.dart';
import 'profissional_form_screen.dart';

class ProfissionaisScreen extends StatefulWidget {
  const ProfissionaisScreen({super.key});

  @override
  State<ProfissionaisScreen> createState() => _ProfissionaisScreenState();
}

class _ProfissionaisScreenState extends State<ProfissionaisScreen> {
  List<Profissional> _lista = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getProfissionais();
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

  Future<void> _delete(Profissional p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir profissional'),
        content: Text('Deseja excluir "${p.nome}"?'),
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
      await ApiService.deleteProfissional(p.id!);
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
        title: const Text('Profissionais'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _lista.isEmpty
                  ? const Center(child: Text('Nenhum profissional cadastrado.'))
                  : ListView.builder(
                      itemCount: _lista.length,
                      itemBuilder: (_, i) {
                        final p = _lista[i];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.badge)),
                          title: Text(p.nome),
                          subtitle: Text(p.especialidade ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(p.status,
                                    style: const TextStyle(fontSize: 11)),
                                backgroundColor: p.status == 'ativo'
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProfissionalFormScreen(
                                            profissional: p)),
                                  );
                                  _load();
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _delete(p),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfissionalFormScreen()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
