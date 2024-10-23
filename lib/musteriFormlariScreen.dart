import 'package:flutter/material.dart';
import 'package:pdf_editor/formolustur.dart';
import 'databaseHelper.dart';
import 'formModel.dart';
import 'formModel3.dart';
import 'package:share_plus/share_plus.dart'; // PDF paylaşımı için gerekli
import 'package:flutter_pdfview/flutter_pdfview.dart';

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
    // form numarasına göre forms_2 ve forms_3'ten verileri alın
    final form3 = await DatabaseHelper().getForms2ByNum(form.num);

    if (form3 != null) {
      // FormOlustur sayfasına geçiş yapın ve form verisini gönderin
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormOlustur(
            form: form3,  // FormModel3 verisini gönderiyoruz
            id: 1
          ),
        ),
      );
    } else {
      // Form bulunamadığında bir mesaj göster
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
            width: 400,  // Ekranın %90'ı genişliğinde
            height: 500,  // A4 oranına yakın yükseklik
            child: PDFView(
              filePath: form.pdfFilePath,  // PDF dosya yolu
              enableSwipe: true,  // Sayfalar arasında geçiş yapmak için kaydırma
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
                Navigator.of(context).pop();  // Popup'ı kapat
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$musteriAdSoyad - Formlar'),
        backgroundColor: Colors.teal, // AppBar rengi
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(10), // Liste boşlukları
        itemCount: forms.length,
        itemBuilder: (context, index) {
          final form = forms[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Kartlar arasında boşluk
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Kartın köşeleri yuvarlatılmış
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36), // PDF ikonu
                title: Text(
                  'Seri No: ${form.num}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ), // Form seri numarası
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.black54), // Tarih ikonu
                      SizedBox(width: 5),
                      Text(
                        form.tarih,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ), // Tarih
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.teal),
                      onPressed: () => _editForm(context, form), // Düzenleme ekranına geçiş
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.teal),
                      onPressed: () => _shareForm(form), // Paylaş butonu
                    ),
                  ],
                ),
                onTap: () {
                  // Forma tıklanınca popup ile formu göster
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
