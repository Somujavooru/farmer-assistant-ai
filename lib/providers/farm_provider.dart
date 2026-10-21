import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/power_status.dart';
import '../models/motor_status.dart';
import '../models/water_status.dart';
import '../models/alert.dart';
import '../models/crop.dart';
import '../models/crop_ai_result.dart';
import '../models/expense.dart';
import '../models/farm_history_item.dart';
import '../models/hardware_status.dart';
import '../services/farm_service.dart';
import '../services/voice_service.dart';
 import '../services/sms_service.dart';
import '../localization/app_localizations.dart';
import 'settings_provider.dart';

class FarmProvider with ChangeNotifier {
  final FarmService _farmService = MockFarmService();
  final VoiceService _voiceService = VoiceService();
  final SmsService _smsService = MockSmsService();
  
  SettingsProvider _settings;

  PowerStatus? _powerStatus;
  MotorStatus? _motorStatus;
  WaterStatus? _waterStatus;
  
  List<Crop> _crops = [];
  String? _activeCropId;
  List<Expense> _expenses = [];
  List<CropAiResult> _aiResults = [];

  // State Tracking for Transitions (Decoupled)
  bool? _previousPowerState = false; // Start as false (Power OFF)
  bool? _previousMotorState;
  int? _previousPhaseCount;
  ConnectionStatus? _previousConnectionStatus;
  
  // Alert Prevention (Map of Alert Key to Last Notification Time)
  final Map<String, DateTime> _lastAlertTimes = {};
  static const Duration alertCooldown = Duration(seconds: 2); // Reduced to 2s for testing responsiveness

  final List<Alert> _alerts = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isPendingCommand = false;
  DateTime? _lastUpdateTime;
  
  // Temporary Test Mode State
  // ABSOLUTE RULE: Source of truth is ONLY the TEST switch in this version.
  bool _isPowerTestMode = true; // Default to Test Mode
  bool _testPowerAvailable = false; // Default to Power OFF
  bool _testPhase1 = true;
  bool _testPhase2 = true;
  bool _testPhase3 = true;

  // Water Flow / Dry Run Tracking
  bool _isWaterTestMode = true;
  double _testWaterFlowRate = 0.0;
  Timer? _dryRunConfirmationTimer;
  int _dryRunCountdown = 0;
  bool _isDryRunConfirmed = false;
  static const double flowThreshold = 10.0; // L/min
  static const Duration dryRunConfirmationDuration = Duration(seconds: 10); // Reduced to 10s for faster testing

  // Motor Safety Tracking
  bool _isMotorTestMode = true;
  double _testMotorCurrent = 0.0;
  Timer? _motorStartConfirmationTimer;
  static const Duration motorStartConfirmationDuration = Duration(seconds: 15);
  static const double currentOverloadThreshold = 15.0; // Amps

  StreamSubscription? _connectionSub;
  StreamSubscription? _powerSub;
  StreamSubscription? _motorSub;
  StreamSubscription? _waterSub;
  Timer? _telemetryCheckTimer;

  FarmProvider({required SettingsProvider settings}) : _settings = settings {
    // Initialize PowerStatus with OFF state
    _powerStatus = PowerStatus(
      isAvailable: false,
      phase1Available: false,
      phase2Available: false,
      phase3Available: false,
      phaseInfo: 'No Power',
    );
    
    // Initialize WaterStatus with healthy default level (85%)
    // This prevents "Water level low" alerts during Flow tests.
    _waterStatus = WaterStatus(
      isFlowing: false,
      flowRate: 0.0,
      totalPumped: 0.0,
      waterLevel: 85.0,
    );
    
    _initStreams();
    _startTelemetryCheck();
    _loadCrops();
    _loadExpenses();
    _loadAiResults();
    refreshStaticData();
  }

  Future<void> _loadCrops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cropsJson = prefs.getString('farm_crops');
      if (cropsJson != null) {
        final List<dynamic> decoded = jsonDecode(cropsJson);
        _crops = decoded.map((item) => Crop.fromMap(item)).toList();
      }
      _activeCropId = prefs.getString('active_crop_id');
      
      // If no active crop set but we have crops, set the first active one as default
      if (_activeCropId == null && _crops.isNotEmpty) {
        final firstActive = _crops.where((c) => c.isActive).firstOrNull;
        if (firstActive != null) {
          _activeCropId = firstActive.id;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CROP] Error loading crops: $e');
    }
  }

  Future<void> _saveCrops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_crops.map((c) => c.toMap()).toList());
      await prefs.setString('farm_crops', encoded);
      if (_activeCropId != null) {
        await prefs.setString('active_crop_id', _activeCropId!);
      } else {
        await prefs.remove('active_crop_id');
      }
    } catch (e) {
      debugPrint('[CROP] Error saving crops: $e');
    }
  }

  void addCrop(Crop crop) {
    _crops.add(crop);
    if (_activeCropId == null && crop.isActive) {
      _activeCropId = crop.id;
    }
    _saveCrops();
    notifyListeners();
  }

  void updateCrop(Crop updated) {
    final index = _crops.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _crops[index] = updated;
      _saveCrops();
      notifyListeners();
    }
  }

  void deleteCrop(String id) {
    _crops.removeWhere((c) => c.id == id);
    if (_activeCropId == id) {
      _activeCropId = _crops.where((c) => c.isActive).firstOrNull?.id;
    }
    _saveCrops();
    notifyListeners();
  }

  void setActiveCrop(String id) {
    final crop = _crops.firstWhere((c) => c.id == id);
    if (crop.isActive) {
      _activeCropId = id;
      _saveCrops();
      notifyListeners();
    }
  }

  void archiveCrop(String id) {
    final index = _crops.indexWhere((c) => c.id == id);
    if (index != -1) {
      _crops[index] = _crops[index].copyWith(isActive: false);
      if (_activeCropId == id) {
        _activeCropId = _crops.where((c) => c.isActive).firstOrNull?.id;
      }
      _saveCrops();
      notifyListeners();
    }
  }

  // --- EXPENSE MANAGEMENT ---
  Future<void> _loadExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? expensesJson = prefs.getString('farm_expenses');
      if (expensesJson != null) {
        final List<dynamic> decoded = jsonDecode(expensesJson);
        _expenses = decoded.map((item) => Expense.fromMap(item)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[EXPENSE] Error loading expenses: $e');
    }
  }

  Future<void> _saveExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_expenses.map((e) => e.toMap()).toList());
      await prefs.setString('farm_expenses', encoded);
    } catch (e) {
      debugPrint('[EXPENSE] Error saving expenses: $e');
    }
  }

  List<Expense> get expenses => _expenses;

  List<Expense> getExpensesForCrop(String cropId) {
    return _expenses.where((e) => e.cropId == cropId).toList();
  }

  double getTotalExpenseForCrop(String cropId) {
    return _expenses
        .where((e) => e.cropId == cropId)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getOverallTotalExpense() {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getCategoryBreakdown({String? cropId}) {
    final filtered = cropId == null
        ? _expenses
        : _expenses.where((e) => e.cropId == cropId);
    final Map<String, double> breakdown = {};
    for (var e in filtered) {
      breakdown[e.category] = (breakdown[e.category] ?? 0.0) + e.amount;
    }
    return breakdown;
  }

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    _saveExpenses();
    notifyListeners();
  }

  void updateExpense(Expense updated) {
    final index = _expenses.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _expenses[index] = updated;
      _saveExpenses();
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _saveExpenses();
    notifyListeners();
  }

  // --- CROP AI ANALYSIS PERSISTENCE ---
  Future<void> _loadAiResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? aiJson = prefs.getString('farm_ai_results');
      if (aiJson != null) {
        final List<dynamic> decoded = jsonDecode(aiJson);
        _aiResults = decoded.map((item) => CropAiResult.fromMap(item)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CROP AI] Error loading AI analysis results: $e');
    }
  }

  Future<void> _saveAiResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_aiResults.map((r) => r.toMap()).toList());
      await prefs.setString('farm_ai_results', encoded);
    } catch (e) {
      debugPrint('[CROP AI] Error saving AI analysis results: $e');
    }
  }

  List<CropAiResult> get aiResults => _aiResults;

  List<CropAiResult> getAiResultsForCrop(String cropId) {
    return _aiResults.where((r) => r.cropId == cropId).toList();
  }

  void saveAiAnalysisResult(CropAiResult result) {
    _aiResults.insert(0, result);
    _saveAiResults();
    
    final label = result.predictedLabel ?? 'Crop Inspection';
    final confText = result.confidence != null ? ' (${(result.confidence! * 100).toStringAsFixed(0)}% confidence)' : '';

    final alert = Alert(
      id: 'ai_${result.id}',
      title: 'AI Crop Health: $label',
      message: '${result.cropName} - $label$confText',
      timestamp: result.timestamp,
      severity: label.toLowerCase() == 'healthy'
          ? AlertSeverity.information
          : AlertSeverity.warning,
    );
    _addAlert(alert);

    notifyListeners();
  }

  // --- FARM & CROP HISTORY ---
  List<FarmHistoryItem> getHistoryItems({String? filterCropId, FarmHistoryType? filterType}) {
    final List<FarmHistoryItem> items = [];

    // 1. Planting Records
    for (var crop in _crops) {
      if (filterCropId != null && crop.id != filterCropId) continue;
      items.add(FarmHistoryItem(
        id: 'planting_${crop.id}',
        type: FarmHistoryType.planting,
        date: crop.plantingDate,
        title: 'Crop Planted: ${crop.name}',
        subtitle: 'Field: ${crop.field} • ${crop.area} ${crop.areaUnit}',
        details: 'Stage: ${crop.stage} • Health: ${crop.healthStatus}',
        cropId: crop.id,
        cropName: crop.name,
        originalObject: crop,
      ));
    }

    // 2. Expense Records
    for (var expense in _expenses) {
      if (filterCropId != null && expense.cropId != filterCropId) continue;
      final crop = _crops.where((c) => c.id == expense.cropId).firstOrNull;
      items.add(FarmHistoryItem(
        id: 'expense_${expense.id}',
        type: FarmHistoryType.expense,
        date: expense.date,
        title: 'Expense: ${expense.category}',
        subtitle: '${expense.description} • ₹ ${expense.amount.toStringAsFixed(2)}',
        details: 'Field: ${expense.field ?? crop?.field ?? "N/A"}',
        cropId: expense.cropId,
        cropName: crop?.name ?? 'Unknown Crop',
        amount: expense.amount,
        originalObject: expense,
      ));
    }

    // 3. System Alerts / Real Farm Log Events
    for (var alert in _alerts) {
      if (filterCropId != null) {
        final crop = _crops.where((c) => c.id == filterCropId).firstOrNull;
        if (crop != null) {
          // Include system alerts that occurred on or after the planting date
          if (alert.timestamp.isBefore(crop.plantingDate)) continue;
        }
      }

      items.add(FarmHistoryItem(
        id: 'alert_${alert.id}',
        type: FarmHistoryType.systemAlert,
        date: alert.timestamp,
        title: alert.title,
        subtitle: alert.message,
        details: 'Severity: ${alert.severity.name.toUpperCase()}',
        cropId: null,
        originalObject: alert,
      ));
    }

    // Filter by type if requested
    var result = items;
    if (filterType != null) {
      result = result.where((item) => item.type == filterType).toList();
    }

    // Sort descending by date
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  void _startTelemetryCheck() {
    _telemetryCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectionStatus == ConnectionStatus.connected && _lastUpdateTime != null) {
        if (DateTime.now().difference(_lastUpdateTime!) > const Duration(seconds: 45)) {
          _processAlert('telemetry_timeout_alert', AlertSeverity.warning);
        }
      }
    });
  }

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
  }

  // Test Mode Toggles
  bool get isPowerTestMode => _isPowerTestMode;
  bool get testPowerAvailable => _testPowerAvailable;
  bool get testPhase1 => _testPhase1;
  bool get testPhase2 => _testPhase2;
  bool get testPhase3 => _testPhase3;

  bool get isWaterTestMode => _isWaterTestMode;
  double get testWaterFlowRate => _testWaterFlowRate;
  double get waterFlowThreshold => flowThreshold;

  bool get isMotorTestMode => _isMotorTestMode;
  double get testMotorCurrent => _testMotorCurrent;

  void togglePowerTestMode(bool enabled) {
    _isPowerTestMode = enabled;
    debugPrint('[MAIN POWER TEST] Mode: ${enabled ? "ON (SIMULATED)" : "OFF (LIVE)"}');
    notifyListeners();
  }

  void setTestPhases(bool p1, bool p2, bool p3) {
    if (!_isPowerTestMode) {
      return;
    }
    _testPhase1 = p1;
    _testPhase2 = p2;
    _testPhase3 = p3;
    _testPowerAvailable = p1 || p2 || p3;
    
    _updateSimulatedPower();
  }

  void _updateSimulatedPower() {
    final available = _testPhase1 || _testPhase2 || _testPhase3;
    
    String phaseInfo = 'Normal';
    int count = 0;
    if (_testPhase1) {
      count++;
    }
    if (_testPhase2) {
      count++;
    }
    if (_testPhase3) {
      count++;
    }
    
    if (count == 3) {
      phaseInfo = 'Normal';
    } else if (count > 0) {
      phaseInfo = '$count Phase(s)';
    } else {
      phaseInfo = 'No Power';
    }

    final simulatedStatus = PowerStatus(
      isAvailable: available,
      phase1Available: _testPhase1,
      phase2Available: _testPhase2,
      phase3Available: _testPhase3,
      lastOnTime: available ? DateTime.now() : _powerStatus?.lastOnTime,
      lastOffTime: !available ? DateTime.now() : _powerStatus?.lastOffTime,
      voltage: available ? 230.0 : 0.0,
      current: 0.0,
      power: 0.0,
      phaseInfo: phaseInfo,
    );

    _handlePowerUpdate(simulatedStatus, fromTestControl: true);
  }

  void setTestPower(bool available) {
    if (!_isPowerTestMode) {
      debugPrint('[MAIN POWER ERROR] Attempted to change Main Power while Test Mode is OFF');
      return;
    }
    
    _testPhase1 = available;
    _testPhase2 = available;
    _testPhase3 = available;
    _testPowerAvailable = available;

    _updateSimulatedPower();
  }

  void toggleWaterTestMode(bool enabled) {
    _isWaterTestMode = enabled;
    debugPrint('[WATER FLOW TEST] Mode: ${enabled ? "ON (SIMULATED)" : "OFF (LIVE)"}');
    if (enabled) {
      _testWaterFlowRate = _waterStatus?.flowRate ?? 0.0;
    }
    notifyListeners();
  }

  void setTestWaterFlow(double rate) {
    if (!_isWaterTestMode) {
      debugPrint('[WATER FLOW ERROR] Attempted to change Water Flow while Test Mode is OFF');
      return;
    }
    _testWaterFlowRate = rate;
    
    // Construct simulated WaterStatus
    // We use a healthy water level (85%) by default so it doesn't trigger unrelated alerts
    final simulatedStatus = WaterStatus(
      isFlowing: rate >= flowThreshold,
      flowRate: rate,
      totalPumped: _waterStatus?.totalPumped ?? 0.0,
      waterLevel: _waterStatus?.waterLevel ?? 85.0, 
    );
    
    _handleWaterUpdate(simulatedStatus, fromTestControl: true);
  }

  void toggleMotorTestMode(bool enabled) {
    _isMotorTestMode = enabled;
    debugPrint('[MOTOR TEST] Mode: ${enabled ? "ON (SIMULATED)" : "OFF (LIVE)"}');
    notifyListeners();
  }

  void setTestMotorCurrent(double amps) {
    if (!_isMotorTestMode) return;
    _testMotorCurrent = amps;
    
    if (_motorStatus != null) {
      _handleMotorUpdate(_motorStatus!);
    }
  }

  // Getters
  PowerStatus? get powerStatus => _powerStatus;
  MotorStatus? get motorStatus => _motorStatus;
  WaterStatus? get waterStatus => _waterStatus;
  List<Alert> get alerts => _alerts;
  
  List<Crop> get crops => _crops;
  Crop? get activeCrop => _crops.where((c) => c.id == _activeCropId).firstOrNull;
  Crop? get crop => activeCrop; // Maintain compatibility with HomeScreen
  
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isPendingCommand => _isPendingCommand;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get isLoading => _connectionStatus == ConnectionStatus.connecting;
  bool get isDryRunConfirmed => _isDryRunConfirmed;
  int get dryRunCountdown => _dryRunCountdown;

  bool get isTelemetryTimeout {
    if (_lastUpdateTime == null) return false;
    return DateTime.now().difference(_lastUpdateTime!) > const Duration(seconds: 45);
  }

  void _initStreams() {
    // 1. Connection Stream
    _connectionSub = _farmService.connectionStream.listen((status) {
      debugPrint('[EVENT] RECEIVED CONNECTION: $status');
      _lastUpdateTime = DateTime.now(); // Telemetry heartbeat
      try {
        debugPrint('[EVENT] PROCESSING START: Connection');
        if (_previousConnectionStatus != status) {
          if (status == ConnectionStatus.connected) {
            _processAlert('hardware_reconnected_alert', AlertSeverity.success);
          } else if (status == ConnectionStatus.disconnected || status == ConnectionStatus.error) {
            _processAlert('hardware_disconnected_alert', AlertSeverity.critical);
          }
        }
        _connectionStatus = status;
        _previousConnectionStatus = status;
        notifyListeners();
        debugPrint('[EVENT] PROCESSING END: Connection');
      } catch (e, stack) {
        debugPrint('[ALERT PIPELINE ERROR] Connection Listener: $e');
        debugPrint('$stack');
      }
    }, onError: (e) => debugPrint('[STREAM ERROR] Connection: $e'));

    // 2. Power Stream
    _powerSub = _farmService.powerStream.listen((status) {
      _lastUpdateTime = DateTime.now(); // Telemetry heartbeat
      // ABSOLUTE RULE: Source of truth is ONLY the TEST switch in this version.
      _handlePowerUpdate(status, fromTestControl: false);
    }, onError: (e) => debugPrint('[STREAM ERROR] Power: $e'));

    // 3. Motor Stream
    _motorSub = _farmService.motorStream.listen((status) {
      debugPrint('[EVENT] RECEIVED MOTOR: ${status.isRunning}');
      _lastUpdateTime = DateTime.now(); // Telemetry heartbeat
      
      // If we are in motor test mode, we might want to override some fields
      // but keep the physical feedback logic.
      _handleMotorUpdate(status);
    }, onError: (e) => debugPrint('[STREAM ERROR] Motor: $e'));

    // 4. Water Stream
    _waterSub = _farmService.waterStream.listen((status) {
      debugPrint('[EVENT] RECEIVED WATER: Flowing=${status.isFlowing}');
      _lastUpdateTime = DateTime.now(); // Telemetry heartbeat
      if (_isWaterTestMode) {
        debugPrint('[EVENT] IGNORED WATER: Hardware update received but Test Mode is ON');
        notifyListeners();
        return;
      }
      _handleWaterUpdate(status, fromTestControl: false);
    }, onError: (e) => debugPrint('[STREAM ERROR] Water: $e'));
  }

  void _handleMotorUpdate(MotorStatus status) {
    debugPrint('[EVENT] PROCESSING START: Motor');
    try {
      final physicalRunning = status.isRunning;
      
      // If we are in motor test mode, override physical fields if needed
      // Currently, we only override current for fault testing.
      final currentToUse = _isMotorTestMode ? _testMotorCurrent : (status.motorCurrent ?? 0.0);
      
      // Update local status with the simulated current
      final updatedStatus = MotorStatus(
        isRunning: physicalRunning,
        lastStartTime: status.lastStartTime,
        todayRuntime: status.todayRuntime,
        startsToday: status.startsToday,
        motorCurrent: currentToUse,
      );

      // A. COMMAND FEEDBACK MONITORING (Motor Start Failure)
      if (physicalRunning && _motorStartConfirmationTimer != null) {
        debugPrint('[MOTOR] Feedback received - clearing start confirmation timer');
        _motorStartConfirmationTimer?.cancel();
        _motorStartConfirmationTimer = null;
      }

      // B. MOTOR STATE TRANSITIONS
      if (_previousMotorState != null && _previousMotorState != physicalRunning) {
        // Only alert if power is stable (3 phases)
        bool isPowerStable = _powerStatus != null && 
                            _powerStatus!.isAvailable && 
                            _previousPowerState == true &&
                            _powerStatus!.availablePhasesCount == 3;
        
        if (isPowerStable) {
          if (physicalRunning) {
            _processAlert('motor_started_alert', AlertSeverity.information);
          } else {
            _processAlert('motor_stopped_alert', AlertSeverity.information);
          }
        } else {
          debugPrint('[ALERT] DECOUPLE: Suppressing motor alert because power is transitioning or faulted');
        }
      }

      // C. MOTOR OVERLOAD DETECTION
      if (physicalRunning && currentToUse > currentOverloadThreshold) {
        _processAlert('motor_overload_alert', AlertSeverity.critical);
      }

      _motorStatus = updatedStatus;
      _previousMotorState = physicalRunning;
      _isPendingCommand = false;

      if (_waterStatus != null) {
        _checkWaterAnomalies(_waterStatus!);
      }

      notifyListeners();
      debugPrint('[EVENT] PROCESSING END: Motor');
    } catch (e, stack) {
      debugPrint('[ALERT PIPELINE ERROR] Motor Update Handler: $e');
      debugPrint('$stack');
    }
  }

  void _handleWaterUpdate(WaterStatus status, {bool fromTestControl = false}) {
    if (!fromTestControl && _isWaterTestMode) return;

    debugPrint('[EVENT] RECEIVED WATER UPDATE: ${status.flowRate} L/min');
    try {
      debugPrint('[EVENT] PROCESSING START: Water');
      _waterStatus = status;
      
      _checkWaterAnomalies(status);
      
      notifyListeners();
      debugPrint('[EVENT] PROCESSING END: Water');
    } catch (e, stack) {
      debugPrint('[ALERT PIPELINE ERROR] Water Update Handler: $e');
      debugPrint('$stack');
    }
  }

  void _handlePowerUpdate(PowerStatus status, {bool fromTestControl = false}) {
    if (!fromTestControl) {
      // Log error but don't change state if hardware reports power during test mode
      if (status.isAvailable != _powerStatus?.isAvailable) {
         debugPrint('[MAIN POWER ERROR] Main Power change ignored (Hardware reported ${status.isAvailable ? "ON" : "OFF"} but Test Switch is ${_testPowerAvailable ? "ON" : "OFF"})');
      }
      return;
    }
    
    debugPrint('[EVENT] RECEIVED POWER UPDATE FROM TEST CONTROL: ${status.isAvailable}');
    try {
      debugPrint('[EVENT] PROCESSING START: Power');
      
      final currentPhaseCount = status.availablePhasesCount;
      final currentPowerAvailable = status.isAvailable && currentPhaseCount > 0;
      
      // A. POWER STATE TRANSITION (ON/OFF)
      if (_previousPowerState != null && _previousPowerState != currentPowerAvailable) {
        if (currentPowerAvailable) {
          // Only alert "Power Restored" if it comes back with all 3 phases
          if (currentPhaseCount == 3) {
            _processAlert('power_restored_alert', AlertSeverity.success);
          } else {
            // Power restored but with fault
            _processAlert('phase_fault_${currentPhaseCount}_alert', AlertSeverity.warning);
          }
        } else {
          // 0 phases or isAvailable = false
          _processAlert('power_off_alert', AlertSeverity.warning);
        }
        
        // DECOUPLE: Synchronize motor state tracker to current status to prevent false alerts
        if (_motorStatus != null) {
          _previousMotorState = _motorStatus!.isRunning;
        }
      }

      // B. PHASE STATE MONITORING (Within Power ON state)
      if (currentPowerAvailable && _previousPhaseCount != currentPhaseCount) {
        if (currentPhaseCount == 2) {
          _processAlert('phase_fault_2_alert', AlertSeverity.warning);
        } else if (currentPhaseCount == 1) {
          _processAlert('phase_fault_1_alert', AlertSeverity.warning);
        } else if (currentPhaseCount == 3 && _previousPhaseCount != null && _previousPhaseCount! < 3) {
          _processAlert('power_restored_alert', AlertSeverity.success);
        }
        
        if (_motorStatus != null) {
          _previousMotorState = _motorStatus!.isRunning;
        }
      }
      
      _powerStatus = status;
      _previousPowerState = currentPowerAvailable;
      _previousPhaseCount = currentPhaseCount;
      
      _checkElectricalAnomalies(status);
      notifyListeners();
      debugPrint('[EVENT] PROCESSING END: Power');
    } catch (e, stack) {
      debugPrint('[ALERT PIPELINE ERROR] Power Update Handler: $e');
      debugPrint('$stack');
    }
  }

  /// Central Alert Processing Engine
  void _processAlert(String localizationKey, AlertSeverity severity) {
    try {
      final now = DateTime.now();
      
      // 1. Duplicate Prevention check
      if (_lastAlertTimes.containsKey(localizationKey)) {
        if (now.difference(_lastAlertTimes[localizationKey]!) < alertCooldown) {
          debugPrint('[ALERT] DUPLICATE SUPPRESSED: $localizationKey');
          return; // Prevent spamming same alert
        }
      }
      _lastAlertTimes[localizationKey] = now;

      debugPrint('[ALERT] CREATE START: $localizationKey');

      // 2. Generate and Store Alert Object (Uses App Language for List View)
      final appLoc = AppLocalizations(_settings.currentLocale);
      final alert = Alert(
        id: '${localizationKey}_${now.millisecondsSinceEpoch}',
        title: appLoc.translate(localizationKey).split('.').first, // Simple title
        message: appLoc.translate(localizationKey),
        timestamp: now,
        severity: severity,
      );
      
      _addAlert(alert);

      // 3. Trigger Voice Alert (Uses Voice Language - Independent)
      if (_settings.voiceAlertsEnabled) {
        debugPrint('[ALERT DELIVERY] Attempting Voice: $localizationKey');
        _triggerVoice(localizationKey);
      } else {
        debugPrint('[ALERT DELIVERY] Voice DISABLED in settings');
      }

      // 4. Trigger SMS Alert (Uses SMS Language - Independent)
      debugPrint('[ALERT DELIVERY] Attempting SMS: $localizationKey');
      _triggerSms(localizationKey);
      
      debugPrint('[ALERT] PROCESSING END: $localizationKey');
    } catch (e, stack) {
      debugPrint('[ALERT PIPELINE ERROR] _processAlert: $e');
      debugPrint('$stack');
    }
  }

  void _triggerVoice(String localizationKey) {
    debugPrint('[VOICE] QUEUE START: $localizationKey');
    try {
      final voiceLoc = AppLocalizations(_settings.voiceLocale);
      // Non-blocking call to VoiceService
      _voiceService.speak(voiceLoc.translate(localizationKey), _settings.voiceLocale).then((success) {
        if (!success) {
          debugPrint('[VOICE] SKIPPED: Engine unable to speak or was busy');
        }
      }).catchError((e) {
        debugPrint('[VOICE] ERROR: Async failure: $e');
      }).whenComplete(() {
        debugPrint('[VOICE] QUEUE COMPLETE: $localizationKey');
      });
    } catch (e) {
      debugPrint('[VOICE] ERROR: Sync initialization failure: $e');
    }
  }

  void _triggerSms(String localizationKey) {
    debugPrint('[SMS] QUEUE START: $localizationKey');
    try {
      final smsLoc = AppLocalizations(_settings.smsLocale);
      // Non-blocking call to SmsService
      _smsService.sendAlertSms(
        smsLoc.translate(localizationKey), 
        '+91 98765 43210', // Mock Phone
        _settings.smsLocale
      ).catchError((e) {
        debugPrint('[SMS] ERROR: Async failure: $e');
      }).whenComplete(() {
        debugPrint('[SMS] QUEUE COMPLETE: $localizationKey');
      });
    } catch (e) {
      debugPrint('[SMS] ERROR: Sync initialization failure: $e');
    }
  }

  void _addAlert(Alert alert) {
    debugPrint('[ALERT] ADD START: ${alert.id}');
    _alerts.insert(0, alert);
    debugPrint('[ALERT] ADD COMPLETE: ${alert.id}');
    debugPrint('[ALERT] NOTIFY LISTENERS');
    notifyListeners();
  }

  void _checkElectricalAnomalies(PowerStatus status) {
    if (!status.isAvailable) return;

    if (status.current > 15.0) {
      _processAlert('overcurrent_alert', AlertSeverity.critical);
    }
    
    if (status.voltage > 260) {
      _processAlert('high_voltage_alert', AlertSeverity.warning);
    } else if (status.voltage < 180) {
      _processAlert('low_voltage_alert', AlertSeverity.warning);
    }
  }

  void _checkWaterAnomalies(WaterStatus status) {
    final isMotorRunning = _motorStatus?.isRunning ?? false;
    final isFlowNormal = status.flowRate >= flowThreshold;

    if (!isMotorRunning) {
      // Motor is OFF - cancel any active dry run confirmation
      if (_dryRunConfirmationTimer != null) {
        debugPrint('[WATER FLOW] Monitoring stopped because motor is OFF');
        _dryRunConfirmationTimer?.cancel();
        _dryRunConfirmationTimer = null;
      }
      _dryRunCountdown = 0;
      _isDryRunConfirmed = false;
      return;
    }

    // Motor is RUNNING
    if (isFlowNormal) {
      // Flow is NORMAL
      if (_isDryRunConfirmed) {
        debugPrint('[WATER FLOW] Flow restored');
        _processAlert('water_flow_restored_alert', AlertSeverity.success);
        _isDryRunConfirmed = false;
      }
      
      // Cancel confirmation timer if it was running (intermittent flow recovered)
      if (_dryRunConfirmationTimer != null) {
        debugPrint('[WATER FLOW] Flow NORMAL - cancelling confirmation timer');
        _dryRunConfirmationTimer?.cancel();
        _dryRunConfirmationTimer = null;
      }
      _dryRunCountdown = 0;
      
      debugPrint('[WATER FLOW] Flow NORMAL (${status.flowRate} L/min)');
    } else {
      // Flow is LOW or NONE
      debugPrint('[WATER FLOW] Flow LOW/NONE (${status.flowRate} L/min)');
      
      if (!_isDryRunConfirmed && _dryRunConfirmationTimer == null) {
        debugPrint('[WATER FLOW] Starting Dry Run confirmation (${dryRunConfirmationDuration.inSeconds}s)');
        _dryRunCountdown = dryRunConfirmationDuration.inSeconds;
        
        // Use a periodic timer to update the countdown UI
        _dryRunConfirmationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_dryRunCountdown > 1) {
            _dryRunCountdown--;
            notifyListeners();
          } else {
            debugPrint('[WATER FLOW] Dry Run confirmation successful');
            _isDryRunConfirmed = true;
            _dryRunCountdown = 0;
            _dryRunConfirmationTimer?.cancel();
            _dryRunConfirmationTimer = null;
            _processAlert('dry_run_alert', AlertSeverity.critical);
            notifyListeners();
          }
        });
      } else if (_isDryRunConfirmed) {
        debugPrint('[WATER FLOW] Dry Run already reported - no duplicate alert');
      }
    }

    if (status.waterLevel < 20.0) {
      _processAlert('low_water_alert', AlertSeverity.warning);
    }
  }

  Future<void> refreshStaticData() async {
    try {
      final results = await Future.wait([
        _farmService.getAlerts(),
        _farmService.getCropDetails(),
      ]);
      
      // IMPORTANT: refreshStaticData() must not overwrite newly generated runtime alerts.
      final historicalAlerts = results[0] as List<Alert>;
      
      // Filter out alerts that are already in our runtime list
      final Set<String> existingIds = _alerts.map((a) => a.id).toSet();
      final newToApp = historicalAlerts.where((a) => !existingIds.contains(a.id)).toList();
      
      if (newToApp.isNotEmpty) {
        _alerts.addAll(newToApp);
        // Sort by timestamp descending
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
      
      // We don't overwrite user-saved crops with mock data anymore
      // _crop = results[1] as Crop;
      notifyListeners();
    } catch (e) {
      debugPrint('[ALERT] ERROR: Static data fetch failed: $e');
    }
  }

  Future<void> toggleMotor(bool turnOn) async {
    if (_connectionStatus != ConnectionStatus.connected) return;
    
    _isPendingCommand = true;
    notifyListeners();

    debugPrint('[MOTOR COMMAND] MANUAL ${turnOn ? "ON" : "OFF"}');

    // Start Motor Start Failure confirmation timer if turning ON
    if (turnOn) {
      _motorStartConfirmationTimer?.cancel();
      _motorStartConfirmationTimer = Timer(motorStartConfirmationDuration, () {
        if (_motorStatus == null || !_motorStatus!.isRunning) {
          debugPrint('[MOTOR] CRITICAL: Motor Start Failure detected');
          _processAlert('motor_start_failure_alert', AlertSeverity.critical);
          _isPendingCommand = false;
          notifyListeners();
        }
      });
    }
    
    final success = await _farmService.toggleMotor(turnOn);
    if (!success) {
      _motorStartConfirmationTimer?.cancel();
      _motorStartConfirmationTimer = null;
      _isPendingCommand = false;
      _processAlert('motor_failed_alert', AlertSeverity.critical);
      notifyListeners();
    }
  }

  void markAlertAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// FOR AUDIT/DEMO ONLY: Manually trigger an alert flow
  void triggerManualAlert(String key, AlertSeverity severity) {
    _processAlert(key, severity);
  }

  @override
  void dispose() {
    _telemetryCheckTimer?.cancel();
    _connectionSub?.cancel();
    _powerSub?.cancel();
    _motorSub?.cancel();
    _waterSub?.cancel();
    _farmService.dispose();
    super.dispose();
  }
}
