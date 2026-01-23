 
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TimingGateScreen extends StatelessWidget {
  const TimingGateScreen({Key? key}) : super(key: key);
 
  Widget buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String batteryLevel,
    required IconData trackModeIcon,
    required int gates,
    required String connectionStatus,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage('assets/HomeDash/c.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), BlendMode.darken),
            ),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: AppTextStyles.bold.copyWith(
                  color: MainColors.white,
                ),
              ),
              const SizedBox(height: 18), 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        connectionStatus,
                        style: AppTextStyles.regular
                            .copyWith(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.battery_full, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        batteryLevel,
                        style: AppTextStyles.regular
                            .copyWith(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(trackModeIcon, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Track Mode',
                        style: AppTextStyles.regular
                            .copyWith(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.wifi_tethering, color: Colors.white),
                      const SizedBox(width: 1),
                      Text(
                        '$gates Gates',
                        style: AppTextStyles.regular
                            .copyWith(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildMyPlansCard(
      String title,
      String subtitle,
      IconData icon,
      String batteryLevel,
      IconData trackModeIcon,
      int gates,
      String connectionStatus,
      VoidCallback onTap) {
    return buildCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      batteryLevel: batteryLevel,
      trackModeIcon: trackModeIcon,
      gates: gates,
      connectionStatus: connectionStatus,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: MainColors.white,
        shadowColor: MainColors.black,
        elevation: 1,
        toolbarHeight: 55,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icon/Devices_icon.svg',
              height: 26,
              width: 26,
            ),
            const SizedBox(width: 8),
            Text('Devices', style: AppTextStyles.header.copyWith()),
          ],
        ),
      ),
      backgroundColor: MainColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // First card
            // _buildMyPlansCard(
            //   'Timing Gate',
            //   'Connected',
            //   Icons.wifi,
            //   '78%',
            //   Icons.track_changes,
            //   4,
            //   'Connected',
            //   () {
            //     print("Timing Gate Clicked");
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => BluetoothPage(email: '',)),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
