import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:signature/signature.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // Geçici dizine erişmek için
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'databaseHelper.dart';
import 'formModel.dart';
import 'formModel2.dart';

class FormOlustur extends StatefulWidget {
  const FormOlustur({super.key});

  @override
  _FormOlusturState createState() => _FormOlusturState();
}

class _FormOlusturState extends State<FormOlustur> {
  // Metin alanları için controller'lar
  late String tarih;
  late String num;
  final TextEditingController adSoyadController = TextEditingController();
  final TextEditingController adresController = TextEditingController();
  final TextEditingController telefonController = TextEditingController();
  final TextEditingController yetkiliController = TextEditingController();
  final TextEditingController islemKisaTanimController =
      TextEditingController();
  final TextEditingController mailController =
  TextEditingController();
  final TextEditingController islemDetayController = TextEditingController();

  // Checkbox durumları için değişkenler
  bool montajChecked = false;
  bool egitimChecked = false;
  bool tamirChecked = false;
  bool revizyonChecked = false;
  bool projeSureciChecked = false;
  bool bakimChecked = false;
  bool odemeNakitChecked = false;
  bool odemeKartChecked = false;
  bool odemeFaturaChecked = false;
  bool odemeCekChecked = false;

  // İmza alanları için controller'lar
  final SignatureController yetkiliImzaController =
      SignatureController(penStrokeWidth: 2, penColor: Colors.black);
  final SignatureController musteriImzaController =
      SignatureController(penStrokeWidth: 2, penColor: Colors.black);

  late pdfx.PdfController pdfController;
  final double boxWidth = 375; // PDF görüntüleme kutusunun genişliği
  final double boxHeight = 550; // PDF görüntüleme kutusunun yüksekliği
  final double pdfWidth = 498; // PDF görüntüleme kutusunun genişliği
  final double pdfHeight = 698; // PDF görüntüleme kutusunun yüksekliği
  @override
  void initState() {
    super.initState();
    _initializePdf();

    adSoyadController.addListener(() async {
      // Ad-soyad her değiştiğinde kontrol et
      String adSoyad = adSoyadController.text;
      FormModel2? form = await getFormDataByAdSoyad(adSoyad);

      if (form != null) {
        // Eğer form bilgisi bulunursa diğer alanları doldur
        setState(() {
          mailController.text = form.mail;
          telefonController.text = form.telefon;
          adresController.text = form.adres;
        });
      }
    });
  }

  Future<void> _initializePdf() async {
    pdfController = pdfx.PdfController(
      document:
          pdfx.PdfDocument.openAsset('assets/documents/sydservisformu.pdf'),
    );
    DateTime now = DateTime.now();
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    tarih = dateFormatter.format(now);
    String day = now.day.toString().padLeft(2, '0'); // Günü 2 haneli göster
    String month = now.month.toString().padLeft(2, '0'); // Ayı 2 haneli göster
    String year = now.year.toString().substring(2); // Yılın son iki hanesini al
    String hour = now.hour.toString().padLeft(2, '0'); // Saati 2 haneli göster
    String minute = now.minute.toString().padLeft(2, '0'); // Dakikayı 2 haneli göster
    int seriNumber = int.parse(day + month + year + hour + minute);
    num = seriNumber.toString();
  }

  Future<void> requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      // İzin verildi
    } else {
      // İzin verilmedi
    }
  }

  Future<void> saveFormData(FormModel2 form) async {
    final prefs = await SharedPreferences.getInstance();

    // Daha önceki kayıtları kontrol et
    List<String> savedForms = prefs.getStringList('savedForms') ?? [];

    // Yeni formu JSON formatına çevir
    savedForms.add(jsonEncode(form.toJson()));

    // Yeni listeyi kaydet
    await prefs.setStringList('savedForms', savedForms);
  }

  Future<FormModel2?> getFormDataByAdSoyad(String adSoyad) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> savedForms = prefs.getStringList('savedForms') ?? [];

    for (String formString in savedForms) {
      final form = FormModel2.fromJson(jsonDecode(formString));

      if (form.adSoyad == adSoyad) {
        return form; // Eşleşen formu geri döndür
      }
    }
    return null; // Eşleşme bulunmazsa null döndür
  }

  Future<Uint8List?> pdfImageFromPdfDocument(pdfx.PdfDocument document) async {
    final page = await document.getPage(1); // İlk sayfayı al
    // Sayfayı görüntüleyebilmek için uygun bir görüntü formatında render edin
    final pdfPageImage = await page.render(
      width: 896, // Sayfanın genişliği
      height: 1256,
    );

    await page.close(); // Sayfayı kapat

    // Render edilen resmi Uint8List olarak döndür
    return pdfPageImage!
        .bytes; // pdfPageImage.data ile doğrudan Uint8List döndürülür
  }

  Future<void> generateAndSharePdf(int islem) async {
    final pdf = pw.Document();

    // PDF Şablonunu yükleyin
    final pdfTemplate =
        await pdfx.PdfDocument.openAsset('assets/documents/sydservisformu.pdf');

    // PDF sayfasını resim olarak alın
    final pdfImageData = await pdfImageFromPdfDocument(pdfTemplate);

    // Asenkron imza işlemlerini bekle
    final seriNum = (await _buildPdfPositionedText(0.1415, 0.4, num));
    final yetkiliImza =
        await _buildPdfPositionedSignature(0.85, 0.365, yetkiliImzaController);
    final musteriImza =
        await _buildPdfPositionedSignature(0.85, 0.715, musteriImzaController);
    final adSoyad =
        await _buildPdfPositionedText(0.1825, 0.15, adSoyadController.text);
    final adSoyad2 =
        await _buildPdfPositionedText(0.797, 0.667, adSoyadController.text);
    final adres =
        await _buildPdfPositionedText(0.2575, 0.15, adresController.text);
    final telefon =
        await _buildPdfPositionedText(0.2185, 0.15, telefonController.text);
    final mail =
    await _buildPdfPositionedText(0.2385, 0.15, mailController.text);
    final yetkili =
        await _buildPdfPositionedText(0.293, 0.15, yetkiliController.text);
    final yetkili2 =
        await _buildPdfPositionedText(0.797, 0.29, yetkiliController.text);
    final islemTanim = await _buildPdfPositionedText(
        0.343, 0.05, islemKisaTanimController.text);
    final islemDetay = await _buildPdfPositionedLongText(
        0.393, 0.05, islemDetayController.text);
    final anlikTarih = await _buildPdfPositionedDate(0.1415, 0.65, tarih);

    if (pdfImageData != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // PDF şablonunu resim olarak ekleyin
                pw.Image(pw.MemoryImage(pdfImageData)),
                // Üzerine yazılacak diğer metinler
                anlikTarih,
                seriNum,
                adSoyad,
                adres,
                mail,
                telefon,
                yetkili,
                islemTanim,
                islemDetay,
                yetkili2,
                adSoyad2,
                // Checkbox işaretleri
                _buildPdfPositionedCheck(0.768, 0.235, montajChecked),
                _buildPdfPositionedCheck(0.78375, 0.235, tamirChecked),
                _buildPdfPositionedCheck(0.81525, 0.235, revizyonChecked),
                _buildPdfPositionedCheck(0.831, 0.235, projeSureciChecked),
                _buildPdfPositionedCheck(0.7995, 0.235, bakimChecked),
                _buildPdfPositionedCheck(0.85675, 0.235, odemeNakitChecked),
                _buildPdfPositionedCheck(0.8725, 0.235, odemeKartChecked),
                _buildPdfPositionedCheck(0.88825, 0.235, odemeFaturaChecked),
                _buildPdfPositionedCheck(0.904, 0.235, odemeCekChecked),

                // İmza alanlarını ekle
                yetkiliImza, // Yetkili imzası
                musteriImza, // Müşteri imzası
              ],
            );
          },
        ),
      );

      // PDF dosyasını kaydet ve paylaş
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/servisislemformu.pdf';

      if (islem == 0) {
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        saveFormToDatabase(context, filePath, adSoyadController.text, tarih,
            num); // PDF dosyasının yolunu gönderiyoruz
      } else {
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        final xFile = XFile(filePath);
        await Share.shareXFiles([xFile], text: 'Paylaşılan PDF');
      }
    } else {
      // Resim verisi alınamazsa hata mesajı gösterin
      print('PDF sayfasından resim alınamadı.');
    }
  }

  @override
  void dispose() {
    pdfController.dispose();
    yetkiliImzaController.dispose();
    musteriImzaController.dispose();
    adSoyadController.dispose();
    adresController.dispose();
    telefonController.dispose();
    yetkiliController.dispose();
    islemKisaTanimController.dispose();
    islemDetayController.dispose();
    mailController.dispose();
    super.dispose();
  }

  // Box'un genişlik ve yüksekliğini referans alarak yüzdelik pozisyon hesaplama
  Future<pw.Positioned> _buildPdfPositionedText(
      double topPercent, double leftPercent, String text) async {
    return pw.Positioned(
      top: pdfHeight * topPercent, // Yüzdelik konuma göre top
      left: pdfWidth * leftPercent, // Yüzdelik konuma göre left
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          font: pw.Font.ttf(await rootBundle.load('assets/fonts/georgia.ttf')),
          color: PdfColor(4 / 255, 11 / 255,
              71 / 255), // RGB değerlerini PdfColor'a dönüştür
        ),
      ),
    );
  }

// Uzun metin için fonksiyon
  Future<pw.Positioned> _buildPdfPositionedLongText(
      double topPercent, double leftPercent, String text) async {
    return pw.Positioned(
      top: pdfHeight * topPercent, // Yüzdelik konuma göre top
      left: pdfWidth * leftPercent, // Yüzdelik konuma göre left
      child: pw.Container(
        width: pdfWidth * 0.8, // Metin genişliği (örneğin %90)
        child: pw.Text(
          text,
          softWrap: true, // Metnin kutu dışına taşmasını engelle
          style: pw.TextStyle(
            fontSize: 10,
            font:
                pw.Font.ttf(await rootBundle.load('assets/fonts/georgia.ttf')),
            fontWeight: pw.FontWeight.bold,
            color: PdfColor(4 / 255, 11 / 255,
                71 / 255), // RGB değerlerini PdfColor'a dönüştür
          ),
        ),
      ),
    );
  }

// Tarih için fonksiyon
  Future<pw.Positioned> _buildPdfPositionedDate(
      double topPercent, double leftPercent, String text) async {
    return pw.Positioned(
      top: pdfHeight * topPercent,
      left: pdfWidth * leftPercent,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          font: pw.Font.ttf(await rootBundle.load('assets/fonts/georgia.ttf')),
          fontWeight: pw.FontWeight.bold,
          color: PdfColor(4 / 255, 11 / 255,
              71 / 255), // RGB değerlerini PdfColor'a dönüştür
        ),
      ),
    );
  }

// Check işareti için fonksiyon
  pw.Widget _buildPdfPositionedCheck(
      double topPercent, double leftPercent, bool isChecked) {
    return pw.Positioned(
      top: topPercent * pdfHeight, // yüzdelik değeri kullanarak pozisyonlama
      left: leftPercent * pdfWidth, // yüzdelik değeri kullanarak pozisyonlama
      child: pw.Container(
        width: 13, // Check işaretinin genişliği
        height: 20, // Check işaretinin yüksekliği
        child: isChecked
            ? pw.Stack(
                children: [
                  pw.Positioned(
                    top: 0, // Çizgiyi biraz yukarı kaydırmak için top değeri
                    left: 3, // Ortalamak için left değeri
                    child: pw.Transform.rotate(
                      angle:
                          0.79, // İlk çizginin rotasyon açısı (yaklaşık 45 derece)
                      child: pw.Container(
                        width: 1,
                        height: 9, // Çizginin uzunluğu
                        color: PdfColor(4 / 255, 11 / 255, 71 / 255),
                      ),
                    ),
                  ),
                  pw.Positioned(
                    top: 0,
                    left: 3,
                    child: pw.Transform.rotate(
                      angle: -0.79, // Ters rotasyon açısı (yaklaşık -45 derece)
                      child: pw.Container(
                        width: 1,
                        height: 9, // Çizginin uzunluğu
                        color: PdfColor(4 / 255, 11 / 255, 71 / 255),
                      ),
                    ),
                  ),
                ],
              )
            : pw.Container(), // Eğer işaretlenmediyse boş bırakılır
      ),
    );
  }

// İmza için fonksiyon
  // İmzayı PDF'ye eklemek için bir fonksiyon
  Future<Uint8List?> _getSignatureImageBytes(
      SignatureController controller) async {
    // İmza boşsa null döner
    if (controller.isEmpty) {
      return null;
    }

    // İmza verilerini Uint8List olarak kaydet
    final signatureImageBytes = await controller.toPngBytes();

    return signatureImageBytes;
  }

// İmzayı PDF'ye yerleştirmek için widget
  Future<pw.Widget> _buildPdfPositionedSignature(double topPercent,
      double leftPercent, SignatureController controller) async {
    // İmza verilerini al
    final signatureImageBytes = await _getSignatureImageBytes(controller);

    if (signatureImageBytes != null) {
      return pw.Positioned(
        top: pdfHeight * topPercent,
        left: pdfWidth * leftPercent,
        child: pw.Container(
          width: boxWidth * 0.1, // İmza genişliği
          height: boxHeight * 0.02, // İmza yüksekliği
          child: pw.Image(pw.MemoryImage(signatureImageBytes)), // İmzayı ekle
        ),
      );
    } else {
      // İmza yoksa boş bir alan bırak veya başka bir gösterim kullan
      return pw.Positioned(
        top: pdfHeight * topPercent,
        left: pdfWidth * leftPercent,
        child: pw.Container(
          width: boxWidth * 0.1, // İmza genişliği
          height: boxHeight * 0.02, // İmza yüksekliği
          color: PdfColors.white, // İmza alanı boşsa beyaz arka plan
        ),
      );
    }
  }

  // Pop-up ekranını açan fonksiyon
  void _showEditPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Servis Formu'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: adSoyadController,
                      decoration: const InputDecoration(
                        labelText: 'Müşteri Adı-Soyadı',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Pop-up içindeki girdileri yansıtıyoruz
                        setState(() {}); // Ana widget güncelleniyor
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    // Adres alanı
                    TextField(
                      controller: adresController,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Pop-up içindeki girdileri yansıtıyoruz
                        setState(() {}); // Ana widget güncelleniyor
                      },
                    ),
                    const SizedBox(height: 10),
                    // Telefon alanı
                    TextField(
                      controller: telefonController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Pop-up içindeki girdileri yansıtıyoruz
                        setState(() {}); // Ana widget güncelleniyor
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    // Telefon alanı
                    TextField(
                      controller: mailController,
                      decoration: const InputDecoration(
                        labelText: 'Mail',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Pop-up içindeki girdileri yansıtıyoruz
                        setState(() {}); // Ana widget güncelleniyor
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    // Yetkili alanı
                    TextField(
                      controller: yetkiliController,
                      decoration: const InputDecoration(
                        labelText: 'Yetkili',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Pop-up içindeki girdileri yansıtıyoruz
                        setState(() {}); // Ana widget güncelleniyor
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    // İşlem kısa tanım alanı
                    TextField(
                      controller: islemKisaTanimController,
                      decoration: const InputDecoration(
                        labelText: 'İşlem Kısa Tanımı',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Pop-up içindeki girdileri yansıtıyoruz
                        setState(() {}); // Ana widget güncelleniyor
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    // İşlem kısa tanım alanı
                    TextField(
                      controller: islemDetayController,
                      decoration: const InputDecoration(
                        labelText: 'İşlem Detay Kısmı',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null, // Alt satıra geçmesine izin verir
                      minLines: 3,    // Başlangıçta görünmesini istediğiniz en az satır sayısı
                      onChanged: (value) {
                        // Pop-up içindeki girdileri yansıtıyoruz
                        setState(() {}); // Ana widget güncelleniyor
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    // İşlem seçenekleri (Checkbox'lar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                      crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortalama
                      children: [
                        const Text('Montaj'),
                        Checkbox(
                          value: montajChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              montajChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                        const Text('Arıza'),
                        Checkbox(
                          value: tamirChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              tamirChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                        const Text('Bakım'),
                        Checkbox(
                          value: bakimChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              bakimChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                      crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortalama
                      children: [
                        const Text(
                          'Revizyon',
                          style: TextStyle(
                            fontSize:
                                12, // Burada font büyüklüğünü belirliyorsunuz
                          ),
                        ),
                        Checkbox(
                          value: revizyonChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              revizyonChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                        const Text(
                          'Proje S.',
                          style: TextStyle(
                            fontSize:
                                12, // Burada font büyüklüğünü belirliyorsunuz
                          ),
                        ),
                        Checkbox(
                          value: projeSureciChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              projeSureciChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Ödeme Şekli:'),
                    // Ödeme seçenekleri (Checkbox'lar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                      crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortalama
                      children: [
                        const Text('Nakit'),
                        Checkbox(
                          value: odemeNakitChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              odemeNakitChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                        const Text('Kart'),
                        Checkbox(
                          value: odemeKartChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              odemeKartChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                      crossAxisAlignment: CrossAxisAlignment.center, // Dikeyde ortalama
                      children: [
                        const Text('Fatura'),
                        Checkbox(
                          value: odemeFaturaChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              odemeFaturaChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                        const Text('Çek'),
                        Checkbox(
                          value: odemeCekChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              odemeCekChecked = value ?? false;
                            });
                            setStateDialog(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Yetkili imza alanı
                    const Text('Yetkili İmza:', style: TextStyle(fontSize: 16)),
                    SizedBox(
                      width: 250,
                      height: 125,
                      child: Stack(
                        children: [
                          Signature(
                            controller: yetkiliImzaController,
                            backgroundColor: Colors.grey[200]!,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.cleaning_services_rounded),
                              onPressed: () {
                                setState(() {
                                  yetkiliImzaController
                                      .clear(); // Yetkili İmza Alanını Temizle
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Müşteri İmza:', style: TextStyle(fontSize: 16)),
                    SizedBox(
                      width: 250,
                      height: 125,
                      child: Stack(
                        children: [
                          Signature(
                            controller: musteriImzaController,
                            backgroundColor: Colors.grey[200]!,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.cleaning_services_rounded),
                              onPressed: () {
                                setState(() {
                                  musteriImzaController
                                      .clear(); // Müşteri İmza Alanını Temizle
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Pop-up'ı kapat
                  },
                  child: const Text('Kapat',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Georgia',
                      color: Color(0xFF040B47),
                      fontWeight: FontWeight.w600,
                    ),),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {}); // Değerleri ekrana yansıt
                    Navigator.of(context).pop(); // Pop-up'ı kapat
                    final form = FormModel2(
                      adSoyad: adSoyadController.text,
                      mail: mailController.text,
                      telefon: telefonController.text,
                      adres: adresController.text,
                    );

                    saveFormData(form).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Form başarıyla kaydedildi!')),
                      );
                    });
                  },
                  child: const Text('Kaydet',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Georgia',
                      color: Color(0xFF040B47),
                      fontWeight: FontWeight.w600,
                    ),),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void saveFormToDatabase(BuildContext context, String pdfFilePath, String musteriAdSoyad, String tarih, String num) async {
    final dbHelper = DatabaseHelper();

    // Müşteri klasörünü oluştur
    final directory = await getApplicationDocumentsDirectory();
    final customerFolder = Directory('${directory.path}/$musteriAdSoyad');

    // Eğer klasör yoksa oluştur
    if (!(await customerFolder.exists())) {
      await customerFolder.create();
    }

    // PDF dosyasını yeni müşteri klasörüne taşı
    final newFilePath = '${customerFolder.path}/$num.pdf';
    final file = File(pdfFilePath);
    await file.copy(newFilePath);

    // FormModel nesnesi oluştur ve yeni dosya yolunu kaydet
    FormModel form = FormModel(
      num: num,
      pdfFilePath: newFilePath,
      musteriAdSoyad: musteriAdSoyad,
      tarih: tarih,
    );

    // Formu veritabanına kaydet
    await dbHelper.insertForm(form);

    // SnackBar ile mesaj göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF dosyası başarıyla ${musteriAdSoyad} klasörüne kaydedildi.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: boxWidth,
              height: boxHeight,
              child: Stack(
                children: [
                  pdfx.PdfView(
                    controller: pdfController,
                  ),
                  Positioned(
                    top: boxHeight * 0.193,
                    left: boxWidth * 0.15,
                    child: Text(
                      adSoyadController.text,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: boxHeight * 0.273,
                    left: boxWidth * 0.15,
                    child: Text(
                      adresController.text,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: boxHeight * 0.252,
                    left: boxWidth * 0.15,
                    child: Text(
                      mailController.text,
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: boxHeight * 0.231,
                    left: boxWidth * 0.15,
                    child: Text(
                      telefonController.text,
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: boxHeight * 0.307,
                    left: boxWidth * 0.15,
                    child: Text(
                      yetkiliController.text,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: boxHeight * 0.357,
                    left: boxWidth * 0.05,
                    child: Text(
                      islemKisaTanimController.text,
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              Positioned(
                top: boxHeight * 0.409,
                left: boxWidth * 0.05, // Genel left değeri
                child: SizedBox(
                  width: boxWidth * 0.8,
                    child: Text(
                      islemDetayController.text,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
              ),
                  Positioned(
                    top: boxHeight * 0.81,
                    left: boxWidth * 0.3,
                    child: Text(
                      yetkiliController.text,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: boxHeight * 0.81,
                    left: boxWidth * 0.687,
                    child: Text(
                      adSoyadController.text,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontFamily: 'Georgia',
                        color: Color(0xFF040B47),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Checkbox işaretleri
                  Positioned(
                    top: boxHeight * 0.78, // Yüzdelik konuma göre top
                    left: boxWidth * 0.2375, // Yüzdelik konuma göre left
                    child: montajChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.8105, // Yüzdelik konuma göre top
                    left: boxWidth * 0.2375, // Yüzdelik konuma göre left
                    child: bakimChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.79525,
                    left: boxWidth * 0.2375,
                    child: tamirChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.8275,
                    left: boxWidth * 0.2375,
                    child: revizyonChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.8421,
                    left: boxWidth * 0.2375,
                    child: projeSureciChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.8675,
                    left: boxWidth * 0.2357,
                    child: odemeNakitChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.8835,
                    left: boxWidth * 0.2357,
                    child: odemeFaturaChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.899,
                    left: boxWidth * 0.2357,
                    child: odemeCekChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.91425,
                    left: boxWidth * 0.2357,
                    child: odemeKartChecked
                        ? const Icon(
                            Icons.clear,
                            size: 11,
                            color: Color(0xFF040B47), // Tick işareti için renk
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: boxHeight * 0.85, // Yüzdelik konuma göre top
                    left: boxWidth * 0.3, // Yüzdelik konuma göre left
                    child: Container(
                      width: boxWidth * 0.125, // İmza alanının genişliği
                      height: boxHeight * 0.025, // İmza alanının yüksekliği
                      decoration: BoxDecoration(
                        color: Colors.white, // Arkaplan rengi
                      ),
                      child: Transform.scale(
                        scale: 0.27, // Çizim boyutunu %50 küçültmek için
                        child: Signature(
                          controller: yetkiliImzaController,
                          backgroundColor: Colors.transparent, // Arkaplan rengi
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: boxHeight * 0.85, // Yüzdelik konuma göre top
                    left: boxWidth * 0.665, // Yüzdelik konuma göre left
                    child: Container(
                      width: boxWidth * 0.125, // İmza alanının genişliği
                      height: boxHeight * 0.025, // İmza alanının yüksekliği
                      decoration: BoxDecoration(
                        color: Colors.white, // Arkaplan rengi
                      ),
                      child: Transform.scale(
                        scale: 0.27, // Çizim boyutunu %50 küçültmek için
                        child: Signature(
                          controller: musteriImzaController,
                          backgroundColor: Colors.transparent, // Arkaplan rengi
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () async => await generateAndSharePdf(
                      0), // Formu veritabanına kaydetme fonksiyonu
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.save),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: () {
                    _showEditPopup(context); // Pop-up'ı aç
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.edit),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: () async =>
                      await generateAndSharePdf(1), // PDF oluştur ve paylaş
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.share),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
