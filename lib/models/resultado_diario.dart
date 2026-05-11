import 'package:flutter/material.dart';

enum StatusDia {
  excelente,
  bom,
  regular,
  critico,
}

extension StatusDiaExtension on StatusDia {
  String get displayName {
    switch (this) {
      case StatusDia.excelente:
        return 'Excelente 🎉';
      case StatusDia.bom:
        return 'Bom ✅';
      case StatusDia.regular:
        return 'Regular ⚠️';
      case StatusDia.critico:
        return 'Crítico ❌';
    }
  }

  Color get cor {
    switch (this) {
      case StatusDia.excelente:
        return Colors.green;
      case StatusDia.bom:
        return Colors.lightGreen;
      case StatusDia.regular:
        return Colors.orange;
      case StatusDia.critico:
        return Colors.red;
    }
  }
}

class ResultadoDiario {
  DateTime data;
  double totalVendasBruto;
  double totalDescontos;
  double totalVendasLiquido;
  double custoTotalProducao;
  double custoTotalMercadorias;
  double despesasFuncionarios; // salário base + comissões
  double despesasFixas; // aluguel, luz, água, etc
  double lucroLiquido;
  
  // Métricas operacionais
  int totalItensVendidos;
  int totalItensProduzidos;
  int totalClientesAtendidos;
  int totalFuncionariosAtivos;
  double ticketMedio;
  
  // Métricas de eficiência
  double percentualDesperdicio;
  double eficienciaFuncionarios; // itens por funcionário
  double produtividadeMediaHora; // itens por hora de trabalho total
  
  // Rankings e comparativos
  Map<int, double> vendasPorFuncionario; // funcionarioId -> total vendido
  Map<int, double> desperdicioPorFuncionario; // funcionarioId -> percentual desperdício
  Map<String, double> vendasPorProduto; // produtoNome -> quantidade vendida
  Map<String, double> desperdicioPorProduto; // produtoNome -> percentual desperdício
  
  // Alertas e recomendações
  List<String> alertas;
  List<String> recomendacoes;
  StatusDia status;
  
  // Metas
  double metaVendasDiaria;
  double metaDesperdicioMaximo; // percentual máximo aceitável
  bool metaVendasAtingida;
  bool metaDesperdicioAtingida;

  ResultadoDiario({
    required this.data,
    this.totalVendasBruto = 0,
    this.totalDescontos = 0,
    this.totalVendasLiquido = 0,
    this.custoTotalProducao = 0,
    this.custoTotalMercadorias = 0,
    this.despesasFuncionarios = 0,
    this.despesasFixas = 0,
    this.lucroLiquido = 0,
    this.totalItensVendidos = 0,
    this.totalItensProduzidos = 0,
    this.totalClientesAtendidos = 0,
    this.totalFuncionariosAtivos = 0,
    this.ticketMedio = 0,
    this.percentualDesperdicio = 0,
    this.eficienciaFuncionarios = 0,
    this.produtividadeMediaHora = 0,
    this.vendasPorFuncionario = const {},
    this.desperdicioPorFuncionario = const {},
    this.vendasPorProduto = const {},
    this.desperdicioPorProduto = const {},
    this.alertas = const [],
    this.recomendacoes = const [],
    this.status = StatusDia.regular,
    this.metaVendasDiaria = 3000, // meta padrão
    this.metaDesperdicioMaximo = 15, // 15% máximo
    this.metaVendasAtingida = false,
    this.metaDesperdicioAtingida = false,
  });

  // Calcular todos os indicadores baseado nos dados brutos
  void calcularIndicadores() {
    // Vendas líquidas
    totalVendasLiquido = totalVendasBruto - totalDescontos;
    
    // Lucro
    lucroLiquido = totalVendasLiquido - 
                   (custoTotalProducao + custoTotalMercadorias + 
                    despesasFuncionarios + despesasFixas);
    
    // Ticket médio
    ticketMedio = totalClientesAtendidos > 0 
        ? totalVendasLiquido / totalClientesAtendidos 
        : 0;
    
    // Percentual desperdício
    percentualDesperdicio = totalItensProduzidos > 0
        ? ((totalItensProduzidos - totalItensVendidos) / totalItensProduzidos) * 100
        : 0;
    
    // Eficiência funcionários
    eficienciaFuncionarios = totalFuncionariosAtivos > 0
        ? totalItensVendidos / totalFuncionariosAtivos
        : 0;
    
    // Verificar metas
    metaVendasAtingida = totalVendasLiquido >= metaVendasDiaria;
    metaDesperdicioAtingida = percentualDesperdicio <= metaDesperdicioMaximo;
    
    // Determinar status
    determinarStatus();
    
    // Gerar alertas e recomendações
    gerarAlertas();
    gerarRecomendacoes();
  }
  
  void determinarStatus() {
    if (metaVendasAtingida && metaDesperdicioAtingida && percentualDesperdicio < 8) {
      status = StatusDia.excelente;
    } else if (metaVendasAtingida && metaDesperdicioAtingida) {
      status = StatusDia.bom;
    } else if (totalVendasLiquido > metaVendasDiaria * 0.8 && percentualDesperdicio < 20) {
      status = StatusDia.regular;
    } else {
      status = StatusDia.critico;
    }
  }
  
  void gerarAlertas() {
    List<String> novosAlertas = [];
    
    if (!metaVendasAtingida) {
      novosAlertas.add('📉 Meta de vendas não atingida (' + r'R$ ' + '${(metaVendasDiaria - totalVendasLiquido).toStringAsFixed(2)} abaixo)');
    }
    
    if (!metaDesperdicioAtingida) {
      novosAlertas.add('🗑️ Desperdício acima da meta: ${percentualDesperdicio.toStringAsFixed(1)}% (meta: $metaDesperdicioMaximo%)');
    }
    
    if (percentualDesperdicio > 20) {
      novosAlertas.add('⚠️ CRÍTICO: Desperdício muito alto! Revisar produção imediatamente');
    }
    
    if (totalClientesAtendidos < 50 && totalVendasLiquido > 0) {
      novosAlertas.add('📊 Ticket médio alto (' + r'R$ ' + '${ticketMedio.toStringAsFixed(2)}), mas poucos clientes');
    }
    
    // Produto com maior desperdício
    if (desperdicioPorProduto.isNotEmpty) {
      var piorProduto = desperdicioPorProduto.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (piorProduto.value > 20) {
        novosAlertas.add('🍽️ Produto com maior desperdício: ${piorProduto.key} (${piorProduto.value.toStringAsFixed(1)}%)');
      }
    }
    
    // Funcionário com menor produtividade
    if (vendasPorFuncionario.isNotEmpty) {
      double mediaVendas = vendasPorFuncionario.values.reduce((a, b) => a + b) / vendasPorFuncionario.length;
      var piorFuncionario = vendasPorFuncionario.entries
          .where((e) => e.value < mediaVendas * 0.6)
          .toList();
      
      if (piorFuncionario.isNotEmpty) {
        novosAlertas.add('👤 Funcionário(s) com produtividade baixa: ${piorFuncionario.length} pessoas abaixo de 60% da média');
      }
    }
    
    alertas = novosAlertas;
  }
  
  void gerarRecomendacoes() {
    List<String> novasRecomendacoes = [];
    
    // Recomendação de produção
    if (percentualDesperdicio > 15) {
      int reducaoSugerida = ((percentualDesperdicio - 15) / 100 * totalItensProduzidos).round();
      novasRecomendacoes.add('🥘 Reduzir produção total em aproximadamente $reducaoSugerida itens amanhã');
    } else if (percentualDesperdicio < 5 && totalItensVendidos > totalItensProduzidos * 0.95) {
      int aumento = (totalItensProduzidos * 1.1).round() - totalItensProduzidos;
      novasRecomendacoes.add('📈 Aumentar produção em $aumento itens (alta demanda)');
    }
    
    // Recomendação de horário
    if (produtividadeMediaHora > 0) {
      String melhorHorario = "11h-14h"; // exemplo
      novasRecomendacoes.add('⏰ Foco no horário de pico: $melhorHorario (melhor produtividade)');
    }
    
    // Recomendação financeira
    double margemLucro = totalVendasLiquido > 0 
        ? (lucroLiquido / totalVendasLiquido) * 100 
        : 0;
    
    if (margemLucro < 20) {
      novasRecomendacoes.add('💰 Margem de lucro baixa (${margemLucro.toStringAsFixed(1)}%). Revisar custos ou preços');
    }
    
    // Recomendação por produto
    if (desperdicioPorProduto.isNotEmpty) {
      var produtosRuins = desperdicioPorProduto.entries
          .where((e) => e.value > 20)
          .take(2)
          .toList();
      
      if (produtosRuins.isNotEmpty) {
        novasRecomendacoes.add('🔧 Revisar produção de: ${produtosRuins.map((e) => e.key).join(', ')}');
      }
    }
    
    recomendacoes = novasRecomendacoes;
  }
  
  // Formatar relatório para exibição
  String formatarRelatorioCompleto() {
    StringBuffer sb = StringBuffer();
    
    sb.writeln('═══════════════════════════════════════');
    sb.writeln('📊 RELATÓRIO DIÁRIO - ${data.day}/${data.month}/${data.year}');
    sb.writeln('═══════════════════════════════════════');
    sb.writeln('');
    sb.writeln('💰 FINANCEIRO');
    sb.writeln('   Vendas Brutas: ' + r'R$ ' + totalVendasBruto.toStringAsFixed(2));
    sb.writeln('   Descontos: ' + r'R$ ' + totalDescontos.toStringAsFixed(2));
    sb.writeln('   Vendas Líquidas: ' + r'R$ ' + totalVendasLiquido.toStringAsFixed(2));
    sb.writeln('   Custo Produção: ' + r'R$ ' + custoTotalProducao.toStringAsFixed(2));
    sb.writeln('   Custo Mercadorias: ' + r'R$ ' + custoTotalMercadorias.toStringAsFixed(2));
    sb.writeln('   Despesas Funcionários: ' + r'R$ ' + despesasFuncionarios.toStringAsFixed(2));
    sb.writeln('   Despesas Fixas: ' + r'R$ ' + despesasFixas.toStringAsFixed(2));
    sb.writeln('   💵 LUCRO LÍQUIDO: ' + r'R$ ' + lucroLiquido.toStringAsFixed(2));
    sb.writeln('');
    sb.writeln('📈 OPERACIONAL');
    sb.writeln('   Itens Vendidos: $totalItensVendidos');
    sb.writeln('   Itens Produzidos: $totalItensProduzidos');
    sb.writeln('   Clientes Atendidos: $totalClientesAtendidos');
    sb.writeln('   Ticket Médio: ' + r'R$ ' + ticketMedio.toStringAsFixed(2));
    sb.writeln('   Desperdício: ${percentualDesperdicio.toStringAsFixed(1)}%');
    sb.writeln('');
    sb.writeln('👥 FUNCIONÁRIOS');
    sb.writeln('   Total Ativos: $totalFuncionariosAtivos');
    sb.writeln('   Eficiência: ${eficienciaFuncionarios.toStringAsFixed(1)} itens/funcionário');
    sb.writeln('');
    sb.writeln('🎯 METAS');
    sb.writeln('   Vendas: ${metaVendasAtingida ? "✅" : "❌"} ' + r'R$ ' + totalVendasLiquido.toStringAsFixed(2) + ' / ' + r'R$ ' + metaVendasDiaria.toStringAsFixed(2));
    sb.writeln('   Desperdício: ${metaDesperdicioAtingida ? "✅" : "❌"} ${percentualDesperdicio.toStringAsFixed(1)}% / $metaDesperdicioMaximo%');
    sb.writeln('');
    sb.writeln('🔔 ALERTAS');
    if (alertas.isEmpty) {
      sb.writeln('   Nenhum alerta no momento');
    } else {
      for (var alerta in alertas) {
        sb.writeln('   $alerta');
      }
    }
    sb.writeln('');
    sb.writeln('💡 RECOMENDAÇÕES');
    if (recomendacoes.isEmpty) {
      sb.writeln('   Operação estável, continue assim!');
    } else {
      for (var rec in recomendacoes) {
        sb.writeln('   $rec');
      }
    }
    sb.writeln('');
    sb.writeln('⭐ STATUS DO DIA: ${status.displayName}');
    sb.writeln('═══════════════════════════════════════');
    
    return sb.toString();
  }
  
  Map<String, dynamic> toMap() {
    return {
      'data': data.toIso8601String(),
      'total_vendas_bruto': totalVendasBruto,
      'total_descontos': totalDescontos,
      'total_vendas_liquido': totalVendasLiquido,
      'custo_producao': custoTotalProducao,
      'custo_mercadorias': custoTotalMercadorias,
      'despesas_funcionarios': despesasFuncionarios,
      'despesas_fixas': despesasFixas,
      'lucro_liquido': lucroLiquido,
      'itens_vendidos': totalItensVendidos,
      'itens_produzidos': totalItensProduzidos,
      'clientes_atendidos': totalClientesAtendidos,
      'funcionarios_ativos': totalFuncionariosAtivos,
      'percentual_desperdicio': percentualDesperdicio,
      'status': status.index,
    };
  }
  
  factory ResultadoDiario.fromMap(Map<String, dynamic> map) {
    return ResultadoDiario(
      data: DateTime.parse(map['data']),
      totalVendasBruto: map['total_vendas_bruto'],
      totalDescontos: map['total_descontos'],
      totalVendasLiquido: map['total_vendas_liquido'],
      custoTotalProducao: map['custo_producao'],
      custoTotalMercadorias: map['custo_mercadorias'],
      despesasFuncionarios: map['despesas_funcionarios'],
      despesasFixas: map['despesas_fixas'],
      lucroLiquido: map['lucro_liquido'],
      totalItensVendidos: map['itens_vendidos'],
      totalItensProduzidos: map['itens_produzidos'],
      totalClientesAtendidos: map['clientes_atendidos'],
      totalFuncionariosAtivos: map['funcionarios_ativos'],
      percentualDesperdicio: map['percentual_desperdicio'],
      status: StatusDia.values[map['status']],
    );
  }
}