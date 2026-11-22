import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/models/incoming_share_item.dart';

class IncomingShareService {
  static const MethodChannel _channel =
      MethodChannel('com.example.ketion/share_target');

  final StreamController<List<IncomingShareItem>> _shareController =
      StreamController<List<IncomingShareItem>>.broadcast();

  Stream<List<IncomingShareItem>> get onShareReceived =>
      _shareController.stream;

  IncomingShareService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onShareReceived':
        final rawList = call.arguments;
        if (rawList is List) {
          final items = rawList
              .whereType<Map<dynamic, dynamic>>()
              .map((map) => IncomingShareItem.fromMap(map))
              .toList();
          if (items.isNotEmpty) {
            _shareController.add(items);
          }
        } else if (rawList is Map<dynamic, dynamic>) {
          _shareController.add([IncomingShareItem.fromMap(rawList)]);
        }
        return null;
      default:
        return null;
    }
  }

  Future<List<IncomingShareItem>> getPendingShares() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getPendingShares');
      if (result == null || result.isEmpty) {
        return [];
      }

      final items = <IncomingShareItem>[];
      for (final entry in result) {
        if (entry is Map<dynamic, dynamic>) {
          items.add(IncomingShareItem.fromMap(entry));
        }
      }
      return items;
    } on MissingPluginException {
      // Platform channels may not be implemented on platforms like web
      return [];
    } catch (e) {
      debugPrint('[IncomingShareService] Failed to retrieve pending shares: $e');
      return [];
    }
  }

  Future<void> clearPendingShares() async {
    try {
      await _channel.invokeMethod('clearPendingShares');
    } on MissingPluginException {
      // ignore
    } catch (e) {
      debugPrint('[IncomingShareService] Failed to clear pending shares: $e');
    }
  }

  void dispose() {
    _shareController.close();
  }
}
