class Servico {
  final int? id;
  final int? idProfissional;
  final String? profissionalNome;
  final String descricao;
  final double? valor;
  final int? duracaoMin;
  final String? observacao;
  final String status;

  Servico({
    this.id,
    this.idProfissional,
    this.profissionalNome,
    required this.descricao,
    this.valor,
    this.duracaoMin,
    this.observacao,
    this.status = 'ativo',
  });

  factory Servico.fromJson(Map<String, dynamic> json) => Servico(
        id: json['id'] as int?,
        idProfissional: json['id_profissional'] as int?,
        profissionalNome: json['profissional_nome'] as String?,
        descricao: json['descricao'] as String,
        valor: (json['valor'] != null)
            ? double.tryParse(json['valor'].toString())
            : null,
        duracaoMin: json['duracao_min'] as int?,
        observacao: json['observacao'] as String?,
        status: (json['status'] as String?) ?? 'ativo',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (idProfissional != null) 'id_profissional': idProfissional,
        'descricao': descricao,
        if (valor != null) 'valor': valor,
        if (duracaoMin != null) 'duracao_min': duracaoMin,
        if (observacao != null) 'observacao': observacao,
        'status': status,
      };
}
