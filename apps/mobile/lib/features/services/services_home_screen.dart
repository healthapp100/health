import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/responsive.dart';

/// Entry point for the Services module (Health Data is the existing Track tab — no separate
/// screen needed there). Reached from Home's quick actions rather than a 6th bottom-nav item,
/// consistent with the "flat nav doesn't scale past 5" decision this app already made for Labs.
class ServicesHomeScreen extends StatelessWidget {
  const ServicesHomeScreen({super.key});

  static const _sections = [
    (Icons.campaign_outlined, 'Daily Monitoring', 'Messages and advice from your care team', '/services/monitoring'),
    (Icons.play_circle_outline, 'Daily Videos', 'Short videos, available for a limited time', '/services/videos'),
    (Icons.science_outlined, 'Lab Test Support', 'Clinics and diagnostic centers near you', '/services/labs-directory'),
    (Icons.fitness_center_outlined, 'Health Kit Support', 'Devices and equipment for home monitoring', '/services/health-kits'),
    (Icons.medication_outlined, 'Medicines', 'Educational information about common medicines', '/services/medicines'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: ResponsiveContent(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _sections.length,
          itemBuilder: (context, index) {
            final (icon, title, subtitle, path) = _sections[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Icon(icon)),
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(path),
              ),
            );
          },
        ),
      ),
    );
  }
}
