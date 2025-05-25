import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'header_footer.dart';
import 'background_image_wrapper.dart';

class UserReportPage extends StatefulWidget {
  final String username;

  const UserReportPage({Key? key, required this.username}) : super(key: key);

  @override
  _UserReportPageState createState() => _UserReportPageState();
}

class _UserReportPageState extends State<UserReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: HeaderFooter(
        title: 'My Reports',
        child: BackgroundImageWrapper(
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reports')
                  .where('username', isEqualTo: widget.username)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading reports'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return Center(child: Text('No reports submitted yet'));
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
                                Row(
                                  children: [
                                    Text('Status: '),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? Colors.orange
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        data['status'].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                    'Reported at: ${DateTime.parse(data['timestamp'].toDate().toString()).toString()}'),
                                if (!isPending) ...[
                                  SizedBox(height: 8),
                                  Text('Resolved by: ${data['resolved_by']}'),
                                  SizedBox(height: 8),
                                  Text(
                                      'Resolved at: ${DateTime.parse(data['resolved_at'].toDate().toString()).toString()}'),
                                ],
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
