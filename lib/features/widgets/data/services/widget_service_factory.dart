export 'widget_service_unsupported.dart'
    if (dart.library.ffi) 'widget_service_native.dart'
    if (dart.library.js_interop) 'widget_service_web.dart';
