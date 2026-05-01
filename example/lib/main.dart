import 'dart:convert';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:example/chopper/chopper_service.dart';
import 'package:example/logger_test_page.dart';
import 'package:example/performance_test_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  ChuckerFlutter.configure(
    showOnRelease: true,
    showNotification: true,
    notificationAlignment: Alignment.topCenter,
    offsetBegin: const Offset(0, -0.1),
    offsetEnd: Offset.zero,
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [ChuckerFlutter.navigatorObserver],
      theme: ThemeData(
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF13B9FF)),
        colorScheme: ColorScheme.fromSwatch(
          accentColor: const Color(0xFF13B9FF),
        ),
      ),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _baseUrl = 'https://jsonplaceholder.typicode.com';
  var _clientType = _Client.dio;

  late final _dio = Dio(
    BaseOptions(
        sendTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*',
        }),
  );

  final _chuckerHttpClient = ChuckerHttpClient(http.Client());

  final _chopperApiService = ChopperApiService.create();

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(ChuckerDioInterceptor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chucker Flutter Example'),
        actions: [
          IconButton(
            tooltip: 'Logger Test',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoggerTestPage()),
            ),
            icon: const Icon(Icons.logo_dev),
          ),
          IconButton(
            tooltip: 'Performance Test',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerformanceTestPage()),
            ),
            icon: const Icon(Icons.speed),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChuckerFlutter.chuckerButton,
            const SizedBox(height: 20),
            const Text('Click the icons in AppBar to test features'),
          ],
        ),
      ),
    );
  }
}

enum _Client {
  dio,
  http,
  chopper,
}
