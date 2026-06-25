import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _especialidadeCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureConfirma = true;
  bool _loading = false;
  String _tipoConta = 'cliente';

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _especialidadeCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ApiService.register(
        _nomeCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _senhaCtrl.text,
        _tipoConta,
        telefone: _telefoneCtrl.text.trim().isEmpty
            ? null
            : _telefoneCtrl.text.trim(),
        especialidade: _tipoConta == 'profissional' &&
                _especialidadeCtrl.text.trim().isNotEmpty
            ? _especialidadeCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Faça login.'),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, size: 56, color: Color(0xFF4A90A4)),
                const SizedBox(height: 8),
                Text(
                  'PetCare',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF4A90A4),
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Informe o e-mail';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: _obscureSenha,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureSenha
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureSenha = !_obscureSenha),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < 6) return 'Mínimo de 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // ── Tipo de conta ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de conta',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'cliente',
                              groupValue: _tipoConta,
                              onChanged: (v) => setState(() => _tipoConta = v!),
                              title: const Text('Cliente',
                                  overflow: TextOverflow.ellipsis),
                              secondary: const Icon(Icons.pets, size: 20),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'profissional',
                              groupValue: _tipoConta,
                              onChanged: (v) => setState(() => _tipoConta = v!),
                              title: const Text('Prestador',
                                  overflow: TextOverflow.ellipsis, maxLines: 1),
                              secondary:
                                  const Icon(Icons.content_cut, size: 20),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                if (_tipoConta == 'profissional') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _especialidadeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Especialidade (ex: Banho, Tosa)',
                      prefixIcon: Icon(Icons.star_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmaSenhaCtrl,
                  obscureText: _obscureConfirma,
                  decoration: InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirma
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirma = !_obscureConfirma),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme a senha';
                    if (v != _senhaCtrl.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Criar conta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
