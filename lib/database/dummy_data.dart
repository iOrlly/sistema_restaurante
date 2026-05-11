import 'package:intl/intl.dart';
import 'database_helper.dart';
import '../models/funcionario.dart';
import '../models/produto.dart';
import '../models/producao_dia.dart';
import '../models/venda_dia.dart';
import '../models/estoque_item.dart';
import '../models/terceirizado.dart';

class DummyData {
  static Future<void> seedDatabase() async {
    final db = DatabaseHelper.instance;

    // 1. Inserir Funcionários
    final funcs = await db.getAllFuncionarios();
    if (funcs.isEmpty) {
      await db.insertFuncionario(Funcionario(
        nome: 'João Silva',
        cargo: CargoFuncionario.cozinheiro,
        setor: SetorFuncionario.cozinha,
        dataContratacao: DateTime.now().subtract(const Duration(days: 365)),
        telefone: '11999999999',
        salario: 2500.0,
      ));
      await db.insertFuncionario(Funcionario(
        nome: 'Maria Oliveira',
        cargo: CargoFuncionario.atendente,
        setor: SetorFuncionario.salao,
        dataContratacao: DateTime.now().subtract(const Duration(days: 180)),
        telefone: '11888888888',
        salario: 1800.0,
      ));
    }

    // 2. Inserir Produtos
    final prods = await db.getAllProdutos();
    if (prods.isEmpty) {
      await db.insertProduto(Produto(nome: 'Marmitex Executiva', categoria: 'Refeição', precoUnitario: 25.0, tempoPreparoMin: 15));
      await db.insertProduto(Produto(nome: 'Suco Natural 500ml', categoria: 'Bebida', precoUnitario: 12.0, tempoPreparoMin: 5));
      await db.insertProduto(Produto(nome: 'Sobremesa da Casa', categoria: 'Sobremesa', precoUnitario: 8.0, tempoPreparoMin: 2));
    }

    // 3. Inserir Estoque
    final estoque = await db.getAllEstoque();
    if (estoque.isEmpty) {
      await db.insertEstoque(EstoqueItem(
        nome: 'Arroz agulhinha',
        categoria: 'Grãos',
        quantidadeAtual: 50.0,
        quantidadeMinima: 10.0,
        custoUnitario: 5.5,
        unidadeMedida: 'KG',
      ));
      await db.insertEstoque(EstoqueItem(
        nome: 'Feijão Carioca',
        categoria: 'Grãos',
        quantidadeAtual: 5.0, // Nível Crítico para teste
        quantidadeMinima: 8.0,
        custoUnitario: 8.0,
        unidadeMedida: 'KG',
      ));
      await db.insertEstoque(EstoqueItem(
        nome: 'Óleo de Soja',
        categoria: 'Óleos',
        quantidadeAtual: 20.0,
        quantidadeMinima: 5.0,
        custoUnitario: 7.0,
        unidadeMedida: 'Litro',
      ));
    }

    // 4. Inserir Terceirizados
    final terceirizados = await db.getAllTerceirizados();
    if (terceirizados.isEmpty) {
      await db.insertTerceirizado(Terceirizado(
        nome: 'Carlos Extra',
        valorDiaria: 120.0,
        contato: '11777777777',
        observacao: 'Garçom para fins de semana',
      ));
    }

    // 5. Gerar Vendas e Produção Fictícias para HOJE
    final dataHoje = DateTime.now();
    final produtosAtuais = await db.getAllProdutos();
    final funcionariosAtuais = await db.getAllFuncionarios();

    if (produtosAtuais.isNotEmpty && funcionariosAtuais.isNotEmpty) {
      final p1 = produtosAtuais[0];
      final f1 = funcionariosAtuais[0];

      // Registro de Produção
      await db.insertProducao(ProducaoDia(
        data: dataHoje,
        produtoId: p1.id!,
        produtoNome: p1.nome,
        quantidadeProduzida: 100,
        quantidadeRestante: 5,
        horarioInicioProducao: dataHoje.subtract(const Duration(hours: 4)),
        horarioFimProducao: dataHoje.subtract(const Duration(hours: 1)),
        funcionarioResponsavelId: f1.id!,
        custoEstimadoProducao: 8.0 * 100,
      ));

      // Registro de Vendas
      await db.insertVenda(VendaDia(
        data: dataHoje,
        produtoId: p1.id!,
        produtoNome: p1.nome,
        quantidade: 10,
        precoUnitario: p1.precoUnitario,
        formaPagamento: FormaPagamento.pix,
        funcionarioAtendenteId: f1.id!,
        horarioVenda: DateTime.now(),
      ));
      
      await db.insertVenda(VendaDia(
        data: dataHoje,
        produtoId: p1.id!,
        produtoNome: p1.nome,
        quantidade: 5,
        precoUnitario: p1.precoUnitario,
        formaPagamento: FormaPagamento.cartaoDebito,
        funcionarioAtendenteId: f1.id!,
        horarioVenda: DateTime.now().subtract(const Duration(minutes: 30)),
      ));
    }
  }
}
