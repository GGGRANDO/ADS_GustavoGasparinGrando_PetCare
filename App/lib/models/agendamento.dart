class Agendamento {
  final int? id;
  final int idCliente;
  final int idProfissional;
  final int idServico;
  final String dataAtendimento;
  final String horario;
  final String status;
  final String? observacao;
  final String? motivoCancelamento;

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
    this.status = 'aguardando_confirmacao',
    this.observacao,
    this.motivoCancelamento,
    this.clienteNome,
    this.profissionalNome,
    this.servicoDescricao,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) => Agendamento(
        id: json['id'] == null ? null : (json['id'] as num).toInt(),
        idCliente: (json['id_cliente'] as num).toInt(),
        idProfissional: (json['id_profissional'] as num).toInt(),
        idServico: (json['id_servico'] as num).toInt(),
        dataAtendimento: json['data_atendimento'].toString().substring(0, 10),
        horario: json['horario'].toString().substring(0, 5),
        status: (json['status'] as String?) ?? 'aguardando_confirmacao',
        observacao: json['observacao'] as String?,
        motivoCancelamento: json['motivo_cancelamento'] as String?,
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
