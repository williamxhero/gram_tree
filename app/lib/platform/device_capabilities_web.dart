import 'device_capabilities.dart';
import 'fake_device_capabilities.dart';

/// Web build: phone-only capabilities are replaced by a fake.
DeviceCapabilities createDeviceCapabilities() => FakeDeviceCapabilities();
