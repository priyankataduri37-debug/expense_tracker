import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sync_provider.dart';

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SyncProvider>();
    final scheme = Theme.of(context).colorScheme;
    final n = s.pendingCount;
    final changes = n == 1 ? '1 change' : '$n changes';

    Widget leading;
    String label;
    Color color = scheme.onSurfaceVariant;

    if (!s.isOnline) {
      leading = Icon(Icons.cloud_off, size: 16, color: color);
      label = n == 0 ? 'Offline' : 'Offline • $changes will sync later';
    } else if (s.state == SyncState.syncing) {
      leading = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      label = 'Syncing...';
    } else if (s.state == SyncState.failed) {
      color = scheme.error;
      leading = Icon(Icons.warning_amber_rounded, size: 16, color: color);
      label = 'Sync failed • tap to retry';
    } else if (n > 0) {
      leading = Icon(Icons.cloud_upload_outlined, size: 16, color: color);
      label = '$changes waiting';
    } else {
      leading = Icon(Icons.cloud_done_outlined, size: 16, color: color);
      label = 'Synced';
    }

    return InkWell(
      onTap: s.state == SyncState.failed ? () => s.syncNow() : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}