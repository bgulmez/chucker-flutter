import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';

class LoggerTestPage extends StatelessWidget {
  const LoggerTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logger Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aşağıdaki butonlara basarak Chucker\'a log gönderin ve ardından Chucker ekranını açıp Logs sekmesini kontrol edin.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ChuckerFlutter.info('Kullanıcı giriş ekranı açıldı.'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Send Info Log'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ChuckerFlutter.debug('Lokal veri tabanı senkronizasyonu başlatılıyor...'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Send Debug Log'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ChuckerFlutter.warning('Kullanıcı lokasyon izni vermedi!'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text('Send Warning Log'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ChuckerFlutter.error('Veriler çekilirken bir hata oluştu!'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Send Error Log'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => ChuckerFlutter.showChuckerScreen(),
              icon: const Icon(Icons.search),
              label: const Text('Open Chucker Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
