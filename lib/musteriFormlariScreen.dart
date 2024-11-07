import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_editor/formolustur.dart';
import 'databaseHelper.dart';
import 'formModel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

class MusteriFormlariScreen extends StatelessWidget {
  final String musteriAdSoyad;
  final List<FormModel> forms;

  MusteriFormlariScreen({required this.musteriAdSoyad, required this.forms});

  Future<void> _shareForm(FormModel form) async {
    String filePath = form.pdfFilePath;
    final xFile = XFile(filePath);

    try {
      await Share.shareXFiles([xFile], text: 'Paylaşılan PDF: ${form.musteriAdSoyad}');
    } catch (e) {
      print('Paylaşım hatası: $e');
    }
  }

  Future<void> _editForm(BuildContext context, FormModel form) async {
    final form3 = await DatabaseHelper().getForms2ByNum(form.num);

    if (form3 != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormOlustur(
            form: form3,
            id: 1,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form bulunamadı!')),
      );
    }
  }

  Future<void> _showFormDialog(BuildContext context, FormModel form) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            width: 400,
            height: 500,
            child: PDFView(
              filePath: form.pdfFilePath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: false,
              onRender: (pages) => print("Toplam sayfa sayısı: $pages"),
              onError: (error) => print(error.toString()),
              onPageError: (page, error) => print('$page. sayfada hata: $error'),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadForm(BuildContext context, FormModel form) async {
    try {
      // Genel depolama yolunu doğrudan tanımlıyoruz
      final directoryPath = '/storage/emulated/0/Documents/SYD MEKATRONİK/${form.musteriAdSoyad}';
      final sydFolder = Directory(directoryPath);

      // Klasör oluşturma
      if (!await sydFolder.exists()) {
        await sydFolder.create(recursive: true);
      }

      final filePath = '${sydFolder.path}/${form.num}.pdf';
      final file = File(filePath);

      // PDF dosyasını kaydetme işlemi
      final originalFile = File(form.pdfFilePath);
      await file.writeAsBytes(await originalFile.readAsBytes());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF indirildi: ${file.path}')),
      );
    } catch (e) {
      print('İndirme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF indirilemedi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$musteriAdSoyad - Formlar'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: forms.length,
        itemBuilder: (context, index) {
          final form = forms[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36),
                title: Text(
                  'Seri No: ${form.num}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                      SizedBox(width: 5),
                      Text(
                        form.tarih,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.teal),
                      onPressed: () => _editForm(context, form),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.teal),
                      onPressed: () => _shareForm(form),
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.teal),
                      onPressed: () => _downloadForm(context, form), // İndirme butonu
                    ),
                  ],
                ),
                onTap: () {
                  _showFormDialog(context, form);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
