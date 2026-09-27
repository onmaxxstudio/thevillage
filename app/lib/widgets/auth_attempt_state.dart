import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps a dismissed external sign-in window from locking the host screen.
/// Re-enabling controls does not assume cancellation: a successful pending
/// result can still finish, unless the user has started a newer attempt.
mixin AuthAttemptState<T extends StatefulWidget> on State<T> {
  bool loading = false;
  int _attempt = 0;
  bool _external = false;
  Timer? _resumeTimer;
  Timer? _recoveryTimer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _recoverOnReturn);
  }

  int beginAuthAttempt({required bool external}) {
    _resumeTimer?.cancel();
    _recoveryTimer?.cancel();
    final attempt = ++_attempt;
    _external = external;
    setState(() => loading = true);
    if (external) {
      // Some browsers never report popup cancellation or a focus transition.
      _recoveryTimer = Timer(const Duration(seconds: 60), () {
        if (isCurrentAuthAttempt(attempt)) {
          setState(() => loading = false);
        }
      });
    }
    return attempt;
  }

  bool isCurrentAuthAttempt(int attempt) => mounted && attempt == _attempt;

  void _recoverOnReturn() {
    if (!_external || !loading) return;
    final attempt = _attempt;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 700), () {
      if (isCurrentAuthAttempt(attempt) && _external && loading) {
        setState(() => loading = false);
      }
    });
  }

  void finishAuthAttempt(int attempt) {
    if (!isCurrentAuthAttempt(attempt)) return;
    _resumeTimer?.cancel();
    _recoveryTimer?.cancel();
    _external = false;
    if (loading) setState(() => loading = false);
  }

  @override
  void dispose() {
    ++_attempt;
    _resumeTimer?.cancel();
    _recoveryTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }
}
