class WaterStatus {
  final bool isFlowing;
  final double flowRate; // L/min
  final double totalPumped; // Liters
  final double waterLevel; // Percentage

  WaterStatus({
    required this.isFlowing,
    this.flowRate = 0.0,
    this.totalPumped = 0.0,
    this.waterLevel = 0.0,
  });
}
