import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/buildings.dart';
import '../services/auth_service.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _building;
  String? _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _authService.getCurrentUserAccountData();
      if (!mounted) return;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _building = data['building'];
        _email = data['email'];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load account details.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if ((_building ?? '').trim().isEmpty) {
      setState(() => _error = 'Please select your building.');
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _error = 'Username is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _authService.updateCurrentUserAccount(
        name: _nameController.text,
        address: _addressController.text,
        username: _usernameController.text,
        building: _building!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to save account details.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dedupedBuildings = LinkedHashSet<String>.from(
      kBuildings.map((value) => value.trim()),
    ).toList();
    if (_building != null &&
        _building!.trim().isNotEmpty &&
        !dedupedBuildings.contains(_building)) {
      dedupedBuildings.add(_building!.trim());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Manage account')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: (_building ?? '').trim().isEmpty ? null : _building,
                  decoration: const InputDecoration(labelText: 'Building'),
                  items: dedupedBuildings
                      .map(
                        (building) => DropdownMenuItem<String>(
                          value: building,
                          child: Text(
                            building,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _building = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _email ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    helperText: 'Email changes are disabled for now.',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save changes'),
                  ),
                ),
              ],
            ),
    );
  }
}

