import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../services/api_service.dart';

class EditPerfilScreen extends StatefulWidget {
  const EditPerfilScreen({super.key});

  @override
  State<EditPerfilScreen> createState() => _EditPerfilScreenState();
}

class _EditPerfilScreenState extends State<EditPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _email;
  late final TextEditingController _obs;

  bool _loadingData = true;
  bool _saving = false;
  Cliente? _cliente;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController();
    _telefone = TextEditingController();
    _email = TextEditingController();
    _obs = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCliente());
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    _obs.dispose();
    super.dispose();
  }

  String? _loadError;

  Future<void> _loadCliente() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final c = await ApiService.getMeuPerfil();
      if (mounted) {
        setState(() {
          _cliente = c;
          _nome.text = c.nome;
          _telefone.text = c.telefone ?? '';
          _email.text = c.email ?? '';
          _obs.text = c.observacoes ?? '';
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
          _loadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cliente == null) return;
    setState(() => _saving = true);
    try {
      final atualizado = Cliente(
        id: _cliente!.id,
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
        email: _cliente!.email, // e-mail não pode ser alterado
        observacoes: _obs.text.trim().isEmpty ? null : _obs.text.trim(),
        status: _cliente!.status,
      );
      await ApiService.updateCliente(atualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro atualizado com sucesso!')),
        );
        Navigator.pop(context, true);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 56, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadCliente,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar com inicial
                        Center(
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.teal.shade100,
                            child: Text(
                              _nome.text.isNotEmpty
                                  ? _nome.text[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_cliente!.dataCadastro != null)
                          Center(
                            child: Text(
                              'Cliente desde ${_formatDate(_cliente!.dataCadastro!)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        const SizedBox(height: 28),
                        const Text(
                          'Informações pessoais',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nome,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo *',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nome obrigatório'
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefone,
                          decoration: const InputDecoration(
                            labelText: 'Telefone / WhatsApp',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            suffixIcon: const Tooltip(
                              message: 'O e-mail não pode ser alterado',
                              child: Icon(Icons.lock_outline,
                                  size: 18, color: Colors.grey),
                            ),
                          ),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _obs,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            prefixIcon: Icon(Icons.notes_outlined),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 28),
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
                            label: Text(
                                _saving ? 'Salvando…' : 'Salvar alterações'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
