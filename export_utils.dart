import 'dart:typed_data';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

Future<Uint8List?> fetchUrlBytes(String url) async {
  try {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) return resp.bodyBytes;
  } catch (e) {
    // ignore
  }
  return null;
}

Future<void> exportRecordsToExcel(List<QueryDocumentSnapshot> docs, {String fileName = 'records.xlsx'}) async {
  final workbook = xls.Workbook();
  final sheet = workbook.worksheets[0];

  final headers = [
    'Area','Line','Size','Material','Meter','TX No','Place','BeforeUrl','AfterUrl','Lat','Lon','CreatedAt'
  ];
  for (var i=0;i<headers.length;i++) sheet.getRangeByIndex(1,i+1).setText(headers[i]);

  for (var i=0;i<docs.length;i++) {
    final d = docs[i].data() as Map<String,dynamic>;
    sheet.getRangeByIndex(i+2,1).setText(d['area']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,2).setText(d['line']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,3).setText(d['size']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,4).setText(d['material']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,5).setText(d['meter']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,6).setText(d['txNo']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,7).setText(d['place']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,8).setText(d['beforeUrl']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,9).setText(d['afterUrl']?.toString() ?? '');
    sheet.getRangeByIndex(i+2,10).setText((d['latitude'] ?? '').toString());
    sheet.getRangeByIndex(i+2,11).setText((d['longitude'] ?? '').toString());
    final ts = d['createdAt'];
    sheet.getRangeByIndex(i+2,12).setText(ts != null ? ts.toDate().toIso8601String() : '');
  }

  final bytes = workbook.saveAsStream();
  workbook.dispose();
  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..setAttribute('download', fileName)..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> exportRecordsToPdf(List<QueryDocumentSnapshot> docs, {required String fileName, String? bgImageUrl, bool embedThumbnails = true}) async {
  final pdf = pw.Document();
  pdf.addPage(pw.Page(build: (pw.Context context) {
    return pw.Center(child: pw.Text('PDF export placeholder - see canvas for full implementation'));
  }));
  final bytes = await pdf.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..setAttribute('download', fileName)..click();
  html.Url.revokeObjectUrl(url);
}
