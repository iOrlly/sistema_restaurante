class NotificacaoGeral {
  int? id;
  String tipo; // 'folga', 'estoque_reposicao', 'estoque_desperdicio'
  String titulo;
  String mensagem;
  DateTime dataCriacao;
  String status; // 'pendente', 'lida'
  int? referenciaId; // ID do item do estoque ou da folga

  NotificacaoGeral({
    this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.dataCriacao,
    this.status = 'pendente',
    this.referenciaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'titulo': titulo,
      'mensagem': mensagem,
      'data_criacao': dataCriacao.toIso8601String(),
      'status': status,
      'referencia_id': referenciaId,
    };
  }

  factory NotificacaoGeral.fromMap(Map<String, dynamic> map) {
    return NotificacaoGeral(
      id: map['id'],
      tipo: map['tipo'],
      titulo: map['titulo'],
      mensagem: map['mensagem'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      status: map['status'],
      referenciaId: map['referencia_id'],
    );
  }
}
