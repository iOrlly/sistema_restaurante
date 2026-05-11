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
}
