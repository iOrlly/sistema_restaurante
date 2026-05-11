class Fechamento {
  int? id;
  DateTime data;
  double valorBruto;
  double custoFuncionarios;
  double gastosExtras;
  double lucroLiquido;
  String? observacao;

  Fechamento({
    this.id,
    required this.data,
    required this.valorBruto,
    required this.custoFuncionarios,
    required this.gastosExtras,
    required this.lucroLiquido,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String().split('T')[0],
      'valor_bruto': valorBruto,
      'custo_funcionarios': custoFuncionarios,
      'gastos_extras': gastosExtras,
      'lucro_liquido': lucroLiquido,
      'observacao': observacao,
    };
  }

  factory Fechamento.fromMap(Map<String, dynamic> map) {
    return Fechamento(
      id: map['id'],
      data: DateTime.parse(map['data']),
      valorBruto: map['valor_bruto'],
      custoFuncionarios: map['custo_funcionarios'],
      gastosExtras: map['gastos_extras'],
      lucroLiquido: map['lucro_liquido'],
      observacao: map['observacao'],
    );
  }
}
