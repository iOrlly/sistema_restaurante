import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/boleto.dart';
import '../services/excel_service.dart';

class BoletosScreen extends StatefulWidget {
  const BoletosScreen({super.key});

  @override
  State<BoletosScreen> createState() => _BoletosScreenState();
}

class _BoletosScreenState extends State<BoletosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Boleto> _allBoletos = [];
  double _totalHoje = 0;
  double _totalSemanal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final boletos = await _dbHelper.getAllBoletos();
    final hoje = await _dbHelper.getTotalPendenteHoje();
    final semanal = await _dbHelper.getTotalSemanal();

    setState(() {
      _allBoletos = boletos;
      _totalHoje = hoje;
      _totalSemanal = semanal;
      _isLoading = false;
    });
  }

  Map<String, List<Boleto>> _agruparBoletos() {
    Map<String, List<Boleto>> grupos = {};
    for (var b in _allBoletos) {
      DateTime dt = b.dataEfetiva;
      String chave = DateFormat('yyyy-MM-dd').format(dt);
      if (!grupos.containsKey(chave)) {
        grupos[chave] = [];
      }
      grupos[chave]!.add(b);
    }
    return grupos;
  }

  Future<void> _alternarStatus(Boleto boleto) async {
    boleto.status = boleto.status == 0 ? 1 : 0;
    await _dbHelper.updateBoleto(boleto);
    _carregarDados();
  }

  void _abrirFormBoleto({Boleto? boleto}) {
    showDialog(
      context: context,
      builder: (context) => _BoletoFormDialog(
        boleto: boleto,
        onSave: () => _carregarDados(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparBoletos();
    final datasOrdenadas = grupos.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('GESTÃO DE BOLETOS'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFB300),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Relatório',
            onPressed: () => ExcelService.exportarBoletos(_allBoletos),
          ),
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () => _abrirFormBoleto(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : Column(
              children: [
                _buildResumoHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: datasOrdenadas.length,
                    itemBuilder: (context, index) {
                      String dataStr = datasOrdenadas[index];
                      List<Boleto> boletosDoDia = grupos[dataStr]!;
                      DateTime data = DateTime.parse(dataStr);
                      bool isSegunda = data.weekday == DateTime.monday;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDataHeader(data, isSegunda),
                          ...boletosDoDia.map((b) => _buildBoletoTile(b)),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResumoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: _buildResumoCard('TOTAL HOJE', _totalHoje, const Color(0xFFFFB300)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildResumoCard('SEMANAL', _totalSemanal, const Color(0xFFFFB300)),
          ),
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
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDataHeader(DateTime data, bool isSegunda) {
    String label = DateFormat('dd/MM/yyyy - EEEE', 'pt_BR').format(data);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (isSegunda)
            const Text(
              'inclui vencimentos de Sábado e Domingo',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
            ),
          const Divider(color: Color(0xFF333333)),
        ],
      ),
    );
  }

  Widget _buildBoletoTile(Boleto b) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: b.isPago,
          activeColor: const Color(0xFF2E7D32),
          checkColor: Colors.white,
          onChanged: (v) => _alternarStatus(b),
        ),
        title: Text(
          b.descricao,
          style: TextStyle(
            color: b.isPago ? Colors.grey : Colors.white,
            decoration: b.isPago ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${b.categoria} • Vence em: ${DateFormat('dd/MM').format(b.dataVencimento)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R\$ ${b.valor.toStringAsFixed(2)}',
              style: TextStyle(
                color: b.isPago ? Colors.grey : const Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        onLongPress: () {
          // Opção de deletar ou editar
          _showOpcoes(b);
        },
      ),
    );
  }

  void _showOpcoes(Boleto b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Editar', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _abrirFormBoleto(boleto: b);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Color(0xFFD32F2F)),
            title: const Text('Excluir', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await _dbHelper.deleteBoleto(b.id!);
              Navigator.pop(context);
              _carregarDados();
            },
          ),
        ],
      ),
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
      _valorController.text = widget.boleto!.valor.toString();
      _dataVenc = widget.boleto!.dataVencimento;
      _categoria = widget.boleto!.categoria;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        widget.boleto == null ? 'NOVO BOLETO' : 'EDITAR BOLETO',
        style: const TextStyle(color: Color(0xFFFFB300)),
      ),
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
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoria,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Categoria', labelStyle: TextStyle(color: Colors.grey)),
                items: ['Fornecedores', 'Impostos', 'Insumos', 'Outros']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vencimento', style: TextStyle(color: Colors.grey, fontSize: 12)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataVenc), style: const TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFFD32F2F)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataVenc,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
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
                valor: double.parse(_valorController.text.replaceAll(',', '.')),
                dataVencimento: _dataVenc,
                categoria: _categoria,
                status: widget.boleto?.status ?? 0,
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
