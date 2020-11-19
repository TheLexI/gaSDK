package ru.goldenapple.ga_sdk.dto;

import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import java.lang.reflect.Type


class BluetoothDeviceDto(
       var name: String,
       var address: String,
       var type: Int,
       var bondState: Int,
       var deviceClass: Int,
       var majorDeviceClass: Int
) {}

class BluetoothDeviceDtoSerializer : JsonSerializer<BluetoothDeviceDto> {
    override fun serialize(src: BluetoothDeviceDto?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        val result = JsonObject();
        result.addProperty("name", src?.name ?: "")
        result.addProperty("address", src?.address ?: "")
        result.addProperty("type", src?.type ?: 0)
        result.addProperty("bondState", src?.bondState ?: 0)
        result.addProperty("deviceClass", src?.deviceClass ?: 0)
        result.addProperty("majorDeviceClass", src?.majorDeviceClass ?: 0)
        return  result;
    }
}