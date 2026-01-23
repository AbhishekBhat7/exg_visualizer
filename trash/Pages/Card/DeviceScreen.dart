// import 'package:aikyamm/BLOC/Dashboard/Pages/Devices/Pages/BLE/BleConnectionManager.dart';
// import 'package:aikyamm/BLOC/Dashboard/Pages/Devices/Pages/BLE/ble3.dart';
// import 'package:aikyamm/BLOC/Libraries/Colors/Colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// class DevicesScreen extends StatefulWidget {
//   final String email;
//   const DevicesScreen({super.key, required this.email});

//   @override
//   State<DevicesScreen> createState() => _DevicesScreenState();
// }

// class _DevicesScreenState extends State<DevicesScreen> {
//   final ble = BleConnectionManager.instance;
//   int? _batteryPercent;
//   bool _loadingBattery = false;

//   @override
//   void initState() {
//     super.initState();
//     ble.connectedDeviceNotifier.addListener(_onDeviceChanged);
//     _onDeviceChanged();
//   }

//   @override
//   void dispose() {
//     ble.connectedDeviceNotifier.removeListener(_onDeviceChanged);
//     super.dispose();
//   }

//   void _onDeviceChanged() {
//     final device = ble.connectedDevice;
//     if (device == null) {
//       setState(() => _batteryPercent = null);
//       return;
//     }
//     _readBattery();
//   }

//   Future<void> _readBattery() async {
//     setState(() => _loadingBattery = true);
//     try {
//       final level = await ble.readBatteryLevel();
//       if (!mounted) return;
//       setState(() => _batteryPercent = level);
//     } finally {
//       if (mounted) setState(() => _loadingBattery = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         backgroundColor: MainColors.white,
//         elevation: 1,
//         automaticallyImplyLeading: false,
//         title: const Text(
//           'Devices',
//           style: TextStyle(
//             color: MainColors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 28,
//           ),
//         ),
//         centerTitle: false,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: MainColors.black),
//             onPressed: ble.isConnected ? _readBattery : null,
//             tooltip: 'Refresh battery',
//           ),
//         ],
//       ),
//       body: ValueListenableBuilder<BluetoothDevice?>(
//         valueListenable: ble.connectedDeviceNotifier,
//         builder: (context, device, _) {
//           final bool isConnected = device != null;

//           return ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               if (isConnected)
//                 DeviceCard(
//                   title: _deviceName(device!),
//                   description: 'Configure Type: Mono Gate\n'
//                       'Configured For: Sprint Exercises\n'
//                       'Slaves Connected: --\n'
//                       'Battery: ${_loadingBattery ? '...' : (_batteryPercent?.toString() ?? '--')}%',
//                   actionText: '',
//                   actionColor: MainColors.primaryColor,
//                   imageUrl: 'assets/images/TimingGate.png',
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => BluetoothPage(email: widget.email),
//                       ),
//                     );
//                   },
//                 )
//               else
//                 DeviceCard(
//                   icon: Icons.power_off_outlined,
//                   title: 'No Device Connected',
//                   description: '',
//                   actionText: 'Connect Now',
//                   actionColor: MainColors.primaryColor,
//                   imageUrl: 'assets/images/TimingGate.png',
//                   onActionPressed: () async {
//                     await Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) =>   BluetoothPage(email: widget.email)),
//                     );
//                     // If user connects, notifier will rebuild automatically
//                   },
//                 ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   String _deviceName(BluetoothDevice device) {
//     try {
//       if (device.platformName.isNotEmpty) return device.platformName;
//     } catch (_) {}
//     return device.remoteId.toString();
//   }
// }

// class DeviceCard extends StatelessWidget {
//   final String title;
//   final String description;
//   final String actionText;
//   final Color actionColor;
//   final String imageUrl;
//   final IconData? icon;
//   final VoidCallback? onActionPressed;
//   final VoidCallback? onTap;

//   const DeviceCard({
//     super.key,
//     required this.title,
//     required this.description,
//     required this.actionText,
//     required this.actionColor,
//     required this.imageUrl,
//     this.icon,
//     this.onActionPressed,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final radius = BorderRadius.circular(20);

//     return Card(
//       color: MainColors.white,
//       elevation: 2,
//       clipBehavior: Clip.antiAlias,
//       shape: RoundedRectangleBorder(
//         borderRadius: radius,
//         side: BorderSide(
//           color: MainColors.primaryColor.withOpacity(0.4),
//           width: 1.5,
//         ),
//       ),
//       child: InkWell(
//         borderRadius: radius,
//         onTap: onTap,
//         child: SizedBox(
//           height: 180,
//           child: Stack(
//             children: [
//               Positioned(
//                 right: -76,
//                 top: -25,
//                 child: Container(
//                   width: 250,
//                   height: 250,
//                   decoration: BoxDecoration(
//                     border:
//                         Border.all(color: MainColors.primaryColor, width: 2),
//                     color: MainColors.white,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: -72,
//                 top: -15,
//                 child: Container(
//                   width: 230,
//                   height: 230,
//                   decoration: const BoxDecoration(
//                     color: MainColors.primaryColor,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: -45,
//                 top: 10,
//                 child: Container(
//                   width: 187,
//                   height: 187,
//                   decoration: const BoxDecoration(
//                     color: MainColors.white,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 16,
//                         horizontal: 20,
//                       ),
//                       child: SingleChildScrollView(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisAlignment: icon != null && description.isEmpty
//                               ? MainAxisAlignment.center
//                               : MainAxisAlignment.start,
//                           children: [
//                             if (icon != null)
//                               Padding(
//                                 padding: const EdgeInsets.only(bottom: 5),
//                                 child: Icon(
//                                   icon,
//                                   color:
//                                       hint.customGray,
//                                   size: 65,
//                                 ),
//                               ),
//                             Text(
//                               title,
//                               style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w700,
//                                 color: description.isNotEmpty
//                                     ? MainColors.primaryColor
//                                     : MainColors.black,
//                               ),
//                             ),
//                             if (description.isNotEmpty) ...[
//                               const SizedBox(height: 12),
//                               Text(
//                                 description,
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: hint.customGray,
//                                   height: 1.4,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                             ],
//                             if (actionText.isNotEmpty)
//                               ElevatedButton(
//                                 onPressed: onActionPressed ?? () {},
//                                 style: ElevatedButton.styleFrom(
//                                   foregroundColor: MainColors.white,
//                                   backgroundColor: actionColor,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 20,
//                                     vertical: 10,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   elevation: 2,
//                                 ),
//                                 child: Text(
//                                   actionText,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const Expanded(flex: 2, child: SizedBox()),
//                 ],
//               ),
//               Positioned(
//                 right: 0,
//                 top: 0,
//                 bottom: 0,
//                 child: Image.asset(
//                   imageUrl,
//                   width: 150,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
 
import 'package:exg_visualizer/BLE/ble.dart';
import 'package:exg_visualizer/BLE/BleConnectionManager.dart';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DevicesScreen extends StatefulWidget {
  final String email;
  const DevicesScreen({super.key, required this.email});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final ble = BleConnectionManager.instance;
  int? _batteryPercent;
  bool _loadingBattery = false;

  @override
  void initState() {
    super.initState();
    ble.connectedDeviceNotifier.addListener(_onDeviceChanged);
    _onDeviceChanged();
  }

  @override
  void dispose() {
    ble.connectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  void _onDeviceChanged() {
    final device = ble.connectedDevice;
    if (device == null) {
      if (mounted) {
        setState(() => _batteryPercent = null);
      }
      return;
    }
    _readBattery();
  }

  Future<void> _readBattery() async {
    if (!mounted || !ble.isConnected) return;
    setState(() => _loadingBattery = true);
    try {
      final level = await ble.readBatteryLevel();
      if (!mounted) return;
      setState(() => _batteryPercent = level);
    } catch (e) {
      print('Error reading battery: $e');
      if (mounted) setState(() => _batteryPercent = null);
    } finally {
      if (mounted) setState(() => _loadingBattery = false);
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MainColors.black),
            onPressed: ble.isConnected ? _readBattery : null,
            tooltip: 'Refresh battery',
          ),
        ],
      ),
      body: ValueListenableBuilder<BluetoothDevice?>(
        valueListenable: ble.connectedDeviceNotifier,
        builder: (context, device, _) {
          final bool isConnected = device != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isConnected)
                DeviceCard(
                  title: _deviceName(device!),
                  description: 'Configure Type: Mono Gate\n'
                      'Configured For: Sprint Exercises\n'
                      'Slaves Connected: --\n'
                      'Battery: ${_loadingBattery ? '...' : (_batteryPercent?.toString() ?? '--')}%',
                  actionText: 'Disconnect',
                  actionColor: MainColors.primaryColor,
                  onActionPressed: () {
                    ble.disconnectDevice();
                  },
                  imageUrl: 'assets/images/TimingGate.png',
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (_) => BluetoothPage(email: widget.email),
                    //   ),
                    // );
                    print("Device Screen tapped");
                  },
                )
              else
                DeviceCard(
                  icon: Icons.power_off_outlined,
                  title: 'No Device Connected',
                  description: '',
                  actionText: 'Connect Now',
                  actionColor: MainColors.primaryColor,
                  imageUrl: 'assets/images/TimingGate.png',
                  onActionPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BluetoothPage(email: widget.email)),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  String _deviceName(BluetoothDevice device) {
    try {
      if (device.platformName.isNotEmpty) return device.platformName;
    } catch (_) {}
    return device.remoteId.toString();
  }
}

class DeviceCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionText;
  final Color actionColor;
  final String imageUrl;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.title,
    required this.description,
    required this.actionText,
    required this.actionColor,
    required this.imageUrl,
    this.icon,
    this.onActionPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Card(
      color: MainColors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: MainColors.primaryColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
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
                    border:
                        Border.all(color: MainColors.primaryColor, width: 2),
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
                              // const SizedBox(height: 8),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hint.customGray,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // const SizedBox(height: 8),
                            ],
                            if (actionText.isNotEmpty)
                              ElevatedButton(
                                onPressed: onActionPressed ?? () {},
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: MainColors.white,
                                  backgroundColor: actionColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  actionText,
                                  style: const TextStyle(
                                    fontSize: 14,
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
      ),
    );
  }
}
