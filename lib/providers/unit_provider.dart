import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/unit.dart';
import '../services/pocketbase_service.dart';
import '../services/unit_service.dart';

class UnitProvider extends ChangeNotifier {
  final PocketBaseService _pbService;
  late final UnitService _unitService;
  
  List<Unit> _units = [];
  Unit? _selectedUnit;
  bool _isLoading = false;
  String? _errorMessage;

  UnitProvider(this._pbService) {
    _unitService = UnitService(_pbService);
  }

  // Getters
  List<Unit> get units => _units;
  Unit? get selectedUnit => _selectedUnit;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnits => _units.isNotEmpty;

  /// Load units for a course
  Future<void> loadUnits(String courseId) async {
    _setLoading(true);
    _clearError();

    try {
      _units = await _unitService.getUnitsByCourse(courseId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load units: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load a single unit
  Future<void> loadUnit(String unitId) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedUnit = await _unitService.getUnit(unitId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load unit: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Create a new unit
  Future<bool> createUnit({
    required String title,
    required String content,
    required String courseId,
    required double order,
    Uint8List? videoBytes,
    String? videoFileName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final unit = await _unitService.createUnit(
        title: title,
        content: content,
        courseId: courseId,
        order: order,
        videoBytes: videoBytes,
        videoFileName: videoFileName,
      );

      _units.add(unit);
      _units.sort((a, b) => a.order.compareTo(b.order));
      _selectedUnit = unit;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create unit: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing unit
  Future<bool> updateUnit({
    required String unitId,
    String? title,
    String? content,
    double? order,
    Uint8List? videoBytes,
    String? videoFileName,
    bool removeVideo = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUnit = await _unitService.updateUnit(
        unitId: unitId,
        title: title,
        content: content,
        order: order,
        videoBytes: videoBytes,
        videoFileName: videoFileName,
        removeVideo: removeVideo,
      );

      // Update in list
      final index = _units.indexWhere((u) => u.id == unitId);
      if (index != -1) {
        _units[index] = updatedUnit;
        _units.sort((a, b) => a.order.compareTo(b.order));
      }
      
      _selectedUnit = updatedUnit;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update unit: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete a unit
  Future<bool> deleteUnit(String unitId) async {
    _setLoading(true);
    _clearError();

    try {
      await _unitService.deleteUnit(unitId);
      
      _units.removeWhere((u) => u.id == unitId);
      if (_selectedUnit?.id == unitId) {
        _selectedUnit = null;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete unit: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get next unit order for a course
  Future<double> getNextUnitOrder(String courseId) async {
    try {
      return await _unitService.getNextUnitOrder(courseId);
    } catch (e) {
      return 1.0;
    }
  }

  /// Reorder units
  Future<bool> reorderUnits(List<Unit> reorderedUnits) async {
    _setLoading(true);
    _clearError();

    try {
      await _unitService.reorderUnits(reorderedUnits);
      _units = reorderedUnits;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reorder units: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Duplicate a unit
  Future<bool> duplicateUnit(String unitId) async {
    _setLoading(true);
    _clearError();

    try {
      final duplicatedUnit = await _unitService.duplicateUnit(unitId);
      _units.add(duplicatedUnit);
      _units.sort((a, b) => a.order.compareTo(b.order));
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to duplicate unit: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Set selected unit
  void setSelectedUnit(Unit unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  /// Clear selected unit
  void clearSelectedUnit() {
    _selectedUnit = null;
    notifyListeners();
  }

  /// Get unit count
  int get unitCount => _units.length;

  /// Check if unit order exists
  Future<bool> checkUnitOrderExists(String courseId, double order, {String? excludeUnitId}) async {
    try {
      return await _unitService.unitOrderExists(courseId, order, excludeUnitId: excludeUnitId);
    } catch (e) {
      return false;
    }
  }

  /// Refresh units
  Future<void> refreshUnits(String courseId) async {
    await loadUnits(courseId);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error manually (for UI)
  void clearError() {
    _clearError();
    notifyListeners();
  }
}