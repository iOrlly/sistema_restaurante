import 'package:flutter/material.dart';

enum SetorFuncionario {
  cozinha,
  salao,
  administrativo,
  pizzaria,
  outro,
}

extension SetorFuncionarioExtension on SetorFuncionario {
  String get displayName {
    switch (this) {
      case SetorFuncionario.cozinha: return 'Cozinha';
      case SetorFuncionario.salao: return 'Salão';
      case SetorFuncionario.administrativo: return 'Administrativo';
      case SetorFuncionario.pizzaria: return 'Pizzaria';
      case SetorFuncionario.outro: return 'Outro';
    }
  }
}

enum CargoFuncionario {
  cozinheiro,
  atendente,
  gerente,
  auxiliarLimpanca,
  pizzaiolo,
  garcon,
  auxiliarCozinha,
  outro,
}

extension CargoFuncionarioExtension on CargoFuncionario {
  String get displayName {
    switch (this) {
      case CargoFuncionario.cozinheiro: return 'Cozinheiro(a)';
      case CargoFuncionario.atendente: return 'Atendente';
      case CargoFuncionario.gerente: return 'Gerente';
      case CargoFuncionario.auxiliarLimpanca: return 'Auxiliar de Limpeza';
      case CargoFuncionario.pizzaiolo: return 'Pizzaiolo(a)';
      case CargoFuncionario.garcon: return 'Garçom/Garçonete';
      case CargoFuncionario.auxiliarCozinha: return 'Auxiliar de Cozinha';
      case CargoFuncionario.outro: return 'Outro';
    }
  }

  Color get cor {
    switch (this) {
      case CargoFuncionario.cozinheiro: return Colors.blue;
      case CargoFuncionario.atendente: return Colors.green;
      case CargoFuncionario.gerente: return Colors.purple;
      case CargoFuncionario.auxiliarLimpanca: return Colors.orange;
      case CargoFuncionario.pizzaiolo: return Colors.red;
      case CargoFuncionario.garcon: return Colors.teal;
      default: return Colors.grey;
    }
  }
}

class Funcionario {
  int? id;
  String nome;
  SetorFuncionario setor;
  CargoFuncionario cargo;
  SetorFuncionario? setor2;
  CargoFuncionario? cargo2;
  DateTime dataContratacao;
  String telefone;
  double salario;
  double valorDiaria;
  int diasTrabalhados;
  bool ativo;
  bool emFerias;
  DateTime? dataInicioFerias;
  String? observacao;
  double produtividadeMedia;
  int totalHorasTrabalhadas;
  int totalItensProduzidosOuVendidos;
  DateTime? ultimaAvaliacao;

  Funcionario({
    this.id,
    required this.nome,
    this.setor = SetorFuncionario.outro,
    required this.cargo,
    this.setor2,
    this.cargo2,
    required this.dataContratacao,
    required this.telefone,
    required this.salario,
    this.valorDiaria = 0.0,
    this.diasTrabalhados = 0,
    this.ativo = true,
    this.emFerias = false,
    this.dataInicioFerias,
    this.observacao,
    this.produtividadeMedia = 0.0,
    this.totalHorasTrabalhadas = 0,
    this.totalItensProduzidosOuVendidos = 0,
    this.ultimaAvaliacao,
  });

  // Calcular produtividade baseado no histórico
  void calcularProdutividadeMedia() {
    if (totalHorasTrabalhadas > 0) {
      produtividadeMedia = totalItensProduzidosOuVendidos / totalHorasTrabalhadas;
    }
  }

  // Adicionar registro de produção/vendas
  void adicionarRegistroProducao(int quantidadeItens, int horasTrabalhadas) {
    totalItensProduzidosOuVendidos += quantidadeItens;
    totalHorasTrabalhadas += horasTrabalhadas;
    calcularProdutividadeMedia();
  }

  // Verificar eficiência (se está abaixo da média esperada)
  String getAvaliacoEficiencia(double mediaEquipe) {
    if (produtividadeMedia >= mediaEquipe * 1.2) {
      return 'Excelente 🏆';
    } else if (produtividadeMedia >= mediaEquipe) {
      return 'Bom ✅';
    } else if (produtividadeMedia >= mediaEquipe * 0.8) {
      return 'Regular ⚠️';
    } else {
      return 'Necessita Melhorar ❌';
    }
  }

  // Tempo de casa em meses
  int get tempoDeCasaMeses {
    final now = DateTime.now();
    int months = (now.year - dataContratacao.year) * 12;
    months += now.month - dataContratacao.month;
    return months;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'setor': setor.index,
      'cargo': cargo.index,
      'setor2': setor2?.index,
      'cargo2': cargo2?.index,
      'data_contratacao': dataContratacao.toIso8601String(),
      'telefone': telefone,
      'salario': salario,
      'valor_diaria': valorDiaria,
      'dias_trabalhados': diasTrabalhados,
      'ativo': ativo ? 1 : 0,
      'em_ferias': emFerias ? 1 : 0,
      'data_inicio_ferias': dataInicioFerias?.toIso8601String(),
      'observacao': observacao,
      'produtividade_media': produtividadeMedia,
      'total_horas_trabalhadas': totalHorasTrabalhadas,
      'total_itens_produzidos': totalItensProduzidosOuVendidos,
      'ultima_avaliacao': ultimaAvaliacao?.toIso8601String(),
    };
  }

  factory Funcionario.fromMap(Map<String, dynamic> map) {
    return Funcionario(
      id: map['id'],
      nome: map['nome'],
      setor: map['setor'] != null ? SetorFuncionario.values[map['setor']] : SetorFuncionario.outro,
      cargo: CargoFuncionario.values[map['cargo']],
      setor2: map['setor2'] != null ? SetorFuncionario.values[map['setor2']] : null,
      cargo2: map['cargo2'] != null ? CargoFuncionario.values[map['cargo2']] : null,
      dataContratacao: DateTime.parse(map['data_contratacao']),
      telefone: map['telefone'],
      salario: map['salario'],
      valorDiaria: (map['valor_diaria'] ?? 0.0).toDouble(),
      diasTrabalhados: map['dias_trabalhados'] ?? 0,
      ativo: map['ativo'] == 1,
      emFerias: map['em_ferias'] == 1,
      dataInicioFerias: map['data_inicio_ferias'] != null ? DateTime.parse(map['data_inicio_ferias']) : null,
      observacao: map['observacao'],
      produtividadeMedia: map['produtividade_media'] ?? 0.0,
      totalHorasTrabalhadas: map['total_horas_trabalhadas'] ?? 0,
      totalItensProduzidosOuVendidos: map['total_itens_produzidos'] ?? 0,
      ultimaAvaliacao: map['ultima_avaliacao'] != null ? DateTime.parse(map['ultima_avaliacao']) : null,
    );
  }

  @override
  String toString() {
    return '$nome - ${cargo.displayName} (Produtividade: ${produtividadeMedia.toStringAsFixed(1)} itens/hora)';
  }
}