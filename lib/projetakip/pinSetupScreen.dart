import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bakiyeKontrolSayfasi.dart';

class PinSetupScreen extends StatefulWidget {
  @override
  _PinSetupScreenState createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _currentPinController = TextEditingController();
  String? _errorText;
  String? _successText;
  int _attempts = 0;
  DateTime? _lockoutEndTime;

  Future<String?> _getSavedPin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPin');
  }

  Future<void> _savePin(String pin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPin', pin);
  }

  void _setPin() async {
    if (_pinController.text == _confirmPinController.text &&
        _pinController.text.isNotEmpty) {
      await _savePin(_pinController.text);
      setState(() {
        _successText = "PIN başarıyla kaydedildi.";
        _errorText = null;
      });

      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorText = "PIN'ler eşleşmiyor veya boş olamaz.";
        _successText = null;
      });
    }
  }

  Future<void> _incrementAttempts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _attempts++;
    await prefs.setInt('attempts', _attempts);

    if (_attempts >= 5) {
      _lockoutEndTime = DateTime.now().add(const Duration(minutes: 5));
      await prefs.setString('lockoutEndTime', _lockoutEndTime!.toIso8601String());
    }
  }

  Future<void> _resetAttempts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _attempts = 0;
    await prefs.setInt('attempts', _attempts);
    await prefs.remove('lockoutEndTime');
  }

  Future<void> _loadAttempts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _attempts = prefs.getInt('attempts') ?? 0;

    String? lockoutTimeString = prefs.getString('lockoutEndTime');
    if (lockoutTimeString != null) {
      _lockoutEndTime = DateTime.tryParse(lockoutTimeString);
      if (_lockoutEndTime != null && _lockoutEndTime!.isBefore(DateTime.now())) {
        await _resetAttempts();
      }
    }
  }

  void _validatePin() async {
    await _loadAttempts();
    if (_lockoutEndTime != null && _lockoutEndTime!.isAfter(DateTime.now())) {
      setState(() {
        _errorText = "Çok fazla yanlış deneme yaptınız. Lütfen 5 dakika bekleyin.";
      });
      return;
    }

    final savedPin = await _getSavedPin();
    if (_currentPinController.text == savedPin) {
      await _resetAttempts();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BakiyeKontrolSayfasi()),
      );
    } else {
      await _incrementAttempts();
      setState(() {
        _errorText = "PIN yanlış. $_attempts/5 deneme yaptınız.";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getSavedPin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final savedPin = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text("PIN Girişi"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (savedPin == null) ...[
                  const Text(
                    "PIN belirleme ekranı",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "PIN",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "PIN Tekrar",
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _setPin,
                    child: const Text("PIN Belirle"),
                  ),
                ] else ...[
                  const Text(
                    "PIN doğrulama ekranı",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _currentPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "PIN",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _validatePin,
                    child: const Text("Sayfaya Gir"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BakiyeKontrolSayfasi()),
                      );
                    },
                    child: const Text("PIN Değiştir"),
                  ),
                ],
                if (_errorText != null)
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                if (_successText != null)
                  Text(
                    _successText!,
                    style: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
