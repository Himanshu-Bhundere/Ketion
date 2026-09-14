export 'background_sync_scheduler_unsupported.dart'
    if (dart.library.ffi) 'background_sync_scheduler_native.dart'
    if (dart.library.js_interop) 'background_sync_scheduler_web.dart';
