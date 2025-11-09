import 'package:flutter/material.dart';
import '../../models/donations/donation_model.dart';
import '../../services/api/donations_api.dart';
import '../../services/api/trash_pickups_api.dart';
import '../../screens/trash_pickups/trash_pickup_model.dart';

class ActiveDonationDrivesScreen extends StatefulWidget {
  const ActiveDonationDrivesScreen({super.key});

  @override
  State<ActiveDonationDrivesScreen> createState() => _ActiveDonationDrivesScreenState();
}

class _ActiveDonationDrivesScreenState extends State<ActiveDonationDrivesScreen> {
  bool _loading = true;
  String? _error;
  List<DonationDrive> _drives = [];

  @override
  void initState() {
    super.initState();
    _loadDrives();
  }

  Future<void> _loadDrives() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final drives = await DonationsApi.getAllDrives();
      setState(() => _drives = drives);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _donateTrash(DonationDrive drive) async {
    try {
      final pickups = await TrashPickupsApi.getAll();
      final completedPickups = pickups.where((p) => p.status == "completed").toList();

      if (completedPickups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No completed trash pickups available for donation.")),
        );
        return;
      }

      final selected = await showDialog<TrashPickup>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text("Select Trash Pickup to Donate"),
          children: completedPickups.map((pickup) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, pickup),
              child: Text("${pickup.wasteTypeDisplay} • ${pickup.weightKg} kg"),
            );
          }).toList(),
        ),
      );

      if (selected == null) return;

      await DonationsApi.donateTrash(drive.id!, selected.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Donated ${selected.weightKg} kg of ${selected.wasteTypeDisplay}!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to donate: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Donation Drives')),
      body: RefreshIndicator(
        onRefresh: _loadDrives,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                    )
                  ])
                : _drives.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No active donation drives available.')),
                      ])
                    : ListView.builder(
                        itemCount: _drives.length,
                        itemBuilder: (context, i) {
                          final drive = _drives[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.recycling, color: Colors.green),
                              title: Text(drive.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Waste Type: ${drive.wasteType}\n${drive.description}',
                              ),
                              isThreeLine: true,
                              trailing: FilledButton(
                                onPressed: () => _donateTrash(drive),
                                child: const Text('Donate'),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
