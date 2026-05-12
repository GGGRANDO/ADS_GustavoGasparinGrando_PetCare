class Cliente {
  final int? id;
  final String nome;
  final String? telefone;
  final String? email;
  final String? observacoes;
  final String status;
  final String? dataCadastro;

  Cliente({
    this.id,
    required this.nome,
    this.telefone,
    this.email,
    this.observacoes,
    this.status = 'ativo',
    this.dataCadastro,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    id: json['id'] as int?,
    nome: json['nome'] as String,
    telefone: json['telefone'] as String?,
    email: json['email'] as String?,
    observacoes: json['observacoes'] as String?,
    status: (json['status'] as String?) ?? 'ativo',
    dataCadastro: json['data_cadastro'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'nome': nome,
    if (telefone != null) 'telefone': telefone,
    if (email != null) 'email': email,
    if (observacoes != null) 'observacoes': observacoes,
    'status': status,
  };
}
