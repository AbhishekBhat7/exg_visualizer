 
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:flutter/material.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.white,
      appBar: AppBar(
        backgroundColor: MainColors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: const Text(
          'Devices',
          style: TextStyle(
            color: MainColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: false,
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          DeviceCard(
            title: 'Device Name',
            description: 'Configure Type: Mono Gate\n'
                'Configured For: Sprint Exercises\n'
                'Slaves Connected: --\n'
                'Battery: 78%',
            actionText: '',
            actionColor: MainColors.primaryColor,
            imageUrl: 'assets/images/TimingGate.png',
          ),
          SizedBox(height: 16),
          DeviceCard(
            icon: Icons.power_off_outlined,
            title: 'No Device Connected',
            description: '',
            actionText: 'Connect Now',
            actionColor: MainColors.primaryColor,
            imageUrl: 'assets/images/TimingGate.png',
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionText;
  final Color actionColor;
  final String imageUrl;
  final IconData? icon;

  const DeviceCard({
    super.key,
    required this.title,
    required this.description,
    required this.actionText,
    required this.actionColor,
    required this.imageUrl,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MainColors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: MainColors.primaryColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            Positioned(
              right: -76,
              top: -25,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: MainColors.primaryColor, width: 2),
                  color: MainColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -72,
              top: -15,
              child: Container(
                width: 230,
                height: 230,
                decoration: const BoxDecoration(
                  color: MainColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -45,
              top: 10,
              child: Container(
                width: 187,
                height: 187,
                decoration: const BoxDecoration(
                  color: MainColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: icon != null && description.isEmpty
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          if (icon != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Icon(
                                icon,
                                color: hint.customGray,
                                size: 65,
                              ),
                            ),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: description.isNotEmpty
                                  ? MainColors.primaryColor
                                  : MainColors.black,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: hint.customGray,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (actionText.isNotEmpty)
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                foregroundColor: MainColors.white,
                                backgroundColor: actionColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                actionText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Image.asset(
                imageUrl,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
