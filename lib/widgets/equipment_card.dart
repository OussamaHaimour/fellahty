import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../services/app_localizations.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;
  final Widget? trailing;

  const EquipmentCard({
    Key? key,
    required this.equipment,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  bool _isBase64(String s) {
    // Base64 images won't start with http
    return !s.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    final hasImages = equipment.imageUrls.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            if (hasImages)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: equipment.imageUrls.length == 1
                    ? _buildImage(equipment.imageUrls.first)
                    : PageView.builder(
                        itemCount: equipment.imageUrls.length,
                        itemBuilder: (context, index) {
                          return _buildImage(equipment.imageUrls[index]);
                        },
                      ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasImages)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.agriculture, color: Theme.of(context).primaryColor, size: 32),
                    ),
                  if (!hasImages) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.type,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                            Text(
                              '${equipment.price.toStringAsFixed(0)} MAD',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            Expanded(
                              child: Text(
                                equipment.location,
                                style: TextStyle(color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: equipment.isAvailable
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            equipment.isAvailable ? t.get('available') : t.get('rented'),
                            style: TextStyle(
                              color: equipment.isAvailable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageData) {
    if (_isBase64(imageData)) {
      try {
        final Uint8List bytes = base64Decode(imageData);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (e) {
        return _placeholder();
      }
    } else {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.agriculture, size: 60, color: Colors.grey[400]),
    );
  }
}
