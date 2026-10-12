import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/chat.pb.dart';
import 'package:ratatosk/src/ui/format.dart';

void main() {
  test('only missing messages say no messages yet', () {
    expect(ChatFormat.preview(null), 'No messages yet');
    expect(ChatFormat.preview(Message(encrypted: true)), 'Encrypted message');
    expect(ChatFormat.preview(Message(encrypted: true, deleted: true)),
        'This message was deleted');
    expect(ChatFormat.preview(Message(text: 'hello')), 'hello');
  });
}
