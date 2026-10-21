import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../models/hardware_status.dart';

import '../../providers/scheduler_provider.dart';
import '../../models/motor_schedule.dart';
import 'widgets/add_edit_schedule_dialog.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FarmProvider>(context);
    final scheduler = Provider.of<SchedulerProvider>(context);
    final motor = provider.motorStatus;
    final power = provider.powerStatus;
    final water = provider.waterStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farm Control', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMainPowerTestControl(context, provider),
            const SizedBox(height: 12),
            _buildMotorTestControl(context, provider),
            const SizedBox(height: 12),
            _buildWaterFlowTestControl(context, provider),
            const SizedBox(height: 24),
            _buildConnectivityBar(context, provider),
            const SizedBox(height: 24),
            _buildNextActionCard(context, scheduler),
            const SizedBox(height: 24),
            _buildMotorStatusHeader(context, motor),
            const SizedBox(height: 40),
            _buildMotorControlButton(context, provider),
            const SizedBox(height: 40),
            _buildWaterFlowSection(context, motor, water, provider),
            const SizedBox(height: 24),
            _buildSchedulerSection(context, scheduler),
            const SizedBox(height: 24),
            _buildElectricalReadings(context, power),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPowerTestControl(BuildContext context, FarmProvider provider) {
    return Card(
      elevation: 0,
      color: AppColors.warning.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.warning, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Main Power',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'TEST MODE — Phase Selection',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: provider.testPhase1 && provider.testPhase2 && provider.testPhase3,
                  onChanged: (val) {
                    if (!provider.isPowerTestMode) provider.togglePowerTestMode(true);
                    provider.setTestPower(val);
                  },
                  activeColor: AppColors.success,
                  activeTrackColor: AppColors.success.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPhaseToggle('L1', provider.testPhase1, (v) => provider.setTestPhases(v, provider.testPhase2, provider.testPhase3)),
                _buildPhaseToggle('L2', provider.testPhase2, (v) => provider.setTestPhases(provider.testPhase1, v, provider.testPhase3)),
                _buildPhaseToggle('L3', provider.testPhase3, (v) => provider.setTestPhases(provider.testPhase1, provider.testPhase2, v)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseToggle(String label, bool value, Function(bool) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMotorTestControl(BuildContext context, FarmProvider provider) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motor Current',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'TEST MODE — Simulation Only',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Normal', style: TextStyle(fontSize: 10)),
                Switch(
                  value: provider.testMotorCurrent > 15.0,
                  onChanged: (val) {
                    if (!provider.isMotorTestMode) provider.toggleMotorTestMode(true);
                    provider.setTestMotorCurrent(val ? 18.5 : 8.5);
                  },
                  activeColor: AppColors.error,
                  activeTrackColor: AppColors.error.withValues(alpha: 0.3),
                  inactiveThumbColor: AppColors.success,
                  inactiveTrackColor: AppColors.success.withValues(alpha: 0.3),
                ),
                const Text('Overload', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterFlowTestControl(BuildContext context, FarmProvider provider) {
    return Card(
      elevation: 0,
      color: AppColors.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.secondary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water Flow',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'TEST MODE — Simulation Only',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Normal', style: TextStyle(fontSize: 10)),
                Switch(
                  value: provider.testWaterFlowRate < provider.waterFlowThreshold,
                  onChanged: (val) {
                    if (!provider.isWaterTestMode) {
                      provider.toggleWaterTestMode(true);
                    }
                    provider.setTestWaterFlow(val ? 0.0 : 350.0);
                  },
                  activeColor: AppColors.error,
                  activeTrackColor: AppColors.error.withOpacity(0.3),
                  inactiveThumbColor: AppColors.success,
                  inactiveTrackColor: AppColors.success.withOpacity(0.3),
                ),
                const Text('None', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextActionCard(BuildContext context, SchedulerProvider scheduler) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next scheduled action',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  scheduler.getNextActionText(),
                  style: const TextStyle(fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulerSection(BuildContext context, SchedulerProvider scheduler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Motor Scheduler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showAddEditScheduleDialog(context, scheduler),
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (scheduler.schedules.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_note, size: 48, color: AppColors.onSurfaceVariant.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text('No automatic schedules set'),
                    Text(
                      'Automate your irrigation by adding a schedule',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduler.schedules.length,
            itemBuilder: (context, index) {
              final schedule = scheduler.schedules[index];
              return _buildScheduleItem(context, scheduler, schedule);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleItem(BuildContext context, SchedulerProvider scheduler, MotorSchedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule.repeatDaysText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.enabled,
                  onChanged: (val) => scheduler.toggleSchedule(schedule.id, val),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScheduleTimeInfo(context, 'ON', schedule.onTime, AppColors.primary),
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.onSurfaceVariant),
                _buildScheduleTimeInfo(context, 'OFF', schedule.offTime, AppColors.error),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showAddEditScheduleDialog(context, scheduler, schedule),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: () => scheduler.deleteSchedule(schedule.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTimeInfo(BuildContext context, String label, TimeOfDay time, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Text(
          time.format(context),
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _showAddEditScheduleDialog(BuildContext context, SchedulerProvider scheduler, [MotorSchedule? schedule]) async {
    final result = await showDialog<MotorSchedule>(
      context: context,
      builder: (context) => AddEditScheduleDialog(schedule: schedule),
    );

    if (result != null) {
      if (schedule == null) {
        scheduler.addSchedule(result);
      } else {
        scheduler.updateSchedule(result);
      }
    }
  }


  Widget _buildConnectivityBar(BuildContext context, FarmProvider provider) {
    final status = provider.connectionStatus;
    final isTimeout = provider.isTelemetryTimeout;
    
    Color color;
    String text;
    IconData icon;

    if (isTimeout && status == ConnectionStatus.connected) {
      color = AppColors.error;
      text = 'Telemetry Timeout';
      icon = Icons.timer_off_outlined;
    } else {
      switch (status) {
        case ConnectionStatus.connected:
          color = AppColors.success;
          text = 'Hardware Connected';
          icon = Icons.signal_cellular_4_bar;
          break;
        case ConnectionStatus.connecting:
          color = AppColors.warning;
          text = 'Connecting to Farm...';
          icon = Icons.signal_cellular_connected_no_internet_4_bar;
          break;
        case ConnectionStatus.error:
          color = AppColors.error;
          text = 'Communication Error';
          icon = Icons.signal_cellular_off;
          break;
        default:
          color = AppColors.onSurfaceVariant;
          text = 'Hardware Disconnected';
          icon = Icons.signal_cellular_0_bar;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                if (provider.lastUpdateTime != null)
                  Text(
                    'Last telemetry: ${DateFormat('hh:mm:ss a').format(provider.lastUpdateTime!)}',
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
                  ),
              ],
            ),
          ),
          if (isTimeout && status == ConnectionStatus.connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'STALE',
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMotorStatusHeader(BuildContext context, dynamic motor) {
    bool isRunning = motor?.isRunning ?? false;
    return FadeInDown(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isRunning ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRunning ? Icons.play_circle : Icons.stop_circle,
                  color: isRunning ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isRunning ? 'MOTOR IS RUNNING' : 'MOTOR IS STOPPED',
                  style: TextStyle(
                    color: isRunning ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRunning ? 'Runtime: ${motor?.currentRuntime}' : 'Stopped for 02h 15m',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildMotorControlButton(BuildContext context, FarmProvider provider) {
    bool isRunning = provider.motorStatus?.isRunning ?? false;
    bool isPending = provider.isPendingCommand;
    bool isOffline = provider.connectionStatus != ConnectionStatus.connected;

    return GestureDetector(
      onTap: isOffline || isPending ? null : () => _showConfirmationDialog(context, provider, !isRunning),
      child: ZoomIn(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isPending)
              const SizedBox(
                width: 210,
                height: 210,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOffline ? AppColors.grey200 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (isRunning ? AppColors.primary : AppColors.error).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: isOffline 
                      ? AppColors.grey400 
                      : (isRunning ? AppColors.primary : AppColors.error),
                  width: 8,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPending ? Icons.sync : Icons.power_settings_new,
                    size: 60,
                    color: isOffline 
                        ? AppColors.grey400 
                        : (isRunning ? AppColors.primary : AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPending ? 'WAITING' : (isRunning ? 'STOP' : 'START'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isOffline 
                          ? AppColors.grey400 
                          : (isRunning ? AppColors.primary : AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, FarmProvider provider, bool turnOn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Motor ${turnOn ? "Start" : "Stop"}'),
        content: Text(
          'Are you sure you want to ${turnOn ? "start" : "stop"} the irrigation motor? '
          'Please ensure the area is safe before proceeding.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.toggleMotor(turnOn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: turnOn ? AppColors.primary : AppColors.error,
            ),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterFlowSection(BuildContext context, dynamic motor, dynamic water, FarmProvider provider) {
    bool isRunning = motor?.isRunning ?? false;
    double flowRate = water?.flowRate ?? 0.0;
    bool isFlowNormal = flowRate >= provider.waterFlowThreshold;
    bool isDryRun = isRunning && !isFlowNormal && provider.isDryRunConfirmed;

    return Column(
      children: [
        if (isDryRun)
          FadeInUp(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'DRY RUN DETECTED: Motor is running but no water flow detected!',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Water Flow Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (isRunning)
                    Row(
                      children: [
                        if (provider.dryRunCountdown > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'VERIFYING (${provider.dryRunCountdown}s)',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFlowNormal ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFlowNormal ? 'NORMAL' : 'LOW/NONE',
                            style: TextStyle(
                              color: isFlowNormal ? AppColors.success : AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFlowReading('Flow Rate', '${flowRate.toStringAsFixed(1)} L/min', Icons.water_drop),
                  const VerticalDivider(),
                  _buildFlowReading('Water Level', '${water?.waterLevel?.toStringAsFixed(0) ?? 0}%', Icons.equalizer),
                ],
              ),
              if (!isRunning)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      'Monitoring inactive — Motor is OFF',
                      style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant.withOpacity(0.6)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowReading(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildElectricalReadings(BuildContext context, dynamic power) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Electrical Readings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildReadingItem(context, 'Voltage', '${power?.voltage?.toStringAsFixed(1) ?? 0} V', Icons.bolt),
            _buildReadingItem(context, 'Current', '${power?.current?.toStringAsFixed(1) ?? 0} A', Icons.electric_bolt),
            _buildReadingItem(context, 'Power', '${power?.power?.toStringAsFixed(1) ?? 0} kW', Icons.speed),
            _buildReadingItem(context, 'Frequency', '${power?.frequency?.toStringAsFixed(1) ?? 50.0} Hz', Icons.waves),
            _buildReadingItem(context, 'Phase Info', power?.phaseInfo ?? 'Normal', Icons.account_tree),
            _buildReadingItem(context, 'Energy', '${power?.energy?.toStringAsFixed(1) ?? 0} kWh', Icons.pie_chart),
          ],
        ),
      ],
    );
  }

  Widget _buildReadingItem(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
