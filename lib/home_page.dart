import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'platform_service_android.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _batteryLevel = 'Unknown';
  Map<String, dynamic> _deviceInfo = {};
  double _accelerometerX = 0;
  double _accelerometerY = 0;
  double _accelerometerZ = 0;
  bool _isAccelerometerRunning = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    PlatformService.setAccelerometerCallback((x, y, z) {
      setState(() {
        _accelerometerX = x;
        _accelerometerY = y;
        _accelerometerZ = z;
      });
    });
  }

  Future<void> _requestNotificationPermission() async {
    await Permission.notification.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform API Example'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildInfoCard('Battery Level', _batteryLevel, _getBatteryLevel),
              _buildInfoCard('Device Info', _deviceInfo.toString(), _getDeviceInfo),
              _buildAccelerometerCard(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showToast,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Show Toast'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showNotification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Show Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(content),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2)),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
              ),
              child: Text('Get $title'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccelerometerCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accelerometer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: AccelerometerPainter(_accelerometerX, _accelerometerY, _accelerometerZ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('X: ${_accelerometerX.toStringAsFixed(2)}'),
                      Text('Y: ${_accelerometerY.toStringAsFixed(2)}'),
                      Text('Z: ${_accelerometerZ.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleAccelerometer,
              style: ElevatedButton.styleFrom(
                shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(2)),
                backgroundColor: _isAccelerometerRunning ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
              ),
              child: Text(_isAccelerometerRunning ? 'Stop Accelerometer' : 'Start Accelerometer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAccelerometer() async {
    if (_isAccelerometerRunning) {
      await PlatformService.stopAccelerometer();
      setState(() {
        _isAccelerometerRunning = false;
        _accelerometerX = 0;
        _accelerometerY = 0;
        _accelerometerZ = 0;
      });
    } else {
      await PlatformService.startAccelerometer();
      setState(() {
        _isAccelerometerRunning = true;
      });
    }
  }

  Future<void> _getBatteryLevel() async {
    String batteryLevel = await PlatformService.getBatteryLevel();
    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  Future<void> _showToast() async {
    await PlatformService.showToast('Hello from Flutter!');
  }

  Future<void> _getDeviceInfo() async {
    try {
      Map<String, dynamic> deviceInfo = await PlatformService.getDeviceInfo();
      setState(() {
        _deviceInfo = deviceInfo;
      });
    } catch (e) {
      debugPrint("Error getting device info: $e");
      setState(() {
        _deviceInfo = {"error": "Failed to get device info"};
      });
    }
  }

  Future<void> _showNotification() async {
    debugPrint("Attempting to show notification");
    if (await Permission.notification.isGranted) {
      await PlatformService.showNotification('Flutter Notification', 'This is a test notification from Flutter!');
      debugPrint("Notification should have been shown");
    } else {
      if (Platform.isAndroid) {
        if (await Permission.notification.status.isDenied) {
          await Permission.notification.request();
        }
      }
    }
  }
}

class AccelerometerPainter extends CustomPainter {
  final double x, y, z;

  AccelerometerPainter(this.x, this.y, this.z);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 3;

    canvas.drawCircle(center, radius, Paint()..color = Colors.grey.shade200);

    final dotX = center.dx + (x / 10 * radius);
    final dotY = center.dy - (y / 10 * radius);
    final dotRadius = (z.abs() / 10 * radius / 3) + 5;

    canvas.drawCircle(Offset(dotX, dotY), dotRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
