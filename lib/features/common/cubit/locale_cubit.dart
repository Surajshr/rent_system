import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._box) : super(_load(_box));

  final Box<String> _box;
  static const _key = 'locale_code';

  static Locale _load(Box<String> box) {
    final saved = box.get(_key);
    if (saved == 'ne') return const Locale('ne');
    return const Locale('en');
  }

  bool get isNepali => state.languageCode == 'ne';

  Future<void> setEnglish() => _set(const Locale('en'));
  Future<void> setNepali() => _set(const Locale('ne'));

  Future<void> toggle() => isNepali ? setEnglish() : setNepali();

  Future<void> _set(Locale locale) async {
    await _box.put(_key, locale.languageCode);
    emit(locale);
  }
}
