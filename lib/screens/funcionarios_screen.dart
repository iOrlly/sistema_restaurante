import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/funcionario.dart';
import '../models/notificacao_folga.dart';
import '../services/currency_formatter.dart';

class FuncionariosScreen extends StatefulWidget {
  const FuncionariosScreen({super.key});

  @override
  State<FuncionariosScreen> createState() => _FuncionariosScreenState();
}

class _FuncionariosScreenState extends State<FuncionariosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Funcionario> _funcionarios = [];
  List<Funcionario> _funcionariosFiltrados = [];
  Map<int, String?> _presencasHoje = {};
  Map<int, int> _faltasMes = {};
  int _pendentesCount = 0;
  bool _isLoading = true;
  
  String _searchQuery = '';
  SetorFuncionario? _setorSelecionado;
  CargoFuncionario? _cargoSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final lista = await _dbHelper.getAllFuncionarios();
    final pendentes = await _dbHelper.getNotificacoesPendentes();
    
    Map<int, String?> presencas = {};
    Map<int, int> faltas = {};
    for (var f in lista) {
      presencas[f.id!] = await _dbHelper.getPresencaHoje(f.id!);
      faltas[f.id!] = await _dbHelper.countFaltasMes(f.id!);
    }
    
    setState(() {
      _funcionarios = lista;
      _presencasHoje = presencas;
      _faltasMes = faltas;
      _pendentesCount = pendentes.length;
      _aplicarFiltros();
      _isLoading = false;
    });
  }

  void _aplicarFiltros() {
    _funcionariosFiltrados = _funcionarios.where((f) {
      bool matchSearch = f.nome.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchSetor = _setorSelecionado == null || f.setor == _setorSelecionado || f.setor2 == _setorSelecionado;
      bool matchCargo = _cargoSelecionado == null || f.cargo == _cargoSelecionado || f.cargo2 == _cargoSelecionado;
      return matchSearch && matchSetor && matchCargo;
    }).toList();
  }

  Future<void> _togglePresenca(Funcionario f) async {
    String atual = _presencasHoje[f.id!] ?? 'presente';
    String novoStatus = atual == 'presente' ? 'falta' : 'presente';
    await _dbHelper.togglePresenca(f.id!, novoStatus);
    _carregarDados();
  }

  Future<void> _alterarDias(Funcionario f, int delta) async {
    f.diasTrabalhados = (f.diasTrabalhados + delta).clamp(0, 31);
    await _dbHelper.updateFuncionario(f);
    _carregarDados();
  }

  Future<void> _abrirWhatsApp(String tel) async {
    final num = tel.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/55$num');
    if (!await launchUrl(url)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao abrir WhatsApp')));
    }
  }

  Future<void> _agendarFolga(Funcionario f) async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Selecione a data da folga',
    );

    if (data != null) {
      final TextEditingController motivoController = TextEditingController();
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Solicitar Folga: ${f.nome}'),
          content: TextField(
            controller: motivoController,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            maxLines: 2,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Solicitar')),
          ],
        ),
      );

      if (confirmar == true) {
        await _dbHelper.insertNotificacaoFolga(NotificacaoFolga(
          funcionarioId: f.id!,
          funcionarioNome: f.nome,
          funcionarioCargo: f.cargo.displayName,
          dataSolicitada: data,
          dataCriacao: DateTime.now(),
          motivo: motivoController.text,
        ));
        _carregarDados();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação enviada!'), backgroundColor: Colors.blue));
      }
    }
  }

  Future<void> _registrarPagamentoSalario(Funcionario f) async {
    final TextEditingController valorController = TextEditingController(
      text: f.salario.toStringAsFixed(2).replaceAll('.', ',')
    );
    final mesReferencia = DateFormat('MMMM / yyyy', 'pt_BR').format(DateTime.now());

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Pagar Salário: ${f.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Referente a $mesReferencia', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Valor do Pagamento (R\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar Pagamento')),
        ],
      ),
    );

    if (confirmar == true) {
      await _dbHelper.registrarPagamento(
        funcionarioId: f.id,
        tipo: 'mensalista',
        valor: double.tryParse(valorController.text.replaceAll(',', '.')) ?? f.salario,
        referenciaMes: DateFormat('yyyy-MM').format(DateTime.now()),
        observacao: 'Salário fixo mensal',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salário registrado e enviado ao financeiro! 💰'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _abrirCentralSolicitacoes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CentralSolicitacoes(onRefresh: _carregarDados),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Gestão de Equipe'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD32F2F),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Color(0xFFFFB300)),
                onPressed: _abrirCentralSolicitacoes,
              ),
              if (_pendentesCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_pendentesCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.person_add, color: Color(0xFFFFB300)), onPressed: () => _showForm(null)),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : Column(
              children: [
                _buildFiltros(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _funcionariosFiltrados.length,
                    itemBuilder: (context, index) => _buildFuncionarioCard(_funcionariosFiltrados[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar funcionário...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFFB300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFB300))),
            ),
            onChanged: (v) {
              _searchQuery = v;
              setState(() => _aplicarFiltros());
            },
          ),
          const SizedBox(height: 12),
          const Text('Setores', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _setorSelecionado == null,
                  onSelected: (_) => setState(() { _setorSelecionado = null; _cargoSelecionado = null; _aplicarFiltros(); }),
                ),
                ...SetorFuncionario.values.map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(s.displayName),
                    selected: _setorSelecionado == s,
                    onSelected: (val) => setState(() { _setorSelecionado = val ? s : null; _cargoSelecionado = null; _aplicarFiltros(); }),
                  ),
                )),
              ],
            ),
          ),
          if (_setorSelecionado != null) ...[
            const SizedBox(height: 8),
            const Text('Funções', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _cargoSelecionado == null,
                    onSelected: (_) => setState(() { _cargoSelecionado = null; _aplicarFiltros(); }),
                  ),
                  ...CargoFuncionario.values.map((c) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(c.displayName),
                      selected: _cargoSelecionado == c,
                      onSelected: (val) => setState(() { _cargoSelecionado = val ? c : null; _aplicarFiltros(); }),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuncionarioCard(Funcionario f) {
    String? status = _presencasHoje[f.id!];
    bool isFalta = status == 'falta';
    Color emerald = const Color(0xFF2ECC71);
    Color pastelCoral = const Color(0xFFF1948A);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: f.cargo.cor.withOpacity(0.2),
                  child: Icon(Icons.person, color: f.cargo.cor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text('${f.cargo.displayName}${f.cargo2 != null ? ' / ${f.cargo2!.displayName}' : ''}', 
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isFalta ? Icons.check_circle : Icons.cancel, color: isFalta ? emerald : pastelCoral),
                  tooltip: isFalta ? 'Confirmar Presença' : 'Registrar Falta',
                  onPressed: () => _togglePresenca(f),
                ),
                IconButton(
                  icon: const Icon(Icons.event_note, color: Color(0xFFFFB300)),
                  tooltip: 'Agendar Folga',
                  onPressed: () => _agendarFolga(f),
                ),
                IconButton(
                  icon: const Icon(Icons.payments, color: Colors.green),
                  tooltip: 'Registrar Pagamento de Salário',
                  onPressed: () => _registrarPagamentoSalario(f),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
                  tooltip: 'Editar Cadastro',
                  onPressed: () => _showForm(f),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faltas no mês: ${_faltasMes[f.id!] ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (f.valorDiaria > 0)
                      Text('Devido: R\$ ${(f.valorDiaria * f.diasTrabalhados).toStringAsFixed(2)}', 
                          style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
                  ],
                ),
                if (f.valorDiaria > 0)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _alterarDias(f, -1),
                        icon: const Icon(Icons.remove_circle_outline, size: 20, color: Color(0xFFD32F2F)),
                        tooltip: 'Remover Dia',
                      ),
                      Text('${f.diasTrabalhados}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        onPressed: () => _alterarDias(f, 1),
                        icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF2ECC71)),
                        tooltip: 'Adicionar Dia',
                      ),
                    ],
                  ),
                if (f.telefone.isNotEmpty)
                  IconButton(
                    onPressed: () => _abrirWhatsApp(f.telefone),
                    icon: const Icon(Icons.message, color: Color(0xFF2ECC71)),
                    tooltip: 'Abrir WhatsApp',
                  ),
              ],
            ),
            if (isFalta)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(color: pastelCoral.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: pastelCoral.withOpacity(0.3))),
                child: Center(child: Text('FALTA REGISTRADA HOJE', style: TextStyle(color: pastelCoral, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1))),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showForm(Funcionario? f) async {
    final result = await showDialog<Funcionario>(
      context: context,
      builder: (context) => _FuncionarioDialog(funcionario: f),
    );
    if (result != null) {
      if (f == null) {
        await _dbHelper.insertFuncionario(result);
      } else {
        await _dbHelper.updateFuncionario(result);
      }
      _carregarDados();
    }
  }
}

class _FuncionarioDialog extends StatefulWidget {
  final Funcionario? funcionario;
  const _FuncionarioDialog({this.funcionario});

  @override
  State<_FuncionarioDialog> createState() => _FuncionarioDialogState();
}

class _FuncionarioDialogState extends State<_FuncionarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _tel = TextEditingController();
  final _salario = TextEditingController();
  final _diaria = TextEditingController();
  final _obs = TextEditingController();
  
  SetorFuncionario _setor = SetorFuncionario.cozinha;
  SetorFuncionario? _setor2;
  CargoFuncionario _cargo = CargoFuncionario.cozinheiro;
  CargoFuncionario? _cargo2;

  @override
  void initState() {
    super.initState();
    if (widget.funcionario != null) {
      _nome.text = widget.funcionario!.nome;
      _tel.text = widget.funcionario!.telefone;
      _salario.text = NumberFormat.currency(locale: 'pt_BR', symbol: '').format(widget.funcionario!.salario).trim();
      _diaria.text = NumberFormat.currency(locale: 'pt_BR', symbol: '').format(widget.funcionario!.valorDiaria).trim();
      _obs.text = widget.funcionario!.observacao ?? '';
      _setor = widget.funcionario!.setor;
      _setor2 = widget.funcionario!.setor2;
      _cargo = widget.funcionario!.cargo;
      _cargo2 = widget.funcionario!.cargo2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(widget.funcionario == null ? 'Novo Funcionário' : 'Editar', style: const TextStyle(color: Color(0xFFD32F2F))),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInput(_nome, 'Nome'),
              _buildDropdown<SetorFuncionario>('Setor Principal', _setor, SetorFuncionario.values, (v) => setState(() => _setor = v!), (s) => s.displayName),
              _buildDropdown<CargoFuncionario>('Cargo Principal', _cargo, CargoFuncionario.values, (v) => setState(() => _cargo = v!), (c) => c.displayName),
              const Divider(color: Colors.white10, height: 32),
              _buildDropdown<CargoFuncionario?>('Cargo Secundário', _cargo2, [null, ...CargoFuncionario.values], (v) => setState(() => _cargo2 = v), (c) => c?.displayName ?? 'Nenhum'),
              if (_cargo2 != null)
                _buildDropdown<SetorFuncionario?>('Setor Secundário', _setor2, [null, ...SetorFuncionario.values], (v) => setState(() => _setor2 = v), (s) => s?.displayName ?? 'Nenhum'),
              _buildInput(_tel, 'Telefone/WhatsApp', type: TextInputType.phone),
              _buildInput(_salario, 'Salário Fixo', type: TextInputType.number, isMoeda: true),
              _buildInput(_diaria, 'Valor Diária (Terceirizados)', type: TextInputType.number, isMoeda: true),
              _buildInput(_obs, 'Observações', maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, Funcionario(
                id: widget.funcionario?.id,
                nome: _nome.text,
                setor: _setor,
                cargo: _cargo,
                setor2: _setor2,
                cargo2: _cargo2,
                telefone: _tel.text,
                salario: CurrencyInputFormatter.parse(_salario.text),
                valorDiaria: CurrencyInputFormatter.parse(_diaria.text),
                dataContratacao: widget.funcionario?.dataContratacao ?? DateTime.now(),
                diasTrabalhados: widget.funcionario?.diasTrabalhados ?? 0,
                observacao: _obs.text,
              ));
            }
          },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }

  Widget _buildInput(TextEditingController controller, String label, {TextInputType type = TextInputType.text, int maxLines = 1, bool isMoeda = false}) {
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
        inputFormatters: isMoeda ? [
          FilteringTextInputFormatter.digitsOnly,
          CurrencyInputFormatter(),
        ] : null,
        validator: (v) => (v == null || v.isEmpty && label == 'Nome') ? 'Obrigatório' : null,
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, ValueChanged<T?> onChanged, String Function(T) labelFn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        dropdownColor: const Color(0xFF1E1E1E),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        ),
        style: const TextStyle(color: Colors.white),
        items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(i == null ? 'Nenhum' : labelFn(i)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _CentralSolicitacoes extends StatefulWidget {
  final VoidCallback onRefresh;
  const _CentralSolicitacoes({required this.onRefresh});

  @override
  State<_CentralSolicitacoes> createState() => _CentralSolicitacoesState();
}

class _CentralSolicitacoesState extends State<_CentralSolicitacoes> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<NotificacaoFolga> _notificacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    // Carrega todas as notificações para manter o histórico, não apenas as pendentes
    final lista = await _dbHelper.getNotificacoesPendentes(); 
    setState(() {
      _notificacoes = lista;
      _loading = false;
    });
  }

  Future<void> _responder(int id, String status) async {
    await _dbHelper.responderFolga(id, status);
    _carregar();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Solicitações e Folgas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB300))),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
                : _notificacoes.isEmpty
                    ? const Center(child: Text('Nenhuma solicitação registrada', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _notificacoes.length,
                        itemBuilder: (context, index) {
                          final n = _notificacoes[index];
                          final bool isPendente = n.status == 'pendente';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text('${n.funcionarioNome} (${n.funcionarioCargo})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data: ${DateFormat('dd/MM/yyyy').format(n.dataSolicitada)}', 
                                      style: TextStyle(color: isPendente ? const Color(0xFFFFB300) : Colors.grey)),
                                  if (n.motivo != null && n.motivo!.isNotEmpty) Text('Motivo: ${n.motivo}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${n.status.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: n.status == 'aprovado' ? Colors.green : (n.status == 'recusado' ? Colors.red : Colors.orange)
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isPendente ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Color(0xFF2ECC71)),
                                    tooltip: 'Aprovar Folga',
                                    onPressed: () => _responder(n.id!, 'aprovado')
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Color(0xFFD32F2F)),
                                    tooltip: 'Recusar Folga',
                                    onPressed: () => _responder(n.id!, 'recusado')
                                  ),
                                ],
                              ) : Icon(
                                  n.status == 'aprovado' ? Icons.verified : Icons.block,
                                  color: n.status == 'aprovado' ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
