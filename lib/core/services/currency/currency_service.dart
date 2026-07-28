import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/app_strings.dart';
import 'data/world_currencies.dart';
import 'domain/entities/currency_entity.dart';

import 'package:path_provider/path_provider.dart';

class CurrencyService {
  CurrencyService._internal();
  static final CurrencyService instance = CurrencyService._internal();

  static const String _boxName = 'currency_box';
  static const String _activeCurrencyKey = 'active_currency_data';

  Box<String>? _box;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userSubscription;

  /// Reactive notifier for instant UI updates across the entire application
  final ValueNotifier<CurrencyEntity> currencyNotifier =
      ValueNotifier<CurrencyEntity>(CurrencyEntity.defaultCurrency);

  /// Current active currency entity
  CurrencyEntity get currentCurrency => currencyNotifier.value;

  /// Current active localized currency symbol based on application language
  String get currentSymbol =>
      currentCurrency.getSymbol(AppStrings.currentLang);

  Future<void> _ensureHiveInitialized() async {
    try {
      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocumentDir.path);
      }
    } catch (_) {}
  }

  /// Initialize CurrencyService: load Hive cache & setup Firestore snapshot listener
  Future<void> init() async {
    try {
      await _ensureHiveInitialized();

      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<String>(_boxName);
      } else {
        _box = Hive.box<String>(_boxName);
      }

      // 1. Load from local Hive cache first for 100% offline support
      _loadFromCache();

      // 2. Setup real-time Firestore listener for active user
      _setupUserListener();

      // Listen to FirebaseAuth state changes to re-subscribe if user logs in/out
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _setupUserListener();
        } else {
          _userSubscription?.cancel();
          _userSubscription = null;
        }
      });
    } catch (e) {
      debugPrint('CurrencyService init error: $e');
    }
  }

  void _loadFromCache() {
    final cachedStr = _box?.get(_activeCurrencyKey);
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(cachedStr);
        currencyNotifier.value = CurrencyEntity.fromMap(map);
      } catch (_) {
        // Fallback if legacy string code was stored
        currencyNotifier.value = WorldCurrencies.findByCode(cachedStr);
      }
    }
  }

  void _setupUserListener() {
    _userSubscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((docSnap) {
      if (!docSnap.exists) return;
      final data = docSnap.data();
      if (data == null) return;

      final currencyData = data['currency'];
      if (currencyData != null) {
        CurrencyEntity remoteCurrency;
        if (currencyData is Map<String, dynamic>) {
          remoteCurrency = CurrencyEntity.fromMap(currencyData);
        } else if (currencyData is String) {
          remoteCurrency = WorldCurrencies.findByCode(currencyData);
        } else {
          return;
        }

        if (remoteCurrency != currencyNotifier.value) {
          currencyNotifier.value = remoteCurrency;
          _saveToCache(remoteCurrency);
        }
      }
    }, onError: (err) {
      debugPrint('CurrencyService user snapshot error: $err');
    });
  }

  /// Update active currency: updates memory, Hive local cache & Firebase Firestore
  Future<void> updateCurrency(CurrencyEntity newCurrency) async {
    // 1. Update memory & UI immediately
    currencyNotifier.value = newCurrency;

    // 2. Persist to local Hive storage (Offline-first)
    await _saveToCache(newCurrency);

    // 3. Sync to Firebase Firestore if user is authenticated
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'currency': newCurrency.toMap()}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('CurrencyService Firebase sync error (saved locally): $e');
      }
    }
  }

  Future<void> _saveToCache(CurrencyEntity currency) async {
    try {
      final jsonStr = jsonEncode(currency.toMap());
      await _box?.put(_activeCurrencyKey, jsonStr);
    } catch (e) {
      debugPrint('CurrencyService Hive save error: $e');
    }
  }

  /// Clean up subscriptions on service disposal
  void dispose() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }
}
