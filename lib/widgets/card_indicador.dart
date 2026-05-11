import 'package:flutter/material.dart';

class CardIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final double? variacao;
  final String? subtitulo;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? child;
  
  const CardIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
    this.variacao,
    this.subtitulo,
    this.onTap,
    this.isLoading = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cor.withValues(alpha: 26),
                Colors.white,
              ],
            ),
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(cor),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone e título
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cor.withValues(alpha: 51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icone, color: cor, size: 24),
                        ),
                        if (variacao != null)
                          _buildVariacaoIndicator(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Valor principal
                    Text(
                      valor,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Título
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitulo!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    if (child != null) ...[
                      const SizedBox(height: 8),
                      child!,
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildVariacaoIndicator() {
    final bool isPositive = variacao! >= 0;
    final Color variacaoCor = isPositive ? Colors.green : Colors.red;
    final IconData variacaoIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: variacaoCor.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(variacaoIcon, size: 14, color: variacaoCor),
          const SizedBox(width: 2),
          Text(
            '${variacao!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: variacaoCor,
            ),
          ),
        ],
      ),
    );
  }
}

// Card para indicador de meta
class CardMeta extends StatelessWidget {
  final String titulo;
  final double atual;
  final double meta;
  final String unidade;
  final IconData icone;
  final Color cor;
  
  const CardMeta({
    super.key,
    required this.titulo,
    required this.atual,
    required this.meta,
    required this.unidade,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final double percentual = (atual / meta) * 100;
    final bool metaAtingida = atual >= meta;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: cor, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: metaAtingida ? Colors.green.withValues(alpha: 26) : Colors.orange.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        metaAtingida ? Icons.check_circle : Icons.warning,
                        size: 14,
                        color: metaAtingida ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        metaAtingida ? 'Meta Atingida' : 'Meta Não Atingida',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: metaAtingida ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$atual',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                Text(
                  ' $unidade',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                Text(
                  'Meta: $meta$unidade',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentual / 100,
              backgroundColor: Colors.grey[200],
              color: metaAtingida ? Colors.green : cor,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentual.toStringAsFixed(0)}% da meta',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card para ranking de funcionários
class CardRankingFuncionario extends StatelessWidget {
  final String titulo;
  final List<Map<String, dynamic>> ranking;
  final String metrica;
  final Color cor;
  
  const CardRankingFuncionario({
    super.key,
    required this.titulo,
    required this.ranking,
    required this.metrica,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: cor, size: 24),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...ranking.asMap().entries.map((entry) {
              final index = entry.key;
              final funcionario = entry.value;
              final isTop3 = index < 3;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Posição
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getPosicaoCor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            funcionario['nome'],
                            style: TextStyle(
                              fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          if (funcionario['cargo'] != null)
                            Text(
                              funcionario['cargo'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Valor
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          funcionario['valor'].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cor,
                          ),
                        ),
                        Text(
                          metrica,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (ranking.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Nenhum dado disponível',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPosicaoCor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Ouro
      case 1:
        return Colors.grey[400]!; // Prata
      case 2:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.grey[300]!;
    }
  }
}