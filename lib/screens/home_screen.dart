import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/notificacao_folga.dart';
import '../models/notificacao_geral.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.relatorioLoader = _loadRelatorio});

  final Future<Map<String, dynamic>> Function(String data) relatorioLoader;

  static Future<Map<String, dynamic>> _loadRelatorio(String data) {
    return DatabaseHelper.instance.getRelatorioDiario(data);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _relatorioHoje = {};
  int _pendentesCount = 0;
  bool _loading = true;
  final String _dataHoje = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() => _loading = true);

    try {
      final relatorio = await widget.relatorioLoader(_dataHoje);
      final pendentes = await DatabaseHelper.instance.getAllNotificacoesPendentes();
      if (mounted) {
        setState(() {
          _relatorioHoje = relatorio;
          _pendentesCount = pendentes.length;
        });
      }
    } catch (e, st) {
      debugPrint('Erro carregando relatório: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar relatório: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _abrirCentralSolicitacoes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CentralSolicitacoesHome(onRefresh: _carregarRelatorio),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Crítico': return Colors.redAccent;
      case 'Atenção': return const Color(0xFFFFB300);
      default: return const Color(0xFF2E7D32); // Verde Floresta
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = (_relatorioHoje['status'] as String?) ?? 'N/A';
    final double percentualDesperdicio = (_relatorioHoje['percentual_desperdicio'] as num?)?.toDouble() ?? 0.0;
    final int itensVendidos = (_relatorioHoje['itens_vendidos'] as num?)?.toInt() ?? 0;
    final int itensProduzidos = (_relatorioHoje['itens_produzidos'] as num?)?.toInt() ?? 0;
    final double faturamento = (_relatorioHoje['faturamento'] as num?)?.toDouble() ?? 0.0;
    final double eficienciaPorFuncionario = (_relatorioHoje['eficiencia_por_funcionario'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Restaurante'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Color(0xFFFFB300)),
                tooltip: 'Central de Solicitações',
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFB300)),
            tooltip: 'Recarregar Relatório',
            onPressed: _carregarRelatorio,
          ),
        ],
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : Row(
              children: [
                // Barra Lateral Esquerda (1/3)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'OPERAÇÕES',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          _buildMenuButton(context, 'Faturamento', Icons.monetization_on, '/registrar_faturamento', 'Registrar faturamento bruto do dia'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Fechamento', Icons.account_balance_wallet, '/fechamento_caixa', 'Calcular lucro líquido do dia'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Produção', Icons.kitchen, '/registrar_producao', 'Registrar itens produzidos'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Vendas (Análise)', Icons.analytics, '/registrar_venda', 'Análise granular por produto'),
                          const Divider(height: 32, color: Color(0xFF333333)),
                          const Text(
                            'CADASTROS',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          _buildMenuButton(context, 'Funcionários', Icons.people, '/funcionarios', 'Gestão de equipe e folgas'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Terceirizados', Icons.engineering, '/terceirizados', 'Controle de diárias'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Produtos', Icons.inventory_2, '/produtos', 'Cadastrar produtos e preços'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Boletos', Icons.receipt_long, '/boletos', 'Gestão de contas e vencimentos'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Almoxerifado', Icons.warehouse, '/estoque', 'Gestão de estoque e insumos'),
                          const SizedBox(height: 12),
                          _buildMenuButton(context, 'Relatórios', Icons.bar_chart, '/relatorios', 'Ver evolução e desperdício'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Resumo do Dia (2/3)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Resumo Hoje - $_dataHoje',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildSummaryCard('Faturamento', r'R$ ' + faturamento.toStringAsFixed(2), Icons.attach_money, const Color(0xFFFFB300)),
                            _buildSummaryCard('Desperdício', '${percentualDesperdicio.toStringAsFixed(1)}%', Icons.warning, const Color(0xFFFFB300)),
                            _buildSummaryCard('Vendidos', '$itensVendidos / $itensProduzidos', Icons.restaurant, const Color(0xFFD32F2F)),
                            _buildSummaryCard('Produtividade', '${eficienciaPorFuncionario.toStringAsFixed(1)}/func', Icons.trending_up, const Color(0xFFFFB300)),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Card de Acesso Rápido ao Almoxerifado
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/estoque'),
                          child: Card(
                            color: const Color(0xFF1E1E1E),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD32F2F).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.warehouse, color: Color(0xFFD32F2F)),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ALMOXERIFADO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12, color: Colors.grey)),
                                        Text('Gerenciar Estoque e Insumos', style: TextStyle(color: Colors.white, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        if (percentualDesperdicio > 20)
                          _buildAlerta(percentualDesperdicio),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAlerta(double perc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ALERTA DE DESPERDÍCIO', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                Text('O desperdício está alto! Reduza a produção em ${perc.toStringAsFixed(0)}% amanhã.', style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, IconData icon, String route, [String? tooltip]) {
    return Tooltip(
      message: tooltip ?? label,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: 18, color: const Color(0xFFD32F2F)),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          alignment: Alignment.centerLeft,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Tooltip(
      message: 'Status de $title',
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.5)),
                    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CentralSolicitacoesHome extends StatefulWidget {
  final VoidCallback onRefresh;
  const _CentralSolicitacoesHome({required this.onRefresh});

  @override
  State<_CentralSolicitacoesHome> createState() => _CentralSolicitacoesHomeState();
}

class _CentralSolicitacoesHomeState extends State<_CentralSolicitacoesHome> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _loading = true;
  List<dynamic> _notificacoes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista = await _dbHelper.getAllNotificacoesPendentes();
    setState(() {
      _notificacoes = lista;
      _loading = false;
    });
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
              const Text('Notificações e Solicitações', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB300))),
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
                    ? const Center(child: Text('Nenhuma notificação pendente', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _notificacoes.length,
                        itemBuilder: (context, index) {
                          final n = _notificacoes[index];
                          
                          if (n is NotificacaoFolga) {
                            final bool isPendente = n.status == 'pendente';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.calendar_month, color: Color(0xFFFFB300)),
                                title: Text('${n.funcionarioNome} (${n.funcionarioCargo})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Solicitou folga para: ${DateFormat('dd/MM/yyyy').format(n.dataSolicitada)}', 
                                        style: TextStyle(color: isPendente ? Colors.white70 : Colors.grey)),
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
                                      tooltip: 'Aprovar',
                                      onPressed: () async {
                                        await _dbHelper.responderFolga(n.id!, 'aprovado');
                                        _carregar();
                                        widget.onRefresh();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Color(0xFFD32F2F)),
                                      tooltip: 'Recusar',
                                      onPressed: () async {
                                        await _dbHelper.responderFolga(n.id!, 'recusado');
                                        _carregar();
                                        widget.onRefresh();
                                      },
                                    ),
                                  ],
                                ) : null,
                              ),
                            );
                          } else if (n is NotificacaoGeral) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  n.tipo == 'estoque_reposicao' ? Icons.inventory : Icons.warning_amber,
                                  color: n.tipo == 'estoque_reposicao' ? Colors.redAccent : Colors.orange,
                                ),
                                title: Text(n.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(n.mensagem, style: const TextStyle(color: Colors.white70)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.check, color: Colors.grey),
                                  tooltip: 'Marcar como lida',
                                  onPressed: () async {
                                    await _dbHelper.marcarNotificacaoGeralLida(n.id!);
                                    _carregar();
                                    widget.onRefresh();
                                  },
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
