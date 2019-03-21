@JS()
library polyfill;

import 'package:js/js.dart';
import 'dart:html';

@JS('document.createTextNode')
external Element createTextNode(String text);

@JS('console.log')
external void xo_debug(dynamic object);
