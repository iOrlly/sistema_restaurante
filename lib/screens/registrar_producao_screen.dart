import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';
import '../models/producao_dia.dart';
import '../models/funcionario.dart';

class RegistrarProducaoScreen extends StatefulWidget {
  const RegistrarProducaoScreen({super.key});

  @override
  State<RegistrarProducaoScreen> createState() => _RegistrarProducaoScreenState();
}

class _RegistrarProducaoScreenState extends State<RegistrarProducaoScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  
  final _quantidadeProduzidaController = TextEditingController();
  final _quantidadeRestanteController = TextEditingController();
  final _custoEstimadoController = TextEditingController();
  final _motivoSobraController = TextEditingController();
  
  List<Produto> _produtos = [];
  List<Funcionario> _funcionarios = [];
  Produto? _produtoSelecionado;
  Funcionario? _funcionarioResponsavel;
  DateTime _dataProducao = DateTime.now();
  TimeOfDay _horarioInicio = TimeOfDay.now();
  TimeOfDay _horarioFim = TimeOfDay.now();
  
  bool _isLoading = true;
  String? _sugestaoProducao;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    final produtos = await _dbHelper.getAllProdutos();
    final funcionarios = await _dbHelper.getAllFuncionarios();
    
    setState(() {
      _produtos = produtos;
      _funcionarios = funcionarios.where((f) => f.ativo).toList();
      _isLoading = false;
    });
  }

  Future<void> _registrarProducao() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_produtoSelecionado == null) {
      _mostrarSnackBar('Selecione um produto', Colors.red);
      return;
    }
    
    if (_funcionarioResponsavel == null) {
      _mostrarSnackBar('Selecione o funcionário responsável', Colors.red);
      return;
    }
    
    int quantidadeProduzida = int.parse(_quantidadeProduzidaController.text);
    int quantidadeRestante = int.parse(_quantidadeRestanteController.text);
    
    if (quantidadeRestante > quantidadeProduzida) {
      _mostrarSnackBar('Quantidade restante não pode ser maior que a produzida', Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);
    
    final DateTime inicio = DateTime(
      _dataProducao.year,
      _dataProducao.month,
      _dataProducao.day,
      _horarioInicio.hour,
      _horarioInicio.minute,
    );
    
    final DateTime fim = DateTime(
      _dataProducao.year,
      _dataProducao.month,
      _dataProducao.day,
      _horarioFim.hour,
      _horarioFim.minute,
    );
    
    final producao = ProducaoDia(
      data: _dataProducao,
      produtoId: _produtoSelecionado!.id!,
      produtoNome: _produtoSelecionado!.nome,
      quantidadeProduzida: quantidadeProduzida,
      quantidadeRestante: quantidadeRestante,
      motivoSobra: _motivoSobraController.text.isEmpty ? null : _motivoSobraController.text,
      horarioInicioProducao: inicio,
      horarioFimProducao: fim,
      funcionarioResponsavelId: _funcionarioResponsavel!.id!,
      custoEstimadoProducao: double.parse(_custoEstimadoController.text),
      houveDesperdicio: quantidadeRestante > 0,
    );
    
    // Salvar no banco
    await _dbHelper.insertProducao(producao);
    
    // Atualizar produtividade do funcionário
    _funcionarioResponsavel!.adicionarRegistroProducao(
      quantidadeProduzida, 
      producao.tempoProducaoHoras.round()
    );
    await _dbHelper.updateFuncionario(_funcionarioResponsavel!);
    
    setState(() => _isLoading = false);
    
    // Mostrar análise
    _mostrarDialogAnalise(producao);
  }
  
  void _mostrarDialogAnalise(ProducaoDia producao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Análise da Produção'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producao.alertaDesperdicio),
            const SizedBox(height: 10),
            const Divider(),
            Text(
              producao.sugestaoProximaProducao,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            Text(
              'Eficiência: ${producao.eficienciaProducao.toStringAsFixed(1)} itens/hora',
              style: const TextStyle(fontSize: 12),
            ),
            if (producao.temDesperdicioSignificativo)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Custo do desperdício: R\$ ${producao.custoDesperdicio.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _limparFormulario();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _limparFormulario() {
    _quantidadeProduzidaController.clear();
    _quantidadeRestanteController.clear();
    _custoEstimadoController.clear();
    _motivoSobraController.clear();
    _produtoSelecionado = null;
    _funcionarioResponsavel = null;
    _horarioInicio = TimeOfDay.now();
    _horarioFim = TimeOfDay.now();
    setState(() {});
  }
  
  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _calcularSugestao() {
    if (_produtoSelecionado != null && _quantidadeProduzidaController.text.isNotEmpty) {
      int produzido = int.tryParse(_quantidadeProduzidaController.text) ?? 0;
      int restante = int.tryParse(_quantidadeRestanteController.text) ?? 0;
      
      if (produzido > 0) {
        double percentual = (restante / produzido) * 100;
        if (percentual > 15) {
          int reduzir = (produzido * (percentual - 15) / 100).round();
          setState(() {
            _sugestaoProducao = '⚠️ Reduza a produção em $reduzir unidades na próxima vez';
          });
        } else if (percentual < 5 && restante < 3) {
          setState(() {
            _sugestaoProducao = '📈 Aumente a produção em ${(produzido * 0.1).round()} unidades';
          });
        } else {
          setState(() {
            _sugestaoProducao = '✅ Produção balanceada, mantenha o ritmo';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int sobra = int.tryParse(_quantidadeRestanteController.text) ?? 0;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Registrar Produção'),
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
                        leading: const Icon(Icons.calendar_today, color: Color(0xFFFFB300)),
                        title: const Text('Data da Produção', style: TextStyle(color: Colors.white)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataProducao), style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                          tooltip: 'Alterar Data',
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _dataProducao,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setState(() => _dataProducao = date);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    DropdownButtonFormField<Produto>(
                      decoration: const InputDecoration(
                        labelText: 'Produto *',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                        prefixIcon: Tooltip(
                          message: 'Selecione o produto produzido',
                          child: Icon(Icons.fastfood, color: Color(0xFFD32F2F)),
                        ),
                      ),
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      initialValue: _produtoSelecionado,
                      items: _produtos.map((produto) => DropdownMenuItem(value: produto, child: Text(produto.nome))).toList(),
                      onChanged: (value) => setState(() => _produtoSelecionado = value),
                      validator: (value) => value == null ? 'Selecione um produto' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFireInput(_quantidadeProduzidaController, 'Quantidade Produzida *', Icons.production_quantity_limits, 'Total produzido hoje'),
                    const SizedBox(height: 16),
                    _buildFireInput(_quantidadeRestanteController, 'Quantidade Restante (sobra)', Icons.inventory, 'O que não foi vendido'),
                    
                    if (_sugestaoProducao != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Tooltip(
                              message: 'Sugestão automática',
                              child: Icon(Icons.lightbulb, color: Color(0xFFFFB300), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_sugestaoProducao!, style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    _buildFireInput(_custoEstimadoController, r'Custo Estimado (R$)', Icons.attach_money, 'Custo de ingredientes/insumos'),
                    
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Funcionario>(
                      decoration: const InputDecoration(
                        labelText: 'Responsável *',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                        prefixIcon: Tooltip(
                          message: 'Funcionário encarregado',
                          child: Icon(Icons.person, color: Color(0xFFD32F2F)),
                        ),
                      ),
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      initialValue: _funcionarioResponsavel,
                      items: _funcionarios.map((f) => DropdownMenuItem(value: f, child: Text(f.nome))).toList(),
                      onChanged: (value) => setState(() => _funcionarioResponsavel = value),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Tooltip(
                        message: 'Salvar registro no banco de dados',
                        child: ElevatedButton(
                          onPressed: _registrarProducao,
                          child: const Text('SALVAR PRODUÇÃO', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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
      style: const TextStyle(color: Colors.white),
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
      onChanged: (_) => _calcularSugestao(),
    );
  }
}