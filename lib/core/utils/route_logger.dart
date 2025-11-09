import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_logger.dart';

class RouteLogger extends NavigatorObserver {
  RouteLogger();

  String _name(Route? r) {
    if (r == null) return '-';
    final n = r.settings.name;
    return n ?? r.runtimeType.toString();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    AppLog.nav(
      'push',
      data: {'to': _name(route), 'from': _name(previousRoute)},
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    AppLog.nav('pop', data: {'from': _name(route), 'to': _name(previousRoute)});
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    AppLog.nav(
      'replace',
      data: {'old': _name(oldRoute), 'new': _name(newRoute)},
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

final goRouterObserversProvider = Provider<List<NavigatorObserver>>(
  (ref) => [RouteLogger()],
);
