import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const OnSpeedCustomerApp());
}

const String firebaseUrl = "https://onspeed-logistics-default-rtdb.firebaseio.com";

class OnSpeedCustomerApp extends StatelessWidget {
  const OnSpeedCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnSpeed',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          primary: const Color(0xFF1D4ED8),
        ),
      ),
      home: const OnSpeedCustomerGate(),
    );
  }
}

class OnSpeedCustomerGate extends StatefulWidget {
  const OnSpeedCustomerGate({super.key});

  @override
  State<OnSpeedCustomerGate> createState() => _OnSpeedCustomerGateState();
}

class _OnSpeedCustomerGateState extends State<OnSpeedCustomerGate> {
  bool isLoggedIn = false;
  String customerPhone = "";
  String customerName = "";

  void handleLoginSuccess(String phone, String name) {
    setState(() {
      customerPhone = phone;
      customerName = name;
      isLoggedIn = true;
    });
  }

  void handleLogout() {
    setState(() {
      customerPhone = "";
      customerName = "";
      isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return CustomerPhoneAuthScreen(onSuccess: handleLoginSuccess);
    }
    return CustomerBookingScreen(
      customerPhone: customerPhone,
      customerName: customerName,
      onLogout: handleLogout,
    );
  }
}

// ================= ORIGINAL PHONE NUMBER AUTH SCREEN =================
class CustomerPhoneAuthScreen extends StatefulWidget {
  final Function(String phone, String name) onSuccess;
  const CustomerPhoneAuthScreen({super.key, required this.onSuccess});

  @override
  State<CustomerPhoneAuthScreen> createState() => _CustomerPhoneAuthScreenState();
}

class _CustomerPhoneAuthScreenState extends State<CustomerPhoneAuthScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  bool otpSent = false;
  bool isLoading = false;
  String generatedOtp = "";

  void requestOtp() {
    final phone = phoneCtrl.text.trim();
    final name = nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya apna poora naam enter karein')),
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya 10 ankon ka valid phone number enter karein')),
      );
      return;
    }

    // Generate dynamic 4-digit verification code
    final rnd = Random();
    final otp = (1000 + rnd.nextInt(9000)).toString();

    setState(() {
      generatedOtp = otp;
      otpSent = true;
    });

    // Device notification alert of OTP
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OnSpeed Verification Code'),
        content: Text('Aapke mobile number +91 $phone ke liye OTP hai:\n\n$otp',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              otpCtrl.text = otp; // Auto-fill for convenience
            },
            child: const Text('Auto-Fill OTP'),
          )
        ],
      ),
    );
  }

  Future<void> verifyAndRegister() async {
    final enteredOtp = otpCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final name = nameCtrl.text.trim();

    if (enteredOtp != generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galat OTP, kripya sahi OTP daalein')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Save customer profile permanently in Firebase database
      final userRecord = {
        "name": name,
        "phone": phone,
        "lastLogin": DateTime.now().toIso8601String(),
        "role": "customer"
      };

      await http.put(
        Uri.parse('$firebaseUrl/users/$phone.json'),
        body: jsonEncode(userRecord),
      );

      widget.onSuccess(phone, name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt, size: 40, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(height: 24),
              const Text('Welcome to OnSpeed', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Enter your mobile number to sign in or register', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 32),

              TextField(
                controller: nameCtrl,
                enabled: !otpSent,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: phoneCtrl,
                enabled: !otpSent,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  counterText: '',
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              if (otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'Enter 4-digit OTP',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => otpSent = false),
                    child: const Text('Change Number'),
                  ),
                )
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : (otpSent ? verifyAndRegister : requestOtp),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          otpSent ? 'Verify & Login' : 'Continue with Phone',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= CUSTOMER BOOKING SCREEN =================
class CustomerBookingScreen extends StatefulWidget {
  final String customerPhone;
  final String customerName;
  final VoidCallback onLogout;

  const CustomerBookingScreen({
    super.key,
    required this.customerPhone,
    required this.customerName,
    required this.onLogout,
  });

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  final pickupCtrl = TextEditingController(text: 'Connaught Place, New Delhi');
  final dropCtrl = TextEditingController(text: 'Sector 62, Noida');
  int selectedFleet = 2;
  bool isCreatingOrder = false;

  final fleets = [
    {'title': 'OnSpeed 2-Wheeler', 'cap': 'Up to 20 kg', 'fare': '₹55', 'icon': Icons.two_wheeler},
    {'title': 'OnSpeed 3-Wheeler', 'cap': 'Up to 500 kg', 'fare': '₹195', 'icon': Icons.electric_rickshaw},
    {'title': 'OnSpeed Tata Ace', 'cap': 'Up to 750 kg', 'fare': '₹290', 'icon': Icons.local_shipping},
    {'title': 'OnSpeed 8ft Pickup', 'cap': 'Up to 1200 kg', 'fare': '₹480', 'icon': Icons.fire_truck_sharp},
  ];

  Future<void> submitOrder() async {
    setState(() => isCreatingOrder = true);
    final selectedVehicle = fleets[selectedFleet];
    final randomOtp = (1000 + Random().nextInt(9000)).toString();
    final orderId = "ORD_${DateTime.now().millisecondsSinceEpoch}";

    final orderPayload = {
      "orderId": orderId,
      "customerName": widget.customerName,
      "customerPhone": widget.customerPhone,
      "pickup": pickupCtrl.text.trim(),
      "drop": dropCtrl.text.trim(),
      "vehicle": selectedVehicle['title'],
      "fare": selectedVehicle['fare'],
      "otp": randomOtp,
      "status": "SEARCHING",
      "createdAt": DateTime.now().toIso8601String(),
      "driverName": "",
      "driverPhone": "",
      "driverVehicle": "",
    };

    try {
      // Create specific live active order in Firebase
      await http.put(
        Uri.parse('$firebaseUrl/active_order.json'),
        body: jsonEncode(orderPayload),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => CustomerTrackingScreen(orderId: orderId, expectedOtp: randomOtp),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order submission error: $e')));
    } finally {
      if (mounted) setState(() => isCreatingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = fleets[selectedFleet];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ONSPEED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Text('Hello, ${widget.customerName} (+91 ${widget.customerPhone})',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: pickupCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.my_location, color: Colors.green),
                    labelText: 'Pickup Location',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(),
                TextField(
                  controller: dropCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    labelText: 'Drop Location',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: fleets.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final f = fleets[idx];
                final isSelected = selectedFleet == idx;
                return InkWell(
                  onTap: () => setState(() => selectedFleet = idx),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1D4ED8) : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(f['icon'] as IconData, size: 36, color: const Color(0xFF1D4ED8)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(f['cap'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(f['fare'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isCreatingOrder ? null : submitOrder,
                child: isCreatingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Book ${v['title']} (${v['fare']})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ================= ORIGINAL LIVE TRACKING =================
class CustomerTrackingScreen extends StatefulWidget {
  final String orderId;
  final String expectedOtp;

  const CustomerTrackingScreen({super.key, required this.orderId, required this.expectedOtp});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen> {
  Timer? pollTimer;
  Map<String, dynamic>? activeOrder;

  @override
  void initState() {
    super.initState();
    syncOrder();
    pollTimer = Timer.periodic(const Duration(seconds: 2), (t) => syncOrder());
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> syncOrder() async {
    try {
      final res = await http.get(Uri.parse('$firebaseUrl/active_order.json'));
      if (res.body != "null" && mounted) {
        setState(() {
          activeOrder = jsonDecode(res.body);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (activeOrder == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = activeOrder!['status'] ?? 'SEARCHING';
    final isDriverAssigned = status == 'ACCEPTED' || status == 'STARTED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Live Booking Status'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status == 'STARTED' ? Colors.green.shade50 : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: status == 'STARTED' ? Colors.green : Colors.amber),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'STARTED' ? 'TRIP IN PROGRESS' : 'GIVE OTP TO DRIVER',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: status == 'STARTED' ? Colors.green.shade900 : const Color(0xFF92400E)),
                      ),
                      const Text('Share only upon vehicle arrival', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                  Text(
                    activeOrder!['otp'] ?? widget.expectedOtp,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: status == 'STARTED' ? Colors.green.shade900 : const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDriverAssigned ? Colors.green : Colors.orange,
                  child: Icon(isDriverAssigned ? Icons.person : Icons.radar, color: Colors.white),
                ),
                title: Text(
                  isDriverAssigned ? (activeOrder!['driverName'] ?? 'Driver Assigned') : 'Finding Nearest Driver...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isDriverAssigned
                      ? '${activeOrder!['driverVehicle']} • +91 ${activeOrder!['driverPhone']}\nStatus: $status'
                      : 'Notifying online drivers in your area',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 12, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Pickup: ${activeOrder!['pickup']}')),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Drop: ${activeOrder!['drop']}')),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Fare', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${activeOrder!['fare']} (Cash/UPI)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            if (status == 'COMPLETED') ...[
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 36),
                    SizedBox(height: 8),
                    Text('Delivery Completed!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Thank you for riding with OnSpeed', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Home'),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
