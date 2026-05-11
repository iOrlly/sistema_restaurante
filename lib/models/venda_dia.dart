import 'package:flutter/material.dart';

enum FormaPagamento {
  dinheiro,
  cartaoDebito,
  cartaoCredito,
  pix,
  valeRefeicao,
}

extension FormaPagamentoExtension on FormaPagamento {
  String get displayName {
    switch (this) {
      case FormaPagamento.dinheiro:
        return 'Dinheiro';
      case FormaPagamento.cartaoDebito:
        return 'Cartão Débito';
      case FormaPagamento.cartaoCredito:
        return 'Cartão Crédito';
      case FormaPagamento.pix:
        return 'PIX';
      case FormaPagamento.valeRefeicao:
        return 'Vale Refeição';
    }
  }

  IconData get icone {
    switch (this) {
      case FormaPagamento.dinheiro:
        return Icons.money;
      case FormaPagamento.cartaoDebito:
        return Icons.credit_card;
      case FormaPagamento.cartaoCredito:
        return Icons.credit_card_rounded;
      case FormaPagamento.pix:
        return Icons.qr_code;
      case FormaPagamento.valeRefeicao:
        return Icons.restaurant_menu;
    }
  }
}

class VendaDia {
  int? id;
  DateTime data;
  int produtoId;
  String produtoNome;
  int quantidade;
  double precoUnitario;
  double valorTotal;
  FormaPagamento formaPagamento;
  int funcionarioAtendenteId; // quem registrou a venda
  DateTime horarioVenda;
  bool temDesconto;
  double? percentualDesconto;
  String? observacao;

  VendaDia({
    this.id,
    required this.data,
    required this.produtoId,
    required this.produtoNome,
    required this.quantidade,
    required this.precoUnitario,
    required this.formaPagamento,
    required this.funcionarioAtendenteId,
    required this.horarioVenda,
    this.temDesconto = false,
    this.percentualDesconto,
    this.observacao,
  }) : valorTotal = calcularTotal(quantidade, precoUnitario, percentualDesconto);

  static double calcularTotal(int quantidade, double precoUnitario, double? descontoPercentual) {
    double total = quantidade * precoUnitario;
    if (descontoPercentual != null && descontoPercentual > 0) {
      total = total * (1 - descontoPercentual / 100);
    }
    return total;
  }

  // Atualizar total após modificar quantidade ou desconto
  void atualizarTotal() {
    valorTotal = calcularTotal(quantidade, precoUnitario, percentualDesconto);
  }

  // Verificar se foi um horário de pico
  String get horarioPico {
    final hora = horarioVenda.hour;
    if ((hora >= 11 && hora <= 14) || (hora >= 19 && hora <= 21)) {
      return 'Pico 🚀';
    } else if ((hora >= 6 && hora <= 10) || (hora >= 15 && hora <= 18)) {
      return 'Movimento Médio 📊';
    } else {
      return 'Baixa Movimento 💤';
    }
  }

  // Calcular comissão do funcionário (exemplo: 2% sobre venda)
  double get comissaoFuncionario {
    if (funcionarioAtendenteId > 0) {
      return valorTotal * 0.02;
    }
    return 0;
  }

  // Ticket médio por venda (se considerar que pode ter vários itens na mesma venda)
  double get ticketMedioUnitario {
    if (quantidade > 0) {
      return valorTotal / quantidade;
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String().split('T')[0],
      'produto_id': produtoId,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'valor_total': valorTotal,
      'forma_pagamento': formaPagamento.index,
      'funcionario_id': funcionarioAtendenteId,
      'horario_venda': horarioVenda.toIso8601String(),
      'tem_desconto': temDesconto ? 1 : 0,
      'percentual_desconto': percentualDesconto,
      'observacao': observacao,
    };
  }

  factory VendaDia.fromMap(Map<String, dynamic> map, String produtoNome) {
    return VendaDia(
      id: map['id'],
      data: DateTime.parse(map['data']),
      produtoId: map['produto_id'],
      produtoNome: produtoNome,
      quantidade: map['quantidade'],
      precoUnitario: map['preco_unitario'],
      formaPagamento: FormaPagamento.values[map['forma_pagamento']],
      funcionarioAtendenteId: map['funcionario_id'],
      horarioVenda: DateTime.parse(map['horario_venda']),
      temDesconto: map['tem_desconto'] == 1,
      percentualDesconto: map['percentual_desconto'],
      observacao: map['observacao'],
    );
  }

  @override
  String toString() {
    return 'Venda: $quantidade x $produtoNome = R\$ ${valorTotal.toStringAsFixed(2)} - ${formaPagamento.displayName}';
  }
}