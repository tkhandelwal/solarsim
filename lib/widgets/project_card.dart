// lib/widgets/project_card.dart
import 'package:flutter/material.dart';
import 'package:solar_sim/models/project.dart';
import 'package:intl/intl.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildSystemTypeChip(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Location: ${project.location.address}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Modified: ${dateFormat.format(project.modifiedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSystemTypeChip() {
    Color chipColor;
    String label;
    
    switch (project.systemType) {
      case SystemType.gridConnected:
        chipColor = Colors.blue;
        label = 'Grid';
        break;
      case SystemType.standalone:
        chipColor = Colors.green;
        label = 'Off-Grid';
        break;
      case SystemType.pumping:
        chipColor = Colors.purple;
        label = 'Pumping';
        break;
      case SystemType.solarThermal:
        chipColor = Colors.red;
        label = 'Thermal';
        break;
      case SystemType.hybrid:
        chipColor = Colors.amber;
        label = 'Hybrid';
        break;
    }
    
    return Chip(
      backgroundColor: chipColor.withOpacity(0.2),
      side: BorderSide(color: chipColor),
      label: Text(
        label,
        style: TextStyle(color: chipColor),
      ),
    );
  }
}
