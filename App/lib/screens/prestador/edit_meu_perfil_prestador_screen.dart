import 'package:flutter/material.dart';
import '../../models/profissional.dart';
import '../../services/api_service.dart';
import '../profissionais/horarios_profissional_screen.dart';

class EditMeuPerfilPrestadorScreen extends StatefulWidget {
  const EditMeuPerfilPrestadorScreen({super.key});

  @override
  State<EditMeuPerfilPrestadorScreen> createState() =>
      _EditMeuPerfilPrestadorScreenState();
}

class _EditMeuPerfilPrestadorScreenState
    extends State<EditMeuPerfilPrestadorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _telefone;
  late final TextEditingController _especialidade;

  bool _loadingData = true;
  bool _saving = false;
  String? _loadError;
  Profissional? _profissional;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController();
    _telefone = TextEditingController();
    _especialidade = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPerfil());
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _especialidade.dispose();
    super.dispose();
  }

  Future<void> _loadPerfil() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final p = await ApiService.getMeuPerfilProfissional();
      if (mounted) {
        setState(() {
          _profissional = p;
          _nome.text = p.nome;
          _telefone.text = p.telefone ?? '';
          _especialidade.text = p.especialidade ?? '';
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
    if (_profissional == null) return;
    setState(() => _saving = true);
    try {
      final atualizado = Profissional(
        id: _profissional!.id,
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
        especialidade: _especialidade.text.trim().isEmpty
            ? null
            : _especialidade.text.trim(),
        status: _profissional!.status,
      );
      await ApiService.updateProfissional(atualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
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
                          onPressed: _loadPerfil,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
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
                        // Avatar
                        Center(
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor:
                                const Color(0xFF4A90A4).withOpacity(0.15),
                            child: Text(
                              _nome.text.isNotEmpty
                                  ? _nome.text[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90A4),
                              ),
                            ),
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
                          controller: _especialidade,
                          decoration: const InputDecoration(
                            labelText: 'Área de atuação / Especialidade',
                            prefixIcon: Icon(Icons.work_outline),
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Horários de atendimento',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _profissional == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HorariosProfissionalScreen(
                                                profissional: _profissional!),
                                      ),
                                    ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF4A90A4)
                                        .withOpacity(0.12),
                                    child: const Icon(Icons.schedule_outlined,
                                        color: Color(0xFF4A90A4), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Configurar horários',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15)),
                                        SizedBox(height: 2),
                                        Text(
                                            'Defina dias e horas de atendimento',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
