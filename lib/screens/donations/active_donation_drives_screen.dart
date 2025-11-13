import 'package:flutter/material.dart';
import '../../models/donations/donation_model.dart';
import '../../services/api/donations_api.dart';

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

  void _showDriveInfo(DonationDrive drive) {
    const green = Color(0xFF015704);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: green,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                drive.title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drive.description,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.recycling, color: green, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Waste Type: ${drive.wasteType}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: green, size: 20),
                const SizedBox(width: 8),
                Text(
                  drive.isActive ? "Status: Active" : "Status: Inactive",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: drive.isActive ? green : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Text(
                          '⚠️ Error loading drives:\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drives.length,
                        itemBuilder: (context, i) {
                          final drive = _drives[i];

                          return InkWell(
                            onTap: () => _showDriveInfo(drive),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
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
                                border: Border.all(
                                  color: green.withOpacity(0.25),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Waste Type: ${drive.wasteType}",
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
