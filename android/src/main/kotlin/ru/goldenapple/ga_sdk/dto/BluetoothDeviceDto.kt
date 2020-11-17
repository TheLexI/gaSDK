package ru.goldenapple.ga_sdk.dto

class BluetoothDeviceDto(
        var name: String,
        var address: String,
        var type: Int,
        var bondState: Int,
        var deviceClass: Int,
        var majorDeviceClass: Int
) {
}