class BluetoothDeviceDto {
  final String name;
  final String address;
  final int type;
  final int bondState;
  final int deviceClass;
  final int majorDeviceClass;

  BluetoothDeviceDto({this.name, this.address, this.type, this.bondState, this.deviceClass, this.majorDeviceClass});
}
