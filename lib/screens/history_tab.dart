import 'package:flutter/material.dart';

import '../models/print_history_item.dart';
import '../utils/date_formatter.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.items});

  final List<PrintHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _HistoryItemCard(item: item);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({required this.item});

  final PrintHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(item.subtitle),
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatDateTime(item.timestamp),
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
