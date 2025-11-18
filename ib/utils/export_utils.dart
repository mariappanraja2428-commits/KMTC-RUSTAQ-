// lib/utils/export_utils.dart
import 'dart:html' as html; // for Blob downloads
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

/// Fetch binary from a network URL. Returns null on failure.
Future<Uint8List?> fetchUrlBytes(String url) async {
  try {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) return resp.bodyBytes;
    return null;
  } catch (e) {
    // network or CORS issue; ignore the image
    return null;
  }
}

/// Export Firestore records (pass a QuerySnapshot or list of docs)
Future<void> exportRecordsToExcel(List<QueryDocumentSnapshot> docs, {String fileName = 'records.xlsx'}) async {
  final workbook = xls.Workbook();
  final sheet = workbook.worksheets[0];

  final headers = [
    'Area',
    'Line',
    'Size',
    'Material',
    'Meter',
    'TX No',
    'Place',
    'BeforeUrl',
    'AfterUrl',
    'Latitude',
    'Longitude',
    'CreatedAt'
  ];

  for (var i = 0; i < headers.length; i++) {
    sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
  }

  for (var i = 0; i < docs.length; i++) {
    final d = docs[i].data() as Map<String, dynamic>;
    sheet.getRangeByIndex(i + 2, 1).setText(d['area']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 2).setText(d['line']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 3).setText(d['size']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 4).setText(d['material']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 5).setText(d['meter']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 6).setText(d['txNo']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 7).setText(d['place']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 8).setText(d['beforeUrl']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 9).setText(d['afterUrl']?.toString() ?? '');
    sheet.getRangeByIndex(i + 2, 10).setText((d['latitude'] ?? '').toString());
    sheet.getRangeByIndex(i + 2, 11).setText((d['longitude'] ?? '').toString());
    final ts = d['createdAt'];
    sheet.getRangeByIndex(i + 2, 12).setText(ts != null ? ts.toDate().toIso8601String() : '');
  }

  final bytes = workbook.saveAsStream();
  workbook.dispose();

  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Export Firestore records to PDF with a background image and optional thumbnails.
/// [bgImageUrl] — URL for a background image to appear behind the table (can be an asset hosted URL).
Future<void> exportRecordsToPdf(List<QueryDocumentSnapshot> docs,
    {required String fileName, String? bgImageUrl, bool embedThumbnails = true}) async {
  final pdf = pw.Document();

  // prefetch background bytes (optional)
  Uint8List? bgBytes;
  if (bgImageUrl != null && bgImageUrl.isNotEmpty) {
    bgBytes = await fetchUrlBytes(bgImageUrl);
  }

  // For each page: we will build a table with up to N rows per page.
  const rowsPerPage = 12;
  final totalPages = (docs.length / rowsPerPage).ceil();

  for (var pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final start = pageIndex * rowsPerPage;
    final end = (start + rowsPerPage) > docs.length ? docs.length : start + rowsPerPage;
    final slice = docs.sublist(start, end);

    // Pre-fetch thumbnail images if requested (web CORS may block some images)
    final List<Uint8List?> beforeImages = [];
    final List<Uint8List?> afterImages = [];
    if (embedThumbnails) {
      for (final d in slice) {
        final data = d.data() as Map<String, dynamic>;
        final beforeUrl = (data['beforeUrl'] ?? '').toString();
        final afterUrl = (data['afterUrl'] ?? '').toString();

        beforeImages.add(beforeUrl.isNotEmpty ? await fetchUrlBytes(beforeUrl) : null);
        afterImages.add(afterUrl.isNotEmpty ? await fetchUrlBytes(afterUrl) : null);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final tableHeaders = [
            'Area',
            'Line',
            'Size',
            'Material',
            'Meter',
            'TX',
            'Place',
            if (embedThumbnails) 'Before',
            if (embedThumbnails) 'After',
            'Lat',
            'Lon'
          ];

          final tableData = <List<dynamic>>[];
          for (var i = 0; i < slice.length; i++) {
            final data = slice[i].data() as Map<String, dynamic>;
            final row = [
              data['area'] ?? '',
              data['line'] ?? '',
              data['size'] ?? '',
              data['material'] ?? '',
              data['meter'] ?? '',
              data['txNo'] ?? '',
              data['place'] ?? '',
            ];
            if (embedThumbnails) {
              // Placeholders: we will insert images separately using pw.Widget
              row.add(beforeImages[i] != null ? pw.MemoryImage(beforeImages[i]!) : ''); // will be handled below
              row.add(afterImages[i] != null ? pw.MemoryImage(afterImages[i]!) : '');
            }
            row.add((data['latitude'] ?? '').toString());
            row.add((data['longitude'] ?? '').toString());
            tableData.add(row);
          }

          // Layout: background then header and table
          return pw.Stack(
            children: [
              if (bgBytes != null)
                pw.Positioned.fill(child: pw.Image(pw.MemoryImage(bgBytes), fit: pw.BoxFit.cover)),
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('NAMA ELECTRICITY DISTRIBUTION COMPANY RUSTAQ',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Table.fromTextArray(
                        headers: tableHeaders,
                        data: tableData.map((r) {
                          // For image cells we must transform MemoryImage into something that the table supports.
                          // The table will receive objects; we'll map MemoryImage to widgets after table creation.
                          return r;
                        }).toList(),
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        cellStyle: pw.TextStyle(fontSize: 9),
                        cellAlignment: pw.Alignment.centerLeft,
                        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                        cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Page ${pageIndex + 1} of $totalPages', style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Save PDF bytes and trigger download
  final bytes = await pdf.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
