class EstoqueItem {
  int? id;
  String nome;
  String categoria;
  double quantidadeAtual;
  double quantidadeMinima;
  DateTime? dataValidade;
  double custoUnitario;
  String unidadeMedida; // 'KG', 'Unidade', 'Litro', 'Gramas', 'Caixa'
  double fatorConversao; // Ex: 1 caixa = 12 unidades

  EstoqueItem({
    this.id,
    required this.nome,
    required this.categoria,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
    this.dataValidade,
    required this.custoUnitario,
    required this.unidadeMedida,
    this.fatorConversao = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome_item': nome,
      'categoria': categoria,
      'quantidade_atual': quantidadeAtual,
      'quantidade_minima': quantidadeMinima,
      'data_validade': dataValidade?.toIso8601String(),
      'custo_unitario': custoUnitario,
      'unidade_medida': unidadeMedida,
      'fator_conversao': fatorConversao,
    };
  }

  factory EstoqueItem.fromMap(Map<String, dynamic> map) {
    return EstoqueItem(
      id: map['id'],
      nome: map['nome_item'],
      categoria: map['categoria'],
      quantidadeAtual: map['quantidade_atual'],
      quantidadeMinima: map['quantidade_minima'],
      dataValidade: map['data_validade'] != null ? DateTime.parse(map['data_validade']) : null,
      custoUnitario: map['custo_unitario'],
      unidadeMedida: map['unidade_medida'],
      fatorConversao: map['fator_conversao'] ?? 1.0,
    );
  }
}
