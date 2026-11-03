import 'package:flutter/material.dart';

class MonitorTile extends StatelessWidget {
  final String title;
  final String status;

  const MonitorTile({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(title), subtitle: Text(status));
  }
}
