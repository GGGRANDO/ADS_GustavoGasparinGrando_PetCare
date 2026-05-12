class Agendamento {
  final int? id;
  final int idCliente;
  final int idProfissional;
  final int idServico;
  final String dataAtendimento;
  final String horario;
  final String status;
  final String? observacao;

  // joined fields
  final String? clienteNome;
  final String? profissionalNome;
  final String? servicoDescricao;

  Agendamento({
    this.id,
    required this.idCliente,
    required this.idProfissional,
    required this.idServico,
    required this.dataAtendimento,
    required this.horario,
    this.status = 'agendado',
    this.observacao,
    this.clienteNome,
    this.profissionalNome,
    this.servicoDescricao,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) => Agendamento(
    id: json['id'] as int?,
    idCliente: json['id_cliente'] as int,
    idProfissional: json['id_profissional'] as int,
    idServico: json['id_servico'] as int,
    dataAtendimento: json['data_atendimento'] as String,
    horario: json['horario'] as String,
    status: (json['status'] as String?) ?? 'agendado',
    observacao: json['observacao'] as String?,
    clienteNome: json['cliente_nome'] as String?,
    profissionalNome: json['profissional_nome'] as String?,
    servicoDescricao: json['servico_descricao'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'id_cliente': idCliente,
    'id_profissional': idProfissional,
    'id_servico': idServico,
    'data_atendimento': dataAtendimento,
    'horario': horario,
    'status': status,
    if (observacao != null) 'observacao': observacao,
  };
}
