import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/profile.dart';
import 'profile_providers.dart';

/// Family & dependents — a patient managing a child's or elderly parent's care from their own
/// account (BLUEPRINT.md §5.1). `care_relationships` supports linking a dependent's own account
/// (`dependentProfileId`) for someone who has one, but this screen only offers the
/// display-name-only path (a minor typically has no login of their own) — linking an existing
/// account is a bigger flow (search + consent from that account) intentionally left for later.
class DependentsScreen extends ConsumerWidget {
  const DependentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dependentsAsync = ref.watch(dependentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family & dependents')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDependentSheet(context, ref),
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add dependent'),
      ),
      body: dependentsAsync.when(
        data: (dependents) {
          if (dependents.isEmpty) {
            return ActionableEmptyState(
              icon: Icons.family_restroom_outlined,
              title: 'No dependents added yet',
              subtitle: 'Add a family member to manage their care from your account.',
              actionLabel: 'Add dependent',
              onAction: () => _showAddDependentSheet(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dependents.length,
            itemBuilder: (context, index) {
              final dep = dependents[index];
              return AnimatedListEntry(
                index: index,
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(dep.displayName),
                    subtitle: Text(_relationshipLabel(dep.relationship)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove',
                      onPressed: () => _confirmRemove(context, ref, dep),
                    ),
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
    );
  }

  String _relationshipLabel(String relationship) {
    return relationship[0].toUpperCase() + relationship.substring(1);
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, CareRelationship dep) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove dependent?'),
        content: Text('${dep.displayName} will no longer be linked to your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(profileServiceProvider).removeDependent(dep.id);
      ref.invalidate(dependentsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove. $e')));
    }
  }

  Future<void> _showAddDependentSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddDependentSheet(),
    );
  }
}

class _AddDependentSheet extends ConsumerStatefulWidget {
  const _AddDependentSheet();

  @override
  ConsumerState<_AddDependentSheet> createState() => _AddDependentSheetState();
}

class _AddDependentSheetState extends ConsumerState<_AddDependentSheet> {
  static const _relationships = ['child', 'parent', 'spouse', 'sibling', 'other'];

  final _nameController = TextEditingController();
  String _relationship = 'child';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    try {
      await ref.read(profileServiceProvider).addDependent(
            displayName: name,
            relationship: _relationship,
          );
      ref.invalidate(dependentsProvider);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add. $e')));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a dependent', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            decoration: const InputDecoration(labelText: 'Relationship'),
            items: _relationships
                .map((r) => DropdownMenuItem(value: r, child: Text(r[0].toUpperCase() + r.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => _relationship = v ?? _relationship),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AnimatedConfirmButton(
              label: 'Add',
              successLabel: 'Added',
              onPressed: _submit,
              onSuccessComplete: () {
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
