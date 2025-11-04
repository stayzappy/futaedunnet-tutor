import 'dart:typed_data';
import '../models/unit.dart';
import 'pocketbase_service.dart';
import '../utils/text_helper.dart';
import '../config/pocketbase_config.dart';

class UnitService {
  final PocketBaseService _pbService;

  UnitService(this._pbService);

  /// Get all units for a course
  Future<List<Unit>> getUnitsByCourse(String courseId) async {
    try {
      return await _pbService.getUnitsByCourse(courseId);
    } catch (e) {
      throw Exception('Failed to fetch units: ${e.toString()}');
    }
  }

  /// Get a single unit by ID
  Future<Unit> getUnit(String unitId) async {
    try {
      return await _pbService.getUnit(unitId);
    } catch (e) {
      throw Exception('Failed to fetch unit: ${e.toString()}');
    }
  }

  /// Create a new unit
  Future<Unit> createUnit({
    required String title,
    required String content,
    required String courseId,
    required double order,
    Uint8List? videoBytes,
    String? videoFileName,
  }) async {
    try {
      // Sanitize input data
      final sanitizedTitle = TextHelper.capitalizeWords(title);

      // Create unit without video first
      final unit = await _pbService.createUnit(
        title: sanitizedTitle,
        content: content,
        courseId: courseId,
        order: order,
      );

      // Upload video if provided
      if (videoBytes != null && videoFileName != null) {
        await _pbService.uploadFile(
          PocketBaseConfig.unitsCollection,
          unit.id,
          'video',
          videoBytes,
          videoFileName,
        );
        
        // Fetch updated unit with video
        return await _pbService.getUnit(unit.id);
      }

      return unit;
    } catch (e) {
      throw Exception('Failed to create unit: ${e.toString()}');
    }
  }

  /// Update an existing unit
  Future<Unit> updateUnit({
    required String unitId,
    String? title,
    String? content,
    double? order,
    Uint8List? videoBytes,
    String? videoFileName,
    bool removeVideo = false,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      // Sanitize and add fields to update
      if (title != null) {
        updateData['title'] = TextHelper.capitalizeWords(title);
      }
      if (content != null) {
        updateData['content'] = content;
      }
      if (order != null) {
        updateData['order'] = order;
      }
      if (removeVideo) {
        updateData['video'] = null;
      }

      // Update unit data
      final unit = await _pbService.updateUnit(unitId, updateData);

      // Upload new video if provided
      if (videoBytes != null && videoFileName != null) {
        await _pbService.uploadFile(
          PocketBaseConfig.unitsCollection,
          unitId,
          'video',
          videoBytes,
          videoFileName,
        );
        
        // Fetch updated unit with new video
        return await _pbService.getUnit(unitId);
      }

      return unit;
    } catch (e) {
      throw Exception('Failed to update unit: ${e.toString()}');
    }
  }

  /// Delete a unit
  Future<void> deleteUnit(String unitId) async {
    try {
      await _pbService.deleteUnit(unitId);
    } catch (e) {
      throw Exception('Failed to delete unit: ${e.toString()}');
    }
  }

  /// Get unit count for a course
  Future<int> getUnitCount(String courseId) async {
    try {
      final units = await getUnitsByCourse(courseId);
      return units.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get next unit order number for a course
  Future<double> getNextUnitOrder(String courseId) async {
    try {
      final units = await getUnitsByCourse(courseId);
      if (units.isEmpty) {
        return 1.0;
      }
      
      // Find the maximum order and add 1
      final maxOrder = units.map((unit) => unit.order).reduce((a, b) => a > b ? a : b);
      return maxOrder + 1;
    } catch (e) {
      return 1.0;
    }
  }

  /// Reorder units
  Future<void> reorderUnits(List<Unit> units) async {
    try {
      for (var i = 0; i < units.length; i++) {
        final unit = units[i];
        final newOrder = (i + 1).toDouble();
        
        if (unit.order != newOrder) {
          await _pbService.updateUnit(unit.id, {'order': newOrder});
        }
      }
    } catch (e) {
      throw Exception('Failed to reorder units: ${e.toString()}');
    }
  }

  /// Check if unit order exists for a course
  Future<bool> unitOrderExists(String courseId, double order, {String? excludeUnitId}) async {
    try {
      final units = await getUnitsByCourse(courseId);
      
      return units.any((unit) => 
        unit.order == order && 
        unit.id != excludeUnitId
      );
    } catch (e) {
      return false;
    }
  }

  /// Duplicate a unit
  Future<Unit> duplicateUnit(String unitId) async {
    try {
      final originalUnit = await getUnit(unitId);
      final nextOrder = await getNextUnitOrder(originalUnit.course);
      
      return await createUnit(
        title: '${originalUnit.title} (Copy)',
        content: originalUnit.content,
        courseId: originalUnit.course,
        order: nextOrder,
      );
    } catch (e) {
      throw Exception('Failed to duplicate unit: ${e.toString()}');
    }
  }
}