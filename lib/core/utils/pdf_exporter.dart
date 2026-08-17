import 'dart:io';

import 'package:flutter/services.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

/// أدوات مشتركة لإنشاء وحفظ/عرض ملفات PDF في كل أنحاء التطبيق
/// (فاتورة بيع، تقرير وردية، تقارير مشتريات وموردين) حتى لا تتكرر
/// نفس منطق الخط والحفظ والفتح في كل مُصدّر على حدة.
class PdfExporter {
  PdfExporter._();

  static pw.Font? _cairoFont;
  static bool _mediaStoreInitialized = false;

  /// خط القاهرة (يدعم العربية) — يُحمَّل مرة واحدة ويُعاد استخدامه.
  static Future<pw.Font> cairoFont() async {
    return _cairoFont ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo.ttf'));
  }

  /// مستند PDF جديد بخط عربي جاهز للبناء.
  static Future<pw.Document> newDocument() async {
    final font = await cairoFont();
    return pw.Document(theme: pw.ThemeData.withFont(base: font));
  }

  /// يلف محتوى الصفحة باتجاه RTL (ضروري للعربية).
  static pw.Widget rtl(pw.Widget child) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: child,
    );
  }

  /// يحفظ ملف PDF في مجلد التنزيلات العام (عبر MediaStore على أندرويد).
  /// يعيد وصف مكان الحفظ عند النجاح، أو null عند الفشل.
  static Future<String?> saveToDownloads(
    Uint8List bytes,
    String fileName,
  ) async {
    if (!Platform.isAndroid) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return 'مستندات التطبيق';
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    if (!_mediaStoreInitialized) {
      await MediaStore.ensureInitialized();
      _mediaStoreInitialized = true;
    }
    MediaStore.appFolder = 'OmniOrder';

    final store = MediaStore();
    final info = await store.saveFile(
      tempFilePath: tempFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
      relativePath: FilePath.root,
    );

    if (info == null) return null;
    return 'مجلد التنزيلات';
  }

  /// يعرض ملف PDF عبر التطبيق المثبّت للعرض (نسخة داخل التطبيق).
  /// يعيد true إذا فُتح بنجاح.
  static Future<bool> openPdf(Uint8List bytes, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/open_$fileName');
      await file.writeAsBytes(bytes);
      final result = await OpenFilex.open(file.path);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }
}
