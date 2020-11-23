package ru.goldenapple.ga_sdk.ibox;

import android.annotation.SuppressLint;
import android.os.Build;
import android.util.JsonReader;

import androidx.annotation.RequiresApi;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

import ibox.pro.sdk.external.PaymentController;
import ibox.pro.sdk.external.PaymentControllerListener;
import ibox.pro.sdk.external.PaymentResultContext;
import io.flutter.Log;
import io.flutter.plugin.common.MethodChannel;

import static ibox.pro.sdk.external.PaymentController.ReaderEvent.DISCONNECTED;
import static ibox.pro.sdk.external.PaymentController.ReaderEvent.valueOf;

@SuppressLint("DefaultLocale")
public class IBoxPaymentControllerListener implements PaymentControllerListener {
    enum DartMethods {
        ON_ERROR("onError"),
        ON_EVENT("onEvent"),
        ON_FINISHED("onFinished");

        final String name;

        DartMethods(String name) {
            this.name = name;
        }
    }

    private static final String namespace = "ga_sdk. IBoxPaymentControllerListener";

    private final MethodChannel channel;
    private final IBox handler;

    IBoxPaymentControllerListener(MethodChannel channel, IBox handler) {
        this.channel = channel;
        this.handler = handler;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onReaderEvent(PaymentController.ReaderEvent readerEvent, Map<String, String> map) {
        Log.d(namespace, String.format("onReaderEvent {%1s, %2d, %3s}", readerEvent.name(), readerEvent.ordinal(), (map == null ? "" : map.toString())));
        switch (readerEvent) {
            case DISCONNECTED:
            case INIT_FAILED:
            case EJECT_CARD_TIMEOUT:
            case PAYMENT_CANCELED:
            case EJECT_CARD:
            case BAD_SWIPE:
            case LOW_BATTERY:
            case CARD_TIMEOUT:
            case PIN_TIMEOUT:
                handler.disable();
                break;
            case INIT_SUCCESSFULLY:
                handler.beginPayment();
                break;
        }

        Log.d(namespace, "invokeMethod ON_EVENT");
        channel.invokeMethod(DartMethods.ON_EVENT.name, new HashMap<String, String>() {{
            put("code", String.valueOf(readerEvent.ordinal()));
            put("name", readerEvent.name());
            put("data", (map == null ? "" : map.toString()));
        }});
        Log.d(namespace, "invokeMethod ON_EVENT end");
    }

    @Override
    public void onError(PaymentController.PaymentError paymentError, String s) {
        handler.disable();
        Log.d(namespace, String.format("onError {%1s, %2d, %3s}", paymentError.name(), paymentError.ordinal(), s == null ? "" : s));

        Log.d(namespace, "invokeMethod ON_ERROR");
        channel.invokeMethod(DartMethods.ON_ERROR.name, new HashMap<String, String>() {{
            put("code", String.valueOf(paymentError.ordinal()));
            put("name", paymentError.name());
            put("message", s == null ? "" : s);
        }});
        Log.d(namespace, "invokeMethod ON_ERROR end");
    }

    @Override
    public void onFinished(PaymentResultContext paymentResultContext) {
        try {
            JSONObject paymentResultContextJson = new JSONObject()
                    .put("TerminalName", paymentResultContext.getTerminalName())
                    .put("CardHash", paymentResultContext.getCardHash())
                    .put("DeferredData", paymentResultContext.getDeferredData())
                    .put("TranId", paymentResultContext.getTranId())
                    .put("RequiresSignature", paymentResultContext.isRequiresSignature())
                    .put("AttachedCard", new JSONObject())
                    .put("ScheduleItem", new JSONObject())
                    .put("TransactionItem", paymentResultContext.getTransactionItem().getJSON());

            handler.disable();

            Log.d(namespace, String.format("onReturnPowerOffNFCResult {%1s}", paymentResultContextJson.toString(4)));

            channel.invokeMethod(DartMethods.ON_FINISHED.name, paymentResultContextJson.toString());

        } catch (JSONException e) {
            handler.disable();
            e.printStackTrace();
            Log.e(namespace, String.format("onReturnPowerOffNFCResult {%1s}", e.toString()));
        }
    }

    @Override
    public void onTransactionStarted(String s) {
        Log.d(namespace, String.format("onTransactionStarted {%1s}", s == null ? "" : s));
    }

    @Override
    public int onSelectApplication(List<String> list) {
        try {
            Log.d(namespace, String.format("onSelectApplication {%1s}", new JSONArray(list).toString(4)));
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return 0;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public boolean onConfirmSchedule(List<Map.Entry<Date, Double>> list, double v) {
        try {
            Log.d(namespace, String.format("onConfirmSchedule {%1f, %1s}", v,
                    new JSONArray(
                            list.stream().map(val -> {
                                try {
                                    return new JSONObject().put(val.getKey().toString(), val.getValue());
                                } catch (JSONException e) {
                                    e.printStackTrace();
                                    return new JSONObject();
                                }
                            }).toArray()
                    ).toString(4)
            ));
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return false;
    }

    @Override
    public boolean onScheduleCreationFailed(PaymentController.PaymentError paymentError, String s) {
        Log.d(namespace, String.format("onScheduleCreationFailed {%1s, %2d, %3s}", paymentError.name(), paymentError.ordinal(), s));
        return false;
    }

    @Override
    public boolean onCancellationTimeout() {
        Log.d(namespace, "onCancellationTimeout");
        return false;
    }

    @Override
    public void onPinRequest() {
        Log.d(namespace, "onPinRequest");
    }

    @Override
    public void onPinEntered() {
        Log.d(namespace, "onPinEntered");
    }

    @Override
    public void onAutoConfigUpdate(double v) {
        Log.d(namespace, String.format("onAutoConfigUpdate {%1f}", v));
    }

    @Override
    public void onAutoConfigFinished(boolean b, String s, boolean b1) {
        Log.d(namespace, String.format("onAutoConfigFinished {%1b , %2s , %3b}", b, s, b1));
    }

    @Override
    public void onBatteryState(double v) {
        Log.d(namespace, String.format("onBatteryState {%1f}", v));
    }

    @Override
    public PaymentController.PaymentInputType onSelectInputType(List<PaymentController.PaymentInputType> list) {
        Log.d(namespace, String.format("onSelectInputType {%1s}", new JSONArray(list).toString()));
        return null;
    }

    @Override
    public void onSwitchedToCNP() {
        Log.d(namespace, "onSwitchedToCNP");
    }

    @Override
    public void onSearchMifareCard(Hashtable<String, String> hashtable) {
        Log.d(namespace, String.format("onSearchMifareCard {%1s}", hashtable.toString()));
    }

    @Override
    public void onVerifyMifareCard(boolean b) {
        Log.d(namespace, String.format("onVerifyMifareCard {%1b}", b));
    }

    @Override
    public void onWriteMifareCard(boolean b) {
        Log.d(namespace, String.format("onWriteMifareCard {%1b}", b));
    }

    @Override
    public void onReadMifareCard(Hashtable<String, String> hashtable) {
        Log.d(namespace, String.format("onReadMifareCard {%1s}", hashtable.toString()));
    }

    @Override
    public void onOperateMifareCard(Hashtable<String, String> hashtable) {
        Log.d(namespace, String.format("onOperateMifareCard {%1s}", hashtable.toString()));
    }

    @Override
    public void onTransferMifareData(String s) {
        Log.d(namespace, String.format("onTransferMifareData {%4s}", s));
    }

    @Override
    public void onFinishMifareCard(boolean b) {
        Log.d(namespace, String.format("onFinishMifareCard {%1b}", b));
    }

    @Override
    public void onReturnPowerOnNFCResult(boolean b) {
        Log.d(namespace, String.format("onReturnPowerOnNFCResult {%1b}", b));
    }

    @Override
    public void onReturnNFCApduResult(boolean b, String s, int i) {
        Log.d(namespace, String.format("onReturnNFCApduResult {%1b, %2s, %s3d}", b, s, i));
    }

    @Override
    public void onReturnPowerOffNFCResult(boolean b) {
        Log.d(namespace, String.format("onReturnPowerOffNFCResult {%1b}", b));
    }
}
