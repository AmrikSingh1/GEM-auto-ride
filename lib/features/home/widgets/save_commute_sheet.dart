import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/commutes/providers/commutes_provider.dart';
import '../providers/active_ride_provider.dart';

Future<void> showSaveCommuteSheet(
    BuildContext context, WidgetRef ref, ActiveRideState rideState) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SaveCommuteSheet(rideState: rideState, ref: ref),
  );
}

class _SaveCommuteSheet extends ConsumerStatefulWidget {
  const _SaveCommuteSheet({required this.rideState, required this.ref});
  final ActiveRideState rideState;
  final WidgetRef ref;

  @override
  ConsumerState<_SaveCommuteSheet> createState() => _SaveCommuteSheetState();
}

class _SaveCommuteSheetState extends ConsumerState<_SaveCommuteSheet> {
  final _titleController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Heading
          const Text(
            'Save Commute',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Give your commute a title to find it easily later.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 24),

          // Title field
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Morning Commute',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Summary row
          _SummaryRow(
            startTime: _formatDateTime(widget.rideState.startTime),
            duration: widget.rideState.formattedTime,
            distance: widget.rideState.formattedDistance,
          ),

          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              // Discard
              Expanded(
                child: GestureDetector(
                  onTap: _saving
                      ? null
                      : () async {
                          await widget.ref
                              .read(activeRideProvider.notifier)
                              .discard();
                          widget.ref.read(commutesProvider.notifier).refresh();
                          if (mounted) Navigator.pop(context);
                        },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Text(
                      'DISCARD',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ending,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Save
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final title = _titleController.text.trim();
                          await widget.ref
                              .read(activeRideProvider.notifier)
                              .finish(
                                  title: title.isEmpty ? 'Commute' : title);
                          widget.ref.read(commutesProvider.notifier).refresh();
                          if (mounted) Navigator.pop(context);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _saving ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'SAVE COMMUTE',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.startTime,
    required this.duration,
    required this.distance,
  });

  final String startTime;
  final String duration;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.calendar_today_rounded,
            label: 'Started',
            value: startTime,
            color: AppColors.accent,
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          _SummaryItem(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: duration,
            color: AppColors.primary,
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          _SummaryItem(
            icon: Icons.straighten_rounded,
            label: 'Distance',
            value: distance,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
