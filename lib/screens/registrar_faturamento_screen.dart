import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class RegistrarFaturamentoScreen extends StatefulWidget {
  const RegistrarFaturamentoScreen({super.key});

  @override
  State<RegistrarFaturamentoScreen> createState() => _RegistrarFaturamentoScreenState();
}

class _RegistrarFaturamentoScreenState extends State<RegistrarFaturamentoScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _faturamentoController = TextEditingController();
  final _observacaoController = TextEditingController();
  DateTime _dataSelecionada = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _historicoDiaSemana = [];
  double _mediaHistorica = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    String dataStr = _dataSelecionada.toIso8601String().split('T')[0];
    final faturamento = await _dbHelper.getFaturamentoPorData(dataStr);
    
    if (faturamento != null) {
      _faturamentoController.text = faturamento['valor'].toString();
      _observacaoController.text = faturamento['observacao'] ?? '';
    } else {
      _faturamentoController.clear();
      _observacaoController.clear();
    }

    _historicoDiaSemana = await _dbHelper.getHistoricoMesmoDiaSemana(_dataSelecionada);
    if (_historicoDiaSemana.isNotEmpty) {
      double soma = _historicoDiaSemana.fold(0, (sum, item) => sum + (item['valor'] as double));
      _mediaHistorica = soma / _historicoDiaSemana.length;
    } else {
      _mediaHistorica = 0;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _salvarFaturamento() async {
    if (_faturamentoController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    String dataStr = _dataSelecionada.toIso8601String().split('T')[0];
    await _dbHelper.upsertFaturamentoDiario(
      dataStr, 
      double.parse(_faturamentoController.text.replaceAll(',', '.')),
      observacao: _observacaoController.text
    );
    await _carregarDados();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Faturamento salvo com sucesso!'), backgroundColor: Colors.green),
    );
  }

  String _getMensagemComparativa() {
    if (_faturamentoController.text.isEmpty || _mediaHistorica == 0) return 'Dados insuficientes para comparação.';
    double valorAtual = double.tryParse(_faturamentoController.text.replaceAll(',', '.')) ?? 0;
    double diff = ((valorAtual - _mediaHistorica) / _mediaHistorica) * 100;
    
    if (diff > 10) return 'Excelente! Hoje rendeu ${diff.toStringAsFixed(1)}% a mais que a média deste dia da semana. 🎉';
    if (diff < -10) return 'Hoje o movimento está ${diff.abs().toStringAsFixed(1)}% abaixo da média para este dia. 📉';
    return 'O movimento de hoje está dentro da média esperada. ✅';
  }

  @override
  Widget build(BuildContext context) {
    String diaSemana = DateFormat('EEEE', 'pt_BR').format(_dataSelecionada);
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Faturamento Geral'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFFFFB300)),
                      title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Dia da semana: ${diaSemana.toUpperCase()}', style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                        tooltip: 'Alterar Data',
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dataSelecionada,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _dataSelecionada = date);
                            _carregarDados();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _faturamentoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: r'Faturamento Total do Dia (R$)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                      prefixIcon: Tooltip(
                        message: 'Faturamento em R\$',
                        child: Icon(Icons.monetization_on, color: Color(0xFFFFB300)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _observacaoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observações do dia',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                      prefixIcon: Tooltip(
                        message: 'Notas e ocorrências',
                        child: Icon(Icons.notes, color: Color(0xFFD32F2F)),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _salvarFaturamento,
                      icon: const Icon(Icons.save),
                      label: const Text('SALVAR FATURAMENTO', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(height: 48, color: Color(0xFF333333)),
                  Text(
                    'COMPARAÇÃO COM HISTÓRICO ($diaSemana)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFB300)),
                  ),
                  const SizedBox(height: 8),
                  Text(_getMensagemComparativa(), style: const TextStyle(color: Color(0xFFE0E0E0))),
                  const SizedBox(height: 24),
                  if (_historicoDiaSemana.isNotEmpty) ...[
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: const Color(0xFF1E1E1E),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final dataRow = _historicoDiaSemana[groupIndex];
                                final dataOriginal = DateTime.parse(dataRow['data'] as String);
                                final dataFormatada = DateFormat('dd/MM/yy').format(dataOriginal);
                                final valor = rod.toY;
                                return BarTooltipItem(
                                  '$dataFormatada\n',
                                  const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'R\$ ${valor.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1)),
                          borderData: FlBorderData(show: false),
                          barGroups: _historicoDiaSemana.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value['valor'],
                                  color: const Color(0xFFFFB300).withOpacity(0.7),
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Barras representam o faturamento em datas passadas deste mesmo dia da semana.',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/registrar_venda'),
                    icon: const Icon(Icons.analytics),
                    label: const Text('IR PARA ANÁLISE DETALHADA'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFB300),
                      side: const BorderSide(color: Color(0xFFFFB300)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
