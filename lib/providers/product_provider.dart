
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  final CollectionReference _productCollection =
      FirebaseFirestore.instance.collection('products');

  List<Product> _products = [];
  List<Product> get products => _products;

  Future<void> fetchProducts() async {
    final snapshot = await _productCollection.get();
    _products = snapshot.docs
        .map((doc) => Product.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _productCollection.doc(product.id).set(product.toJson());
    await fetchProducts();
  }

  Future<void> updateProduct(String id, Product product) async {
    await _productCollection.doc(id).update(product.toJson());
    await fetchProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _productCollection.doc(id).delete();
    await fetchProducts();
  }
}
