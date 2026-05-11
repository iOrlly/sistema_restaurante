import 'package:excel/excel.dart';

abstract class SaveHelper {
  static Future<void> saveEAbrir(Excel excel, String fileName) async {
    throw UnsupportedError('Plataforma não suportada');
  }
}
