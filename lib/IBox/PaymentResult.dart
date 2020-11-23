class AttachedCardData {
  final bool isDeleted;
  final String Status;
  final String State;
  final String PanMasked;
  final String PANEnding;
  final int ID;
  final String Bin;
  final String Alias;
  final double Balance;

  AttachedCardData({this.isDeleted, this.Status, this.State, this.PanMasked, this.PANEnding, this.ID, this.Bin, this.Alias, this.Balance});

  static fromJson(Map<String, dynamic> data) => AttachedCardData(
        isDeleted: data['isDeleted'] as bool,
        Status: data['Status'] as String,
        State: data['State'] as String,
        PanMasked: data['PanMasked'] as String,
        PANEnding: data['PANEnding'] as String,
        ID: data['ID'] as int,
        Bin: data['Bin'] as String,
        Alias: data['Alias'] as String,
        Balance: data['Balance'] as double,
      );
}

class ScheduleItemData {
  final int ID;
  final Map<String, dynamic> Card;

  ScheduleItemData({this.ID, this.Card});

  static fromJson(Map<String, dynamic> data) => ScheduleItemData(ID: data['ID'], Card: data['Card']);
}

class PaymentResult {
  final String TerminalName;
  final String CardHash;
  final String DeferredData;
  final String TranId;
  final bool RequiresSignature;
  final AttachedCardData AttachedCard;
  final ScheduleItemData ScheduleItem;
  final Map<String, dynamic> TransactionItem;

  PaymentResult({this.TerminalName, this.CardHash, this.DeferredData, this.TranId, this.RequiresSignature, this.AttachedCard, this.ScheduleItem, this.TransactionItem});

  static fromJson(Map<String, dynamic> data) => PaymentResult(
        TerminalName: data['TerminalName'] as String,
        CardHash: data['CardHash'] as String,
        DeferredData: data['DeferredData'] as String,
        TranId: data['TranId'] as String,
        RequiresSignature: data['RequiresSignature'] as bool,
        AttachedCard: AttachedCardData.fromJson(data['AttachedCard'] as Map<String, dynamic>),
        ScheduleItem: ScheduleItemData.fromJson(data['ScheduleItem'] as Map<String, dynamic>),
        TransactionItem: data['TransactionItem'] as Map<String, dynamic>,
      );
}
