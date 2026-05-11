class NotificacaoFolga {
  int? id;
  int funcionarioId;
  String funcionarioNome;
  String funcionarioCargo;
  DateTime dataSolicitada;
  DateTime dataCriacao;
  String status; // 'pendente', 'aprovado', 'recusado'
  String? motivo;

  NotificacaoFolga({
    this.id,
    required this.funcionarioId,
    required this.funcionarioNome,
    required this.funcionarioCargo,
    required this.dataSolicitada,
    required this.dataCriacao,
    this.status = 'pendente',
    this.motivo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'funcionario_id': funcionarioId,
      'data_solicitada': dataSolicitada.toIso8601String().split('T')[0],
      'data_criacao': dataCriacao.toIso8601String(),
      'status': status,
      'motivo': motivo,
    };
  }

  factory NotificacaoFolga.fromMap(Map<String, dynamic> map, String nome, String cargo) {
    return NotificacaoFolga(
      id: map['id'],
      funcionarioId: map['funcionario_id'],
      funcionarioNome: nome,
      funcionarioCargo: cargo,
      dataSolicitada: DateTime.parse(map['data_solicitada']),
      dataCriacao: DateTime.parse(map['data_criacao']),
      status: map['status'],
      motivo: map['motivo'],
    );
  }
}
