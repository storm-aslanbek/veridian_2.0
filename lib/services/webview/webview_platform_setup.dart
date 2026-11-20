import 'webview_platform_setup_stub.dart'

if (dart.library.js_interop) 'webview_platform_setup_web.dart';

void ensureWebViewPlatformInitialized() {
  initWebViewPlatform();
}