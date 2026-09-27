import 'device_capabilities.dart';
import 'fake_device_capabilities.dart';

/// Fallback for platforms with neither `dart:io` nor JS interop.
DeviceCapabilities createDeviceCapabilities() => FakeDeviceCapabilities();
