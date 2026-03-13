import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jigeen/add_report_screen.dart';
import 'package:jigeen/models/report.dart';
import 'package:jigeen/report_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Filter state variables
  String? _selectedRegion;
  bool? _isUrgentFilter;
  String? _selectedType;

  final List<String> _regions = [
    'Dakar', 'Thiès', 'Diourbel', 'Saint-Louis', 'Louga', 'Fatick', 'Kaolack', 'Kaffrine',
    'Kolda', 'Ziguinchor', 'Sédhiou', 'Tamba', 'Kédougou', 'Matam'
  ];

  final List<String> _violenceTypes = [
    'Violence domestique',
    'Harcèlement de rue',
    'Cyber-harcèlement',
    'Violence psychologique',
    'Témoignage',
    'Autre',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Implement navigation to other screens
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('reports');

    if (_selectedRegion != null) {
      query = query.where('region', isEqualTo: _selectedRegion);
    }
    if (_isUrgentFilter != null) {
      query = query.where('isUrgent', isEqualTo: _isUrgentFilter);
    }
    if (_selectedType != null) {
      query = query.where('type', isEqualTo: _selectedType);
    }

    return query.orderBy('timestamp', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Image.asset('assets/images/logo_white.png'),
        ),
        title: const Text('Jigeen', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un signalement...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2B2940),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('Tout'),
                        selected: _selectedRegion == null && _isUrgentFilter == null && _selectedType == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRegion = null;
                              _isUrgentFilter = null;
                              _selectedType = null;
                            });
                          }
                        },
                        selectedColor: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 8),
                      _buildDropdownFilter('Région', _regions, _selectedRegion, (val) => setState(() => _selectedRegion = val)),
                      const SizedBox(width: 8),
                      _buildUrgencyFilter(),
                      const SizedBox(width: 8),
                      _buildDropdownFilter('Type', _violenceTypes, _selectedType, (val) => setState(() => _selectedType = val)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print(snapshot.error); // For debugging
                  return const Center(child: Text('Une erreur est survenue.', style: TextStyle(color: Colors.white)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aucun signalement correspondant.', style: TextStyle(color: Colors.white)));
                }

                return ListView( 
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: snapshot.data!.docs.map((doc) {
                    final report = Report.fromFirestore(doc);
                    return _buildReportCard(
                      report: report,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddReportScreen(),
            fullscreenDialog: true, // Open as a modal screen
          ));
        },
        label: const Text('Nouveau signalement'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Carte'),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'Ressources'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF1E1B2E),
        selectedItemColor: const Color(0xFF8B5CF6),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

   Widget _buildDropdownFilter(String hint, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2940),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Text(hint, style: const TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF2B2940),
          style: const TextStyle(color: Colors.white),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUrgencyFilter() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2940),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<bool?>(
            value: _isUrgentFilter,
            hint: const Text('Urgence', style: TextStyle(color: Colors.white70)),
            dropdownColor: const Color(0xFF2B2940),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: true, child: Text('Urgent')),
              DropdownMenuItem(value: false, child: Text('Non Urgent')),
            ],
            onChanged: (val) => setState(() => _isUrgentFilter = val),
          ),
        ),
      );
  }


  Widget _buildReportCard({required Report report}) {

    final time = timeago.format(report.timestamp.toDate(), locale: 'fr');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: const Color(0xFF2B2940),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.imagePath != null && report.imagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: Image.network(report.imagePath!, fit: BoxFit.cover, width: double.infinity, height: 120,
                  loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height:120, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (context, error, stack) => const SizedBox(height:120, child: Center(child: Icon(Icons.error, color: Colors.redAccent))), 
                ),
              ),
            if (report.isAnonymous)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [const Color(0xFF8B5CF6).withOpacity(0.6), const Color(0xFF4F46E5).withOpacity(0.8)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.isUrgent)
                    Chip(label: const Text('URGENT'), backgroundColor: Colors.redAccent, labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  
                  Chip(label: Text(report.type.toUpperCase()), backgroundColor: Colors.grey.shade700, labelStyle: const TextStyle(color: Colors.white)),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(report.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(report.description, style: const TextStyle(color: Colors.white70, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ReportDetailScreen(reportId: report.id),
                      ));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [ 
                            const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(report.location, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const Row(
                          children: [
                            Text('Voir détails', style: TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: Color(0xFFC084FC), size: 16),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
