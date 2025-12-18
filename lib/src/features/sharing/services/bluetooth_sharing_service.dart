import 'dart:convert';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for Bluetooth sharing of notes
class BluetoothSharingService {
  static const String serviceUuid = '0000180a-0000-1000-8000-00805f9b34fb';
  static const String characteristicUuid = '00002a29-0000-1000-8000-00805f9b34fb';
  
  static StreamSubscription? _scanSubscription;
  static final List<BluetoothDevice> _discoveredDevices = [];
  
  /// Request Bluetooth permissions
  static Future<bool> requestPermissions() async {
    if (await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      return true;
    }
    
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    return statuses.values.every((status) => status.isGranted);
  }
  
  /// Check if Bluetooth is available
  static Future<bool> isBluetoothAvailable() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }
  
  /// Turn on Bluetooth
  static Future<void> turnOnBluetooth() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      print('Error turning on Bluetooth: $e');
    }
  }
  
  /// Scan for nearby devices
  static Future<List<BluetoothDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!await requestPermissions()) {
      throw Exception('Bluetooth permissions not granted');
    }
    
    if (!await isBluetoothAvailable()) {
      throw Exception('Bluetooth is not available');
    }
    
    _discoveredDevices.clear();
    
    // Listen to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (!_discoveredDevices.contains(result.device)) {
          _discoveredDevices.add(result.device);
        }
      }
    });
    
    // Start scanning
    await FlutterBluePlus.startScan(timeout: timeout);
    
    // Wait for scan to complete
    await Future.delayed(timeout);
    
    // Stop scanning
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    
    return _discoveredDevices;
  }
  
  /// Send note to device
  static Future<bool> sendNote(
    BluetoothDevice device,
    Map<String, dynamic> noteData,
  ) async {
    try {
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));
      
      // Discover services
      final services = await device.discoverServices();
      
      // Find the characteristic to write to
      BluetoothCharacteristic? targetCharacteristic;
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            targetCharacteristic = characteristic;
            break;
          }
        }
        if (targetCharacteristic != null) break;
      }
      
      if (targetCharacteristic == null) {
        throw Exception('No writable characteristic found');
      }
      
      // Convert note to JSON and send
      final jsonData = jsonEncode(noteData);
      final bytes = utf8.encode(jsonData);
      
      // Split into chunks if necessary (BLE has size limits)
      const chunkSize = 512;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        await targetCharacteristic.write(chunk);
      }
      
      // Disconnect
      await device.disconnect();
      
      return true;
    } catch (e) {
      print('Error sending note: $e');
      await device.disconnect();
      return false;
    }
  }
  
  /// Receive note from device
  static Future<Map<String, dynamic>?> receiveNote(BluetoothDevice device) async {
    try {
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));
      
      // Discover services
      final services = await device.discoverServices();
      
      // Find the characteristic to read from
      BluetoothCharacteristic? targetCharacteristic;
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.read) {
            targetCharacteristic = characteristic;
            break;
          }
        }
        if (targetCharacteristic != null) break;
      }
      
      if (targetCharacteristic == null) {
        throw Exception('No readable characteristic found');
      }
      
      // Read data
      final bytes = await targetCharacteristic.read();
      final jsonData = utf8.decode(bytes);
      final noteData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Disconnect
      await device.disconnect();
      
      return noteData;
    } catch (e) {
      print('Error receiving note: $e');
      await device.disconnect();
      return null;
    }
  }
  
  /// Share note via Bluetooth (simplified)
  static Future<bool> shareNote(Map<String, dynamic> noteData) async {
    try {
      final devices = await scanForDevices();
      
      if (devices.isEmpty) {
        return false;
      }
      
      // For now, send to first discovered device
      // In a real app, you'd show a device picker
      return await sendNote(devices.first, noteData);
    } catch (e) {
      print('Error sharing note: $e');
      return false;
    }
  }
}

/// Bluetooth device info
class BluetoothDeviceInfo {
  final String name;
  final String address;
  final int rssi;
  
  BluetoothDeviceInfo({
    required this.name,
    required this.address,
    required this.rssi,
  });
}
