class Servico {
  final int? id;
  final String descricao;
  final double? valor;
  final String? observacao;
  final String status;

  Servico({
    this.id,
    required this.descricao,
    this.valor,
    this.observacao,
    this.status = 'ativo',
  });

  factory Servico.fromJson(Map<String, dynamic> json) => Servico(
    id: json['id'] as int?,
    descricao: json['descricao'] as String,
    valor: (json['valor'] != null)
        ? double.tryParse(json['valor'].toString())
        : null,
    observacao: json['observacao'] as String?,
    status: (json['status'] as String?) ?? 'ativo',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'descricao': descricao,
    if (valor != null) 'valor': valor,
    if (observacao != null) 'observacao': observacao,
    'status': status,
  };
}
