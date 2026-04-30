import 'dart:async';
void main() async {
  var c = Completer<void>();
  c.future.catchError((e) { print('Internal Catch'); });
  c.completeError('My Error');
  try {
    await c.future;
  } catch (e) {
    print('Caller Catch caught: ' + e.toString());
  }
}
