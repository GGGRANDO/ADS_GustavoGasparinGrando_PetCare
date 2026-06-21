class Pagamento {
  final int? id;
  final int idAgendamento;
  final String? asaasCustomerId;
  final String? asaasPaymentId;
  final double valor;
  final String formaPagamento; // PIX | BOLETO | CREDIT_CARD
  final String status;
  final String? pixCopiaCola;
  final String? pixExpiracao;
  final String? linkBoleto;
  final String? linkFatura;
  final String? criadoEm;

  Pagamento({
    this.id,
    required this.idAgendamento,
    this.asaasCustomerId,
    this.asaasPaymentId,
    required this.valor,
    this.formaPagamento = 'PIX',
    this.status = 'PENDING',
    this.pixCopiaCola,
    this.pixExpiracao,
    this.linkBoleto,
    this.linkFatura,
    this.criadoEm,
  });

  factory Pagamento.fromJson(Map<String, dynamic> json) => Pagamento(
        id: json['id'] as int?,
        idAgendamento: json['id_agendamento'] as int,
        asaasCustomerId: json['asaas_customer_id'] as String?,
        asaasPaymentId: json['asaas_payment_id'] as String?,
        valor: double.parse(json['valor'].toString()),
        formaPagamento: (json['forma_pagamento'] as String?) ?? 'PIX',
        status: (json['status'] as String?) ?? 'PENDING',
        pixCopiaCola: json['pix_copia_cola'] as String?,
        pixExpiracao: json['pix_expiracao'] as String?,
        linkBoleto: json['link_boleto'] as String?,
        linkFatura: json['link_fatura'] as String?,
        criadoEm: json['criado_em'] as String?,
      );

  // Human-readable status label in Portuguese
  String get statusLabel {
    const labels = {
      'PENDING': 'Pendente',
      'RECEIVED': 'Recebido',
      'CONFIRMED': 'Confirmado',
      'OVERDUE': 'Vencido',
      'REFUNDED': 'Estornado',
      'RECEIVED_IN_CASH': 'Recebido em dinheiro',
      'REFUND_REQUESTED': 'Estorno solicitado',
      'CANCELLED': 'Cancelado',
    };
    return labels[status] ?? status;
  }
}
