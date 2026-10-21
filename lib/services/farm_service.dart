import 'dart:async';
import '../models/power_status.dart';
import '../models/motor_status.dart';
import '../models/water_status.dart';
import '../models/alert.dart';
import '../models/crop.dart';
import '../models/hardware_status.dart';

abstract class FarmService {
  Stream<ConnectionStatus> get connectionStream;
  Stream<PowerStatus> get powerStream;
  Stream<MotorStatus> get motorStream;
  Stream<WaterStatus> get waterStream;
  
  Future<List<Alert>> getAlerts();
  Future<Crop> getCropDetails();
  Future<bool> toggleMotor(bool turnOn);
  
  void dispose();
}

class MockFarmService implements FarmService {
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  final _powerController = StreamController<PowerStatus>.broadcast();
  final _motorController = StreamController<MotorStatus>.broadcast();
  final _waterController = StreamController<WaterStatus>.broadcast();

  Timer? _timer;
  Timer? _powerTimer;
  bool _currentMotorState = false; // Default to OFF
  bool _currentPowerState = true;

  MockFarmService() {
    _startMockUpdates();
  }

  void _startMockUpdates() {
    _connectionController.add(ConnectionStatus.connecting);
    
    Future.delayed(const Duration(seconds: 2), () {
      _connectionController.add(ConnectionStatus.connected);
      _emitValues();
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _emitValues();
    });

    // DISABLED: Automatic power toggling removed to give user full control via Test Mode
    // _powerTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
    //   _currentPowerState = !_currentPowerState;
    //   _emitValues();
    // });
  }

  void _emitValues() {
    _powerController.add(
      PowerStatus(
        isAvailable: _currentPowerState,
        lastOnTime: _currentPowerState
            ? DateTime.now().subtract(
          const Duration(hours: 4, minutes: 48),
        )
            : null,
        voltage: _currentPowerState
            ? 228.0 + (DateTime.now().second % 5)
            : 0.0,
        current: _currentPowerState && _currentMotorState
            ? 8.2 + (DateTime.now().second % 2) * 0.1
            : 0.0,
        power: _currentPowerState && _currentMotorState ? 1.8 : 0.0,
        energy: 42.5,
        frequency: _currentPowerState ? 50.1 : 0.0,
      ),
    );

    _motorController.add(
      MotorStatus(
        isRunning: _currentPowerState && _currentMotorState,
        lastStartTime: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 24),
        ),
        todayRuntime: const Duration(hours: 3, minutes: 15),
        startsToday: 2,
        motorCurrent: _currentPowerState && _currentMotorState ? 8.5 : 0.0,
      ),
    );

    _waterController.add(
      WaterStatus(
        isFlowing: _currentPowerState && _currentMotorState,
        flowRate: _currentPowerState && _currentMotorState
            ? 320.0
            : 0.0,
        totalPumped: 12500.0,
        waterLevel: 75.0,
      ),
    );
  }

  @override
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;
  @override
  Stream<PowerStatus> get powerStream => _powerController.stream;
  @override
  Stream<MotorStatus> get motorStream => _motorController.stream;
  @override
  Stream<WaterStatus> get waterStream => _waterController.stream;

  @override
  Future<List<Alert>> getAlerts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Alert(
        id: '1',
        title: 'Motor Started',
        message: 'Motor was started at 10:42 AM',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        severity: AlertSeverity.information,
      ),
      Alert(
        id: '2',
        title: 'Power Restored',
        message: 'Electricity is now available',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        severity: AlertSeverity.success,
      ),
    ];
  }

  @override
  Future<Crop> getCropDetails() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Crop(
      id: 'mock_crop_1',
      name: 'Paddy / Rice',
      stage: 'Tillering',
      plantingDate: DateTime.now().subtract(const Duration(days: 45)),
      expectedHarvestDate: DateTime.now().add(const Duration(days: 75)),
      soilMoisture: 64.0,
      healthStatus: 'Healthy',
    );
  }

  @override
  Future<bool> toggleMotor(bool turnOn) async {
    await Future.delayed(const Duration(seconds: 2));
    _currentMotorState = turnOn;
    _emitValues();
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _powerTimer?.cancel();
    _connectionController.close();
    _powerController.close();
    _motorController.close();
    _waterController.close();
  }
}
