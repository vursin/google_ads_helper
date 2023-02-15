import 'package:flutter/foundation.dart';
import 'package:google_ads_helper/google_ads_helper.dart';

abstract class DisposeAd {
  static final List<DisposeAd> list = [];
  static void _addList(DisposeAd disposeAd) => list.add(disposeAd);
  static void _removeList(DisposeAd disposeAd) => list.remove(disposeAd);

  @protected
  @mustCallSuper
  void disposeAdInit() {
    printDebug('Add $this ad widget to DisposeAd');
    _addList(this);
  }

  @protected
  @mustCallSuper
  void disposeAdDispose() {
    printDebug('Remove $this ad widget from DisposeAd');
    _removeList(this);
  }

  void disposeAd();
}
