import 'package:hive_flutter/hive_flutter.dart';

class ConfigService {
  ConfigService._();

  static const _boxName = 'settings';
  static Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  // Nombre de la Entidad / Negocio (editable dinámicamente)
  static String get companyName {
    return _box.get('company_name', defaultValue: 'Créditos Ruriko') as String;
  }

  static Future<void> saveCompanyName(String name) async {
    await _box.put('company_name', name.trim().isEmpty ? 'Créditos Ruriko' : name.trim());
  }

  // Símbolo de moneda
  static String get currency {
    return _box.get('currency_symbol', defaultValue: 'Bs.') as String;
  }

  static Future<void> saveCurrency(String symbol) async {
    await _box.put('currency_symbol', symbol.trim().isEmpty ? 'Bs.' : symbol.trim());
  }

  // Penalización por mora (%)
  static double get defaultPenaltyRate {
    return (_box.get('default_penalty_rate', defaultValue: 0.0) as num).toDouble();
  }

  static Future<void> saveDefaultPenaltyRate(double rate) async {
    await _box.put('default_penalty_rate', rate);
  }
}
