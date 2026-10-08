import 'package:flutter/material.dart';

/// Maps the `iconKey` strings stored in the database to real icons.
const _icons = <String, IconData>{
  'restaurant': Icons.restaurant,
  'flight': Icons.flight,
  'shopping_bag': Icons.shopping_bag,
  'receipt_long': Icons.receipt_long,
  'home': Icons.home,
  'movie': Icons.movie,
  'medical_services': Icons.medical_services,
  'school': Icons.school,
  'subscriptions': Icons.subscriptions,
  'category': Icons.category,
  'payments': Icons.payments,
  'laptop': Icons.laptop,
  'storefront': Icons.storefront,
  'trending_up': Icons.trending_up,
  'card_giftcard': Icons.card_giftcard,
  'savings': Icons.savings,
};

IconData iconFor(String key) => _icons[key] ?? Icons.category;
