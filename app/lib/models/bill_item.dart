import 'package:flutter/material.dart';

class BillItem {
  final String id;
  String name;
  double price;
  int quantity;
  Rect? boundingBox;

  BillItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.boundingBox,
  });

  double get totalPrice => price * quantity;

  BillItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    Rect? boundingBox,
  }) {
    return BillItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
      );
}

class DiningGuest {
  final String id;
  final String name;
  final bool isHost;
  final List<String> claimedItemIds;
  final Map<String, int> sharedItemSplits; // itemId -> total splitters
  final bool isPaid;

  DiningGuest({
    required this.id,
    required this.name,
    this.isHost = false,
    this.claimedItemIds = const [],
    this.sharedItemSplits = const {},
    this.isPaid = false,
  });
}
