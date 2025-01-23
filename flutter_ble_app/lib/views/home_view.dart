import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_app/consts/consts.dart';
import 'package:flutter_ble_app/model/data_model.dart';
import 'package:flutter_ble_app/views/scan_view.dart';
import 'package:flutter_ble_app/widgets/connection_info_widget.dart';
import 'package:flutter_ble_app/widgets/title_widget.dart';
import 'package:flutter_ble_app/widgets/sensor_data_widget.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.dhtCharacteristic,
  });

  final BluetoothCharacteristic dhtCharacteristic;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late ReceivedDataModel _dataModel;
  late BluetoothCharacteristic _dhtCharacteristic;
  bool _isAppInForeground = true; // Track app's lifecycle state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register for lifecycle events
    requestPermission();
    _dhtCharacteristic = widget.dhtCharacteristic;
    _dataModel = ReceivedDataModel(
      bloodSugar: 40,
    );
    //_listenBleData();
    
    _connectToDeviceAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Unregister lifecycle events
    if (_dhtCharacteristic.device.isConnected) {
      _dhtCharacteristic.device.disconnect();
    }
    super.dispose();
  }

  // App lifecycle changes: foreground or background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isAppInForeground = true;
      });
    } else if (state == AppLifecycleState.paused) {
      setState(() {
        _isAppInForeground = false;
      });
    }
  }

  Future<void> _connectToDeviceAndInitialize() async {
    // Connect to the Bluetooth device
    await _dhtCharacteristic.device.connect();

    // Start listening for Bluetooth data and triggering notifications based on thresholds
    _listenBleData();
    
    // Once the device is connected, initialize notifications
    initializeNotifications();

  }

  Future _sendBleData(SendDataModel dataModel) async {
    if (_dhtCharacteristic.device.isConnected) {
      await _dhtCharacteristic
          .write(utf8.encode(jsonEncode(dataModel.toJson())));
    }
  }

  void _listenBleData() async {
    await _dhtCharacteristic.setNotifyValue(true);
    _dhtCharacteristic.lastValueStream.listen(
          (value) {
        if (mounted) {
          setState(() {
            var decode = utf8.decode(value);
            _dataModel = ReceivedDataModel.fromJson(jsonDecode(decode));

            // Check blood sugar level and trigger notifications
            if (_dataModel.bloodSugar > 140 && !_isAppInForeground) {
              showNotification(
                'High Blood Sugar!',
                '${_dataModel.bloodSugar} mg/dL. Your blood sugar level is too high.',
              );
            } else if (_dataModel.bloodSugar < 65 && !_isAppInForeground) {
              showNotification(
                'Low Blood Sugar!',
                '${_dataModel.bloodSugar} mg/dL. Your blood sugar level is dangerously low. ',
              );
            }

          });
        }
      },
    ).onError((err) {
      if (kDebugMode) print(err);
    });
  }
  Future<void> showNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

// Set up the notification channel for Android
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'com.example.flutter_ble_app.blood_sugar_alerts_channel', // Unique channel ID
    'Blood Sugar Alerts', // Channel name
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
    largeIcon: DrawableResourceAndroidBitmap('kulucose_logo_cropped'),
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    title, // Title
    body, // Body message
    platformDetails,
  );
}

Future<void> initializeNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: AndroidInitializationSettings('kulucose_logo_cropped'), // Android-only setup
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create the notification channel for Android 8.0 and above
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'com.example.flutter_ble_app.blood_sugar_alerts_channel', // Unique channel ID
    'Blood Sugar Alerts', // Channel name
    description: 'This channel is used for blood sugar level notifications.',
    importance: Importance.high, // Set importance
  );

  // Register the channel with the system
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void requestPermission() async {
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print("Notification permission granted");
  } else {
    print("Notification permission denied");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: [
          const Gap(homeSizedHeight),
          const TitleWidget(title: 'KUlucoseTrack', isTitle: true),
          const Gap(homeSizedHeight),
          const TitleWidget(title: 'Connection Status', isTitle: false),
          ConnectionInfoWidget(
            isConnected: _dhtCharacteristic.device.isConnected,
            infoText: _dhtCharacteristic.device.isConnected
                ? 'Connected to ${_dhtCharacteristic.device.platformName}'
                : 'Disconnected',
            changeStatus: (p0) async {
              await _dhtCharacteristic.device.disconnect();
              setState(() {});
              Fluttertoast.showToast(
                msg: '${_dhtCharacteristic.device.platformName} disconnected',
              );
              Future.delayed(const Duration(milliseconds: 1500)).then(
                    (value) => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanPage()),
                ),
              );
            },
          ),
          const Gap(vPadding),
          const TitleWidget(title: 'Sensor Data', isTitle: false),
          Center(
            child: SensorDataWidget(
              title: 'Blood Sugar',
              info: '${_dataModel.bloodSugar.toStringAsFixed(1)} mg/dL',
              iconData: Icons.favorite_outlined,
              color: Colors.red,
            )
            ),
            // Add SensorDataWidget for high/low blood sugar levels
          (_dataModel.bloodSugar > 140 || _dataModel.bloodSugar < 65)
              ? SensorDataWidget(
                    title: _dataModel.bloodSugar > 140
                        ? "Blood sugar is too high!"
                        : "Blood sugar is too low!",
                    info: "", // You can leave the info blank if unnecessary
                    iconData: Icons.warning_amber_outlined,
                    color: Colors.red,
                  )
                
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}