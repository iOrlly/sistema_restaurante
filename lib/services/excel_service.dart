import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/funcionario.dart';
import '../database/database_helper.dart';
import 'save_helper.dart' 
  if (dart.library.html) 'save_helper_web.dart' 
  if (dart.library.io) 'save_helper_native.dart';

class ExcelService {
  static Future<void> gerarFolhaPagamento(List<Funcionario> funcionarios, DateTime mes) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Folha de Pagamento'];
    excel.delete('Sheet1');

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#CCCCCC'),
      horizontalAlign: HorizontalAlign.Center,
    );

    List<String> headers = ['ID', 'Nome', 'Cargo', 'Salário Base', 'Faltas', 'Desconto Faltas', 'Salário Líquido', 'Status'];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    final dbHelper = DatabaseHelper.instance;

    for (var i = 0; i < funcionarios.length; i++) {
      var f = funcionarios[i];
      final faltas = await dbHelper.getFaltasFuncionario(f.id!, mes: mes);
      final faltasNaoJustificadas = faltas.where((falta) => falta['justificada'] == 0).length;
      
      double valorDia = f.salario / 30;
      double desconto = faltasNaoJustificadas * valorDia;
      double salarioLiquido = f.salario - desconto;

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = IntCellValue(f.id!);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(f.nome);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(f.cargo.displayName);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = DoubleCellValue(f.salario);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = IntCellValue(faltasNaoJustificadas);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = DoubleCellValue(desconto);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = DoubleCellValue(salarioLiquido);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 1)).value = TextCellValue(f.emFerias ? 'Em Férias' : 'Ativo');
    }

    await SaveHelper.saveEAbrir(excel, 'Folha_Pagamento_${DateFormat('MM_yyyy').format(mes)}.xlsx');
  }

  static Future<void> exportarFaturamento(List<Map<String, dynamic>> dados, String titulo) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Faturamento'];
    excel.delete('Sheet1');

    if (dados.isEmpty) return;

    List<String> headers = dados.first.keys.toList();
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i].toUpperCase());
    }

    for (var i = 0; i < dados.length; i++) {
      var row = dados[i];
      for (var j = 0; j < headers.length; j++) {
        var val = row[headers[j]];
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
        if (val is double) {
          cell.value = DoubleCellValue(val);
        } else if (val is int) {
          cell.value = IntCellValue(val);
        } else {
          cell.value = TextCellValue(val.toString());
        }
      }
    }

    await SaveHelper.saveEAbrir(excel, 'Relatorio_${titulo}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx');
  }

  static Future<void> exportarBoletos(List<dynamic> boletos) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Boletos'];
    excel.delete('Sheet1');

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#CCCCCC'),
    );

    List<String> headers = ['Data Vencimento', 'Descrição', 'Valor', 'Categoria', 'Status'];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var i = 0; i < boletos.length; i++) {
      var b = boletos[i];
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(DateFormat('dd/MM/yyyy').format(b.dataVencimento));
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(b.descricao);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = DoubleCellValue(b.valor);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = TextCellValue(b.categoria);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = TextCellValue(b.status == 1 ? 'Pago' : 'Pendente');
    }

    await SaveHelper.saveEAbrir(excel, 'relatorio_boletos_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx');
  }

  static Future<void> exportarBoletoIndividual(dynamic b) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Comprovante Boleto'];
    excel.delete('Sheet1');

    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('COMPROVANTE DE LANÇAMENTO');
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Descrição:');
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value = TextCellValue(b.descricao);
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('Valor:');
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = DoubleCellValue(b.valor);
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = TextCellValue('Vencimento:');
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = TextCellValue(DateFormat('dd/MM/yyyy').format(b.dataVencimento));
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('Status:');
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = TextCellValue(b.status == 1 ? 'PAGO' : 'PENDENTE');

    await SaveHelper.saveEAbrir(excel, 'boleto_${b.descricao.replaceAll(' ', '_')}.xlsx');
  }

  static Future<void> exportarRelatorioGeral(Map<String, dynamic> dados, DateTimeRange periodo) async {
    var excel = Excel.createExcel();
    excel.delete('Sheet1');

    // Aba de Resumo
    Sheet res = excel['RESUMO FINANCEIRO'];
    res.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Relatório de Fechamento - Beira Rio');
    res.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Período: ${DateFormat('dd/MM/yy').format(periodo.start)} até ${DateFormat('dd/MM/yy').format(periodo.end)}');
    
    res.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('(+) TOTAL VENDAS:');
    res.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = DoubleCellValue(dados['total_vendas']);
    
    res.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = TextCellValue('(-) TOTAL BOLETOS:');
    res.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = DoubleCellValue(dados['total_boletos']);
    
    res.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('(-) TOTAL DIÁRIAS:');
    res.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = DoubleCellValue(dados['total_diarias']);
    
    res.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = TextCellValue('(=) LUCRO LÍQUIDO:');
    res.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).value = DoubleCellValue(dados['lucro_liquido']);

    // Aba de Detalhes de Saída (Boletos + Diárias)
    Sheet out = excel['DETALHES DE SAÍDA'];
    out.appendRow([TextCellValue('TIPO'), TextCellValue('DATA'), TextCellValue('DESCRIÇÃO'), TextCellValue('VALOR')]);
    
    for (var b in dados['lista_boletos']) {
      out.appendRow([
        TextCellValue('BOLETO'),
        TextCellValue(DateFormat('dd/MM/yy').format(DateTime.parse(b['data_pagamento']))),
        TextCellValue(b['descricao']),
        DoubleCellValue(b['valor'])
      ]);
    }
    
    for (var d in dados['lista_diarias']) {
      out.appendRow([
        TextCellValue('DIÁRIA'),
        TextCellValue(DateFormat('dd/MM/yy').format(DateTime.parse(d['data']))),
        TextCellValue(d['nome']),
        DoubleCellValue(d['valor'])
      ]);
    }

    await SaveHelper.saveEAbrir(excel, 'Relatorio_Geral_${DateFormat('ddMMyy').format(periodo.start)}_a_${DateFormat('ddMMyy').format(periodo.end)}.xlsx');
  }
}
