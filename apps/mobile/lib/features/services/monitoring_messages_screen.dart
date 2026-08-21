import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import 'services_providers.dart';

class MonitoringMessagesScreen extends ConsumerWidget {
  const MonitoringMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(ownMonitoringMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Monitoring')),
      body: ResponsiveContent(
        child: messagesAsync.when(
          data: (messages) {
            if (messages.isEmpty) {
              return const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No messages yet',
                subtitle: 'Your care team will send updates and advice here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return AnimatedListEntry(
                  index: index,
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        message.isBroadcast ? Icons.campaign_outlined : Icons.person_outline,
                      ),
                      title: Text(message.title),
                      subtitle: Text(message.body),
                      trailing: Text(
                        DateFormat('d MMM').format(message.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      isThreeLine: message.body.length > 40,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonList(count: 3),
          ),
          error: (e, _) => ErrorState(message: '$e'),
        ),
      ),
    );
  }
}
