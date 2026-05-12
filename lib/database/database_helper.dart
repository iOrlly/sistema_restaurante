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
import '../models/boleto.dart';

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
        version: 12, // Versão 12 para Data de Pagamento em Boletos
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

    await db.execute('''
      CREATE TABLE boletos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        data_vencimento TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        categoria TEXT NOT NULL,
        data_pagamento TEXT
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
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE boletos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          descricao TEXT NOT NULL,
          valor REAL NOT NULL,
          data_vencimento TEXT NOT NULL,
          status INTEGER NOT NULL DEFAULT 0,
          categoria TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 12) {
      await db.execute('ALTER TABLE boletos ADD COLUMN data_pagamento TEXT');
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

  // --- BOLETOS ---
  Future<int> insertBoleto(Boleto b) async {
    final db = await database;
    return await db.insert('boletos', b.toMap());
  }

  Future<List<Boleto>> getAllBoletos() async {
    final db = await database;
    final res = await db.query('boletos', orderBy: 'data_vencimento ASC');
    return res.map((j) => Boleto.fromMap(j)).toList();
  }

  Future<int> updateBoleto(Boleto b) async {
    final db = await database;
    return await db.update('boletos', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> deleteBoleto(int id) async {
    final db = await database;
    return await db.delete('boletos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> marcarBoletosComoPagos(List<int> ids) async {
    final db = await database;
    final dataPagamento = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (int id in ids) {
        await txn.update(
          'boletos', 
          {'status': 1, 'data_pagamento': dataPagamento}, 
          where: 'id = ?', 
          whereArgs: [id]
        );
      }
    });
  }

  Future<List<Boleto>> getBoletosPagosFiltrados({
    String? busca,
    DateTime? inicio,
    DateTime? fim,
    double? valorMin,
    double? valorMax,
  }) async {
    final db = await database;
    List<String> whereClauses = ["status = 1"];
    List<dynamic> whereArgs = [];

    if (busca != null && busca.isNotEmpty) {
      whereClauses.add("descricao LIKE ?");
      whereArgs.add("%$busca%");
    }

    if (inicio != null) {
      whereClauses.add("data_pagamento >= ?");
      // Define o início do dia selecionado
      final start = DateTime(inicio.year, inicio.month, inicio.day, 0, 0, 0);
      whereArgs.add(start.toIso8601String());
    }

    if (fim != null) {
      whereClauses.add("data_pagamento <= ?");
      // Define o final do dia selecionado (23:59:59) para abranger tudo do dia
      final end = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);
      whereArgs.add(end.toIso8601String());
    }

    if (valorMin != null) {
      whereClauses.add("valor >= ?");
      whereArgs.add(valorMin);
    }

    if (valorMax != null) {
      whereClauses.add("valor <= ?");
      whereArgs.add(valorMax);
    }

    String whereString = whereClauses.join(" AND ");
    final res = await db.query('boletos', where: whereString, whereArgs: whereArgs, orderBy: 'data_pagamento DESC');
    return res.map((j) => Boleto.fromMap(j)).toList();
  }

  Future<double> getTotalPendenteHoje() async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Se for segunda-feira, somar sábado, domingo e hoje
    if (now.weekday == DateTime.monday) {
      final sat = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 2)));
      final sun = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
      final res = await db.rawQuery(
        "SELECT SUM(valor) as total FROM boletos WHERE status = 0 AND (data_vencimento LIKE ? OR data_vencimento LIKE ? OR data_vencimento LIKE ?)",
        ['$sat%', '$sun%', '$todayStr%']
      );
      return Sqflite.firstIntValue(res)?.toDouble() ?? (res.first['total'] as num?)?.toDouble() ?? 0.0;
    } else {
      final res = await db.rawQuery(
        "SELECT SUM(valor) as total FROM boletos WHERE status = 0 AND data_vencimento LIKE ?",
        ['$todayStr%']
      );
      return (res.first['total'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<double> getTotalSemanal() async {
    final db = await database;
    final now = DateTime.now();
    // Encontrar a segunda-feira da semana atual
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    
    final start = DateFormat('yyyy-MM-dd').format(monday);
    final end = DateFormat('yyyy-MM-dd').format(sunday);
    
    final res = await db.rawQuery(
      "SELECT SUM(valor) as total FROM boletos WHERE data_vencimento BETWEEN ? AND ?",
      ['$start 00:00:00', '$end 23:59:59']
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
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
      rd.totalVendasLiquido = r['faturamento'] - (r['total_boletos_pagos'] ?? 0.0);
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

  // MÉTODO DE INTEGRAÇÃO TOTAL PARA O FECHAMENTO
  Future<Map<String, double>> getSugestaoFechamento(DateTime data) async {
    final db = await database;
    final dataStr = DateFormat('yyyy-MM-dd').format(data);

    // 1. Soma de Vendas Granulares (se houver)
    final resVendas = await db.rawQuery(
      "SELECT SUM(valor_total) as total FROM vendas_dia WHERE data = ?", [dataStr]
    );
    double vendas = (resVendas.first['total'] as num?)?.toDouble() ?? 0.0;

    // Se não houver vendas granulares, tenta pegar do faturamento manual
    if (vendas == 0) {
      final f = await getFaturamentoPorData(dataStr);
      vendas = (f?['valor'] as num?)?.toDouble() ?? 0.0;
    }

    // 2. Soma de Boletos Pagos NESTE DIA
    final resBoletos = await db.rawQuery(
      "SELECT SUM(valor) as total FROM boletos WHERE status = 1 AND data_pagamento LIKE ?", ['$dataStr%']
    );
    double boletos = (resBoletos.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Soma de Diárias de Funcionários Fixos PRESENTES
    final resFixos = await db.rawQuery('''
      SELECT SUM(f.valor_diaria) as total 
      FROM presencas p 
      JOIN funcionarios f ON p.funcionario_id = f.id 
      WHERE p.data = ? AND p.status = 'presente' AND f.valor_diaria > 0
    ''', [dataStr]);
    double diarias = (resFixos.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'vendas': vendas,
      'boletos': boletos,
      'diarias': diarias,
    };
  }

  // NOVO MÉTODO: BUSCA DETALHADA PARA RELATÓRIO DE PERÍODO
  Future<Map<String, dynamic>> getDadosRelatorioPeriodo(DateTime inicio, DateTime fim) async {
    final db = await database;
    double totalVendas = 0;
    double totalBoletos = 0;
    double totalDiarias = 0;
    
    List<Map<String, dynamic>> listaBoletos = [];
    List<Map<String, dynamic>> listaDiarias = [];

    // Iterar dia a dia no período para garantir a soma correta (priorizando faturamento manual vs granular)
    for (DateTime d = inicio; !d.isAfter(fim); d = d.add(const Duration(days: 1))) {
      final dataStr = DateFormat('yyyy-MM-dd').format(d);
      
      // 1. Vendas do dia (mesma lógica do Dashboard para consistência)
      final resVendas = await db.rawQuery("SELECT SUM(valor_total) as total FROM vendas_dia WHERE data = ?", [dataStr]);
      double vGranular = (resVendas.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final fManual = await getFaturamentoPorData(dataStr);
      double vManual = (fManual?['valor'] as num?)?.toDouble() ?? 0.0;
      
      // Prioridade: Se houver faturamento manual, usa ele. Se não, usa o granular.
      totalVendas += (vManual > 0) ? vManual : vGranular;

      // 2. Boletos pagos NESTE dia específico (filtrando pela data_pagamento)
      final resB = await db.rawQuery('''
        SELECT descricao, valor, categoria, data_pagamento 
        FROM boletos 
        WHERE status = 1 AND data_pagamento LIKE ?
      ''', ['$dataStr%']);
      
      for (var b in resB) {
        totalBoletos += (b['valor'] as num).toDouble();
        listaBoletos.add(b);
      }

      // 3. Diárias do dia
      final resD = await db.rawQuery('''
        SELECT f.nome, f.valor_diaria as valor, p.data
        FROM presencas p 
        JOIN funcionarios f ON p.funcionario_id = f.id 
        WHERE p.data = ? AND p.status = 'presente' AND f.valor_diaria > 0
      ''', [dataStr]);
      
      for (var di in resD) {
        totalDiarias += (di['valor'] as num).toDouble();
        listaDiarias.add(di);
      }
    }

    return {
      'lista_boletos': listaBoletos,
      'lista_diarias': listaDiarias,
      'total_vendas': totalVendas,
      'total_boletos': totalBoletos,
      'total_diarias': totalDiarias,
      'lucro_liquido': totalVendas - (totalBoletos + totalDiarias),
    };
  }
}
