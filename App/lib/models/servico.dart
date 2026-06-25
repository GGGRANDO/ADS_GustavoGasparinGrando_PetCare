class Servico {
  final int? id;
  final int? idProfissional;
  final String? profissionalNome;
  final int? idCategoria;
  final String? categoriaNome;
  final String descricao;
  final double? valor;
  final int? duracaoMin;
  final String? observacao;
  final String status;

  Servico({
    this.id,
    this.idProfissional,
    this.profissionalNome,
    this.idCategoria,
    this.categoriaNome,
    required this.descricao,
    this.valor,
    this.duracaoMin,
    this.observacao,
    this.status = 'ativo',
  });

  factory Servico.fromJson(Map<String, dynamic> json) => Servico(
        id: json['id'] == null ? null : (json['id'] as num).toInt(),
        idProfissional: json['id_profissional'] == null
            ? null
            : (json['id_profissional'] as num).toInt(),
        profissionalNome: json['profissional_nome'] as String?,
        idCategoria: json['id_categoria'] == null
            ? null
            : (json['id_categoria'] as num).toInt(),
        categoriaNome: json['categoria_nome'] as String?,
        descricao: json['descricao'].toString(),
        valor: (json['valor'] != null)
            ? double.tryParse(json['valor'].toString())
            : null,
        duracaoMin: json['duracao_min'] == null
            ? null
            : (json['duracao_min'] as num).toInt(),
        observacao: json['observacao'] as String?,
        status: (json['status'] as String?) ?? 'ativo',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (idProfissional != null) 'id_profissional': idProfissional,
        if (idCategoria != null) 'id_categoria': idCategoria,
        'descricao': descricao,
        if (valor != null) 'valor': valor,
        if (duracaoMin != null) 'duracao_min': duracaoMin,
        if (observacao != null) 'observacao': observacao,
        'status': status,
      };
}
