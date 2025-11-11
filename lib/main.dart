import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const JKNQueueApp());
}

class JKNQueueApp extends StatelessWidget {
  const JKNQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JKN Antrian Sehat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        fontFamily: 'Poppins',
      ),
      home: const QueueHome(),
    );
  }
}

const String baseUrl = 'http://localhost:8000';

class QueueHome extends StatefulWidget {
  const QueueHome({super.key});

  @override
  State<QueueHome> createState() => _QueueHomeState();
}

class _QueueHomeState extends State<QueueHome> with SingleTickerProviderStateMixin {
  QueueTicket? _ticket;
  bool _loading = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> takeTicket() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.delayed(const Duration(seconds: 1)); // simulasi loading

    setState(() {
      _ticket = QueueTicket(
        ticketId: "A-001",
        position: 5,
        estimatedMinutes: 15,
        estimatedRangeMin: 10,
        estimatedRangeMax: 20,
      );
      _loading = false;
    });
  }

  Future<void> fetchEstimate(String ticketId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/queue/$ticketId/estimate');
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final updated = QueueTicket.fromJson(data);
        setState(() => _ticket = updated);
      }
    } catch (_) {}
  }

  Widget buildActionCard() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_ticket == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_hospital, size: 80, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Belum memiliki antrian',
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: takeTicket,
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
            label: const Text('Ambil Antrian', style: TextStyle(color: Colors.white, fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Nomor Antrian',
          style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9)),
        ),
        Text(
          _ticket!.ticketId,
          style: const TextStyle(
              fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Posisi Anda: ${_ticket!.position}',
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const SizedBox(height: 16),
        EstimateCard(ticket: _ticket!),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Estimasi diperbarui (dummy)')),
            );
          },
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Perbarui Estimasi',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _ticket = null),
          child: const Text(
            'Batalkan Antrian',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        title: const Text('Antrian JKN Mobile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradasi background atas bawah
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade900],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 8,
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: buildActionCard(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QueueTicket {
  final String ticketId;
  final int position;
  final int? estimatedMinutes;
  final int? estimatedRangeMin;
  final int? estimatedRangeMax;

  QueueTicket({
    required this.ticketId,
    required this.position,
    this.estimatedMinutes,
    this.estimatedRangeMin,
    this.estimatedRangeMax,
  });

  factory QueueTicket.fromJson(Map<String, dynamic> json) {
    int? rangeMin;
    int? rangeMax;
    if (json['estimated_range'] != null && json['estimated_range'] is List) {
      final arr = json['estimated_range'] as List;
      if (arr.isNotEmpty) rangeMin = arr[0];
      if (arr.length > 1) rangeMax = arr[1];
    }

    return QueueTicket(
      ticketId: json['ticket_id']?.toString() ?? 'unknown',
      position: (json['position'] ?? 0) as int,
      estimatedMinutes:
          json['estimated_minutes'] != null ? (json['estimated_minutes'] as num).toInt() : null,
      estimatedRangeMin: rangeMin,
      estimatedRangeMax: rangeMax,
    );
  }
}

class EstimateCard extends StatelessWidget {
  final QueueTicket ticket;
  const EstimateCard({required this.ticket, super.key});

  String prettyRangeOrSingle() {
    if (ticket.estimatedRangeMin != null && ticket.estimatedRangeMax != null) {
      return '${ticket.estimatedRangeMin}–${ticket.estimatedRangeMax} menit';
    } else if (ticket.estimatedMinutes != null) {
      return '${ticket.estimatedMinutes} menit';
    } else {
      return 'Estimasi belum tersedia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = prettyRangeOrSingle();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time_filled, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Text(
                'Perkiraan Waktu',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rangeText,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.5,
            color: Colors.greenAccent,
            backgroundColor: Colors.white30,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          // 🔽 Bagian ini diubah jadi Column (vertikal)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lebih awal: ${ticket.estimatedRangeMin ?? "-"} mnt',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Lebih lambat: ${ticket.estimatedRangeMax ?? "-"} mnt',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}