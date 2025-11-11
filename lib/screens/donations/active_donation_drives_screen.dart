import 'package:flutter/material.dart';
import '../../models/donations/donation_model.dart';
import '../../services/api/donations_api.dart';
import '../../services/api/trash_pickups_api.dart';
import '../../screens/trash_pickups/trash_pickup_model.dart';

class ActiveDonationDrivesScreen extends StatefulWidget {
  const ActiveDonationDrivesScreen({super.key});

  @override
  State<ActiveDonationDrivesScreen> createState() =>
      _ActiveDonationDrivesScreenState();
}

class _ActiveDonationDrivesScreenState
    extends State<ActiveDonationDrivesScreen> {
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
      final completedPickups =
          pickups.where((p) => p.status == "completed").toList();

      if (completedPickups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("No completed trash pickups available for donation.")),
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
        SnackBar(
            content: Text(
                "✅ Donated ${selected.weightKg} kg of ${selected.wasteTypeDisplay}!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to donate: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ACTIVE DONATION DRIVES',
          style: TextStyle(
            color: green,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: green),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDrives,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: green))
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : _drives.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 150),
                          Center(
                            child: Text(
                              'No active donation drives available.',
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drives.length,
                        itemBuilder: (context, i) {
                          final drive = _drives[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border:
                                  Border.all(color: green.withOpacity(0.25)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.volunteer_activism_rounded,
                                          color: green,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              drive.title,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              drive.description,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Waste Type: ${drive.wasteType}",
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.recycling,
                                              size: 18),
                                          label: const Text('Donate'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => _donateTrash(drive),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
