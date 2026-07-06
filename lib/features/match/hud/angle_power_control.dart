import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AnglePowerControl extends StatelessWidget {
  final bool enabled;
  final double angle;
  final int power;
  final ValueChanged<double> onAngleChanged;
  final ValueChanged<int> onPowerChanged;
  final VoidCallback onShoot;

  const AnglePowerControl({
    super.key,
    required this.enabled,
    required this.angle,
    required this.power,
    required this.onAngleChanged,
    required this.onPowerChanged,
    required this.onShoot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Angle row
          Row(
            children: [
              const SizedBox(
                width: 50,
                child: Text(
                  'Angle',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: angle,
                  min: 0,
                  max: 180,
                  divisions: 180,
                  activeColor: enabled ? AppColors.accent : Colors.grey,
                  inactiveColor: AppColors.primary,
                  onChanged: enabled ? onAngleChanged : null,
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${angle.round()}°',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          // Power row
          Row(
            children: [
              const SizedBox(
                width: 50,
                child: Text(
                  'Power',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: power.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: enabled ? AppColors.warning : Colors.grey,
                  inactiveColor: AppColors.primary,
                  onChanged: enabled
                      ? (v) => onPowerChanged(v.round())
                      : null,
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$power',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Shoot button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: enabled ? onShoot : null,
              icon: const Icon(Icons.gps_fixed, size: 16),
              label: const Text('FIRE!'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    enabled ? AppColors.accent : Colors.grey.shade800,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
