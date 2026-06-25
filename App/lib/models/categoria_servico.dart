class CategoriaServico {
  final int? id;
  final String nome;
  final String? descricao;
  final String status;

  CategoriaServico({
    this.id,
    required this.nome,
    this.descricao,
    this.status = 'ativo',
  });

  factory CategoriaServico.fromJson(Map<String, dynamic> json) =>
      CategoriaServico(
        id: json['id'] as int?,
        nome: json['nome'] as String,
        descricao: json['descricao'] as String?,
        status: (json['status'] as String?) ?? 'ativo',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nome': nome,
        if (descricao != null) 'descricao': descricao,
        'status': status,
      };
}
