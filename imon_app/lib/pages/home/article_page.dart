import 'package:flutter/material.dart';

import '../../utils/style.dart';

class ArticleDetailPage extends StatelessWidget {
  final String title;
  final String imagePath;
  final String body;
  final String imgSrc;
  final String src;

  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.imagePath,
    required this.body,
    required this.imgSrc,
    required this.src,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyling.backgColor,
      appBar: AppBar(
        backgroundColor: AppStyling.backgColor,
        title: const Text("Kembali"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with rounded edges and source text overlay
            Stack(
              children: [
                // Rounded image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  // Adjust corner radius
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                // Text overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      // Semi-transparent background
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      imgSrc,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title and body wrapped in a box with rounded edges and white background
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0), // Rounded edges
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$body\n\nSumber:\n$src',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.justify,  // Apply justify alignment
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
