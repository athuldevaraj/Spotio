import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'background_image_wrapper.dart';
import 'header_footer.dart';

class StatisticsPage extends StatefulWidget {
  final String username;

  const StatisticsPage({Key? key, required this.username}) : super(key: key);

  @override
  _AdminStatisticsPageState createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  late TabController _tabController;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // Data for charts
  List<Map<String, dynamic>> recordsData = [];
  List<Map<String, dynamic>> reportsData = [];

  // Statistics
  int totalParkings = 0;
  double averageParkingTime = 0;
  int totalReports = 0;
  Map<String, int> reportsByStatus = {};
  Map<String, int> parkingsByHour = {};
  Map<String, int> reportsBySlot = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch records
      QuerySnapshot recordsSnapshot = await FirebaseFirestore.instance
          .collection('Records')
          .orderBy('entryTime', descending: true)
          .get();

      // Fetch reports
      QuerySnapshot reportsSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .get();

      // Process records data
      recordsData = recordsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Process reports data
      reportsData = reportsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Calculate statistics
      _calculateStatistics();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    // Records statistics
    totalParkings = recordsData.length;

    // Calculate average parking time
    int totalMinutes = 0;
    int validRecords = 0;

    for (var record in recordsData) {
      if (record['entryTime'] != null && record['exitTime'] != null) {
        Timestamp entryTimestamp = record['entryTime'];
        Timestamp exitTimestamp = record['exitTime'];

        int durationMinutes = exitTimestamp
            .toDate()
            .difference(entryTimestamp.toDate())
            .inMinutes;
        if (durationMinutes > 0) {
          totalMinutes += durationMinutes;
          validRecords++;
        }
      }
    }

    averageParkingTime = validRecords > 0 ? totalMinutes / validRecords : 0;

    // Parkings by hour of day
    parkingsByHour = {};
    for (var record in recordsData) {
      if (record['entryTime'] != null) {
        Timestamp entryTimestamp = record['entryTime'];
        int hour = entryTimestamp.toDate().hour;
        parkingsByHour[hour.toString()] =
            (parkingsByHour[hour.toString()] ?? 0) + 1;
      }
    }

    // Report statistics
    totalReports = reportsData.length;

    // Reports by status
    reportsByStatus = {};
    for (var report in reportsData) {
      String status = report['status'] ?? 'Unknown';
      reportsByStatus[status] = (reportsByStatus[status] ?? 0) + 1;
    }

    // Reports by slot
    reportsBySlot = {};
    for (var report in reportsData) {
      String slot = report['slot'] ?? 'Unknown';
      reportsBySlot[slot] = (reportsBySlot[slot] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeaderFooter(
        title: "Admin Statistics",
        child: BackgroundImageWrapper(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildStatisticsContent(),
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive design based on available width
        final isSmallScreen = constraints.maxWidth < 600;

        // In the _buildStatisticsContent() method, replace the Column with:
        return Column(
          children: [
            // Summary cards section with adjustable height based on screen size
            Container(
              height: isSmallScreen ? 110 : 120,
              child: _buildSummaryCards(),
            ),
            SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Parking Analytics'),
                Tab(text: 'Reports Analytics'),
              ],
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              isScrollable:
                  isSmallScreen, // Make tabs scrollable on small screens
            ),
            // Wrap the Expanded widget with Flexible to allow it to shrink if needed
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildParkingAnalytics(isSmallScreen),
                  _buildReportsAnalytics(isSmallScreen),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    // Calculate responsive width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        screenWidth < 600 ? 130.0 : 140.0; // Smaller cards on small screens
    final cardPadding =
        screenWidth < 600 ? 6.0 : 8.0; // Less padding on small screens

    return Container(
      height: screenWidth < 600
          ? 100
          : 110, // Adjust container height based on screen size
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        thickness: 6,
        radius: Radius.circular(8),
        child: ListView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 600 ? 4 : 8,
              vertical: screenWidth < 600 ? 2 : 4),
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            _buildStatCard('Total Parkings', totalParkings.toString(),
                Icons.local_parking, cardWidth, cardPadding),
            _buildStatCard(
                'Avg. Time',
                '${averageParkingTime.toStringAsFixed(0)} mins',
                Icons.timer,
                cardWidth,
                cardPadding),
            _buildStatCard('Total Reports', totalReports.toString(),
                Icons.report_problem, cardWidth, cardPadding),
            _buildStatCard('Open Issues', '${reportsByStatus['Open'] ?? 0}',
                Icons.error_outline, cardWidth, cardPadding),
            _buildStatCard('Resolved', '${reportsByStatus['Resolved'] ?? 0}',
                Icons.check_circle_outline, cardWidth, cardPadding),
            _buildStatCard(
                'In Progress',
                '${reportsByStatus['In Progress'] ?? 0}',
                Icons.pending_actions,
                cardWidth,
                cardPadding),
          ],
        ),
      ),
    );
  }

// Updated stat card to accept width and padding parameters
  Widget _buildStatCard(
      String title, String value, IconData icon, double width, double padding) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(padding),
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal, size: isSmallScreen ? 24 : 28),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isSmallScreen ? 1 : 2),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingAnalytics(bool isSmallScreen) {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      thickness: 6,
      radius: Radius.circular(8),
      child: ListView(
        controller: _verticalController,
        padding: EdgeInsets.all(16),
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          _sectionTitle('Parkings by Hour of Day'),
          SizedBox(height: 8),
          Container(
            height: isSmallScreen ? 250 : 300,
            padding: EdgeInsets.all(8),
            child: _buildHourlyBarChart(),
          ),
          SizedBox(height: 24),
          _sectionTitle('Recent Parking Records'),
          SizedBox(height: 8),
          _buildRecentRecordsTable(isSmallScreen),
          // Add extra padding at the bottom
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReportsAnalytics(bool isSmallScreen) {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      thickness: 6,
      radius: Radius.circular(8),
      child: ListView(
        controller: _verticalController,
        padding: EdgeInsets.all(16),
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          _sectionTitle('Reports by Status'),
          SizedBox(height: 8),
          Container(
            height: isSmallScreen ? 250 : 300,
            padding: EdgeInsets.all(8),
            child: _buildStatusPieChart(),
          ),
          SizedBox(height: 24),
          _sectionTitle('Reports by Slot'),
          SizedBox(height: 8),
          Container(
            height: isSmallScreen ? 250 : 300,
            padding: EdgeInsets.all(8),
            child: _buildSlotBarChart(),
          ),
          SizedBox(height: 24),
          _sectionTitle('Recent Reports'),
          SizedBox(height: 8),
          _buildRecentReportsTable(isSmallScreen),
          // Add extra padding at the bottom
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildHourlyBarChart() {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < 24; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: parkingsByHour[i.toString()] != null
                  ? parkingsByHour[i.toString()]!.toDouble()
                  : 0,
              color: Colors.teal,
              width: 14,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${group.x}:00 - ${(group.x + 1) % 24}:00\n${rod.toY.toInt()} parkings',
                TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 3 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${value.toInt()}h',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }
                return SizedBox();
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        barGroups: barGroups,
        minY: 0, // Ensure chart starts at 0
      ),
    );
  }

  Widget _buildStatusPieChart() {
    List<PieChartSectionData> sections = [];
    List<Color> statusColors = [
      Colors.teal,
      Colors.red,
      Colors.amber,
      Colors.blue,
      Colors.purple
    ];
    int colorIndex = 0;

    reportsByStatus.forEach((status, count) {
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '$status\n${count}',
          color: statusColors[colorIndex % statusColors.length],
          radius: 100,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }

  Widget _buildSlotBarChart() {
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    reportsBySlot.forEach((slot, count) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.redAccent,
              width: 14,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String slot = reportsBySlot.keys.elementAt(group.x);
              return BarTooltipItem(
                '$slot: ${rod.toY.toInt()} reports',
                TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < reportsBySlot.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      reportsBySlot.keys.elementAt(value.toInt()),
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return SizedBox();
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        barGroups: barGroups,
        minY: 0, // Ensure chart starts at 0
      ),
    );
  }

  Widget _buildRecentRecordsTable(bool isSmallScreen) {
    final ScrollController horizontalRecordsController = ScrollController();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      height: isSmallScreen ? 250 : 300,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Sticky header for data table
          Container(
            color: Colors.grey.shade100,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('User',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Vehicle No.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Entry Time',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Exit Time',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Duration',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: horizontalRecordsController,
              thumbVisibility: true,
              thickness: 6,
              child: SingleChildScrollView(
                controller: horizontalRecordsController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  // Ensure the content is wide enough to trigger horizontal scroll on small screens
                  width: isSmallScreen ? 600 : null,
                  child: ListView.builder(
                    itemCount:
                        recordsData.length > 15 ? 15 : recordsData.length,
                    itemBuilder: (context, index) {
                      final record = recordsData[index];
                      DateTime? entryTime = record['entryTime']?.toDate();
                      DateTime? exitTime = record['exitTime']?.toDate();
                      String duration = '---';

                      if (entryTime != null && exitTime != null) {
                        int minutes = exitTime.difference(entryTime).inMinutes;
                        duration = '${minutes} mins';
                      }

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                          color: index % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade50,
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(record['username'] ?? '---'),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(record['vehicleNumber'] ?? '---'),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(entryTime != null
                                  ? DateFormat('MMM d, HH:mm').format(entryTime)
                                  : '---'),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(exitTime != null
                                  ? DateFormat('MMM d, HH:mm').format(exitTime)
                                  : '---'),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(duration),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsTable(bool isSmallScreen) {
    final ScrollController horizontalReportsController = ScrollController();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      height: isSmallScreen ? 250 : 300,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Sticky header for data table
          Container(
            color: Colors.grey.shade100,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('User',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Slot',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Time',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 4,
                  child: Text('Description',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: horizontalReportsController,
              thumbVisibility: true,
              thickness: 6,
              child: SingleChildScrollView(
                controller: horizontalReportsController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  // Ensure the content is wide enough to trigger horizontal scroll on small screens
                  width: isSmallScreen ? 600 : null,
                  child: ListView.builder(
                    itemCount:
                        reportsData.length > 15 ? 15 : reportsData.length,
                    itemBuilder: (context, index) {
                      final report = reportsData[index];
                      DateTime? timestamp = report['timestamp']?.toDate();

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                          color: index % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade50,
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(report['username'] ?? '---'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(report['slot'] ?? '---'),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(report['status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  report['status'] ?? 'Unknown',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(timestamp != null
                                  ? DateFormat('MMM d, HH:mm').format(timestamp)
                                  : '---'),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                report['description'] ?? '---',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Open':
        return Colors.red;
      case 'In Progress':
        return Colors.amber.shade700;
      case 'Resolved':
        return Colors.teal;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
