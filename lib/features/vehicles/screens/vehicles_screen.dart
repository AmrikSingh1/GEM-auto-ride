import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/bluetooth_provider.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: vehicles.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: vehicles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        return _VehicleTile(
                          vehicle: v,
                          onSetDefault: () =>
                              ref.read(vehiclesProvider.notifier).setDefault(v.id),
                          onDelete: () =>
                              ref.read(vehiclesProvider.notifier).removeVehicle(v.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addVehicle',
        onPressed: () => _showAddDeviceModal(context, ref),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Device',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Vehicles',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paired Bluetooth devices',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.bluetooth_rounded,
              color: AppColors.accent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Vehicles Paired',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + Add Device to pair your vehicle\nfor automatic ride detection.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddDeviceModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _AddDeviceSheet(),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.vehicle,
    required this.onSetDefault,
    required this.onDelete,
  });

  final VehicleModel vehicle;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vehicle.isDefault
              ? AppColors.accent.withOpacity(0.5)
              : AppColors.divider,
          width: vehicle.isDefault ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bluetooth_rounded,
            color: AppColors.accent,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                vehicle.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (vehicle.isDefault)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${vehicle.typeLabel} · ${vehicle.shortAddress}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textSecondary),
          color: AppColors.surfaceCard,
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'default',
              child: Text('Set as Default',
                  style: TextStyle(color: AppColors.textPrimary)),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Remove',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
          onSelected: (v) {
            if (v == 'default') onSetDefault();
            if (v == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}

// ── Add Device Bottom Sheet ──────────────────────────────────────────────────

class _AddDeviceSheet extends ConsumerStatefulWidget {
  const _AddDeviceSheet();

  @override
  ConsumerState<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends ConsumerState<_AddDeviceSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bluetoothScanProvider.notifier).startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanAsync = ref.watch(bluetoothScanProvider);
    final height = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              const Text(
                'Scan for Devices',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              scanAsync.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          ref.read(bluetoothScanProvider.notifier).startScan(),
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.accent, size: 18),
                      label: const Text('Rescan',
                          style: TextStyle(color: AppColors.accent)),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a device to add it to your vehicles',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Results
          Expanded(
            child: scanAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accent),
                    SizedBox(height: 16),
                    Text('Scanning for Bluetooth devices…',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Scan failed: $e\nEnsure Bluetooth is on.',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (results) {
                if (results.isEmpty) {
                  return const Center(
                    child: Text(
                      'No devices found nearby.\nMake your device discoverable.',
                      style: TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(
                      color: AppColors.divider, height: 1),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(r.isBle ? Icons.bluetooth_audio : Icons.directions_car_rounded,
                            color: AppColors.accent, size: 20),
                      ),
                      title: Text(
                        r.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        r.address,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: r.rssi != null 
                        ? Text(
                            '${r.rssi} dBm',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          )
                        : null,
                      onTap: () {
                        final v = VehicleModel(
                          id: const Uuid().v4(),
                          name: r.name,
                          address: r.address,
                          isBle: r.isBle,
                          addedAt: DateTime.now(),
                          rssi: r.rssi ?? 0,
                        );
                        ref.read(vehiclesProvider.notifier).addVehicle(v);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${r.name} added!')),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
