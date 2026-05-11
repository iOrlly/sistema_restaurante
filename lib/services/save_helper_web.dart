import 'package:excel/excel.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SaveHelper {
  static Future<void> saveEAbrir(Excel excel, String fileName) async {
    var fileBytes = excel.save();
    final content = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(content);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
