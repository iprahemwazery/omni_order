import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة المزامنة اللحظية عبر Supabase Realtime.
///
/// تسمع على تغييرات الجداول في Supabase وتنبّه التطبيق فورًا.
class RealtimeSyncService {
  RealtimeSyncService();

  final _channel = Supabase.instance.client.channel('omni_realtime');
  final _controllers = <String, StreamController<dynamic>>{};
  StreamSubscription? _subscription;
  bool _started = false;

  /// تبدأ المزامنة: تفتح اتصال realtime وتسمع على التغييرات.
  void start() {
    if (_started) return;
    _started = true;

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sales',
      callback: (payload) {
        debugPrint('[RealtimeSync] new sale: ${payload.newRecord}');
        _notify('sales');
      },
    );

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        debugPrint('[RealtimeSync] order updated: ${payload.newRecord}');
        _notify('orders');
      },
    );

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        debugPrint('[RealtimeSync] new order: ${payload.newRecord}');
        _notify('orders');
      },
    );

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'products',
      callback: (payload) {
        debugPrint('[RealtimeSync] product updated: ${payload.newRecord}');
        _notify('products');
      },
    );

    _channel.subscribe();
    debugPrint('[RealtimeSync] started');
  }

  /// stream for a specific topic ('sales', 'orders', 'products')
  Stream<dynamic> on(String topic) {
    _controllers.putIfAbsent(topic, () => StreamController<dynamic>.broadcast());
    return _controllers[topic]!.stream;
  }

  void _notify(String topic) {
    _controllers[topic]?.add(DateTime.now());
  }

  void stop() {
    _subscription?.cancel();
    _channel.unsubscribe();
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _started = false;
    debugPrint('[RealtimeSync] stopped');
  }
}
