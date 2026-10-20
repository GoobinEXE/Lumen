import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_labels.dart';

void main() {
  test('a ordem do rótulo segue o idioma e não o id em inglês', () {
    final portuguese = StateOfMindLabels.sortedIds('pt');
    final english = StateOfMindLabels.sortedIds('en');

    expect(
      portuguese.indexOf('annoyed'),
      lessThan(portuguese.indexOf('angry')),
    );
    expect(english.indexOf('angry'), lessThan(english.indexOf('annoyed')));
    expect(portuguese, hasLength(StateOfMindLabels.ids.length));
  });
}
