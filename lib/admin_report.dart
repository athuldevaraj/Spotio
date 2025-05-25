import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'header_footer.dart';
import 'background_image_wrapper.dart';

class AdminReportPage extends StatefulWidget {
  final String username;

  const AdminReportPage({Key? key, required this.username}) : super(key: key);

  @override
  _AdminReportPageState createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateReportStatus(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'done',
        'resolved_by': widget.username,
        'resolved_at': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as resolved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: HeaderFooter(
        title: 'Admin Reports',
        child: BackgroundImageWrapper(
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading reports'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return Center(child: Text('No reports available'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var report = snapshot.data!.docs[index];
                    var data = report.data() as Map<String, dynamic>;
                    bool isPending = data['status'] == 'pending';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      color: isPending ? Colors.red[100] : Colors.green[100],
                      child: ExpansionTile(
                        title: Text(
                          data['description'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Slot: ${data['slot']}',
                          style: TextStyle(color: Colors.black54),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Username: ${data['username']}'),
                                SizedBox(height: 8),
                                Text('Status: ${data['status']}'),
                                SizedBox(height: 8),
                                Text(
                                    'Reported at: ${DateTime.parse(data['timestamp'].toDate().toString()).toString()}'),
                                SizedBox(height: 16),
                                if (isPending)
                                  ElevatedButton(
                                    onPressed: () =>
                                        _updateReportStatus(report.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    child: Text('MARK AS RESOLVED'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
