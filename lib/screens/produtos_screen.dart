import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/produto.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Produto> _produtos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() => _isLoading = true);
    final produtos = await _dbHelper.getAllProdutos();
    setState(() {
      _produtos = produtos;
      _isLoading = false;
    });
  }

  Future<void> _adicionarProduto() async {
    final result = await showDialog<Produto>(
      context: context,
      builder: (context) => const _ProdutoFormDialog(),
    );
    
    if (result != null) {
      await _dbHelper.insertProduto(result);
      _carregarProdutos();
    }
  }

  Future<void> _editarProduto(Produto produto) async {
    final result = await showDialog<Produto>(
      context: context,
      builder: (context) => _ProdutoFormDialog(produto: produto),
    );
    
    if (result != null) {
      await _dbHelper.updateProduto(result);
      _carregarProdutos();
    }
  }

  Future<void> _deletarProduto(Produto produto) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Color(0xFFD32F2F))),
        content: Text('Deseja excluir "${produto.nome}"?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _dbHelper.deleteProduto(produto.id!);
      _carregarProdutos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Cadastrar Produtos'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFFB300)),
            onPressed: _adicionarProduto,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final produto = _produtos[index];
                return Card(
                  child: ListTile(
                    title: Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('${produto.categoria} • ${produto.tempoPreparoMin} min', style: const TextStyle(color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r'R$ ' + produto.precoUnitario.toStringAsFixed(2),
                          style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                          tooltip: 'Editar Produto',
                          onPressed: () => _editarProduto(produto),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFD32F2F), size: 20),
                          tooltip: 'Excluir Produto',
                          onPressed: () => _deletarProduto(produto),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ProdutoFormDialog extends StatefulWidget {
  final Produto? produto;
  const _ProdutoFormDialog({this.produto});

  @override
  State<_ProdutoFormDialog> createState() => __ProdutoFormDialogState();
}

class __ProdutoFormDialogState extends State<_ProdutoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _precoController = TextEditingController();
  final _tempoController = TextEditingController(text: '15');

  @override
  void initState() {
    super.initState();
    if (widget.produto != null) {
      _nomeController.text = widget.produto!.nome;
      _categoriaController.text = widget.produto!.categoria;
      _precoController.text = widget.produto!.precoUnitario.toString().replaceAll('.', ',');
      _tempoController.text = widget.produto!.tempoPreparoMin.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto', style: const TextStyle(color: Color(0xFFD32F2F))),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(_nomeController, 'Nome do Produto'),
              _buildField(_categoriaController, 'Categoria'),
              _buildField(_precoController, r'Preço (R$)', type: TextInputType.number),
              _buildField(_tempoController, 'Tempo de Preparo (min)', type: TextInputType.number),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, Produto(
                id: widget.produto?.id,
                nome: _nomeController.text,
                categoria: _categoriaController.text,
                precoUnitario: double.parse(_precoController.text.replaceAll(',', '.')),
                tempoPreparoMin: int.tryParse(_tempoController.text) ?? 15,
              ));
            }
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB300))),
        ),
        keyboardType: type,
        validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
      ),
    );
  }
}
