import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termora/design/widgets/animated_diff_list.dart';

void main() {
  testWidgets('removals and insertions animate and settle in order', (tester) async {
    var keys = <String>['a', 'b', 'c'];
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return AnimatedDiffList(
                keys: keys,
                itemBuilder: (context, index, key, animation) => Text(key),
                removedBuilder: (context, key, animation) => Text(key),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);

    // Remove the middle row: it stays in the tree during its exit animation.
    rebuild(() => keys = ['a', 'c']);
    await tester.pump();
    expect(find.text('b'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('b'), findsNothing);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('a')).dy,
      lessThan(tester.getTopLeft(find.text('c')).dy),
    );

    // Re-insert the middle row.
    rebuild(() => keys = ['a', 'b', 'c']);
    await tester.pumpAndSettle();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('a')).dy,
      lessThan(tester.getTopLeft(find.text('b')).dy),
    );
    expect(
      tester.getTopLeft(find.text('b')).dy,
      lessThan(tester.getTopLeft(find.text('c')).dy),
    );

    expect(tester.takeException(), isNull);
  });
}
