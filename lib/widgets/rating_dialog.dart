import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class RatingDialog extends StatefulWidget {
  final UserModel worker;

  const RatingDialog({Key? key, required this.worker}) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;
  bool _isLoading = false;

  Future<void> _submitRating() async {
    if (_rating == 0) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Calculate new score: weighted average or simple calculation for MVP
      // For MVP, if it's the first rating, just take it. Otherwise average it.
      double newScore = widget.worker.score == 0 
          ? _rating 
          : ((widget.worker.score + _rating) / 2);
          
      await FirestoreService().rateWorker(widget.worker.id, newScore);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.worker.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How was the worker\'s performance?'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _rating > 0 ? '${_rating.toInt()} out of 5' : 'Select a rating',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              )
            : ElevatedButton(
                onPressed: _rating > 0 ? _submitRating : null,
                child: const Text('SUBMIT'),
              ),
      ],
    );
  }
}
