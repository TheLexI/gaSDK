package ru.goldenapple.ga_sdk.dto;

import android.bluetooth.BluetoothDevice
import android.os.Build
import androidx.annotation.RequiresApi
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import java.lang.reflect.Type

class BluetoothDeviceSerializer : JsonSerializer<BluetoothDevice> {
    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    override fun serialize(src: BluetoothDevice?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        val result = JsonObject();
        result.addProperty("name", src?.name ?: "")
        result.addProperty("address", src?.address ?: "")
        result.addProperty("type", src?.type ?: 0)
        result.addProperty("bondState", src?.bondState ?: 0)
        result.addProperty("deviceClass", src?.bluetoothClass?.deviceClass ?: 0)
        result.addProperty("majorDeviceClass", src?.bluetoothClass?.majorDeviceClass ?: 0)
        return  result;
    }
}