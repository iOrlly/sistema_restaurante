import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';
import '../models/venda_dia.dart';
import '../models/funcionario.dart';

class RegistrarVendaScreen extends StatefulWidget {
  const RegistrarVendaScreen({super.key});

  @override
  State<RegistrarVendaScreen> createState() => _RegistrarVendaScreenState();
}

class _RegistrarVendaScreenState extends State<RegistrarVendaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _quantidadeController = TextEditingController();
  final _observacaoController = TextEditingController();
  
  // Variáveis
  List<Produto> _produtos = [];
  List<Funcionario> _funcionarios = [];
  Produto? _produtoSelecionado;
  Funcionario? _funcionarioSelecionado;
  FormaPagamento _formaPagamento = FormaPagamento.dinheiro;
  bool _temDesconto = false;
  double _percentualDesconto = 0;
  DateTime _dataVenda = DateTime.now();
  TimeOfDay _horarioVenda = TimeOfDay.now();
  
  bool _isLoading = true;

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

  Future<void> _registrarVenda() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_produtoSelecionado == null) {
      _mostrarSnackBar('Selecione um produto', Colors.red);
      return;
    }
    
    if (_funcionarioSelecionado == null) {
      _mostrarSnackBar('Selecione o funcionário atendente', Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);
    
    final DateTime dataHoraVenda = DateTime(
      _dataVenda.year,
      _dataVenda.month,
      _dataVenda.day,
      _horarioVenda.hour,
      _horarioVenda.minute,
    );
    
    final venda = VendaDia(
      data: _dataVenda,
      produtoId: _produtoSelecionado!.id!,
      produtoNome: _produtoSelecionado!.nome,
      quantidade: int.parse(_quantidadeController.text),
      precoUnitario: _produtoSelecionado!.precoUnitario,
      formaPagamento: _formaPagamento,
      funcionarioAtendenteId: _funcionarioSelecionado!.id!,
      horarioVenda: dataHoraVenda,
      temDesconto: _temDesconto,
      percentualDesconto: _temDesconto ? _percentualDesconto : null,
      observacao: _observacaoController.text.isEmpty ? null : _observacaoController.text,
    );
    
    // Registrar venda e verificar alerta
    final resultado = await _dbHelper.registrarVenda(venda);
    
    setState(() => _isLoading = false);
    
    if (resultado['alerta'] == true) {
      _mostrarDialogAlerta(resultado['mensagem']);
    } else {
      _mostrarSnackBar('✅ Venda registrada com sucesso!', Colors.green);
      _limparFormulario();
    }
  }
  
  void _limparFormulario() {
    _quantidadeController.clear();
    _observacaoController.clear();
    _produtoSelecionado = null;
    _temDesconto = false;
    _percentualDesconto = 0;
    _formaPagamento = FormaPagamento.dinheiro;
    setState(() {});
  }
  
  void _mostrarDialogAlerta(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text('Alerta de Desperdício'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensagem),
            const SizedBox(height: 10),
            const Text(
              'Deseja continuar com o registro?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarSnackBar('✅ Venda registrada com alerta', Colors.orange);
              _limparFormulario();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Registrar Mesmo Assim'),
          ),
        ],
      ),
    );
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

  void _mostrarInsightsMercado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Análise de Mercado e Insights', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildInsightCard(
                'Tendência de Categoria',
                'Categorias de Bebidas e Pratos Executivos estão com alta de 15% esta semana.',
                Icons.trending_up,
                Colors.green,
              ),
              _buildInsightCard(
                'Sugestão de Preço',
                'Baseado no mercado local, o preço da Lasanha poderia subir 5% sem afetar a demanda.',
                Icons.lightbulb,
                Colors.amber,
              ),
              _buildInsightCard(
                'Concorrência',
                'Restaurantes vizinhos estão focando em combos executivos entre 12h e 13h.',
                Icons.group,
                Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text('Resumo da Operação Atual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Total de produtos cadastrados: ${_produtos.length}'),
              Text('Funcionários ativos no momento: ${_funcionarios.length}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String desc, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Análise de Vendas e Mercado'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights, color: Color(0xFFFFB300)),
            tooltip: 'Análise de Mercado',
            onPressed: () => _mostrarInsightsMercado(),
          ),
        ],
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.calendar_today, color: Color(0xFFFFB300)),
                              title: const Text('Data da Venda', style: TextStyle(color: Colors.white)),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataVenda), style: const TextStyle(color: Colors.grey)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFFD32F2F)),
                                tooltip: 'Alterar Data',
                                onPressed: () => _selecionarData(),
                              ),
                            ),
                          ],
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
                          message: 'Selecione o item vendido',
                          child: Icon(Icons.fastfood, color: Color(0xFFD32F2F)),
                        ),
                      ),
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      initialValue: _produtoSelecionado,
                      items: _produtos.map((produto) {
                        return DropdownMenuItem(
                          value: produto,
                          child: Text('${produto.nome} - ' r'R$ ' + produto.precoUnitario.toStringAsFixed(2)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _produtoSelecionado = value),
                      validator: (value) => value == null ? 'Selecione um produto' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _quantidadeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Quantidade *',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                        prefixIcon: Tooltip(
                          message: 'Quantidade em unidades',
                          child: Icon(Icons.numbers, color: Color(0xFFFFB300)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Informe a quantidade' : null,
                    ),
                    
                    DropdownButtonFormField<Funcionario>(
                      decoration: const InputDecoration(
                        labelText: 'Funcionário Atendente *',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                        prefixIcon: Icon(Icons.person, color: Color(0xFFD32F2F)),
                      ),
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      initialValue: _funcionarioSelecionado,
                      items: _funcionarios.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f.nome));
                      }).toList(),
                      onChanged: (value) => setState(() => _funcionarioSelecionado = value),
                      validator: (value) => value == null ? 'Selecione um funcionário' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<FormaPagamento>(
                      decoration: const InputDecoration(
                        labelText: 'Forma de Pagamento *',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                        prefixIcon: Icon(Icons.payments, color: Color(0xFFFFB300)),
                      ),
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      initialValue: _formaPagamento,
                      items: FormaPagamento.values.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()));
                      }).toList(),
                      onChanged: (value) => setState(() => _formaPagamento = value!),
                    ),

                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Tem Desconto?', style: TextStyle(color: Colors.white, fontSize: 14)),
                            value: _temDesconto,
                            onChanged: (v) {
                              setState(() => _temDesconto = v);
                              if (v) _mostrarDialogDesconto();
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (_temDesconto)
                          Text('${_percentualDesconto.toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _observacaoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
                        prefixIcon: Icon(Icons.note, color: Colors.grey),
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_produtoSelecionado != null && _quantidadeController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Valor Total:', style: TextStyle(color: Colors.grey)),
                            Text(_calcularValorTotal(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFB300))),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _registrarVenda,
                        child: const Text('REGISTRAR VENDA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  String _calcularValorTotal() {
    if (_produtoSelecionado == null) return r'R$ 0,00';
    int quantidade = int.tryParse(_quantidadeController.text) ?? 0;
    double total = quantidade * _produtoSelecionado!.precoUnitario;
    if (_temDesconto && _percentualDesconto > 0) {
      total = total * (1 - _percentualDesconto / 100);
    }
    return r'R$ ' + total.toStringAsFixed(2);
  }
  
  Future<void> _selecionarData() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataVenda,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dataVenda = date);
    }
  }
  
  Future<void> _selecionarHorario() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _horarioVenda,
    );
    if (time != null) {
      setState(() => _horarioVenda = time);
    }
  }
  
  Future<void> _mostrarDialogDesconto() async {
    double? desconto;
    final TextEditingController descontoController = TextEditingController();

    desconto = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Percentual de Desconto'),
        content: TextField(
          controller: descontoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Desconto (%)',
            suffixText: '%',
          ),
          onChanged: (value) {
            desconto = double.tryParse(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, desconto),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    final double? descontoAplicado = desconto;
    if (descontoAplicado != null && descontoAplicado > 0) {
      setState(() => _percentualDesconto = descontoAplicado.clamp(0, 100));
    } else {
      setState(() => _temDesconto = false);
    }
  }
}