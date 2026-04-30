import 'dart:async';
void main() async {
  var c = Completer<void>();
  c.future.catchError((e) { print('Caught internally: '+e); });
  c.completeError('My Error');
  print('Program finished without crash!');
}
