import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter test background Isolate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

const platform = MethodChannel('samples.flutter.dev/battery');

Future<void> getBatteryLevel(List<Object> args) async {
  String batteryLevel;
  final rootIsolateToken = args[0] as RootIsolateToken;
  final sendPort = args[1] as SendPort;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  try {
    final result = await platform.invokeMethod<int>('getBatteryLevel');
    batteryLevel = 'Battery level at $result % .';
    sendPort.send(batteryLevel);
  } on PlatformException catch (e) {
    batteryLevel = "Failed to get battery level: '${e.message}'.";
  } finally {
    Isolate.current.kill();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final rootIsolateToken = RootIsolateToken.instance!;

  _MyHomePageState();

  String _batteryLevel = 'Unknown battery level';

  // run background Isolate for connect with native code
  Future<void> isolateSpawn() async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(getBatteryLevel, [
      rootIsolateToken,
      receivePort.sendPort,
    ]);
    receivePort.listen((message) {
      setState(() {
        _batteryLevel = message;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          const Spacer(flex: 3),
          ElevatedButton(
            onPressed: isolateSpawn,
            child: const Text('Get Battery Level'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _batteryLevel = 'Reset battery level';
              });
            },
            child: const Text('Reset'),
          ),
          const Spacer(),
          Text(_batteryLevel),
          const Spacer(flex: 5),
        ],
      ),
    );
  }
}
