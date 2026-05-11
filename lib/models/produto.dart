class Produto {
  int? id;
  String nome;
  String categoria;
  double precoUnitario;
  int tempoPreparoMin;

  Produto({
    this.id,
    required this.nome,
    required this.categoria,
    required this.precoUnitario,
    required this.tempoPreparoMin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'preco_unitario': precoUnitario,
      'tempo_preparo_min': tempoPreparoMin,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'],
      nome: map['nome'],
      categoria: map['categoria'],
      precoUnitario: map['preco_unitario'],
      tempoPreparoMin: map['tempo_preparo_min'],
    );
  }
}