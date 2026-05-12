import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/boleto.dart';
import '../services/excel_service.dart';
import '../services/currency_formatter.dart';

class BoletosScreen extends StatefulWidget {
  const BoletosScreen({super.key});

  @override
  State<BoletosScreen> createState() => _BoletosScreenState();
}

class _BoletosScreenState extends State<BoletosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Boleto> _boletosPendentes = [];
  List<Boleto> _boletosPagos = [];
  Set<int> _selecionados = {};
  
  double _totalHoje = 0;
  double _totalSemanal = 0;
  bool _isLoading = true;

  // Filtros para Pagos
  String _buscaPagos = "";
  DateTimeRange? _periodoPagos;
  double? _valorMinPagos;
  double? _valorMaxPagos;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final todos = await _dbHelper.getAllBoletos();
    final hoje = await _dbHelper.getTotalPendenteHoje();
    final semanal = await _dbHelper.getTotalSemanal();
    
    final pagosFiltrados = await _dbHelper.getBoletosPagosFiltrados(
      busca: _buscaPagos,
      inicio: _periodoPagos?.start,
      fim: _periodoPagos?.end,
      valorMin: _valorMinPagos,
      valorMax: _valorMaxPagos,
    );

    setState(() {
      _boletosPendentes = todos.where((b) => b.status == 0).toList();
      _boletosPagos = pagosFiltrados;
      _totalHoje = hoje;
      _totalSemanal = semanal;
      _selecionados.clear();
      _isLoading = false;
    });
  }

  void _selecionarTodos() {
    setState(() {
      if (_selecionados.length == _boletosPendentes.length) {
        _selecionados.clear();
      } else {
        _selecionados = _boletosPendentes.map((b) => b.id!).toSet();
      }
    });
  }

  void _selecionarHoje() {
    final hojeStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _selecionados = _boletosPendentes
          .where((b) => DateFormat('yyyy-MM-dd').format(b.dataEfetiva) == hojeStr)
          .map((b) => b.id!)
          .toSet();
    });
  }

  Future<void> _pagarSelecionados() async {
    if (_selecionados.isEmpty) return;
    await _dbHelper.marcarBoletosComoPagos(_selecionados.toList());
    _carregarDados();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pagamentos registrados com sucesso!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text('CONTROLE DE BOLETOS', style: TextStyle(letterSpacing: 1.5)),
          backgroundColor: Colors.black,
          foregroundColor: const Color(0xFFFFB300),
          bottom: const TabBar(
            indicatorColor: Color(0xFFD32F2F),
            labelColor: Color(0xFFFFB300),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'PENDENTES', icon: Icon(Icons.pending_actions)),
              Tab(text: 'HISTÓRICO PAGO', icon: Icon(Icons.history_edu)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              onSelected: (val) {
                if (val == 'all') ExcelService.exportarBoletos(_boletosPendentes + _boletosPagos);
                if (val == 'filtered') ExcelService.exportarBoletos(_boletosPagos);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Exportar Tudo')),
                const PopupMenuItem(value: 'filtered', child: Text('Exportar Pagos (Filtrados)')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_box, color: Color(0xFFD32F2F)),
              onPressed: () => _abrirFormBoleto(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTabPendentes(),
            _buildTabPagos(),
          ],
        ),
        floatingActionButton: _selecionados.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _pagarSelecionados,
                backgroundColor: const Color(0xFF2E7D32),
                label: Text('PAGAR SELECIONADOS (${_selecionados.length})'),
                icon: const Icon(Icons.check_circle),
              )
            : null,
      ),
    );
  }

  Widget _buildTabPendentes() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
    if (_boletosPendentes.isEmpty) return _buildEmptyState("Tudo pago! Nenhuma pendência.");

    // Agrupamento para Pendentes
    Map<String, List<Boleto>> grupos = {};
    for (var b in _boletosPendentes) {
      String chave = DateFormat('yyyy-MM-dd').format(b.dataEfetiva);
      grupos.putIfAbsent(chave, () => []).add(b);
    }
    final datasOrdenadas = grupos.keys.toList()..sort();

    return Column(
      children: [
        _buildResumoHeader(),
        _buildBulkActionsBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: datasOrdenadas.length,
            itemBuilder: (context, index) {
              String dataStr = datasOrdenadas[index];
              DateTime data = DateTime.parse(dataStr);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataHeader(data),
                  ...grupos[dataStr]!.map((b) => _buildBoletoCard(b)),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabPagos() {
    return Column(
      children: [
        _buildFiltrosPagos(),
        Expanded(
          child: _boletosPagos.isEmpty
              ? _buildEmptyState("Nenhum pagamento encontrado com esses filtros.")
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _boletosPagos.length,
                  itemBuilder: (context, index) => _buildBoletoCard(_boletosPagos[index], isHistorico: true),
                ),
        ),
      ],
    );
  }

  Widget _buildResumoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(child: _buildResumoCard('TOTAL HOJE', _totalHoje, const Color(0xFFFFB300))),
          const SizedBox(width: 12),
          Expanded(child: _buildResumoCard('SEMANAL', _totalSemanal, const Color(0xFFFFB300))),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E1E1E),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              label: const Text('SELECIONAR TODOS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              onPressed: _selecionarTodos,
              backgroundColor: Colors.black,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('SELECIONAR HOJE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              onPressed: _selecionarHoje,
              backgroundColor: Colors.black,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('LIMPAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              onPressed: () => setState(() => _selecionados.clear()),
              backgroundColor: const Color(0xFFD32F2F).withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosPagos() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Buscar fornecedor...',
              prefixIcon: Icon(Icons.search, color: Color(0xFFFFB300)),
              filled: true,
              fillColor: Color(0xFF1E1E1E),
            ),
            onChanged: (v) {
              _buscaPagos = v;
              _carregarDados();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _periodoPagos = picked);
                      _carregarDados();
                    }
                  },
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: Text(_periodoPagos == null ? 'Período' : 'Período Selecionado'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list_off, color: Color(0xFFD32F2F)),
                onPressed: () {
                  setState(() {
                    _buscaPagos = "";
                    _periodoPagos = null;
                    _valorMinPagos = null;
                    _valorMaxPagos = null;
                  });
                  _carregarDados();
                },
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBoletoCard(Boleto b, {bool isHistorico = false}) {
    bool selecionado = _selecionados.contains(b.id);
    return Card(
      color: selecionado ? const Color(0xFFD32F2F).withOpacity(0.1) : const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: isHistorico
            ? const Icon(Icons.verified, color: Color(0xFF2E7D32))
            : Checkbox(
                value: selecionado,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selecionados.add(b.id!);
                    } else {
                      _selecionados.remove(b.id!);
                    }
                  });
                },
              ),
        title: Text(b.descricao, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(
          '${b.categoria} • ${isHistorico ? "Pago em: ${DateFormat('dd/MM').format(b.dataPagamento!)}" : "Vence: ${DateFormat('dd/MM').format(b.dataVencimento)}"}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('R\$ ${b.valor.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (val) async {
                if (val == 'edit') _abrirFormBoleto(boleto: b);
                if (val == 'del') {
                  await _dbHelper.deleteBoleto(b.id!);
                  _carregarDados();
                }
                if (val == 'xls') ExcelService.exportarBoletoIndividual(b);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Editar'))),
                const PopupMenuItem(value: 'xls', child: ListTile(leading: Icon(Icons.download), title: Text('Excel Individual'))),
                const PopupMenuItem(value: 'del', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Excluir', style: TextStyle(color: Colors.red)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, size: 80, color: Color(0xFF333333)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildResumoCard(String label, double valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('R\$ ${valor.toStringAsFixed(2)}', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDataHeader(DateTime data) {
    bool isSegunda = data.weekday == DateTime.monday;
    String label = DateFormat('dd/MM/yyyy - EEEE', 'pt_BR').format(data);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 12)),
          if (isSegunda) const Text('inclui vencimentos de Sábado e Domingo', style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
          const Divider(color: Color(0xFF333333)),
        ],
      ),
    );
  }

  void _abrirFormBoleto({Boleto? boleto}) {
    showDialog(
      context: context,
      builder: (context) => _BoletoFormDialog(boleto: boleto, onSave: () => _carregarDados()),
    );
  }
}

class _BoletoFormDialog extends StatefulWidget {
  final Boleto? boleto;
  final VoidCallback onSave;
  const _BoletoFormDialog({this.boleto, required this.onSave});

  @override
  State<_BoletoFormDialog> createState() => _BoletoFormDialogState();
}

class _BoletoFormDialogState extends State<_BoletoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _valorController = TextEditingController();
  DateTime _dataVenc = DateTime.now();
  String _categoria = 'Fornecedores';

  @override
  void initState() {
    super.initState();
    if (widget.boleto != null) {
      _descController.text = widget.boleto!.descricao;
      _valorController.text = NumberFormat.currency(locale: 'pt_BR', symbol: '').format(widget.boleto!.valor).trim();
      _dataVenc = widget.boleto!.dataVencimento;
      _categoria = widget.boleto!.categoria;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(widget.boleto == null ? 'NOVO BOLETO' : 'EDITAR BOLETO', style: const TextStyle(color: Color(0xFFFFB300))),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Descrição', labelStyle: TextStyle(color: Colors.grey)),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _valorController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Valor (R\$)', labelStyle: TextStyle(color: Colors.grey)),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (v) => (v == null || v.isEmpty || v == '0,00') ? 'Informe um valor' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Categoria', labelStyle: TextStyle(color: Colors.grey)),
                items: ['Fornecedores', 'Impostos', 'Insumos', 'Outros'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vencimento', style: TextStyle(color: Colors.grey, fontSize: 12)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataVenc), style: const TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFFD32F2F)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _dataVenc, firstDate: DateTime(2024), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _dataVenc = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final b = Boleto(
                id: widget.boleto?.id,
                descricao: _descController.text,
                valor: CurrencyInputFormatter.parse(_valorController.text),
                dataVencimento: _dataVenc,
                categoria: _categoria,
                status: widget.boleto?.status ?? 0,
                dataPagamento: widget.boleto?.dataPagamento,
              );
              if (widget.boleto == null) {
                await DatabaseHelper.instance.insertBoleto(b);
              } else {
                await DatabaseHelper.instance.updateBoleto(b);
              }
              widget.onSave();
              Navigator.pop(context);
            }
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}
