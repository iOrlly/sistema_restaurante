import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/excel_service.dart';

class FechamentoCaixaScreen extends StatefulWidget {
  const FechamentoCaixaScreen({super.key});

  @override
  State<FechamentoCaixaScreen> createState() => _FechamentoCaixaScreenState();
}

class _FechamentoCaixaScreenState extends State<FechamentoCaixaScreen> {
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  Map<String, dynamic> _dados = {
    'total_vendas': 0.0,
    'total_boletos': 0.0,
    'total_diarias': 0.0,
    'lucro_liquido': 0.0,
    'lista_vendas': [],
    'lista_boletos': [],
    'lista_diarias': [],
  };

  final _observacaoController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sincronizarDados();
  }

  Future<void> _sincronizarDados() async {
    setState(() => _isLoading = true);
    try {
      final res = await DatabaseHelper.instance.getDadosRelatorioPeriodo(_periodo.start, _periodo.end);
      setState(() {
        _dados = res;
      });
    } catch (e) {
      debugPrint("Erro ao sincronizar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _periodo,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD32F2F),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _periodo = picked);
      _sincronizarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('FECHAMENTO & FLUXO'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFB300),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Excel do Período',
            onPressed: () => ExcelService.exportarRelatorioGeral(_dados, _periodo),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seletor de Período
                  Card(
                    color: const Color(0xFF1E1E1E),
                    child: ListTile(
                      leading: const Icon(Icons.date_range, color: Color(0xFFFFB300)),
                      title: const Text('PERÍODO SELECIONADO', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yy').format(_periodo.start)} até ${DateFormat('dd/MM/yy').format(_periodo.end)}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar, color: Color(0xFFD32F2F)),
                        onPressed: _selecionarPeriodo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Container de Entradas (Bruto)
                  _buildSectionHeader('ENTRADAS (DINHEIRO EM CAIXA)'),
                  _buildDataBox('Total de Vendas / Faturamento', _dados['total_vendas'], Colors.green),
                  
                  const SizedBox(height: 16),

                  // Container de Saídas (Custos)
                  _buildSectionHeader('SAÍDAS (DÉBITOS PAGOS)'),
                  _buildDataBox('Boletos de Fornecedores/Contas', _dados['total_boletos'], const Color(0xFFD32F2F)),
                  const SizedBox(height: 8),
                  _buildDataBox('Diárias de Funcionários / Extras', _dados['total_diarias'], const Color(0xFFD32F2F)),

                  const SizedBox(height: 32),

                  // Resultado Final (Liquido)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.5), width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'LUCRO LÍQUIDO DO PERÍODO',
                          style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'R\$ ${(_dados['lucro_liquido'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFFFB300)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Input de Observação (Único campo editável)
                  const Text('NOTAS E OBSERVAÇÕES', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacaoController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      hintText: 'Digite ocorrências, quebras de caixa ou notas importantes...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildDataBox(String label, double valor, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
