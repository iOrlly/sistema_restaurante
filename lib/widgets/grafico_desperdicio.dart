import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GraficoDesperdicio extends StatefulWidget {
  final List<Map<String, dynamic>> dados;
  final double altura;
  final bool mostrarPrevisao;
  
  const GraficoDesperdicio({
    super.key,
    required this.dados,
    this.altura = 300,
    this.mostrarPrevisao = true,
  });

  @override
  State<GraficoDesperdicio> createState() => _GraficoDesperdicioState();
}

class _GraficoDesperdicioState extends State<GraficoDesperdicio> {
  int _touchedIndex = -1;
  String _tipoGrafico = 'barras'; // barras, linha, pizza

  @override
  Widget build(BuildContext context) {
    if (widget.dados.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: widget.altura,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 26),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header com controles
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Desperdício Diário (%)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Botões de tipo de gráfico
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildTipoGraficoButton(Icons.bar_chart, 'barras'),
                      _buildTipoGraficoButton(Icons.show_chart, 'linha'),
                      _buildTipoGraficoButton(Icons.pie_chart, 'pizza'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Gráfico
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildGrafico(),
            ),
          ),
          // Legenda
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegenda('Desperdício', Colors.orange),
                const SizedBox(width: 16),
                _buildLegenda('Meta (15%)', Colors.green),
                if (_tipoGrafico == 'barras') ...[
                  const SizedBox(width: 16),
                  _buildLegenda('Crítico (>20%)', Colors.red),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoGraficoButton(IconData icon, String tipo) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoGrafico = tipo;
          _touchedIndex = -1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _tipoGrafico == tipo ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: _tipoGrafico == tipo ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildGrafico() {
    switch (_tipoGrafico) {
      case 'linha':
        return _buildGraficoLinha();
      case 'pizza':
        return _buildGraficoPizza();
      default:
        return _buildGraficoBarras();
    }
  }

  Widget _buildGraficoBarras() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 50,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.dados.length) {
                  final data = widget.dados[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM').format(data['data']),
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.dados.asMap().entries.map((entry) {
          final int index = entry.key;
          final double desperdicio = entry.value['desperdicio'];
          final bool isTouched = _touchedIndex == index;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: desperdicio,
                color: _getCorDesperdicio(desperdicio),
                width: 30,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 15, // Linha da meta
                  color: Colors.green.withValues(alpha: 77),
                ),
              ),
            ],
            showingTooltipIndicators: isTouched ? [0] : [],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final desperdicio = widget.dados[group.x.toInt()]['desperdicio'];
              final data = widget.dados[group.x.toInt()]['data'];
              return BarTooltipItem(
                '${DateFormat('dd/MM/yyyy').format(data)}\n',
                const TextStyle(color: Colors.white, fontSize: 12),
                children: [
                  TextSpan(
                    text: 'Desperdício: ${desperdicio.toStringAsFixed(1)}%\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getCorDesperdicio(desperdicio),
                    ),
                  ),
                  if (desperdicio > 15)
                    const TextSpan(
                      text: '⚠️ Acima da meta!',
                      style: TextStyle(color: Colors.orange),
                    ),
                ],
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (barTouchResponse == null || barTouchResponse.spot == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
        ),
      ),
    );
  }

  Widget _buildGraficoLinha() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 10,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.dados.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM').format(widget.dados[value.toInt()]['data']),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 50,
        lineBarsData: [
          // Linha de desperdício
          LineChartBarData(
            spots: widget.dados.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value['desperdicio']);
            }).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withValues(alpha: 26),
            ),
          ),
          // Linha da meta
          LineChartBarData(
            spots: [
              const FlSpot(0, 15),
              FlSpot(widget.dados.length.toDouble() - 1, 15),
            ],
            isCurved: false,
            color: Colors.green,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // Previsão (se habilitado)
          if (widget.mostrarPrevisao && widget.dados.length >= 3)
            LineChartBarData(
              spots: _calcularPrevisao(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              dashArray: [8, 4],
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final desperdicio = spot.y;
                final data = widget.dados[spot.x.toInt()]['data'];
                return LineTooltipItem(
                  '${DateFormat('dd/MM/yyyy').format(data)}\n',
                  const TextStyle(color: Colors.white, fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Desperdício: ${desperdicio.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGraficoPizza() {
    // Agrupar dados por categoria de desperdício
    Map<String, double> categorias = {
      'Excelente (<5%)': 0,
      'Bom (5-10%)': 0,
      'Atenção (10-15%)': 0,
      'Crítico (>15%)': 0,
    };
    
    for (var dado in widget.dados) {
      double desperdicio = dado['desperdicio'];
      if (desperdicio < 5) {
        categorias['Excelente (<5%)'] = categorias['Excelente (<5%)']! + 1;
      } else if (desperdicio < 10) {
        categorias['Bom (5-10%)'] = categorias['Bom (5-10%)']! + 1;
      } else if (desperdicio < 15) {
        categorias['Atenção (10-15%)'] = categorias['Atenção (10-15%)']! + 1;
      } else {
        categorias['Crítico (>15%)'] = categorias['Crítico (>15%)']! + 1;
      }
    }
    
    final List<Map<String, dynamic>> pizzaDados = categorias.entries
        .where((e) => e.value > 0)
        .map((e) => {
          'categoria': e.key,
          'quantidade': e.value,
          'cor': _getCorCategoria(e.key),
        })
        .toList();
    
    return PieChart(
      PieChartData(
        sections: pizzaDados.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final total = pizzaDados.fold<double>(0.0, (sum, item) => sum + (item['quantidade'] as double));
          final percentage = (data['quantidade'] as double) / total * 100;
          
          return PieChartSectionData(
            color: data['cor'],
            value: data['quantidade'],
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _touchedIndex == index
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 204),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data['categoria'],
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        Text(
                          '${(data['quantidade'] as double).toInt()} dias',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
      ),
    );
  }

  List<FlSpot> _calcularPrevisao() {
    // Previsão simples baseada em média móvel dos últimos 3 dias
    final List<FlSpot> previsao = [];
    final ultimosValores = widget.dados.reversed.take(3).map((e) => e['desperdicio']).toList();
    final media = ultimosValores.reduce((a, b) => a + b) / ultimosValores.length;
    final tendencia = ultimosValores[0] - ultimosValores.last;
    
    for (int i = 1; i <= 3; i++) {
      double previsaoValor = media + (tendencia * i * 0.3);
      previsaoValor = previsaoValor.clamp(0, 50);
      previsao.add(FlSpot(widget.dados.length - 1 + i.toDouble(), previsaoValor));
    }
    
    return previsao;
  }

  Widget _buildLegenda(String texto, Color cor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getCorDesperdicio(double desperdicio) {
    if (desperdicio > 20) return Colors.red;
    if (desperdicio > 15) return Colors.orange;
    if (desperdicio > 10) return Colors.yellow[700]!;
    if (desperdicio > 5) return Colors.lightGreen;
    return Colors.green;
  }

  Color _getCorCategoria(String categoria) {
    if (categoria.contains('Excelente')) return Colors.green;
    if (categoria.contains('Bom')) return Colors.lightGreen;
    if (categoria.contains('Atenção')) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.altura,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 26),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum dado disponível',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Registre vendas e produções para ver os gráficos',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}