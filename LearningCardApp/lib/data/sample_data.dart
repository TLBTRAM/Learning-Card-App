import '../models/flashcard.dart';
import '../models/study_set.dart';

List<StudySet> sampleStudySets = [
  StudySet(
    id: '1',
    title: 'Japanese Vocabulary',
    description: 'Từ vựng tiếng Nhật cơ bản',
    progress: 0.6,
    cards: [
      Flashcard(
        term: '試験',
        hiragana: 'しけん',
        definition: 'kỳ thi',
      ),
      Flashcard(
        term: '予定',
        hiragana: 'よてい',
        definition: 'dự định, kế hoạch',
      ),
      Flashcard(
        term: '感動',
        hiragana: 'かんどう',
        definition: 'cảm động',
      ),
      Flashcard(
        term: '活動',
        hiragana: 'かつどう',
        definition: 'hoạt động',
      ),
    ],
  ),
  StudySet(
    id: '2',
    title: 'N3 Grammar',
    description: 'Ngữ pháp tiếng Nhật N3',
    progress: 0.3,
    cards: [
      Flashcard(
        term: '〜によって',
        hiragana: 'によって',
        definition: 'tùy theo, bởi vì',
      ),
      Flashcard(
        term: '〜上で',
        hiragana: 'うえで',
        definition: 'sau khi, trong việc',
      ),
      Flashcard(
        term: '〜に反して',
        hiragana: 'にはんして',
        definition: 'trái với',
      ),
    ],
  ),
];