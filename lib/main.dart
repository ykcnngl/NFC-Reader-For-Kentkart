import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'dart:typed_data';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NfcReaderApp());
}

class NfcReaderApp extends StatelessWidget {
  const NfcReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NFC Reader Sistemi',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const ReaderScreen(),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  String _durumMesaji = "Okuyucu Beklemede";
  Color _durumRengi = Colors.grey;
  bool _dinleniyor = false;

  void _okumayiBaslat() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        _durumMesaji = "HATA: Cihazda NFC Kapalı veya Yok!";
        _durumRengi = Colors.redAccent;
      });
      return;
    }

    setState(() {
      _dinleniyor = true;
      _durumMesaji = "SİSTEM AKTİF\nLütfen Kartınızı Yaklaştırın...";
      _durumRengi = Colors.blueAccent;
    });


    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        IsoDep? isoDep = IsoDep.from(tag);

        if (isoDep == null) {
          _sonucuGoster("GEÇERSİZ KART TİPİ", Colors.orange);
          NfcManager.instance.stopSession();
          return;
        }

        try {
          Uint8List apduCommand = Uint8List.fromList(
              [0x00, 0xA4, 0x04, 0x00, 0x05, 0xF2, 0x22, 0x22, 0x22, 0x22]);

          Uint8List response = await isoDep.transceive(data: apduCommand);
          String hexResponse = response
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(' ')
              .toUpperCase();

          if (hexResponse.endsWith("90 00")) {
            _sonucuGoster("GEÇİŞ ONAYLANDI\nİyi Yolculuklar", Colors.green);
          } else {
            _sonucuGoster("REDDEDİLDİ\nHata Kodu: $hexResponse", Colors.red);
          }
        } catch (e) {
          _sonucuGoster("OKUMA HATASI\nTekrar Deneyin", Colors.red);
        } finally {
          NfcManager.instance.stopSession();
          setState(() => _dinleniyor = false);
        }
      },
    );
  }

  void _sonucuGoster(String mesaj, Color renk) {
    setState(() {
      _durumMesaji = mesaj;
      _durumRengi = renk;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_dinleniyor) {
        setState(() {
          _durumMesaji = "Okuyucu Beklemede";
          _durumRengi = Colors.grey;
        });
      }
    });
  }

  void _okumayiDurdur() {
    NfcManager.instance.stopSession();
    setState(() {
      _dinleniyor = false;
      _durumMesaji = "Okuyucu Kapatıldı";
      _durumRengi = Colors.grey;
    });
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Gişe / Okuyucu Modülü'),
        centerTitle: true,
        backgroundColor: Colors.black45,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _durumRengi.withValues(alpha: 0.2),
                  border: Border.all(color: _durumRengi, width: 4),
                ),
                child: Icon(
                  Icons.nfc,
                  size: 120,
                  color: _durumRengi,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _durumMesaji,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _durumRengi,
                ),
              ),
              const SizedBox(height: 50),
              _dinleniyor
                  ? ElevatedButton.icon(
                onPressed: _okumayiDurdur,
                icon: const Icon(Icons.stop),
                label: const Text("Dinlemeyi Durdur"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              )
                  : ElevatedButton.icon(
                onPressed: _okumayiBaslat,
                icon: const Icon(Icons.play_arrow),
                label: const Text("Sistemi Aktifleştir"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}