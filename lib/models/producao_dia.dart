class ProducaoDia {
  int? id;
  DateTime data;
  int produtoId;
  String produtoNome; // para display, não salva no banco
  int quantidadeProduzida;
  int quantidadeRestante; // sobra do dia
  String? motivoSobra;
  DateTime horarioInicioProducao;
  DateTime horarioFimProducao;
  int funcionarioResponsavelId; // para controle por funcionário
  double custoEstimadoProducao; // baseado em custo de insumos
  bool houveDesperdicio;

  ProducaoDia({
    this.id,
    required this.data,
    required this.produtoId,
    required this.produtoNome,
    required this.quantidadeProduzida,
    required this.quantidadeRestante,
    this.motivoSobra,
    required this.horarioInicioProducao,
    required this.horarioFimProducao,
    required this.funcionarioResponsavelId,
    required this.custoEstimadoProducao,
    this.houveDesperdicio = false,
  });

  // Calcular tempo total de produção em horas
  double get tempoProducaoHoras {
    final diferenca = horarioFimProducao.difference(horarioInicioProducao);
    return diferenca.inMinutes / 60.0;
  }

  // Calcular eficiência de produção (itens por hora)
  double get eficienciaProducao {
    if (tempoProducaoHoras > 0) {
      return quantidadeProduzida / tempoProducaoHoras;
    }
    return 0;
  }

  // Calcular percentual de sobra
  double get percentualSobra {
    if (quantidadeProduzida > 0) {
      return (quantidadeRestante / quantidadeProduzida) * 100;
    }
    return 0;
  }

  // Verificar se houve desperdício significativo (>15%)
  bool get temDesperdicioSignificativo {
    return percentualSobra > 15;
  }

  // Calcular custo do desperdício
  double get custoDesperdicio {
    final percentual = percentualSobra / 100;
    return custoEstimadoProducao * percentual;
  }

  // Gerar alerta automático
  String get alertaDesperdicio {
    if (percentualSobra > 30) {
      return '🚨 CRÍTICO: Desperdício de ${percentualSobra.toStringAsFixed(1)}%! Revisar produção imediatamente.';
    } else if (percentualSobra > 15) {
      return '⚠️ ATENÇÃO: Desperdício de ${percentualSobra.toStringAsFixed(1)}%. Reduzir produção amanhã.';
    } else if (percentualSobra > 5) {
      return 'ℹ️ INFO: Desperdício de ${percentualSobra.toStringAsFixed(1)}%. Aceitável, mas pode melhorar.';
    } else {
      return '✅ ÓTIMO: Desperdício mínimo de ${percentualSobra.toStringAsFixed(1)}%!';
    }
  }

  // Sugestão para próximo dia
  String get sugestaoProximaProducao {
    if (percentualSobra > 15) {
      final reducaoSugerida = (quantidadeProduzida * (1 - (15 / percentualSobra))).round();
      return '💰 Sugestão: Produzir $reducaoSugerida unidades (redução de ${(percentualSobra - 15).toStringAsFixed(0)}%)';
    } else if (percentualSobra < 2 && quantidadeRestante < 3) {
      final aumento = (quantidadeProduzida * 1.1).round();
      return '📈 Sugestão: Aumentar produção para $aumento unidades (alta demanda)';
    }
    return '✅ Manter produção atual de $quantidadeProduzida unidades';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String().split('T')[0],
      'produto_id': produtoId,
      'quantidade_produzida': quantidadeProduzida,
      'quantidade_restante': quantidadeRestante,
      'motivo_sobra': motivoSobra,
      'horario_inicio': horarioInicioProducao.toIso8601String(),
      'horario_fim': horarioFimProducao.toIso8601String(),
      'funcionario_id': funcionarioResponsavelId,
      'custo_estimado': custoEstimadoProducao,
      'houve_desperdicio': houveDesperdicio ? 1 : 0,
    };
  }

  factory ProducaoDia.fromMap(Map<String, dynamic> map, String produtoNome) {
    return ProducaoDia(
      id: map['id'],
      data: DateTime.parse(map['data']),
      produtoId: map['produto_id'],
      produtoNome: produtoNome,
      quantidadeProduzida: map['quantidade_produzida'],
      quantidadeRestante: map['quantidade_restante'],
      motivoSobra: map['motivo_sobra'],
      horarioInicioProducao: DateTime.parse(map['horario_inicio']),
      horarioFimProducao: DateTime.parse(map['horario_fim']),
      funcionarioResponsavelId: map['funcionario_id'],
      custoEstimadoProducao: map['custo_estimado'],
      houveDesperdicio: map['houve_desperdicio'] == 1,
    );
  }
}