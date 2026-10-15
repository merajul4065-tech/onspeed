import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const OnSpeedApp());
}

const String firebaseUrl = "https://onspeed-logistics-default-rtdb.firebaseio.com";
const String businessWhatsApp = "918984216008";

class OnSpeedApp extends StatelessWidget {
  const OnSpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnSpeed',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
        ),
      ),
      home: const OnSpeedGate(),
    );
  }
}

class OnSpeedGate extends StatefulWidget {
  const OnSpeedGate({super.key});

  @override
  State<OnSpeedGate> createState() => _OnSpeedGateState();
}

class _OnSpeedGateState extends State<OnSpeedGate> {
  bool isLoggedIn = false;
  String customerPhone = "";
  String customerName = "";

  void handleLogin(String phone, String name) {
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
      return WhatsAppAuthScreen(onLoginSuccess: handleLogin);
    }
    return OnSpeedCustomerHome(
      customerPhone: customerPhone,
      customerName: customerName,
      onLogout: handleLogout,
    );
  }
}

// ================= AUTH SCREEN =================
class WhatsAppAuthScreen extends StatefulWidget {
  final Function(String phone, String name) onLoginSuccess;
  const WhatsAppAuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<WhatsAppAuthScreen> createState() => _WhatsAppAuthScreenState();
}

class _WhatsAppAuthScreenState extends State<WhatsAppAuthScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final otpInputCtrl = TextEditingController();

  bool codeSent = false;
  String expectedCode = "";

  Future<void> sendCode() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (name.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid Name & 10-digit Phone')),
      );
      return;
    }

    final code = (1000 + Random().nextInt(9000)).toString();
    setState(() {
      expectedCode = code;
      codeSent = true;
    });

    final msg = Uri.encodeComponent("Hello OnSpeed, my name is $name. Verification Code: $code");
    final waUrl = Uri.parse("https://wa.me/$businessWhatsApp?text=$msg");

    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      final webUrl = Uri.parse("https://api.whatsapp.com/send?phone=$businessWhatsApp&text=$msg");
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void verify() {
    if (otpInputCtrl.text.trim() == expectedCode) {
      widget.onLoginSuccess(phoneCtrl.text.trim(), nameCtrl.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Code. Enter WhatsApp code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.bolt, size: 36, color: Color(0xFF16A34A)),
              ),
              const SizedBox(height: 20),
              const Text('OnSpeed Logistics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const Text('Verified WhatsApp Login', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                enabled: !codeSent,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtrl,
                enabled: !codeSent,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (codeSent) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: otpInputCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'Enter 4-Digit Code',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: codeSent ? const Color(0xFF2563EB) : const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: codeSent ? verify : sendCode,
                  child: Text(
                    codeSent ? 'Confirm & Enter' : 'Verify with WhatsApp',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================= CUSTOMER HOME & BOOKING =================
class OnSpeedCustomerHome extends StatefulWidget {
  final String customerPhone;
  final String customerName;
  final VoidCallback onLogout;

  const OnSpeedCustomerHome({
    super.key,
    required this.customerPhone,
    required this.customerName,
    required this.onLogout,
  });

  @override
  State<OnSpeedCustomerHome> createState() => _OnSpeedCustomerHomeState();
}

class _OnSpeedCustomerHomeState extends State<OnSpeedCustomerHome> {
  final pickupCtrl = TextEditingController(text: 'Connaught Place, New Delhi');
  final dropCtrl = TextEditingController(text: 'Sector 62, Noida');
  int selectedFleet = 1;
  bool isBooking = false;

  final fleets = [
    {'title': '2-Wheeler', 'cap': 'Up to 20 kg', 'fare': '₹55', 'icon': Icons.two_wheeler},
    {'title': 'Tata Ace', 'cap': 'Up to 750 kg', 'fare': '₹290', 'icon': Icons.local_shipping},
    {'title': '3-Wheeler', 'cap': 'Up to 500 kg', 'fare': '₹195', 'icon': Icons.electric_rickshaw},
    {'title': '8ft Pickup', 'cap': 'Up to 1200 kg', 'fare': '₹480', 'icon': Icons.fire_truck_sharp},
  ];

  Future<void> bookTrip() async {
    setState(() => isBooking = true);
    final vehicle = fleets[selectedFleet];
    final tripOtp = (1000 + Random().nextInt(9000)).toString();
    final orderId = "ORD_${DateTime.now().millisecondsSinceEpoch}";

    final payload = {
      "orderId": orderId,
      "customerName": widget.customerName,
      "customerPhone": widget.customerPhone,
      "pickup": pickupCtrl.text.trim(),
      "drop": dropCtrl.text.trim(),
      "vehicle": vehicle['title'],
      "fare": vehicle['fare'],
      "otp": tripOtp,
      "status": "SEARCHING",
      "createdAt": DateTime.now().toIso8601String(),
      "driverName": "",
      "driverPhone": "",
      "driverVehicle": "",
    };

    try {
      await http.put(
        Uri.parse('$firebaseUrl/active_order.json'),
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => TrackingScreen(expectedOtp: tripOtp),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ONSPEED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Text('${widget.customerName} • +91 ${widget.customerPhone}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
                      border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.black12, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(f['icon'] as IconData, size: 36, color: const Color(0xFF2563EB)),
                        const SizedBox(width: 14),
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
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isBooking ? null : bookTrip,
                child: isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Book Transport', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ================= LIVE TRACKING VIEW =================
class TrackingScreen extends StatefulWidget {
  final String expectedOtp;
  const TrackingScreen({super.key, required this.expectedOtp});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? pollTimer;
  Map<String, dynamic>? activeOrder;

  @override
  void initState() {
    super.initState();
    refresh();
    pollTimer = Timer.periodic(const Duration(seconds: 2), (t) => refresh());
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final res = await http.get(Uri.parse('$firebaseUrl/active_order.json'));
      if (res.body != "null" && mounted) {
        setState(() => activeOrder = jsonDecode(res.body));
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
      appBar: AppBar(
        title: const Text('Trip Status'),
        backgroundColor: const Color(0xFF2563EB),
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
                        status == 'STARTED' ? 'TRIP IN PROGRESS' : 'TRIP START OTP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == 'STARTED' ? Colors.green.shade900 : const Color(0xFF92400E),
                        ),
                      ),
                      const Text('Give this OTP to driver on arrival', style: TextStyle(fontSize: 11)),
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
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDriverAssigned ? Colors.green : Colors.orange,
                  child: Icon(isDriverAssigned ? Icons.person : Icons.radar, color: Colors.white),
                ),
                title: Text(
                  isDriverAssigned ? (activeOrder!['driverName'] ?? 'Assigned Partner') : 'Finding Nearest Driver...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Status: $status'),
              ),
            ),
            const Spacer(),
            if (status == 'COMPLETED')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Home'),
                ),
              )
          ],
        ),
      ),
    );
  }
}
