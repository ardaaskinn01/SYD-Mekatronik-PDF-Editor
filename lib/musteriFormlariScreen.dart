import 'package:flutter/material.dart';
import 'formModel.dart';
import 'package:share_plus/share_plus.dart'; // PDF paylaşımı için gerekli

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
                      icon: Icon(Icons.share, color: Colors.teal),
                      onPressed: () => _shareForm(form), // Paylaş butonu
                    ),
                  ],
                ),
                onTap: () {
                  // Forma tıklanınca yapılacak işlemler (örneğin PDF görüntüleme)
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
