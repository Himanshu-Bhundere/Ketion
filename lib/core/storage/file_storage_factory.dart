export 'file_storage_unsupported.dart'
    if (dart.library.ffi) 'file_storage_native.dart'
    if (dart.library.js_interop) 'file_storage_web.dart';
