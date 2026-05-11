import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/resultado_diario.dart';
import '../services/excel_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _dataFim = DateTime.now();
  List<ResultadoDiario> _resultados = [];
  bool _isLoading = true;
  String _tipoRelatorio = 'Diário'; // Diário, Semanal, Mensal, Anual

  final List<DateTime> _feriados = [
    DateTime(2024, 1, 1),
    DateTime(2024, 2, 13),
    DateTime(2024, 3, 29),
    DateTime(2024, 4, 21),
    DateTime(2024, 5, 1),
    DateTime(2024, 5, 30),
    DateTime(2024, 9, 7),
    DateTime(2024, 10, 12),
    DateTime(2024, 11, 2),
    DateTime(2024, 11, 15),
    DateTime(2024, 12, 25),
    DateTime(2025, 1, 1),
  ];

  bool _isFeriado(DateTime data) {
    return _feriados.any((f) => f.day == data.day && f.month == data.month && f.year == data.year);
  }
  
  double _totalFaturamento = 0;
  double _totalLucro = 0;
  double _mediaDesperdicio = 0;
  int _totalClientes = 0;
  double _ticketMedioGlobal = 0;
  
  @override
  void initState() {
    super.initState();
    _carregarRelatorios();
  }
  
  Future<void> _carregarRelatorios() async {
    setState(() => _isLoading = true);
    
    if (_tipoRelatorio == 'Anual') {
      _dataInicio = DateTime(DateTime.now().year, 1, 1);
      _dataFim = DateTime.now();
    } else if (_tipoRelatorio == 'Mensal') {
      _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
      _dataFim = DateTime.now();
    }
    
    final resultados = await _dbHelper.getResultadosPorPeriodo(_dataInicio, _dataFim);
    
    setState(() {
      _resultados = resultados;
      _calcularMetricas();
      _isLoading = false;
    });
  }

  Future<void> _exportarExcel() async {
    final dados = _resultados.map((r) => {
      'Data': DateFormat('dd/MM/yyyy').format(r.data),
      'Feriado': _isFeriado(r.data) ? 'Sim' : 'Não',
      'Faturamento': r.totalVendasLiquido,
      'Lucro': r.lucroLiquido,
      'Itens Vendidos': r.totalItensVendidos,
      'Desperdício %': r.percentualDesperdicio,
      'Status': r.status.displayName,
    }).toList();

    await ExcelService.exportarFaturamento(dados, 'Faturamento_$_tipoRelatorio');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planilha exportada com sucesso!'), backgroundColor: Colors.green),
    );
  }
  
  void _calcularMetricas() {
    if (_resultados.isEmpty) {
      _totalFaturamento = 0;
      _totalLucro = 0;
      _mediaDesperdicio = 0;
      _totalClientes = 0;
      _ticketMedioGlobal = 0;
      return;
    }
    
    _totalFaturamento = _resultados.fold(0.0, (sum, r) => sum + r.totalVendasLiquido);
    _totalLucro = _resultados.fold(0.0, (sum, r) => sum + r.lucroLiquido);
    _mediaDesperdicio = _resultados.fold(0.0, (sum, r) => sum + r.percentualDesperdicio) / _resultados.length;
    _totalClientes = _resultados.fold(0, (sum, r) => sum + r.totalClientesAtendidos);
    _ticketMedioGlobal = _totalClientes > 0 ? _totalFaturamento / _totalClientes : 0;
  }
  
  Future<void> _selecionarPeriodo() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
    );
    
    if (range != null) {
      setState(() {
        _dataInicio = range.start;
        _dataFim = range.end;
        _tipoRelatorio = 'Personalizado';
      });
      _carregarRelatorios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Color(0xFFFFB300)),
            tooltip: 'Exportar para Excel',
            onPressed: _exportarExcel,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFFFFB300)),
            tooltip: 'Selecionar Período',
            onPressed: _selecionarPeriodo,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFFFFB300)),
            tooltip: 'Filtrar Relatório',
            onSelected: (value) {
              setState(() => _tipoRelatorio = value);
              _carregarRelatorios();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Diário', child: Text('Relatório Diário')),
              const PopupMenuItem(value: 'Semanal', child: Text('Resumo Semanal')),
              const PopupMenuItem(value: 'Mensal', child: Text('Resumo Mensal')),
              const PopupMenuItem(value: 'Anual', child: Text('Resumo Anual')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : _resultados.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum dado no período selecionado',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESUMO DO PERÍODO',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      _buildResumoCards(),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'EVOLUÇÃO DE VENDAS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      _buildGraficoVendas(),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'DESPERDÍCIO (%)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      _buildGraficoDesperdicio(),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'DETALHAMENTO DIÁRIO',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ..._resultados.map((resultado) => _buildResultadoCard(resultado)),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildResumoCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildCardResumo(
          'Faturamento Total',
          r'R$ ' + _totalFaturamento.toStringAsFixed(2),
          Icons.attach_money,
          const Color(0xFFFFB300),
        ),
        _buildCardResumo(
          'Lucro Total',
          r'R$ ' + _totalLucro.toStringAsFixed(2),
          Icons.trending_up,
          const Color(0xFFD32F2F),
        ),
        _buildCardResumo(
          'Desperdício Médio',
          '${_mediaDesperdicio.toStringAsFixed(1)}%',
          Icons.warning,
          _mediaDesperdicio > 15 ? Colors.redAccent : const Color(0xFFFFB300),
        ),
        _buildCardResumo(
          'Ticket Médio',
          r'R$ ' + _ticketMedioGlobal.toStringAsFixed(2),
          Icons.receipt,
          Colors.blueAccent,
        ),
      ],
    );
  }
  
  Widget _buildCardResumo(String titulo, String valor, IconData icon, Color cor) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: cor),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGraficoVendas() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05))),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _resultados.length) {
                    return Text(
                      DateFormat('dd/MM').format(_resultados[value.toInt()].data),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _resultados.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.totalVendasLiquido);
              }).toList(),
              isCurved: true,
              color: const Color(0xFFD32F2F),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFD32F2F).withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF2C2C2C),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final resultado = _resultados[touchedSpot.x.toInt()];
                  final dataFormatada = DateFormat('dd/MM/yy').format(resultado.data);
                  return LineTooltipItem(
                    '$dataFormatada\n',
                    const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: 'R\$ ${touchedSpot.y.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGraficoDesperdicio() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _resultados.length) {
                    return Text(
                      DateFormat('dd/MM').format(_resultados[value.toInt()].data),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _resultados.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.percentualDesperdicio,
                  color: entry.value.percentualDesperdicio > 15 
                      ? const Color(0xFFD32F2F) 
                      : const Color(0xFFFFB300),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF2C2C2C),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final resultado = _resultados[groupIndex];
                final dataFormatada = DateFormat('dd/MM/yy').format(resultado.data);
                return BarTooltipItem(
                  '$dataFormatada\n',
                  const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultadoCard(ResultadoDiario resultado) {
    bool feriado = _isFeriado(resultado.data);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        iconColor: const Color(0xFFFFB300),
        collapsedIconColor: Colors.grey,
        leading: CircleAvatar(
          backgroundColor: feriado ? const Color(0xFFFFB300) : resultado.status.cor.withOpacity(0.2),
          child: Icon(
            feriado ? Icons.star : Icons.calendar_today,
            color: feriado ? Colors.black : resultado.status.cor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(resultado.data),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            if (feriado)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text('Feriado', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Color(0xFFFFB300),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoLinha('💰 Vendas Líquidas', r'R$ ' + resultado.totalVendasLiquido.toStringAsFixed(2)),
                _buildInfoLinha('📈 Lucro', r'R$ ' + resultado.lucroLiquido.toStringAsFixed(2)),
                _buildInfoLinha('🍽️ Itens Vendidos', resultado.totalItensVendidos.toString()),
                _buildInfoLinha('🗑️ Desperdício', '${resultado.percentualDesperdicio.toStringAsFixed(1)}%'),
                
                if (resultado.alertas.isNotEmpty) ...[
                  const Divider(color: Colors.white10, height: 24),
                  const Text('Alertas:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F), fontSize: 12)),
                  const SizedBox(height: 8),
                  ...resultado.alertas.map((alerta) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 14, color: Color(0xFFFFB300)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(alerta, style: const TextStyle(fontSize: 11, color: Color(0xFFE0E0E0)))),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoLinha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
