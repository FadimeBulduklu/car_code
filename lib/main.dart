import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arduino Bluetooth Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothConnection? connection;

  // Butonların genişlik ve yükseklik değerleri için varsayılan değerler
  double defaultButtonWidth = 150.0;
  double defaultButtonHeight = 70.0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arduino Bluetooth Control'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  controlButton('Forward', 'F'),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  controlButton('Left', 'L'),
                  controlButton('Stop', 'S'),
                  controlButton('Right', 'R'),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  controlButton('Backward', 'B'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final BluetoothDevice? selectedDevice = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SelectBondedDevicePage(
                checkAvailability: false,
              ),
            ),
          );
          if (selectedDevice != null) {
            _connect(selectedDevice);
          }
        },
        child: Icon(Icons.bluetooth),
      ),
    );
  }

  Widget controlButton(String text, String command) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: () {
              _animateButton(); // Butona tıklandığında animasyonu başlat
              if (connection != null && connection!.isConnected) {
                connection!.output.add(Uint8List.fromList(utf8.encode(command + "\r\n")));
              }
            },
            child: Text(
              text,
              style: TextStyle(fontSize: 20.0),
            ),
          ),
        ),
      ),
    );
  }


  // Buton tıklama animasyonu
  void _animateButton() {
    setState(() {
      // Butonun boyutunu geçici olarak büyütün
      defaultButtonWidth = 170.0;
      defaultButtonHeight = 80.0;
    });
    // Bir süre sonra buton boyutunu tekrar eski haline getirin
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        // Butonun boyutunu orijinal boyutuna geri döndürün
        defaultButtonWidth = 150.0;
        defaultButtonHeight = 70.0;
      });
    });
  }

  void _connect(BluetoothDevice device) async {
    if (connection != null) {
      await connection!.close();
    }
    BluetoothConnection.toAddress(device.address).then((_connection) {
      setState(() {
        connection = _connection;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    connection?.dispose();
  }
}

class SelectBondedDevicePage extends StatelessWidget {
  final bool checkAvailability;
  final BluetoothDevice? connectedDevice;

  SelectBondedDevicePage({
    required this.checkAvailability,
    this.connectedDevice,
  });

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Bonded Device'),
      ),
      body: FutureBuilder<void>(
        future: _requestPermissions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return FutureBuilder<List<BluetoothDevice>>(
              future: FlutterBluetoothSerial.instance.getBondedDevices(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<BluetoothDevice> devices = snapshot.data!;
                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final isConnected = device == connectedDevice;
                      return ListTile(
                        title: Text(device.name ?? 'Unknown'),
                        subtitle: Text(device.address),
                        trailing: isConnected ? Icon(Icons.check, color: Colors.green) : null,
                        onTap: () {
                          Navigator.of(context).pop(device);
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
