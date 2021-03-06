package ru.goldenapple.ga_sdk.ibox;

import android.content.Context;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.function.Function;

import ibox.pro.sdk.external.PaymentContext;
import ibox.pro.sdk.external.PaymentController;
import ibox.pro.sdk.external.PaymentControllerListener;
import ibox.pro.sdk.external.PaymentException;
import ibox.pro.sdk.external.ReversePaymentContext;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class IBox implements MethodChannel.MethodCallHandler {

    enum Methods {
        PAY("pay"),
        CANCEL("cancel"),
        REVERSE("reverse");

        public final String method;

        static Methods of(String value) {
            for (Methods method : Methods.values()) {
                if (method.method.equals(value)) return method;
            }
            return null;
        }

        Methods(String method) {
            this.method = method;
        }


    }

    static class PaymentRequest {
        @RequiresApi(api = Build.VERSION_CODES.N)
        PaymentRequest(HashMap<String, Object> map) {
            amount = Double.parseDouble(map.getOrDefault("amount", 0).toString());
            description = String.valueOf(map.getOrDefault("description", ""));
            extId = String.valueOf(map.getOrDefault("extId", ""));
            email = String.valueOf(map.getOrDefault("email", null));
            phone = String.valueOf(map.getOrDefault("phone", null));
            device = String.valueOf(map.getOrDefault("device", "").toString());
            login = String.valueOf(map.getOrDefault("login", "").toString());
            password = String.valueOf(map.getOrDefault("password", "").toString());
        }

        public double amount;
        public String description;
        public String email;
        public String extId;
        public String phone;

        public String device;
        public String login;
        public String password;

    }

    static class ReversePaymentRequest {
        public final String transactionID;
        public final String extID;

        final public String device;
        final public String login;
        final public String password;
        final public Double returnAmount;

        public ReversePaymentRequest(String transactionID, String extID, String device, String login, String password, Double returnAmount) {
            this.transactionID = transactionID;
            this.extID = extID;
            this.device = device;
            this.login = login;
            this.password = password;
            this.returnAmount = returnAmount;
        }

        public ReversePaymentContext getReversePaymentContext() {
            ReversePaymentContext context = new ReversePaymentContext();
            context.setTransactionID(transactionID);
            context.setAction(PaymentController.ReverseAction.CANCEL);
            context.setCurrency(PaymentController.Currency.RUB);
            context.setReturnAmount(returnAmount);
            context.setAuxData(null);
            context.setReceiptEmail(null);
            context.setReceiptPhone(null);
            context.setSuppressSignatureWaiting(true);

            return context;
        }
    }


    final String namespace = "ga_sdk.IBox";
    final PaymentController _paymentController;
    final Context context;
    final MethodChannel channel;

    protected Function<Void, Void> _beginPayment;

    PaymentControllerListener _iBoxPaymentControllerListener;
    PaymentController.PaymentMethod _paymentMethod = PaymentController.PaymentMethod.CARD;


    public IBox(Context context, MethodChannel channel) {
        this.context = context;
        this.channel = channel;
        _paymentController = PaymentController.getInstance();
        _iBoxPaymentControllerListener = new IBoxPaymentControllerListener(channel, this);
        _paymentController.setPaymentControllerListener(_iBoxPaymentControllerListener);
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        Methods calledMethod = Methods.of(call.method);
        if (Methods.PAY == calledMethod) {
            PaymentRequest args = new PaymentRequest((HashMap<String, Object>) call.arguments);
            startPayment(
                    context,
                    buildPaymentContext(
                            args.amount,
                            args.description,
                            args.email,
                            args.phone,
                            args.extId
                    ),
                    args.device,
                    args.login,
                    args.password
            );
        } else if (Methods.REVERSE == calledMethod) {
            ReversePaymentRequest reversePaymentRequest = new ReversePaymentRequest(
                    call.<String>argument("transactionID"),
                    call.<String>argument("extID"),
                    call.<String>argument("device"),
                    call.<String>argument("login"),
                    call.<String>argument("password"),
                    call.<Double>argument("returnAmount")
            );

            reversePayment(
                    context,
                    reversePaymentRequest.getReversePaymentContext(),
                    reversePaymentRequest.device,
                    reversePaymentRequest.login,
                    reversePaymentRequest.password
            );
        } else if (Methods.CANCEL == calledMethod) {
            dismiss();
            result.success(true);
        } else {
            result.notImplemented();
        }

    }

    PaymentContext buildPaymentContext(Double amount, String description, String email, String phone, String extId) {
        PaymentContext context = new PaymentContext();
        context.setMethod(_paymentMethod);
        context.setCurrency(PaymentController.Currency.RUB);
        context.setAmount(amount);
        context.setDescription(description);
        context.setExtID(description);
        context.setExtID(extId);
        context.setReceiptEmail(email);
        context.setReceiptPhone(phone);

        return context;
    }

    void startPayment(Context context, PaymentContext paymentContext, String device, String login, String password) {
        _paymentController.setReaderType(context, PaymentController.ReaderType.P17, device);
        _paymentController.setSingleStepEMV(true);
        _paymentController.setCredentials(login, password);
        _paymentController.auth(context);
        _paymentController.initPaymentSession();
        _paymentController.enable();

        _beginPayment = (t) -> {
            try {
                _paymentController.startPayment(context, paymentContext);
                //return ;
            } catch (PaymentException ex) {
                Log.e(namespace, ex.toString());
                //  return;
            }
            return null;
        };
    }

    void reversePayment(Context context, ReversePaymentContext ReversePaymentContext, String device, String login, String password) {
        _paymentController.setReaderType(context, PaymentController.ReaderType.P17, device);
        _paymentController.setSingleStepEMV(true);
        _paymentController.setCredentials(login, password);
        _paymentController.auth(context);
        _paymentController.initPaymentSession();
        _paymentController.enable();

        _beginPayment = (t) -> {
            try {
                _paymentController.reversePayment(context, ReversePaymentContext);
                //return ;
            } catch (PaymentException ex) {
                Log.e(namespace, ex.toString());
                //  return;
            }
            return null;
        };
    }

    public void disable() {
        _paymentController.disable();
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public void beginPayment() {
        _beginPayment.apply(null);
    }

    void dismiss() {

        _paymentController.disable();
    }

    public void onCreate() {
        //_paymentController.onCreate(context, null);
    }

    public void onDestroy() {
        //_paymentController.onDestroy();
    }

}
