import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class SaveHelper {
  static Future<void> saveEAbrir(Excel excel, String fileName) async {
    var fileBytes = excel.save();
    var directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/$fileName';
    
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    await OpenFilex.open(filePath);
  }
}
