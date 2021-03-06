class PaymentRequest {
  final double amount;
  final String description;
  final String email;
  final String phone;
  final String device;
  final String login;
  final String extId;
  final String password;

  PaymentRequest({this.amount, this.description, this.email, this.phone, this.device, this.login, this.password, this.extId});

  toMap() {
    return {"amount": amount, "description": description, "email": email, "phone": phone, "device": device, "login": login, "password": password, "extId": extId};
  }
}
