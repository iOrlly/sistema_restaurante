import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/estoque_item.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<EstoqueItem> _estoque = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarEstoque();
  }

  Future<void> _carregarEstoque() async {
    setState(() => _isLoading = true);
    final lista = await _dbHelper.getAllEstoque();
    setState(() {
      _estoque = lista;
      _isLoading = false;
    });
  }

  IconData _getUnidadeIcon(String unidade) {
    switch (unidade) {
      case 'KG': return Icons.scale;
      case 'Litro': return Icons.local_drink;
      case 'Gramas': return Icons.fitness_center;
      case 'Caixa': return Icons.inventory_2;
      default: return Icons.shopping_basket;
    }
  }

  Future<void> _showEntradaSaida(EstoqueItem item, bool ehEntrada) async {
    final TextEditingController qtdController = TextEditingController();
    bool ehDesperdicio = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(ehEntrada ? 'Entrada: ${item.nome}' : 'Saída: ${item.nome}', style: const TextStyle(color: Color(0xFFFFB300))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Quantidade (${item.unidadeMedida})',
                  labelStyle: const TextStyle(color: Colors.grey),
                ),
                keyboardType: TextInputType.number,
              ),
              if (!ehEntrada)
                CheckboxListTile(
                  title: const Text('Desperdício/Avaria?', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: ehDesperdicio,
                  onChanged: (v) => setDialogState(() => ehDesperdicio = v ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                double qtd = double.tryParse(qtdController.text.replaceAll(',', '.')) ?? 0;
                final navigator = Navigator.of(context);
                if (ehEntrada) {
                  item.quantidadeAtual += qtd;
                  await _dbHelper.updateEstoque(item);
                } else {
                  await _dbHelper.darBaixaEstoque(item.id!, qtd, ehDesperdicio);
                }
                navigator.pop();
                _carregarEstoque();
              },
              child: const Text('CONFIRMAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Almoxerifado Inteligente'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Color(0xFFFFB300)),
            tooltip: 'Cadastrar Novo Item',
            onPressed: () => _showForm(null),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _estoque.length,
              itemBuilder: (context, index) {
                final item = _estoque[index];
                bool critico = item.quantidadeAtual <= item.quantidadeMinima;
                return Card(
                  child: ListTile(
                    leading: Icon(_getUnidadeIcon(item.unidadeMedida), color: critico ? const Color(0xFFD32F2F) : const Color(0xFFFFB300)),
                    title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('Estoque Mínimo: ${item.quantidadeMinima} ${item.unidadeMedida}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantidadeAtual} ${item.unidadeMedida}',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: critico ? const Color(0xFFD32F2F) : const Color(0xFFFFB300)
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                              onPressed: () => _showEntradaSaida(item, true),
                              tooltip: 'Entrada',
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                              onPressed: () => _showEntradaSaida(item, false),
                              tooltip: 'Saída/Baixa',
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showForm(EstoqueItem? item) async {
    final result = await showDialog<EstoqueItem>(
      context: context,
      builder: (context) => _EstoqueFormDialog(item: item),
    );
    if (result != null) {
      if (item == null) {
        await _dbHelper.insertEstoque(result);
      } else {
        await _dbHelper.updateEstoque(result);
      }
      _carregarEstoque();
    }
  }
}

class _EstoqueFormDialog extends StatefulWidget {
  final EstoqueItem? item;
  const _EstoqueFormDialog({this.item});

  @override
  State<_EstoqueFormDialog> createState() => _EstoqueFormDialogState();
}

class _EstoqueFormDialogState extends State<_EstoqueFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cat = TextEditingController();
  final _qtd = TextEditingController();
  final _min = TextEditingController();
  final _custo = TextEditingController();
  final _fator = TextEditingController(text: '1.0');
  String _unidade = 'Unidade';

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nome.text = widget.item!.nome;
      _cat.text = widget.item!.categoria;
      _qtd.text = widget.item!.quantidadeAtual.toString();
      _min.text = widget.item!.quantidadeMinima.toString();
      _custo.text = widget.item!.custoUnitario.toString();
      _fator.text = widget.item!.fatorConversao.toString();
      _unidade = widget.item!.unidadeMedida;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(widget.item == null ? 'Novo Item' : 'Editar Item', style: const TextStyle(color: Color(0xFFD32F2F))),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInput(_nome, 'Nome do Item'),
              _buildInput(_cat, 'Categoria'),
              Row(
                children: [
                  Expanded(child: _buildInput(_qtd, 'Qtd Atual', type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unidade,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Unidade', labelStyle: TextStyle(color: Colors.grey)),
                      items: ['KG', 'Unidade', 'Litro', 'Gramas', 'Caixa'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _unidade = v!),
                    ),
                  ),
                ],
              ),
              _buildInput(_min, 'Qtd Mínima (Alerta)', type: TextInputType.number),
              _buildInput(_custo, 'Custo Unitário', type: TextInputType.number),
              _buildInput(_fator, 'Fator de Conversão', type: TextInputType.number),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, EstoqueItem(
                id: widget.item?.id,
                nome: _nome.text,
                categoria: _cat.text,
                quantidadeAtual: double.parse(_qtd.text.replaceAll(',', '.')),
                quantidadeMinima: double.parse(_min.text.replaceAll(',', '.')),
                custoUnitario: double.parse(_custo.text.replaceAll(',', '.')),
                unidadeMedida: _unidade,
                fatorConversao: double.tryParse(_fator.text.replaceAll(',', '.')) ?? 1.0,
              ));
            }
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }

  Widget _buildInput(TextEditingController controller, String label, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey)),
      keyboardType: type,
      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
    );
  }
}
