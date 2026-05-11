import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/fechamento.dart';

class FechamentoCaixaScreen extends StatefulWidget {
  const FechamentoCaixaScreen({super.key});

  @override
  State<FechamentoCaixaScreen> createState() => _FechamentoCaixaScreenState();
}

class _FechamentoCaixaScreenState extends State<FechamentoCaixaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendasController = TextEditingController();
  final _diariasController = TextEditingController();
  final _gastosExtrasController = TextEditingController();
  final _observacaoController = TextEditingController();
  
  DateTime _dataSelecionada = DateTime.now();
  double _lucroCalculado = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarFechamento();
  }

  Future<void> _carregarFechamento() async {
    setState(() => _isLoading = true);
    try {
      String dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada);
      final fechamento = await DatabaseHelper.instance.getFechamentoPorData(dataStr);
      
      if (fechamento != null) {
        _vendasController.text = fechamento.valorBruto.toString().replaceAll('.', ',');
        _diariasController.text = fechamento.custoFuncionarios.toString().replaceAll('.', ',');
        _gastosExtrasController.text = fechamento.gastosExtras.toString().replaceAll('.', ',');
        _observacaoController.text = fechamento.observacao ?? '';
        _calcularLucro();
      } else {
        _vendasController.clear();
        _diariasController.clear();
        _gastosExtrasController.clear();
        _observacaoController.clear();
        _lucroCalculado = 0.0;
      }
    } catch (e) {
      debugPrint("Erro ao carregar fechamento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calcularLucro() {
    double bruto = double.tryParse(_vendasController.text.replaceAll(',', '.')) ?? 0.0;
    double diarias = double.tryParse(_diariasController.text.replaceAll(',', '.')) ?? 0.0;
    double extras = double.tryParse(_gastosExtrasController.text.replaceAll(',', '.')) ?? 0.0;
    
    setState(() {
      _lucroCalculado = bruto - (diarias + extras);
    });
  }

  Future<void> _salvarFechamento() async {
    if (!_formKey.currentState!.validate()) return;
    
    _calcularLucro();
    
    final fechamento = Fechamento(
      data: _dataSelecionada,
      valorBruto: double.parse(_vendasController.text.replaceAll(',', '.')),
      custoFuncionarios: double.parse(_diariasController.text.replaceAll(',', '.')),
      gastosExtras: double.parse(_gastosExtrasController.text.replaceAll(',', '.')),
      lucroLiquido: _lucroCalculado,
      observacao: _observacaoController.text,
    );

    await DatabaseHelper.instance.insertFechamento(fechamento);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fechamento salvo com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Fechamento de Caixa'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month, color: Color(0xFFFFB300)),
                        title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}', style: const TextStyle(color: Colors.white)),
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
                              _carregarFechamento();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildFireInput(_vendasController, r'Vendas Brutas (R$)', Icons.monetization_on, 'Total ganho no dia'),
                    const SizedBox(height: 16),
                    _buildFireInput(_diariasController, r'Diárias Funcionários (R$)', Icons.people_alt, 'Soma das diárias pagas'),
                    const SizedBox(height: 16),
                    _buildFireInput(_gastosExtrasController, r'Gastos Diversos (R$)', Icons.shopping_basket, 'Compras e emergências'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _observacaoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Observações (ex: ocorrências)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                        prefixIcon: Tooltip(
                          message: 'Motivos e notas',
                          child: Icon(Icons.note_add, color: Color(0xFFD32F2F)),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lucroCalculado >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_lucroCalculado >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)).withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'LUCRO LÍQUIDO ESTIMADO',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            r'R$ ' + _lucroCalculado.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 36, 
                              fontWeight: FontWeight.bold,
                              color: _lucroCalculado >= 0 ? const Color(0xFFFFB300) : const Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _salvarFechamento,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('FINALIZAR FECHAMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFireInput(TextEditingController controller, String label, IconData icon, [String? tip]) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
        prefixIcon: Tooltip(
          message: tip ?? label,
          child: Icon(icon, color: const Color(0xFFFFB300)),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => _calcularLucro(),
    );
  }
}
