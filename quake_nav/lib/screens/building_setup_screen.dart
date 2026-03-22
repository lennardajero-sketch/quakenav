import 'package:flutter/material.dart';

import '../models/buildings.dart';
import '../services/auth_service.dart';

class BuildingSetupScreen extends StatefulWidget {
  final AuthService authService;

  const BuildingSetupScreen({
    super.key,
    required this.authService,
  });

  @override
  State<BuildingSetupScreen> createState() => _BuildingSetupScreenState();
}

class _BuildingSetupScreenState extends State<BuildingSetupScreen> {
  String? _selectedBuilding;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final building = _selectedBuilding;
    if (building == null || building.isEmpty) {
      setState(() => _error = 'Please select your building.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.authService.updateCurrentUserBuilding(building);
    } catch (_) {
      setState(() {
        _error = 'Failed to save building. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your building to enable assigned evacuation routing.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedBuilding,
              decoration: const InputDecoration(labelText: 'Building'),
              items: kBuildings
                  .map(
                    (building) => DropdownMenuItem<String>(
                      value: building,
                      child: Text(building),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() => _selectedBuilding = value);
                    },
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save building'),
            ),
          ],
        ),
      ),
    );
  }
}
