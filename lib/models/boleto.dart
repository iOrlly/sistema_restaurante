class Boleto {
  int? id;
  String descricao;
  double valor;
  DateTime dataVencimento;
  int status; // 0: pendente, 1: pago
  String categoria;
  DateTime? dataPagamento;

  Boleto({
    this.id,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    this.status = 0,
    required this.categoria,
    this.dataPagamento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data_vencimento': dataVencimento.toIso8601String(),
      'status': status,
      'categoria': categoria,
      'data_pagamento': dataPagamento?.toIso8601String(),
    };
  }

  factory Boleto.fromMap(Map<String, dynamic> map) {
    return Boleto(
      id: map['id'],
      descricao: map['descricao'],
      valor: map['valor'],
      dataVencimento: DateTime.parse(map['data_vencimento']),
      status: map['status'],
      categoria: map['categoria'],
      dataPagamento: map['data_pagamento'] != null ? DateTime.parse(map['data_pagamento']) : null,
    );
  }

  bool get isPago => status == 1;

  // Lógica para compensação de fim de semana
  DateTime get dataEfetiva {
    if (dataVencimento.weekday == DateTime.saturday) {
      return dataVencimento.add(const Duration(days: 2));
    } else if (dataVencimento.weekday == DateTime.sunday) {
      return dataVencimento.add(const Duration(days: 1));
    }
    return dataVencimento;
  }
}
