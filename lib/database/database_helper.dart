import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/funcionario.dart';
import '../models/produto.dart';
import '../models/producao_dia.dart';
import '../models/resultado_diario.dart';
import '../models/venda_dia.dart';
import '../models/fechamento.dart';
import '../models/terceirizado.dart';
import '../models/notificacao_folga.dart';
import '../models/estoque_item.dart';
import '../models/notificacao_geral.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('restaurante.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    try {
      final database = await openDatabase(
        path,
        version: 10, // Versão 10 para Estoque e Notificações Gerais
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      );
      return database;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE produtos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        preco_unitario REAL NOT NULL,
        tempo_preparo_min INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE producao_dia(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        produto_id INTEGER NOT NULL,
        quantidade_produzida INTEGER NOT NULL,
        quantidade_restante INTEGER,
        motivo_sobra TEXT,
        horario_inicio TEXT NOT NULL,
        horario_fim TEXT NOT NULL,
        funcionario_id INTEGER NOT NULL,
        custo_estimado REAL NOT NULL,
        houve_desperdicio INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (produto_id) REFERENCES produtos(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE vendas_dia(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        produto_id INTEGER NOT NULL,
        quantidade INTEGER NOT NULL,
        preco_unitario REAL NOT NULL,
        valor_total REAL NOT NULL,
        forma_pagamento INTEGER NOT NULL,
        funcionario_id INTEGER NOT NULL,
        horario_venda TEXT NOT NULL,
        tem_desconto INTEGER NOT NULL DEFAULT 0,
        percentual_desconto REAL,
        observacao TEXT,
        FOREIGN KEY (produto_id) REFERENCES produtos(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE funcionarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        setor INTEGER NOT NULL DEFAULT 0,
        cargo INTEGER NOT NULL,
        setor2 INTEGER,
        cargo2 INTEGER,
        data_contratacao TEXT NOT NULL,
        telefone TEXT NOT NULL,
        salario REAL NOT NULL,
        valor_diaria REAL NOT NULL DEFAULT 0.0,
        dias_trabalhados INTEGER NOT NULL DEFAULT 0,
        ativo INTEGER NOT NULL DEFAULT 1,
        em_ferias INTEGER NOT NULL DEFAULT 0,
        data_inicio_ferias TEXT,
        observacao TEXT,
        produtividade_media REAL NOT NULL DEFAULT 0.0,
        total_horas_trabalhadas INTEGER NOT NULL DEFAULT 0,
        total_itens_produzidos INTEGER NOT NULL DEFAULT 0,
        ultima_avaliacao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE presencas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        funcionario_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id),
        UNIQUE(funcionario_id, data)
      )
    ''');

    await db.execute('''
      CREATE TABLE faltas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        funcionario_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        justificada INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE faturamento_diario(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL UNIQUE,
        valor REAL NOT NULL,
        observacao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fechamentos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL UNIQUE,
        valor_bruto REAL NOT NULL,
        custo_funcionarios REAL NOT NULL,
        gastos_extras REAL NOT NULL,
        lucro_liquido REAL NOT NULL,
        observacao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE terceirizados(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor_diaria REAL NOT NULL,
        dias_trabalhados INTEGER NOT NULL DEFAULT 0,
        contato TEXT NOT NULL,
        observacao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notificacoes_folga(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        funcionario_id INTEGER NOT NULL,
        data_solicitada TEXT NOT NULL,
        data_criacao TEXT NOT NULL,
        status TEXT NOT NULL,
        motivo TEXT,
        FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE estoque(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_item TEXT NOT NULL,
        categoria TEXT NOT NULL,
        quantidade_atual REAL NOT NULL,
        quantidade_minima REAL NOT NULL,
        data_validade TEXT,
        custo_unitario REAL NOT NULL,
        unidade_medida TEXT NOT NULL,
        fator_conversao REAL NOT NULL DEFAULT 1.0
      )
    ''');

    await db.execute('''
      CREATE TABLE notificacoes_gerais(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        data_criacao TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        referencia_id INTEGER
      )
    ''');
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE producao_dia ADD COLUMN motivo_sobra TEXT');
      await db.execute('ALTER TABLE producao_dia ADD COLUMN horario_inicio TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE producao_dia ADD COLUMN horario_fim TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE producao_dia ADD COLUMN funcionario_id INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE producao_dia ADD COLUMN custo_estimado REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE producao_dia ADD COLUMN houve_desperdicio INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE vendas_dia ADD COLUMN preco_unitario REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE vendas_dia ADD COLUMN forma_pagamento INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE vendas_dia ADD COLUMN funcionario_id INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE vendas_dia ADD COLUMN horario_venda TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE vendas_dia ADD COLUMN tem_desconto INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE vendas_dia ADD COLUMN percentual_desconto REAL');
      await db.execute('ALTER TABLE vendas_dia ADD COLUMN observacao TEXT');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN telefone TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN salario REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN ativo INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN produtividade_media REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN total_horas_trabalhadas INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN total_itens_produzidos INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN ultima_avaliacao TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE funcionarios ADD COLUMN em_ferias INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN data_inicio_ferias TEXT');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN observacao TEXT');
      await db.execute('CREATE TABLE faltas(id INTEGER PRIMARY KEY AUTOINCREMENT, funcionario_id INTEGER NOT NULL, data TEXT NOT NULL, justificada INTEGER NOT NULL DEFAULT 0, FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id))');
    }
    if (oldVersion < 4) await db.execute('CREATE TABLE faturamento_diario(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT NOT NULL UNIQUE, valor REAL NOT NULL, observacao TEXT)');
    if (oldVersion < 5) await db.execute('CREATE TABLE fechamentos(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT NOT NULL UNIQUE, valor_bruto REAL NOT NULL, custo_funcionarios REAL NOT NULL, gastos_extras REAL NOT NULL, lucro_liquido REAL NOT NULL, observacao TEXT)');
    if (oldVersion < 6) await db.execute('CREATE TABLE terceirizados(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL, valor_diaria REAL NOT NULL, dias_trabalhados INTEGER NOT NULL DEFAULT 0, contato TEXT NOT NULL, observacao TEXT)');
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE funcionarios ADD COLUMN setor INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN cargo2 INTEGER');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN valor_diaria REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE funcionarios ADD COLUMN dias_trabalhados INTEGER NOT NULL DEFAULT 0');
      await db.execute('CREATE TABLE presencas(id INTEGER PRIMARY KEY AUTOINCREMENT, funcionario_id INTEGER NOT NULL, data TEXT NOT NULL, status TEXT NOT NULL, FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id), UNIQUE(funcionario_id, data))');
    }
    if (oldVersion < 8) await db.execute('ALTER TABLE funcionarios ADD COLUMN setor2 INTEGER');
    if (oldVersion < 9) await db.execute('CREATE TABLE notificacoes_folga(id INTEGER PRIMARY KEY AUTOINCREMENT, funcionario_id INTEGER NOT NULL, data_solicitada TEXT NOT NULL, data_criacao TEXT NOT NULL, status TEXT NOT NULL, motivo TEXT, FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id))');
    if (oldVersion < 10) {
      await db.execute('CREATE TABLE estoque(id INTEGER PRIMARY KEY AUTOINCREMENT, nome_item TEXT NOT NULL, categoria TEXT NOT NULL, quantidade_atual REAL NOT NULL, quantidade_minima REAL NOT NULL, data_validade TEXT, custo_unitario REAL NOT NULL, unidade_medida TEXT NOT NULL, fator_conversao REAL NOT NULL DEFAULT 1.0)');
      await db.execute('CREATE TABLE notificacoes_gerais(id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT NOT NULL, titulo TEXT NOT NULL, mensagem TEXT NOT NULL, data_criacao TEXT NOT NULL, status TEXT NOT NULL DEFAULT "pendente", referencia_id INTEGER)');
    }
  }

  // --- MÉTODOS CRUD ---

  // Produtos
  Future<int> insertProduto(Produto p) async { final db = await database; return await db.insert('produtos', p.toMap()); }
  Future<List<Produto>> getAllProdutos() async { final db = await database; final res = await db.query('produtos'); return res.map((j) => Produto.fromMap(j)).toList(); }
  Future<int> updateProduto(Produto p) async { final db = await database; return await db.update('produtos', p.toMap(), where: 'id = ?', whereArgs: [p.id]); }
  Future<int> deleteProduto(int id) async { final db = await database; return await db.delete('produtos', where: 'id = ?', whereArgs: [id]); }

  // Produção
  Future<int> insertProducao(ProducaoDia p) async { final db = await database; return await db.insert('producao_dia', p.toMap()); }
  Future<List<ProducaoDia>> getProducaoPorData(String data) async {
    final db = await database;
    final res = await db.query('producao_dia', where: 'data = ?', whereArgs: [data]);
    final prods = await getAllProdutos();
    final pMap = {for (var p in prods) p.id: p.nome};
    return res.map((j) => ProducaoDia.fromMap(j, pMap[j['produto_id']] ?? 'Desconhecido')).toList();
  }

  // Vendas
  Future<int> insertVenda(VendaDia v) async { final db = await database; return await db.insert('vendas_dia', v.toMap()); }
  Future<List<VendaDia>> getVendasPorData(String data) async {
    final db = await database;
    final res = await db.query('vendas_dia', where: 'data = ?', whereArgs: [data]);
    final prods = await getAllProdutos();
    final pMap = {for (var p in prods) p.id: p.nome};
    return res.map((j) => VendaDia.fromMap(j, pMap[j['produto_id']] ?? 'Desconhecido')).toList();
  }

  // Funcionários
  Future<int> insertFuncionario(Funcionario f) async { final db = await database; return await db.insert('funcionarios', f.toMap()); }
  Future<List<Funcionario>> getAllFuncionarios() async { final db = await database; final res = await db.query('funcionarios'); return res.map((j) => Funcionario.fromMap(j)).toList(); }
  Future<int> updateFuncionario(Funcionario f) async { final db = await database; return await db.update('funcionarios', f.toMap(), where: 'id = ?', whereArgs: [f.id]); }
  Future<int> deleteFuncionario(int id) async { final db = await database; return await db.delete('funcionarios', where: 'id = ?', whereArgs: [id]); }

  // Faltas e Presenças
  Future<int> insertFalta(int fId, DateTime d, {bool just = false}) async { final db = await database; return await db.insert('faltas', {'funcionario_id': fId, 'data': d.toIso8601String().split('T')[0], 'justificada': just ? 1 : 0}); }
  Future<List<Map<String, dynamic>>> getFaltasFuncionario(int fId, {DateTime? mes}) async {
    final db = await database;
    if (mes != null) { String m = DateFormat('yyyy-MM').format(mes); return await db.query('faltas', where: 'funcionario_id = ? AND data LIKE ?', whereArgs: [fId, '$m%']); }
    return await db.query('faltas', where: 'funcionario_id = ?', whereArgs: [fId]);
  }
  Future<int> togglePresenca(int fId, String s) async { final db = await database; String d = DateTime.now().toIso8601String().split('T')[0]; return await db.insert('presencas', {'funcionario_id': fId, 'data': d, 'status': s}, conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<String?> getPresencaHoje(int fId) async { final db = await database; String d = DateTime.now().toIso8601String().split('T')[0]; final r = await db.query('presencas', where: 'funcionario_id = ? AND data = ?', whereArgs: [fId, d]); return r.isNotEmpty ? r.first['status'] as String : null; }
  Future<int> countFaltasMes(int fId) async { final db = await database; String m = DateFormat('yyyy-MM').format(DateTime.now()); final r = await db.rawQuery("SELECT COUNT(*) as total FROM presencas WHERE funcionario_id = ? AND status = 'falta' AND data LIKE ?", [fId, '$m%']); return Sqflite.firstIntValue(r) ?? 0; }

  // Faturamento e Fechamento
  Future<int> upsertFaturamentoDiario(String d, double v, {String? observacao}) async { final db = await database; return await db.insert('faturamento_diario', {'data': d, 'valor': v, 'observacao': observacao}, conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<Map<String, dynamic>?> getFaturamentoPorData(String d) async { final db = await database; final r = await db.query('faturamento_diario', where: 'data = ?', whereArgs: [d]); return r.isNotEmpty ? r.first : null; }
  Future<List<Map<String, dynamic>>> getHistoricoMesmoDiaSemana(DateTime d) async { final db = await database; final w = d.weekday; final all = await db.query('faturamento_diario'); return all.where((r) => DateTime.parse(r['data'] as String).weekday == w && DateTime.parse(r['data'] as String).isBefore(d)).toList(); }
  Future<int> insertFechamento(Fechamento f) async { final db = await database; return await db.insert('fechamentos', f.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<Fechamento?> getFechamentoPorData(String d) async { final db = await database; final r = await db.query('fechamentos', where: 'data = ?', whereArgs: [d]); return r.isNotEmpty ? Fechamento.fromMap(r.first) : null; }

  // Notificações de Folga
  Future<int> insertNotificacaoFolga(NotificacaoFolga n) async { final db = await database; return await db.insert('notificacoes_folga', n.toMap()); }
  Future<List<NotificacaoFolga>> getNotificacoesPendentes() async {
    final db = await database;
    final result = await db.query('notificacoes_folga', orderBy: "status DESC, data_criacao DESC");
    final funcs = await getAllFuncionarios();
    final fMap = {for (var f in funcs) f.id: f};
    return result.map((r) { final f = fMap[r['funcionario_id']]; return NotificacaoFolga.fromMap(r, f?.nome ?? 'Desconhecido', f?.cargo.displayName ?? ''); }).toList();
  }
  Future<void> responderFolga(int id, String s) async {
    final db = await database;
    await db.update('notificacoes_folga', {'status': s}, where: 'id = ?', whereArgs: [id]);
    if (s == 'aprovado') {
      final n = await db.query('notificacoes_folga', where: 'id = ?', whereArgs: [id]);
      if (n.isNotEmpty) await db.insert('presencas', {'funcionario_id': n.first['funcionario_id'], 'data': n.first['data_solicitada'], 'status': 'falta'}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // --- ESTOQUE ---
  Future<int> insertEstoque(EstoqueItem item) async {
    final db = await database;
    return await db.insert('estoque', item.toMap());
  }

  Future<List<EstoqueItem>> getAllEstoque() async {
    final db = await database;
    final res = await db.query('estoque');
    return res.map((j) => EstoqueItem.fromMap(j)).toList();
  }

  Future<int> updateEstoque(EstoqueItem item) async {
    final db = await database;
    int res = await db.update('estoque', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    await _verificarEstoqueMinimo(item);
    return res;
  }

  Future<void> _verificarEstoqueMinimo(EstoqueItem item) async {
    if (item.quantidadeAtual <= item.quantidadeMinima) {
      await insertNotificacaoGeral(NotificacaoGeral(
        tipo: 'estoque_reposicao',
        titulo: 'Reposição de Estoque',
        mensagem: 'O item ${item.nome} atingiu o nível crítico (${item.quantidadeAtual} ${item.unidadeMedida}). Favor reabastecer.',
        dataCriacao: DateTime.now(),
        referenciaId: item.id,
      ));
    }
  }

  Future<void> darBaixaEstoque(int id, double qtdSaida, bool ehDesperdicio) async {
    final db = await database;
    final res = await db.query('estoque', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      EstoqueItem item = EstoqueItem.fromMap(res.first);
      item.quantidadeAtual -= qtdSaida;
      await updateEstoque(item);

      if (ehDesperdicio) {
        await insertNotificacaoGeral(NotificacaoGeral(
          tipo: 'estoque_desperdicio',
          titulo: 'Alerta de Desperdício',
          mensagem: 'Alto índice de desperdício detectado para o item ${item.nome} ($qtdSaida ${item.unidadeMedida}).',
          dataCriacao: DateTime.now(),
          referenciaId: item.id,
        ));
      }
    }
  }

  Future<int> deleteEstoque(int id) async {
    final db = await database;
    return await db.delete('estoque', where: 'id = ?', whereArgs: [id]);
  }

  // --- NOTIFICAÇÕES GERAIS ---
  Future<int> insertNotificacaoGeral(NotificacaoGeral n) async {
    final db = await database;
    return await db.insert('notificacoes_gerais', n.toMap());
  }

  Future<List<NotificacaoGeral>> getNotificacoesGeraisPendentes() async {
    final db = await database;
    final res = await db.query('notificacoes_gerais', where: "status = 'pendente'", orderBy: "data_criacao DESC");
    return res.map((j) => NotificacaoGeral.fromMap(j)).toList();
  }

  Future<int> countTotalNotificacoesPendentes() async {
    final db = await database;
    final folgas = await db.rawQuery("SELECT COUNT(*) as c FROM notificacoes_folga WHERE status = 'pendente'");
    final gerais = await db.rawQuery("SELECT COUNT(*) as c FROM notificacoes_gerais WHERE status = 'pendente'");
    return (Sqflite.firstIntValue(folgas) ?? 0) + (Sqflite.firstIntValue(gerais) ?? 0);
  }

  Future<void> marcarNotificacaoGeralLida(int id) async {
    final db = await database;
    await db.update('notificacoes_gerais', {'status': 'lida'}, where: 'id = ?', whereArgs: [id]);
  }

  // Método unificado para obter todas as notificações pendentes (folga + estoque)
  Future<List<dynamic>> getAllNotificacoesPendentes() async {
    final folgas = await getNotificacoesPendentes();
    final gerais = await getNotificacoesGeraisPendentes();
    final todas = <dynamic>[...folgas, ...gerais];
    // Ordenar por data mais recente primeiro
    todas.sort((a, b) {
      DateTime dataA;
      DateTime dataB;
      if (a is NotificacaoFolga) {
        dataA = a.dataCriacao;
      } else {
        dataA = (a as NotificacaoGeral).dataCriacao;
      }
      if (b is NotificacaoFolga) {
        dataB = b.dataCriacao;
      } else {
        dataB = (b as NotificacaoGeral).dataCriacao;
      }
      return dataB.compareTo(dataA);
    });
    return todas;
  }

  // --- TERCEIRIZADOS ---
  Future<int> insertTerceirizado(Terceirizado t) async {
    final db = await database;
    return await db.insert('terceirizados', t.toMap());
  }

  Future<List<Terceirizado>> getAllTerceirizados() async {
    final db = await database;
    final res = await db.query('terceirizados');
    return res.map((j) => Terceirizado.fromMap(j)).toList();
  }

  Future<int> updateTerceirizado(Terceirizado t) async {
    final db = await database;
    return await db.update('terceirizados', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTerceirizado(int id) async {
    final db = await database;
    return await db.delete('terceirizados', where: 'id = ?', whereArgs: [id]);
  }

  // Relatórios e Lógica de Negócio
  Future<Map<String, dynamic>> registrarVenda(VendaDia v) async {
    final db = await database;
    await insertVenda(v);
    final prod = await db.query('producao_dia', where: 'produto_id = ? AND data = ?', whereArgs: [v.produtoId, v.data.toIso8601String().split('T')[0]]);
    if (prod.isNotEmpty) {
      int p = prod.first['quantidade_produzida'] as int;
      final tV = await db.rawQuery('SELECT SUM(quantidade) as total FROM vendas_dia WHERE produto_id = ? AND data = ?', [v.produtoId, v.data]);
      int vend = tV.first['total'] as int? ?? 0;
      double per = (p - vend) / p * 100;
      if (per > 20) return {'alerta': true, 'mensagem': '⚠️ Produto ${v.produtoId} com ${per.toStringAsFixed(1)}% de sobra prevista'};
    }
    return {'alerta': false};
  }

  Future<Map<String, dynamic>> getRelatorioDiario(String data) async {
    final db = await database;
    final v = await db.rawQuery('SELECT SUM(valor_total) as tf, SUM(quantidade) as qv FROM vendas_dia WHERE data = ?', [data]);
    final p = await db.rawQuery('SELECT SUM(quantidade_produzida) as tp FROM producao_dia WHERE data = ?', [data]);
    final fm = await getFaturamentoPorData(data);
    final fmv = fm != null ? (fm['valor'] as num).toDouble() : 0.0;
    final funcs = await db.rawQuery('SELECT COUNT(*) as c FROM funcionarios');
    double tp = (p.first['tp'] as num?)?.toDouble() ?? 0.0;
    double qv = (v.first['qv'] as num?)?.toDouble() ?? 0.0;
    double tf = fmv > 0 ? fmv : ((v.first['tf'] as num?)?.toDouble() ?? 0.0);
    double perD = tp > 0 ? ((tp - qv) / tp) * 100 : 0.0;
    return {'faturamento': tf, 'itens_vendidos': qv, 'itens_produzidos': tp, 'percentual_desperdicio': perD, 'status': perD > 20 ? 'Crítico' : perD > 10 ? 'Atenção' : 'Bom', 'total_funcionarios': funcs.first['c'] as int? ?? 0, 'eficiencia_por_funcionario': qv / (funcs.first['c'] as int? ?? 1)};
  }

  Future<List<ResultadoDiario>> getResultadosPorPeriodo(DateTime inicio, DateTime fim) async {
    List<ResultadoDiario> res = [];
    for (DateTime d = inicio; !d.isAfter(fim); d = d.add(const Duration(days: 1))) {
      final r = await getRelatorioDiario(d.toIso8601String().split('T')[0]);
      ResultadoDiario rd = ResultadoDiario(data: d);
      rd.totalVendasBruto = r['faturamento'];
      rd.totalVendasLiquido = r['faturamento'];
      rd.totalItensVendidos = (r['itens_vendidos']).toInt();
      rd.totalItensProduzidos = (r['itens_produzidos']).toInt();
      rd.percentualDesperdicio = r['percentual_desperdicio'];
      rd.totalFuncionariosAtivos = r['total_funcionarios'];
      rd.eficienciaFuncionarios = r['eficiencia_por_funcionario'];
      rd.calcularIndicadores();
      res.add(rd);
    }
    return res;
  }
}
