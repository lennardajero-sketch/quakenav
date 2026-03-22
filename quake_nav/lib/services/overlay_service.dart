import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  static final Stream<String> _sharedOverlayStream =
      FlutterOverlayWindow.overlayListener
          .map((event) => event.toString())
          .asBroadcastStream();

  Stream<String> messages() {
    return _sharedOverlayStream;
  }

  Future<bool> isPermissionGranted() async {
    return FlutterOverlayWindow.isPermissionGranted();
  }

  Future<bool> ensurePermission() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (granted) {
      return true;
    }
    final result = await FlutterOverlayWindow.requestPermission();
    return result ?? false;
  }

  Future<bool> showBubble() async {
    // Some OEMs fail to show a new overlay if a stale instance exists.
    await FlutterOverlayWindow.closeOverlay();
    await FlutterOverlayWindow.showOverlay(
      height: 120,
      width: 120,
      alignment: OverlayAlignment.centerRight,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'QuakeNav',
      overlayContent: 'Tap bubble to open map',
      enableDrag: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return FlutterOverlayWindow.isActive();
  }

  Future<void> close() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
