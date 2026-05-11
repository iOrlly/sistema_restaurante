import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/terceirizado.dart';

class TerceirizadosScreen extends StatefulWidget {
  const TerceirizadosScreen({super.key});

  @override
  State<TerceirizadosScreen> createState() => _TerceirizadosScreenState();
}

class _TerceirizadosScreenState extends State<TerceirizadosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Terceirizado> _terceirizados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarTerceirizados();
  }

  Future<void> _carregarTerceirizados() async {
    setState(() => _isLoading = true);
    final lista = await _dbHelper.getAllTerceirizados();
    setState(() {
      _terceirizados = lista;
      _isLoading = false;
    });
  }

  Future<void> _abrirWhatsApp(String contato) async {
    final cleanNumber = contato.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.isEmpty) return;
    
    final prefix = cleanNumber.startsWith('55') ? '' : '55';
    final url = Uri.parse('https://wa.me/$prefix$cleanNumber');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  Future<void> _alterarDias(Terceirizado t, int delta) async {
    final novosDias = (t.diasTrabalhados + delta).clamp(0, 31);
    if (novosDias != t.diasTrabalhados) {
      t.diasTrabalhados = novosDias;
      await _dbHelper.updateTerceirizado(t);
      _carregarTerceirizados();
    }
  }

  Future<void> _zerarDias(Terceirizado t) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Zerar Frequência', style: TextStyle(color: Color(0xFFD32F2F))),
        content: Text('Confirmar pagamento e zerar dias de ${t.nome}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmar == true) {
      t.diasTrabalhados = 0;
      await _dbHelper.updateTerceirizado(t);
      _carregarTerceirizados();
    }
  }

  Future<void> _salvarTerceirizado(Terceirizado? original) async {
    final result = await showDialog<Terceirizado>(
      context: context,
      builder: (context) => _TerceirizadoFormDialog(terceirizado: original),
    );

    if (result != null) {
      if (original == null) {
        await _dbHelper.insertTerceirizado(result);
      } else {
        await _dbHelper.updateTerceirizado(result);
      }
      _carregarTerceirizados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Funcionários Terceirizados'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFFFFB300)),
            onPressed: () => _salvarTerceirizado(null),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : _terceirizados.isEmpty
              ? const Center(child: Text('Nenhum terceirizado cadastrado', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _terceirizados.length,
                  itemBuilder: (context, index) {
                    final t = _terceirizados[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.2),
                                  child: const Icon(Icons.engineering, color: Color(0xFFD32F2F)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text('Diária: R\$ ${t.valorDiaria.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
                                  tooltip: 'Editar Terceirizado',
                                  onPressed: () => _salvarTerceirizado(t),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('DIAS TRABALHADOS', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _alterarDias(t, -1), 
                                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFD32F2F)),
                                          tooltip: 'Remover Dia',
                                        ),
                                        Text('${t.diasTrabalhados}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                        IconButton(
                                          onPressed: () => _alterarDias(t, 1), 
                                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2ECC71)),
                                          tooltip: 'Adicionar Dia',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('TOTAL DEVIDO', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
                                    Text(
                                      'R\$ ${t.totalDevido.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB300)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _abrirWhatsApp(t.contato),
                                    icon: const Icon(Icons.message, size: 18),
                                    label: const Text('WHATSAPP'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2ECC71),
                                      side: const BorderSide(color: Color(0xFF2ECC71)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _zerarDias(t),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300), foregroundColor: Colors.black),
                                    child: const Text('QUITAR / ZERAR', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
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

class _TerceirizadoFormDialog extends StatefulWidget {
  final Terceirizado? terceirizado;
  const _TerceirizadoFormDialog({this.terceirizado});

  @override
  State<_TerceirizadoFormDialog> createState() => __TerceirizadoFormDialogState();
}

class __TerceirizadoFormDialogState extends State<_TerceirizadoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _diariaController = TextEditingController();
  final _contatoController = TextEditingController();
  final _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.terceirizado != null) {
      _nomeController.text = widget.terceirizado!.nome;
      _diariaController.text = widget.terceirizado!.valorDiaria.toString().replaceAll('.', ',');
      _contatoController.text = widget.terceirizado!.contato;
      _obsController.text = widget.terceirizado!.observacao ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(widget.terceirizado == null ? 'Novo Terceirizado' : 'Editar Terceirizado', style: const TextStyle(color: Color(0xFFD32F2F))),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInput(_nomeController, 'Nome Completo'),
              _buildInput(_diariaController, r'Valor da Diária (R$)', type: TextInputType.number),
              _buildInput(_contatoController, 'WhatsApp (apenas números)', type: TextInputType.phone),
              _buildInput(_obsController, 'Observações', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, Terceirizado(
                id: widget.terceirizado?.id,
                nome: _nomeController.text,
                valorDiaria: double.parse(_diariaController.text.replaceAll(',', '.')),
                contato: _contatoController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                observacao: _obsController.text,
                diasTrabalhados: widget.terceirizado?.diasTrabalhados ?? 0,
              ));
            }
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }

  Widget _buildInput(TextEditingController controller, String label, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
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
