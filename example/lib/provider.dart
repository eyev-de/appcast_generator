import 'package:appcast_generator/appcast_generator.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'provider.g.dart';

@riverpod
class XMLAppCast extends _$XMLAppCast {
  @override
  AsyncValue<Appcast?> build() => AsyncValue.data(null);

  parse() async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final xml = await rootBundle.loadString("assets/appcast.xml");
      return AppcastUtil.parseItemsFromXMLString(xml);
    });
  }
}
