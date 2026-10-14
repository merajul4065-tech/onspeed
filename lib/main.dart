import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const OnSpeedCustomerApp());
}

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
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8), primary: const Color(0xFF1D4ED8)),
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
  bool loggedIn = false;
  String phone = "";

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) {
      return OnSpeedCustomerLogin(onDone: (p) => setState(() { phone = p; loggedIn = true; }));
    }
    return OnSpeedCustomerBooking(customerPhone: phone);
  }
}

class OnSpeedCustomerLogin extends StatefulWidget {
  final Function(String) onDone;
  const OnSpeedCustomerLogin({super.key, required this.onDone});
  @override
  State<OnSpeedCustomerLogin> createState() => _OnSpeedCustomerLoginState();
}

class _OnSpeedCustomerLoginState extends State<OnSpeedCustomerLogin> {
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

class OnSpeedCustomerBooking extends StatefulWidget {
  final String customerPhone;
  const OnSpeedCustomerBooking({super.key, required this.customerPhone});
  @override
  State<OnSpeedCustomerBooking> createState() => _OnSpeedCustomerBookingState();
}

class _OnSpeedCustomerBookingState extends State<OnSpeedCustomerBooking> {
  final pickupCtrl = TextEditingController(text: 'Connaught Place, Central Delhi');
  final dropCtrl = TextEditingController(text: 'Sector 62, Noida');
  int selected = 2;

  final fleets = [
    {'title': 'OnSpeed 2-Wheeler', 'cap': '20 kg', 'fare': '₹55', 'icon': Icons.two_wheeler},
    {'title': 'OnSpeed 3-Wheeler', 'cap': '500 kg', 'fare': '₹195', 'icon': Icons.electric_rickshaw},
    {'title': 'OnSpeed Tata Ace', 'cap': '750 kg', 'fare': '₹290', 'icon': Icons.local_shipping},
    {'title': 'OnSpeed 8ft Pickup', 'cap': '1200 kg', 'fare': '₹480', 'icon': Icons.fire_truck_sharp},
  ];

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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => OnSpeedTracking(
                        pickup: pickupCtrl.text,
                        drop: dropCtrl.text,
                        vehicle: v['title'] as String,
                        fare: v['fare'] as String,
                      ),
                    ),
                  );
                },
                child: Text('Book OnSpeed (${v['fare']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class OnSpeedTracking extends StatelessWidget {
  final String pickup;
  final String drop;
  final String vehicle;
  final String fare;

  const OnSpeedTracking({super.key, required this.pickup, required this.drop, required this.vehicle, required this.fare});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking'), backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('TRIP OTP: Share with driver', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                  Text('4829', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF1D4ED8), child: Icon(Icons.person, color: Colors.white)),
                title: Text('Mukesh Yadav ($vehicle)'),
                subtitle: const Text('UP 16 BT 9921 • Assigned Driver'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text('From: $pickup'),
                    const Divider(),
                    Text('To: $drop'),
                    const Divider(),
                    Text('Fare: $fare', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
