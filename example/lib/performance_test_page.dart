import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PerformanceTestPage extends StatefulWidget {
  const PerformanceTestPage({super.key});

  @override
  State<PerformanceTestPage> createState() => _PerformanceTestPageState();
}

class _PerformanceTestPageState extends State<PerformanceTestPage> {
  final _dio = Dio();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(ChuckerDioInterceptor());
  }

  Future<void> _makeRequest() async {
    setState(() => _loading = true);
    try {
      await _dio.get('https://jsonplaceholder.typicode.com/posts');
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _makeRequest,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Make List Request'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click the Bolt icon (FAB) for Stress Test (50 requests).\nWatch the shimmer stability.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Skeletonizer(
                enabled: true,
                effect: ShimmerEffect(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.blue[400]!, // Daha belirgin bir mavi shimmer
                  duration: const Duration(milliseconds: 1000),
                ),
                child: ListView.builder(
                  itemCount: 15, // Daha fazla item ile kaydırmayı da test edebilirsin
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey,
                        ),
                        title: Text(
                          'Stress Testing Chucker Performance $index',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'If this blue highlight moves smoothly while notifications pop up, the fix is working!',
                        ),
                        trailing: const Icon(Icons.bolt, color: Colors.amber),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Stress test: 50 requests at once
          for (int i = 1; i <= 50; i++) {
            _dio.get('https://jsonplaceholder.typicode.com/posts/$i').catchError((e) {
              debugPrint('Caught expected error for request $i');
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('50 requests triggered! Watch the blue shimmer...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.bolt, color: Colors.white),
      ),
    );
  }
}
