import 'package:flutter/material.dart';
import 'header_footer.dart';
import 'background_image_wrapper.dart';

class AboutPage extends StatefulWidget {
  final String? username;

  const AboutPage({Key? key, this.username}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 0.7, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      body: HeaderFooter(
        title: 'About Us',
        child: BackgroundImageWrapper(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.05,
              vertical: screenSize.height * 0.03,
            ),
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.username != null &&
                              widget.username!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom: screenSize.height * 0.02),
                            ),
                          SizedBox(height: screenSize.height * 0.04),
                          Text(
                            'Development Team',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.03),
                          _buildTeamGrid(context, screenSize, isPortrait),
                          SizedBox(height: screenSize.height * 0.05),
                          _buildAppInfoCard(context, screenSize),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context, Size screenSize) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          children: [
            Text(
              'SpotIO - Parking App',
              style: TextStyle(
                fontSize: screenSize.width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              'Our smart parking solution simplifies parking management with real-time '
              'slot tracking, digital payments, and automated booking system. '
              'Designed for efficiency and user convenience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenSize.width * 0.04,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: screenSize.width * 0.035,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamGrid(
      BuildContext context, Size screenSize, bool isPortrait) {
    final teamMembers = [
      _TeamMember(
        name: 'Athish Raj U K',
        role: 'Developer',
        icon: Icons.code,
      ),
      _TeamMember(
        name: 'Helna J',
        role: 'Developer',
        icon: Icons.design_services,
      ),
      _TeamMember(
        name: 'Sandra P',
        role: 'Developer',
        icon: Icons.storage,
      ),
      _TeamMember(
        name: 'Athul Devaraj M',
        role: 'Developer',
        icon: Icons.engineering,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isPortrait ? 2 : 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: screenSize.width * 0.04,
        mainAxisSpacing: screenSize.width * 0.04,
      ),
      itemCount: teamMembers.length,
      itemBuilder: (context, index) {
        return _buildTeamMemberCard(
          context,
          screenSize,
          teamMembers[index],
        );
      },
    );
  }

  Widget _buildTeamMemberCard(
      BuildContext context, Size screenSize, _TeamMember member) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.03),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenSize.width * 0.2,
              height: screenSize.width * 0.2,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                member.icon,
                size: screenSize.width * 0.1,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              member.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenSize.height * 0.01),
            Text(
              member.role,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenSize.width * 0.035,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  final IconData icon;

  _TeamMember({
    required this.name,
    required this.role,
    required this.icon,
  });
}
