class Profissional {
  final int? id;
  final String nome;
  final String? telefone;
  final String? especialidade;
  final String? disponibilidade;
  final String status;

  Profissional({
    this.id,
    required this.nome,
    this.telefone,
    this.especialidade,
    this.disponibilidade,
    this.status = 'ativo',
  });

  factory Profissional.fromJson(Map<String, dynamic> json) => Profissional(
    id: json['id'] as int?,
    nome: json['nome'] as String,
    telefone: json['telefone'] as String?,
    especialidade: json['especialidade'] as String?,
    disponibilidade: json['disponibilidade'] as String?,
    status: (json['status'] as String?) ?? 'ativo',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'nome': nome,
    if (telefone != null) 'telefone': telefone,
    if (especialidade != null) 'especialidade': especialidade,
    if (disponibilidade != null) 'disponibilidade': disponibilidade,
    'status': status,
  };
}
