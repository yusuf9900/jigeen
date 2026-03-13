import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jigeen/models/report.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour commenter.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .add({
        'text': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonyme', // Using displayName if available
      });
      _commentController.clear();
      // Scroll to bottom after adding comment
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error sending comment: $e'); // For debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi du commentaire.')),
        );
      }
    } finally {
       if(mounted){
          setState(() {
            _isSending = false;
          });
       }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B2E),
      appBar: AppBar(
        title: const Text('Signalement'),
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get(),
        builder: (context, reportSnapshot) {
          if (reportSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!reportSnapshot.hasData || !reportSnapshot.data!.exists) {
            return const Center(child: Text('Signalement non trouvé.', style: TextStyle(color: Colors.white)));
          }

          final report = Report.fromFirestore(reportSnapshot.data!); 

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Details
                      Text(report.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(report.location, style: const TextStyle(color: Colors.white70)),
                          const Spacer(),
                          Text(timeago.format(report.timestamp.toDate(), locale: 'fr'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (report.imagePath != null && report.imagePath!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(report.imagePath!, width: double.infinity, fit: BoxFit.cover),
                        ),
                      const SizedBox(height: 20),
                      Text(report.description, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, height: 1.5)),
                      const Divider(color: Colors.white24, height: 40),

                      // Comments Section
                      const Text('Commentaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reports')
                            .doc(widget.reportId)
                            .collection('comments')
                            .orderBy('timestamp')
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (commentSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          if (!commentSnapshot.hasData || commentSnapshot.data!.docs.isEmpty) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Text('Soyez le premier à commenter.', style: TextStyle(color: Colors.white70)),
                            ));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: commentSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final commentData = commentSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2B2940),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(commentData['text'] ?? '', style: const TextStyle(color: Colors.white, height: 1.4)),
                                    const SizedBox(height: 6),
                                    Text(
                                      commentData['authorName'] ?? 'Anonyme',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Add Comment Input
              Container(
                padding: const EdgeInsets.all(8.0),
                color: const Color(0xFF2B2940),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        icon: _isSending ? const SizedBox(width:20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,)) : const Icon(Icons.send, color: Color(0xFF8B5CF6)),
                        onPressed: _isSending ? null : _addComment,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
