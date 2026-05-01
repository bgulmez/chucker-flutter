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
  )..interceptors.add(ChuckerDioInterceptor());

  final _chuckerHttpClient = ChuckerHttpClient(http.Client());
  final _chopperApiService = ChopperApiService.create();

  Future<void> _handleRequest(Future<dynamic> request) async {
    try {
      await request;
    } catch (e) {
      // Hataları burada yakalıyoruz ki uygulama kırılmasın.
      // ChuckerInterceptor zaten kendi içinde hatayı yakalayıp kaydediyor.
      debugPrint('Chucker Example Error: $e');
    }
  }

  Future<void> get({bool error = false}) async {
    final path = '/post${error ? 'temp' : ''}s/1';
    switch (_clientType) {
      case _Client.dio:
        await _handleRequest(_dio.get('$_baseUrl$path'));
        break;
      case _Client.http:
        await _handleRequest(_chuckerHttpClient.get(Uri.parse('$_baseUrl$path')));
        break;
      case _Client.chopper:
        await _handleRequest(error ? _chopperApiService.getError() : _chopperApiService.get());
        break;
    }
  }

  Future<void> getWithParam() async {
    const path = '/posts';
    switch (_clientType) {
      case _Client.dio:
        await _handleRequest(_dio.get('$_baseUrl$path', queryParameters: {'userId': '1'}));
        break;
      case _Client.http:
        await _handleRequest(_chuckerHttpClient.get(Uri.parse('$_baseUrl$path?userId=1')));
        break;
      case _Client.chopper:
        await _handleRequest(_chopperApiService.getWithParams());
        break;
    }
  }

  Future<void> post() async {
    const path = '/posts';
    final request = {'title': 'foo', 'body': 'bar', 'userId': '101010'};
    switch (_clientType) {
      case _Client.dio:
        await _handleRequest(_dio.post('$_baseUrl$path', data: request));
        break;
      case _Client.http:
        await _handleRequest(_chuckerHttpClient.post(Uri.parse('$_baseUrl$path'), body: jsonEncode(request)));
        break;
      case _Client.chopper:
        await _handleRequest(_chopperApiService.post(request));
        break;
    }
  }

  Future<void> put() async {
    const path = '/posts/1';
    final request = {'title': 'PUT foo', 'body': 'PUT bar', 'userId': '101010'};
    switch (_clientType) {
      case _Client.dio:
        await _handleRequest(_dio.put('$_baseUrl$path', data: request));
        break;
      case _Client.http:
        await _handleRequest(_chuckerHttpClient.put(Uri.parse('$_baseUrl$path'), body: request));
        break;
      case _Client.chopper:
        await _handleRequest(_chopperApiService.put(request));
        break;
    }
  }

  Future<void> delete() async {
    const path = '/posts/1';
    switch (_clientType) {
      case _Client.dio:
        await _handleRequest(_dio.delete('$_baseUrl$path'));
        break;
      case _Client.http:
        await _handleRequest(_chuckerHttpClient.delete(Uri.parse('$_baseUrl$path')));
        break;
      case _Client.chopper:
        await _handleRequest(_chopperApiService.delete());
        break;
    }
  }

  Future<void> patch() async {
    const path = '/posts/1';
    final request = {'title': 'PATCH foo'};
    switch (_clientType) {
      case _Client.dio:
        await _handleRequest(_dio.patch('$_baseUrl$path', data: request));
        break;
      case _Client.http:
        await _handleRequest(_chuckerHttpClient.patch(Uri.parse('$_baseUrl$path'), body: request));
        break;
      case _Client.chopper:
        await _handleRequest(_chopperApiService.patch(request));
        break;
    }
  }

  Future<void> uploadImage() async {
    try {
      final formData = FormData.fromMap({
        "key": "6d207e02198a847aa98d0a2a901485a5",
        "source": await MultipartFile.fromFile('assets/logo.png'),
      });
      await _handleRequest(_dio.post('https://freeimage.host/api/1/upload', data: formData));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chucker Flutter Example'),
        actions: [
          IconButton(
            tooltip: 'Logger Test',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoggerTestPage())),
            icon: const Icon(Icons.logo_dev),
          ),
          IconButton(
            tooltip: 'Performance Test',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceTestPage())),
            icon: const Icon(Icons.speed),
          )
        ],
      ),
      persistentFooterButtons: [
        Text('Using ${_clientType.name.toUpperCase()}'),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _clientType = _Client.values[(_clientType.index + 1) % _Client.values.length];
            });
          },
          child: const Text('Switch Client'),
        )
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChuckerFlutter.chuckerButton,
            const SizedBox(height: 16),
            ElevatedButton(onPressed: get, child: const Text('GET')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: getWithParam, child: const Text('GET WITH PARAMS')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: post, child: const Text('POST')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: put, child: const Text('PUT')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: delete, child: const Text('DELETE')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: patch, child: const Text('PATCH')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => get(error: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('ERROR (404 Test)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: uploadImage, child: const Text('UPLOAD IMAGE')),
            const SizedBox(height: 16),
            Image.asset('assets/logo.png', height: 100),
          ],
        ),
      ),
    );
  }
}

enum _Client { dio, http, chopper }
