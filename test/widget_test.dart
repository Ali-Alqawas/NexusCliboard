// NexusClip Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_clip/main.dart';

void main() {
  testWidgets('NexusClip app loads successfully', (WidgetTester tester) async {
    // Build NexusClip app and trigger a frame
    await tester.pumpWidget(const NexusClipApp());

    // Verify that the app title is displayed
    expect(find.text('NexusClip'), findsWidgets);
  });
}
