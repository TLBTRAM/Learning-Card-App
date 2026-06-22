import '../models/flashcard.dart';
import '../models/study_set.dart';

List<StudySet> sampleStudySets = [
  StudySet(
    id: '1',
    title: 'Japanese Vocabulary',
    description: 'Từ vựng tiếng Nhật cơ bản cho bài học hằng ngày',
    category: 'Vocabulary',
    progress: 0.75,
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
    description: 'Ngữ pháp tiếng Nhật trung cấp thường gặp',
    category: 'Grammar',
    progress: 0.45,
    cards: [
      Flashcard(
        term: '〜によって',
        hiragana: 'によって',
        definition: 'tùy theo, bởi vì, bằng cách',
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
      Flashcard(
        term: '〜に限り',
        hiragana: 'にかぎり',
        definition: 'chỉ giới hạn trong',
      ),
    ],
  ),
  StudySet(
    id: '3',
    title: 'Kanji Basic',
    description: 'Kanji cơ bản kèm hiragana và nghĩa tiếng Việt',
    category: 'Kanji',
    progress: 0.2,
    cards: [
      Flashcard(
        term: '安全',
        hiragana: 'あんぜん',
        definition: 'an toàn',
      ),
      Flashcard(
        term: '全国',
        hiragana: 'ぜんこく',
        definition: 'toàn quốc',
      ),
      Flashcard(
        term: '写真',
        hiragana: 'しゃしん',
        definition: 'hình ảnh, ảnh chụp',
      ),
      Flashcard(
        term: '参考',
        hiragana: 'さんこう',
        definition: 'tham khảo',
      ),
    ],
  ),
];