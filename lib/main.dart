import 'dart:async';
import 'dart:convert';
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
      title: 'OnSpeed Customer',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8), primary: const Color(0xFF1D4ED8)),
      ),
      home: const CustomerGate(),
    );
  }
}

class CustomerGate extends StatefulWidget {
  const CustomerGate({super.key});
  @override
  State<CustomerGate> createState() => _CustomerGateState();
}

class _CustomerGateState extends State<CustomerGate> {
  bool loggedIn = false;
  String phone = "";

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) {
      return CustomerLogin(onDone: (p) => setState(() { phone = p; loggedIn = true; }));
    }
    return CustomerBooking(customerPhone: phone);
  }
}

class CustomerLogin extends StatefulWidget {
  final Function(String) onDone;
  const CustomerLogin({super.key, required this.onDone});
  @override
  State<CustomerLogin> createState() => _CustomerLoginState();
}

class _CustomerLoginState extends State<CustomerLogin> {
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  bool otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.bolt, size: 36, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(height: 20),
              const Text('OnSpeed Customer', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const Text('Superfast city logistics, couriers & mini trucks', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 30),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  counterText: '',
                  prefixText: '+91 ',
                  hintText: 'Enter Mobile Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (otpSent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(letterSpacing: 6, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Demo OTP: 1234',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8)),
                  onPressed: () {
                    if (!otpSent) {
                      if (phoneCtrl.text.length == 10) setState(() => otpSent = true);
                    } else {
                      if (otpCtrl.text == "1234") widget.onDone(phoneCtrl.text);
                    }
                  },
                  child: Text(otpSent ? 'Verify & Continue' : 'Get OTP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerBooking extends StatefulWidget {
  final String customerPhone;
  const CustomerBooking({super.key, required this.customerPhone});
  @override
  State<CustomerBooking> createState() => _CustomerBookingState();
}

class _CustomerBookingState extends State<CustomerBooking> {
  final pickupCtrl = TextEditingController(text: 'Connaught Place, Central Delhi');
  final dropCtrl = TextEditingController(text: 'Sector 62, Noida');
  int selected = 2;
  bool isBooking = false;

  final fleets = [
    {'title': 'OnSpeed 2-Wheeler', 'cap': '20 kg', 'fare': '₹55', 'icon': Icons.two_wheeler},
    {'title': 'OnSpeed 3-Wheeler', 'cap': '500 kg', 'fare': '₹195', 'icon': Icons.electric_rickshaw},
    {'title': 'OnSpeed Tata Ace', 'cap': '750 kg', 'fare': '₹290', 'icon': Icons.local_shipping},
    {'title': 'OnSpeed 8ft Pickup', 'cap': '1200 kg', 'fare': '₹480', 'icon': Icons.fire_truck_sharp},
  ];

  Future<void> bookRide() async {
    setState(() => isBooking = true);
    final v = fleets[selected];
    final orderData = {
      "status": "SEARCHING",
      "customerPhone": widget.customerPhone,
      "pickup": pickupCtrl.text,
      "drop": dropCtrl.text,
      "vehicle": v['title'],
      "fare": v['fare'],
      "otp": "4829",
      "driverName": "",
      "driverPhone": "",
      "driverVehicle": ""
    };

    try {
      await http.put(
        Uri.parse('$firebaseUrl/active_order.json'),
        body: jsonEncode(orderData),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const CustomerLiveTracking()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = fleets[selected];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ONSPEED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                TextField(controller: pickupCtrl, decoration: const InputDecoration(icon: Icon(Icons.circle, size: 12, color: Colors.green), labelText: 'Pickup (Point A)')),
                TextField(controller: dropCtrl, decoration: const InputDecoration(icon: Icon(Icons.location_on, size: 14, color: Colors.red), labelText: 'Drop (Point Z)')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: fleets.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, i) {
                final item = fleets[i];
                return ListTile(
                  tileColor: selected == i ? const Color(0xFFEFF6FF) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: Icon(item['icon'] as IconData, color: const Color(0xFF1D4ED8)),
                  title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Capacity: ${item['cap']}'),
                  trailing: Text(item['fare'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onTap: () => setState(() => selected = i),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8)),
                onPressed: isBooking ? null : bookRide,
                child: isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Book OnSpeed (${v['fare']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CustomerLiveTracking extends StatefulWidget {
  const CustomerLiveTracking({super.key});
  @override
  State<CustomerLiveTracking> createState() => _CustomerLiveTrackingState();
}

class _CustomerLiveTrackingState extends State<CustomerLiveTracking> {
  Timer? pollTimer;
  Map<String, dynamic>? currentOrder;

  @override
  void initState() {
    super.initState();
    fetchOrder();
    pollTimer = Timer.periodic(const Duration(seconds: 2), (t) => fetchOrder());
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrder() async {
    try {
      final res = await http.get(Uri.parse('$firebaseUrl/active_order.json'));
      if (res.body != "null" && mounted) {
        setState(() {
          currentOrder = jsonDecode(res.body);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (currentOrder == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = currentOrder!['status'] ?? 'SEARCHING';
    final isAssigned = status == 'ACCEPTED' || status == 'STARTED';

    return Scaffold(
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: status == 'STARTED' ? Colors.green.shade50 : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status == 'STARTED' ? 'TRIP ONGOING' : 'START OTP (Give to Driver)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: status == 'STARTED' ? Colors.green.shade800 : const Color(0xFF92400E)),
                  ),
                  Text(
                    currentOrder!['otp'] ?? '',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: status == 'STARTED' ? Colors.green.shade800 : const Color(0xFF92400E)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAssigned ? Colors.green : Colors.grey,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(isAssigned ? (currentOrder!['driverName'] ?? 'Assigned Partner') : 'Finding nearby driver...'),
                subtitle: Text(isAssigned
                    ? '${currentOrder!['driverVehicle']} • ${currentOrder!['driverPhone']}\nStatus: $status'
                    : 'Broadcasting request to nearby drivers'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text('From: ${currentOrder!['pickup']}'),
                    const Divider(),
                    Text('To: ${currentOrder!['drop']}'),
                    const Divider(),
                    Text('Fare: ${currentOrder!['fare']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (status == 'COMPLETED') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: const Text('Trip Completed Successfully! Cash Paid.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
    );
  }
}
