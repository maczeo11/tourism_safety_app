// lib/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2, // 2 columns
          crossAxisSpacing: 10, // Horizontal space between cards
          mainAxisSpacing: 10, // Vertical space between cards
          children: <Widget>[
            _buildDashboardCard(context, 'Get UUID', Icons.perm_identity, () {
              // TODO: Implement UUID functionality
              print('Get UUID tapped!');
            }),
            _buildDashboardCard(context, 'Get Live Location', Icons.location_on, () {
              // TODO: Implement live location functionality
              print('Get Live Location tapped!');
            }),
            _buildDashboardCard(context, 'Blank Card 1', Icons.apps, () {
              // TODO: Implement functionality for blank card 1
              print('Blank Card 1 tapped!');
            }),
            _buildDashboardCard(context, 'Blank Card 2', Icons.apps, () {
              // TODO: Implement functionality for blank card 2
              print('Blank Card 2 tapped!');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}