import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const OnSpeedApp());
}

class OnSpeedApp extends StatelessWidget {
  const OnSpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnSpeed Logistics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'sans-serif',
      ),
      home: const OnSpeedHomeScreen(),
    );
  }
}

class VehicleItem {
  final String id;
  final String name;
  final String capacity;
  final int fare;
  final IconData icon;
  final bool isPopular;

  const VehicleItem({
    required this.id,
    required this.name,
    required this.capacity,
    required this.fare,
    required this.icon,
    this.isPopular = false,
  });
}

class OnSpeedHomeScreen extends StatefulWidget {
  const OnSpeedHomeScreen({super.key});

  @override
  State<OnSpeedHomeScreen> createState() => _OnSpeedHomeScreenState();
}

class _OnSpeedHomeScreenState extends State<OnSpeedHomeScreen> {
  static const String rtdbUrl =
      'https://onspeed-logistics-default-rtdb.firebaseio.com/active_order.json';

  final TextEditingController _pickupController = TextEditingController(
    text: 'Connaught Place, Central Delhi',
  );
  final TextEditingController _dropController = TextEditingController(
    text: 'Okhla Industrial Area Phase III',
  );

  final List<VehicleItem> _vehicles = const [
    VehicleItem(
      id: '2w',
      name: '2-Wheeler',
      capacity: 'Parcels up to 20kg',
      fare: 55,
      icon: Icons.two_wheeler,
    ),
    VehicleItem(
      id: '3w',
      name: '3-Wheeler Loader',
      capacity: 'Up to 500kg',
      fare: 195,
      icon: Icons.electric_rickshaw,
    ),
    VehicleItem(
      id: 'tata_ace',
      name: 'Tata Ace / Chota Hathi',
      capacity: 'Up to 750kg',
      fare: 290,
      icon: Icons.local_shipping,
      isPopular: true,
    ),
    VehicleItem(
      id: 'pickup_8ft',
      name: '8ft Pickup / Bolero',
      capacity: 'Up to 1200kg',
      fare: 480,
      icon: Icons.fire_truck,
    ),
  ];

  late VehicleItem _selectedVehicle;
  bool _isBooking = false;
  Map<String, dynamic>? _activeOrder;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = _vehicles[2]; // Tata Ace default
    _fetchActiveOrder();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchActiveOrder();
    });
  }

  Future<void> _fetchActiveOrder() async {
    try {
      final res = await http.get(Uri.parse(rtdbUrl));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final data = json.decode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _activeOrder = data;
          });
        }
      } else {
        if (mounted && _activeOrder != null) {
          setState(() {
            _activeOrder = null;
          });
        }
      }
    } catch (_) {
      // Graceful offline fallback
    }
  }

  Future<void> _bookRide() async {
    if (_pickupController.text.trim().isEmpty ||
        _dropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup and drop locations')),
      );
      return;
    }

    setState(() => _isBooking = true);
    final randomOtp = (1000 + Random().nextInt(9000)).toString();
    final rideId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';

    final orderData = {
      'id': rideId,
      'pickupAddress': _pickupController.text.trim(),
      'dropAddress': _dropController.text.trim(),
      'vehicleId': _selectedVehicle.id,
      'vehicleName': _selectedVehicle.name,
      'fare': _selectedVehicle.fare,
      'status': 'SEARCHING',
      'otp': randomOtp,
      'customerName': 'Vikram Sharma',
      'customerPhone': '+91 98765 12345',
      'driverName': 'Merajul Alam',
      'driverPhone': '+91 98765 43210',
      'driverVehicleNo': 'HR-98-U-6634',
      'driverRating': 4.8,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await http.put(
        Uri.parse(rtdbUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      if (mounted) {
        setState(() {
          _activeOrder = orderData;
          _isBooking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeOrder = orderData; // Offline/local fallback
          _isBooking = false;
        });
      }
    }
  }

  Future<void> _cancelRide() async {
    try {
      await http.delete(Uri.parse(rtdbUrl));
    } catch (_) {}
    if (mounted) {
      setState(() {
        _activeOrder = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveOrder = _activeOrder != null &&
        _activeOrder!['status'] != null &&
        _activeOrder!['status'] != 'CANCELLED';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'OnSpeed',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LOGISTICS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActiveOrder,
            tooltip: 'Refresh Status',
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: hasActiveOrder
          ? _buildLiveTrackingView()
          : _buildBookingView(),
    );
  }

  Widget _buildBookingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Locations Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trip_origin,
                          color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _pickupController,
                          decoration: const InputDecoration(
                            labelText: 'Pickup Address',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _pickupController.text =
                                'Cyber City, Gurugram (Current GPS)';
                          });
                        },
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Current',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dropController,
                          decoration: const InputDecoration(
                            labelText: 'Drop-off Address',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Select Vehicle Fleet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // 4 Vehicle Fleet Cards
          ..._vehicles.map((v) => _buildVehicleCard(v)),

          const SizedBox(height: 20),

          // Checkout Tray
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVehicle.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Payment: Cash / UPI on Delivery',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${_selectedVehicle.fare}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _bookRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Book Ride Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleItem v) {
    final isSelected = _selectedVehicle.id == v.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(v.icon,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                  size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        v.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (v.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v.capacity,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${v.fare}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrackingView() {
    final status = _activeOrder?['status'] ?? 'SEARCHING';
    final otp = _activeOrder?['otp'] ?? '----';
    final driverName = _activeOrder?['driverName'] ?? 'Merajul Alam';
    final driverVehicle = _activeOrder?['driverVehicleNo'] ?? 'HR-98-U-6634';
    final driverRating = _activeOrder?['driverRating'] ?? 4.8;
    final fare = _activeOrder?['fare'] ?? _selectedVehicle.fare;

    Color statusColor = const Color(0xFFF59E0B);
    String statusTitle = 'Searching for Nearby Drivers...';
    String statusSubtitle = 'Connecting to best captain in your area';

    if (status == 'ACCEPTED') {
      statusColor = const Color(0xFF2563EB);
      statusTitle = 'Driver Accepted Order!';
      statusSubtitle = '$driverName is arriving at pickup location';
    } else if (status == 'STARTED') {
      statusColor = const Color(0xFF10B981);
      statusTitle = 'Trip In-Transit';
      statusSubtitle = 'Goods are securely on the way to drop destination';
    } else if (status == 'COMPLETED') {
      statusColor = const Color(0xFF059669);
      statusTitle = 'Trip Completed!';
      statusSubtitle = 'Goods delivered successfully. Pay ₹$fare cash.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toString(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  statusTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
    
