import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ketion/core/router/routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ketion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Routes.search),
          ),
        ],
      ),
      body: const Center(
        child: Text('Ketion - Offline-first Note Taking'),
      ),
    );
  }
}
