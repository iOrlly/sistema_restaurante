class Terceirizado {
  int? id;
  String nome;
  double valorDiaria;
  int diasTrabalhados;
  String contato;
  String? observacao;

  Terceirizado({
    this.id,
    required this.nome,
    required this.valorDiaria,
    this.diasTrabalhados = 0,
    required this.contato,
    this.observacao,
  });

  double get totalDevido => valorDiaria * diasTrabalhados;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valor_diaria': valorDiaria,
      'dias_trabalhados': diasTrabalhados,
      'contato': contato,
      'observacao': observacao,
    };
  }

  factory Terceirizado.fromMap(Map<String, dynamic> map) {
    return Terceirizado(
      id: map['id'],
      nome: map['nome'],
      valorDiaria: map['valor_diaria'],
      diasTrabalhados: map['dias_trabalhados'],
      contato: map['contato'],
      observacao: map['observacao'],
    );
  }
}
