import 'package:flutter/material.dart';

class TO0100Screen extends StatefulWidget {
  @override
  _TO0100ScreenState createState() => _TO0100ScreenState();
}

class _TO0100ScreenState extends State<TO0100Screen> with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TO0100 Screen'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Event'),
            Tab(text: 'Schedule'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: Text('Event Tab Content')),
          Center(child: Text('Schedule Tab Content')),
          Center(child: Text('Settings Tab Content')),
        ],
      ),
    );
  }
}
