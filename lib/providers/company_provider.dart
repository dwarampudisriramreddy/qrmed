import 'package:flutter/material.dart';
import '../models/company.dart';

class CompanyProvider with ChangeNotifier {
  final List<Company> _companies = [];

  List<Company> get companies => _companies;

  void addCompany(Company company) {
    _companies.add(company);
    notifyListeners();
  }

  void updateCompany(int index, Company company) {
    _companies[index] = company;
    notifyListeners();
  }

  void deleteCompany(int index) {
    _companies.removeAt(index);
    notifyListeners();
  }
}
