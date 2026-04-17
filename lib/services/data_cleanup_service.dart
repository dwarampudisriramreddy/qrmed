import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DataCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deletes ALL data from the entire application
  /// WARNING: This is irreversible!
  static Future<Map<String, int>> deleteAllData() async {
    final results = <String, int>{};
    
    try {
      // List of all collections to delete
      final collections = [
        'colleges',
        'equipments',
        'employees',
        'departments',
        'tickets',
        'inspections',
        'products', // If exists
      ];

      for (final collectionName in collections) {
        try {
          final collection = _firestore.collection(collectionName);
          final snapshot = await collection.get();
          
          if (snapshot.docs.isEmpty) {
            results[collectionName] = 0;
            debugPrint('📋 [deleteAllData] Collection "$collectionName" is empty');
            continue;
          }

          // Delete in batches (Firestore limit is 500 per batch)
          int deleted = 0;
          final docs = snapshot.docs;
          
          for (int i = 0; i < docs.length; i += 500) {
            final batch = _firestore.batch();
            final batchDocs = docs.skip(i).take(500);
            
            for (var doc in batchDocs) {
              batch.delete(doc.reference);
            }
            
            await batch.commit();
            deleted += batchDocs.length;
            debugPrint('🗑️ [deleteAllData] Deleted batch from "$collectionName": ${batchDocs.length} documents');
          }
          
          results[collectionName] = deleted;
          debugPrint('✅ [deleteAllData] Deleted $deleted documents from "$collectionName"');
        } catch (e) {
          debugPrint('⚠️ [deleteAllData] Error deleting collection "$collectionName": $e');
          results[collectionName] = -1; // -1 indicates error
        }
      }

      final totalDeleted = results.values.where((v) => v > 0).fold<int>(0, (sum, v) => sum + v);
      debugPrint('✅ [deleteAllData] Total documents deleted: $totalDeleted');
      
      return results;
    } catch (e, stackTrace) {
      debugPrint('❌ [deleteAllData] Fatal error: $e');
      debugPrint('❌ [deleteAllData] Stack trace: $stackTrace');
      rethrow;
    }
  }
}



