const path = require('path');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');
const mysql = require('mysql2/promise');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const demoPassword = 'Demo@123';
const demoUsers = [
  {
    name: 'Minh Anh Demo',
    email: 'minh.demo@learningcard.local',
    dailyGoal: 18,
  },
  {
    name: 'Lan Chi Demo',
    email: 'lan.demo@learningcard.local',
    dailyGoal: 12,
  },
];

const daysAgo = (days, hour = 20) => {
  const value = new Date();
  value.setDate(value.getDate() - days);
  value.setHours(hour, 0, 0, 0);
  return value;
};

const daysFromNow = (days, hour = 8) => {
  const value = new Date();
  value.setDate(value.getDate() + days);
  value.setHours(hour, 0, 0, 0);
  return value;
};

async function createSet(connection, userId, definition) {
  const [setResult] = await connection.query(
    `INSERT INTO flashcard_sets
       (user_id, title, description, color, visibility, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      userId,
      definition.title,
      definition.description,
      definition.color,
      definition.visibility || 'private',
      definition.createdAt || daysAgo(14),
      definition.updatedAt || daysAgo(0),
    ]
  );

  const cardIds = [];
  for (const card of definition.cards) {
    const [cardResult] = await connection.query(
      `INSERT INTO flashcards
         (set_id, user_id, front, back, example, image_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        setResult.insertId,
        userId,
        card.front,
        card.back,
        card.example || null,
        card.imageUrl || null,
      ]
    );
    cardIds.push(cardResult.insertId);
  }

  return { id: setResult.insertId, cardIds };
}

async function createNote(connection, userId, definition) {
  const [result] = await connection.query(
    `INSERT INTO notes
       (user_id, title, content_text, drawing_data, visibility, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      userId,
      definition.title,
      definition.content,
      JSON.stringify(definition.drawingData || []),
      definition.visibility || 'private',
      definition.createdAt || daysAgo(8),
      definition.updatedAt || daysAgo(0),
    ]
  );
  return result.insertId;
}

async function createSession(connection, userId, setId, session) {
  await connection.query(
    `INSERT INTO study_sessions
       (user_id, set_id, total_cards, learned_cards, correct_answers, wrong_answers, studied_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      userId,
      setId,
      session.total,
      session.learned,
      session.correct,
      session.wrong,
      daysAgo(session.daysAgo, session.hour || 20),
    ]
  );
}

async function createReview(connection, userId, setId, cardId, review) {
  await connection.query(
    `INSERT INTO card_reviews
       (user_id, card_id, set_id, rating, repetitions, interval_days,
        next_review_at, last_reviewed_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      userId,
      cardId,
      setId,
      review.rating,
      review.repetitions,
      review.intervalDays,
      review.nextReviewAt,
      review.lastReviewedAt,
    ]
  );
}

async function seed() {
  const required = ['DB_HOST', 'DB_USER', 'DB_NAME'];
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length) {
    throw new Error(`Missing environment values: ${missing.join(', ')}`);
  }

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    await connection.beginTransaction();
    const passwordHash = await bcrypt.hash(demoPassword, 10);

    for (const user of demoUsers) {
      await connection.query(
        `INSERT INTO users (name, email, password, daily_goal)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           name = VALUES(name),
           password = VALUES(password),
           daily_goal = VALUES(daily_goal)`,
        [user.name, user.email, passwordHash, user.dailyGoal]
      );
    }

    const [users] = await connection.query(
      'SELECT id, email FROM users WHERE email IN (?, ?)',
      demoUsers.map((user) => user.email)
    );
    const userIdByEmail = new Map(users.map((user) => [user.email, user.id]));
    const minhId = userIdByEmail.get(demoUsers[0].email);
    const lanId = userIdByEmail.get(demoUsers[1].email);
    const demoIds = [minhId, lanId];

    // Only reset data scoped to the dedicated demo accounts. Real accounts and
    // their learning content are never deleted by this seed.
    await connection.query(
      'DELETE FROM flashcard_set_shares WHERE shared_with_user_id IN (?, ?) OR shared_by_user_id IN (?, ?)',
      [...demoIds, ...demoIds]
    );
    await connection.query(
      'DELETE FROM note_shares WHERE shared_with_user_id IN (?, ?) OR shared_by_user_id IN (?, ?)',
      [...demoIds, ...demoIds]
    );
    await connection.query('DELETE FROM card_reviews WHERE user_id IN (?, ?)', demoIds);
    await connection.query('DELETE FROM study_sessions WHERE user_id IN (?, ?)', demoIds);
    await connection.query('DELETE FROM study_progress WHERE user_id IN (?, ?)', demoIds);
    await connection.query('DELETE FROM chat_history WHERE user_id IN (?, ?)', demoIds);
    await connection.query('DELETE FROM notes WHERE user_id IN (?, ?)', demoIds);
    await connection.query('DELETE FROM flashcard_sets WHERE user_id IN (?, ?)', demoIds);

    const academicEnglish = await createSet(connection, minhId, {
      title: 'Tiếng Anh học thuật – Cốt lõi',
      description: 'Từ vựng thường gặp trong bài đọc và bài luận đại học.',
      color: '#7565A7',
      cards: [
        {
          front: 'Analyze',
          back: 'Phân tích một vấn đề thành các phần để hiểu rõ hơn.',
          example: 'The report analyzes how study habits affect memory.',
        },
        {
          front: 'Evidence',
          back: 'Bằng chứng dùng để hỗ trợ một nhận định hoặc kết luận.',
          example: 'The conclusion is supported by strong evidence.',
        },
        {
          front: 'Significant',
          back: 'Đáng kể, quan trọng hoặc có ý nghĩa thống kê.',
          example: 'There was a significant improvement in test scores.',
        },
        {
          front: 'Interpret',
          back: 'Giải thích ý nghĩa của dữ liệu, văn bản hoặc sự kiện.',
          example: 'Students were asked to interpret the graph.',
        },
        {
          front: 'Approach',
          back: 'Phương pháp hoặc cách tiếp cận một vấn đề.',
          example: 'This approach makes revision more manageable.',
        },
        {
          front: 'Consequence',
          back: 'Kết quả hoặc hệ quả của một hành động.',
          example: 'Sleep deprivation has serious consequences for learning.',
        },
      ],
    });

    const cellBiology = await createSet(connection, minhId, {
      title: 'Sinh học – Tế bào',
      description: 'Các khái niệm nền tảng về cấu trúc và hoạt động của tế bào.',
      color: '#4D8064',
      cards: [
        {
          front: 'Màng sinh chất',
          back: 'Lớp màng kép phospholipid kiểm soát chất đi vào và ra khỏi tế bào.',
          example: 'Protein màng hỗ trợ vận chuyển chọn lọc các phân tử.',
        },
        {
          front: 'Ty thể',
          back: 'Bào quan tạo phần lớn ATP thông qua hô hấp tế bào.',
          example: 'Tế bào cơ thường có nhiều ty thể để đáp ứng nhu cầu năng lượng.',
        },
        {
          front: 'Ribosome',
          back: 'Cấu trúc thực hiện quá trình tổng hợp protein.',
          example: 'Ribosome đọc mRNA để nối các amino acid.',
        },
        {
          front: 'Nhân tế bào',
          back: 'Bào quan chứa DNA và điều phối hoạt động của tế bào nhân thực.',
          example: 'Màng nhân ngăn cách vật chất di truyền với tế bào chất.',
        },
        {
          front: 'Nguyên phân',
          back: 'Quá trình một tế bào mẹ tạo ra hai tế bào con giống nhau về di truyền.',
          example: 'Nguyên phân giúp cơ thể tăng trưởng và sửa chữa mô.',
        },
      ],
    });

    const studySkills = await createSet(connection, minhId, {
      title: 'Kỹ năng học hiệu quả',
      description: 'Bộ thẻ công khai về active recall và spaced repetition.',
      color: '#C7A565',
      visibility: 'public',
      cards: [
        {
          front: 'Active recall',
          back: 'Chủ động truy xuất kiến thức từ trí nhớ thay vì chỉ đọc lại.',
          example: 'Đóng tài liệu và tự trả lời câu hỏi sau mỗi phần học.',
        },
        {
          front: 'Spaced repetition',
          back: 'Ôn lại kiến thức theo khoảng cách thời gian tăng dần.',
          example: 'Ôn sau 1 ngày, 3 ngày, 7 ngày rồi 14 ngày.',
        },
        {
          front: 'Interleaving',
          back: 'Xen kẽ nhiều dạng bài hoặc chủ đề trong một buổi học.',
          example: 'Luyện đại số, hình học và xác suất theo từng cụm ngắn.',
        },
        {
          front: 'Feynman technique',
          back: 'Giải thích kiến thức bằng ngôn ngữ đơn giản để phát hiện chỗ chưa hiểu.',
          example: 'Thử giảng lại khái niệm như đang nói với người mới học.',
        },
      ],
    });

    const microeconomics = await createSet(connection, lanId, {
      title: 'Kinh tế vi mô căn bản',
      description: 'Cung, cầu, chi phí cơ hội và các cấu trúc thị trường.',
      color: '#B47B36',
      cards: [
        {
          front: 'Chi phí cơ hội',
          back: 'Giá trị của phương án tốt nhất bị từ bỏ khi đưa ra lựa chọn.',
          example: 'Thời gian đi làm thêm là chi phí cơ hội của việc học buổi tối.',
        },
        {
          front: 'Cầu',
          back: 'Lượng hàng hóa người tiêu dùng sẵn sàng và có khả năng mua ở mỗi mức giá.',
          example: 'Khi giá giảm, lượng cầu thường tăng nếu các yếu tố khác không đổi.',
        },
        {
          front: 'Cung',
          back: 'Lượng hàng hóa nhà sản xuất sẵn sàng bán ở mỗi mức giá.',
          example: 'Giá cao hơn có thể khuyến khích doanh nghiệp tăng lượng cung.',
        },
        {
          front: 'Điểm cân bằng',
          back: 'Mức giá và sản lượng tại đó lượng cung bằng lượng cầu.',
          example: 'Thị trường có xu hướng điều chỉnh về điểm cân bằng.',
        },
        {
          front: 'Độ co giãn',
          back: 'Mức độ phản ứng của một biến trước thay đổi của biến khác.',
          example: 'Cầu co giãn mạnh khi người mua dễ tìm sản phẩm thay thế.',
        },
      ],
    });

    const flutterWidgets = await createSet(connection, lanId, {
      title: 'Flutter – Widget nền tảng',
      description: 'Các widget thiết yếu để xây dựng giao diện Flutter.',
      color: '#17233C',
      cards: [
        {
          front: 'StatelessWidget',
          back: 'Widget không tự lưu trạng thái thay đổi trong vòng đời của nó.',
          example: 'Dùng cho nhãn, icon hoặc giao diện chỉ phụ thuộc tham số đầu vào.',
        },
        {
          front: 'StatefulWidget',
          back: 'Widget có đối tượng State để quản lý dữ liệu thay đổi theo thời gian.',
          example: 'Dùng cho form, animation hoặc bộ đếm tương tác.',
        },
        {
          front: 'Expanded',
          back: 'Cho phép widget con chiếm phần không gian còn lại trong Row hoặc Column.',
          example: 'Bọc nội dung dài trong Expanded để tránh overflow theo chiều ngang.',
        },
        {
          front: 'ListView.builder',
          back: 'Tạo danh sách cuộn theo nhu cầu, phù hợp với dữ liệu có nhiều phần tử.',
          example: 'Chỉ những item gần vùng hiển thị mới được dựng.',
        },
      ],
    });

    await connection.query(
      `INSERT INTO flashcard_set_shares
         (set_id, shared_with_user_id, shared_by_user_id, permission)
       VALUES (?, ?, ?, 'viewer'), (?, ?, ?, 'viewer')`,
      [cellBiology.id, lanId, minhId, flutterWidgets.id, minhId, lanId]
    );

    const activeRecallNote = await createNote(connection, minhId, {
      title: 'Quy trình Active Recall',
      content: [
        '1. Học một phần ngắn trong 20–25 phút.',
        '2. Đóng tài liệu và viết lại ý chính từ trí nhớ.',
        '3. So sánh với tài liệu, đánh dấu phần còn thiếu.',
        '4. Tạo flashcard cho các ý khó.',
        '5. Ôn lại theo lịch giãn cách.',
      ].join('\n'),
    });
    const biologyNote = await createNote(connection, minhId, {
      title: 'Tóm tắt Sinh học tế bào',
      content: 'Tế bào là đơn vị cấu trúc và chức năng cơ bản của cơ thể sống. Màng sinh chất kiểm soát trao đổi chất; nhân lưu DNA; ty thể tạo ATP; ribosome tổng hợp protein.',
    });
    await createNote(connection, minhId, {
      title: 'Mẫu ghi chú Cornell',
      content: 'Cột trái: câu hỏi và từ khóa.\nCột phải: nội dung chính.\nCuối trang: tóm tắt bằng 2–3 câu.\n\nGhi chú mẫu này được đặt công khai để thử tính năng tìm kiếm.',
      visibility: 'public',
    });
    await createNote(connection, lanId, {
      title: 'Công thức Kinh tế vi mô',
      content: 'Độ co giãn của cầu theo giá = % thay đổi lượng cầu / % thay đổi giá.\nDoanh thu = Giá × Sản lượng.\nLợi nhuận = Tổng doanh thu − Tổng chi phí.',
    });
    const examChecklistNote = await createNote(connection, lanId, {
      title: 'Checklist tuần thi',
      content: '□ Chốt danh sách chương cần ôn\n□ Làm đề thử có bấm giờ\n□ Ôn lại các thẻ Chưa nhớ\n□ Chuẩn bị đồ dùng\n□ Ngủ đủ trước ngày thi',
    });

    await connection.query(
      `INSERT INTO note_shares
         (note_id, shared_with_user_id, shared_by_user_id, permission)
       VALUES (?, ?, ?, 'viewer'), (?, ?, ?, 'viewer')`,
      [biologyNote, lanId, minhId, examChecklistNote, minhId, lanId]
    );

    await connection.query(
      `INSERT INTO study_progress
         (user_id, set_id, total_cards, learned_cards, correct_answers,
          wrong_answers, last_studied_at)
       VALUES (?, ?, 6, 4, 17, 4, ?),
              (?, ?, 5, 3, 10, 3, ?),
              (?, ?, 5, 2, 8, 4, ?),
              (?, ?, 4, 2, 7, 2, ?)`,
      [
        minhId,
        academicEnglish.id,
        daysAgo(0),
        minhId,
        cellBiology.id,
        daysAgo(1),
        lanId,
        microeconomics.id,
        daysAgo(0),
        lanId,
        flutterWidgets.id,
        daysAgo(1),
      ]
    );

    const minhSessions = [
      { daysAgo: 6, total: 6, learned: 2, correct: 5, wrong: 1 },
      { daysAgo: 5, total: 5, learned: 3, correct: 4, wrong: 1 },
      { daysAgo: 4, total: 6, learned: 4, correct: 5, wrong: 1 },
      { daysAgo: 3, total: 5, learned: 3, correct: 4, wrong: 1 },
      { daysAgo: 2, total: 6, learned: 5, correct: 5, wrong: 1 },
      { daysAgo: 1, total: 5, learned: 4, correct: 4, wrong: 1 },
      { daysAgo: 0, total: 6, learned: 4, correct: 5, wrong: 1 },
    ];
    for (const session of minhSessions) {
      await createSession(connection, minhId, academicEnglish.id, session);
    }
    await createSession(connection, minhId, cellBiology.id, {
      daysAgo: 0,
      hour: 9,
      total: 5,
      learned: 3,
      correct: 4,
      wrong: 1,
    });

    const lanSessions = [
      { daysAgo: 3, total: 5, learned: 2, correct: 3, wrong: 2 },
      { daysAgo: 1, total: 4, learned: 2, correct: 3, wrong: 1 },
      { daysAgo: 0, total: 5, learned: 3, correct: 4, wrong: 1 },
    ];
    for (const session of lanSessions) {
      await createSession(connection, lanId, microeconomics.id, session);
    }

    await createReview(connection, minhId, academicEnglish.id, academicEnglish.cardIds[0], {
      rating: 'forgotten',
      repetitions: 0,
      intervalDays: 1,
      nextReviewAt: daysAgo(1),
      lastReviewedAt: daysAgo(2),
    });
    await createReview(connection, minhId, academicEnglish.id, academicEnglish.cardIds[1], {
      rating: 'learning',
      repetitions: 2,
      intervalDays: 3,
      nextReviewAt: daysFromNow(1),
      lastReviewedAt: daysAgo(2),
    });
    await createReview(connection, minhId, academicEnglish.id, academicEnglish.cardIds[2], {
      rating: 'remembered',
      repetitions: 3,
      intervalDays: 14,
      nextReviewAt: daysFromNow(8),
      lastReviewedAt: daysAgo(6),
    });
    await createReview(connection, minhId, cellBiology.id, cellBiology.cardIds[0], {
      rating: 'learning',
      repetitions: 1,
      intervalDays: 3,
      nextReviewAt: daysAgo(0, 7),
      lastReviewedAt: daysAgo(3),
    });
    await createReview(connection, minhId, flutterWidgets.id, flutterWidgets.cardIds[0], {
      rating: 'remembered',
      repetitions: 2,
      intervalDays: 7,
      nextReviewAt: daysFromNow(3),
      lastReviewedAt: daysAgo(4),
    });

    await createReview(connection, lanId, microeconomics.id, microeconomics.cardIds[0], {
      rating: 'forgotten',
      repetitions: 0,
      intervalDays: 1,
      nextReviewAt: daysAgo(1),
      lastReviewedAt: daysAgo(2),
    });
    await createReview(connection, lanId, microeconomics.id, microeconomics.cardIds[1], {
      rating: 'learning',
      repetitions: 1,
      intervalDays: 3,
      nextReviewAt: daysFromNow(1),
      lastReviewedAt: daysAgo(2),
    });
    await createReview(connection, lanId, cellBiology.id, cellBiology.cardIds[1], {
      rating: 'remembered',
      repetitions: 2,
      intervalDays: 7,
      nextReviewAt: daysFromNow(4),
      lastReviewedAt: daysAgo(3),
    });

    await connection.query(
      `INSERT INTO chat_history (user_id, role, message, created_at)
       VALUES (?, 'user', ?, ?),
              (?, 'assistant', ?, ?),
              (?, 'user', ?, ?),
              (?, 'assistant', ?, ?)`,
      [
        minhId,
        'Giải thích active recall thật ngắn gọn.',
        daysAgo(1),
        minhId,
        'Active recall là cách chủ động tự nhớ lại kiến thức mà không nhìn tài liệu, giúp phát hiện phần chưa vững.',
        daysAgo(1),
        lanId,
        'Tạo kế hoạch ôn thi trong ba ngày.',
        daysAgo(1),
        lanId,
        'Ngày 1 hệ thống kiến thức, ngày 2 làm đề và sửa lỗi, ngày 3 ôn thẻ khó và nghỉ ngơi hợp lý.',
        daysAgo(1),
      ]
    );

    // Keep variables referenced to make the intended sample inventory explicit.
    void studySkills;
    void activeRecallNote;

    await connection.commit();
    console.log('Demo database seeded successfully.');
    console.log(`Minh: ${demoUsers[0].email} / ${demoPassword}`);
    console.log(`Lan:  ${demoUsers[1].email} / ${demoPassword}`);
    console.log('The seed is repeatable and only resets these two demo accounts.');
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    await connection.end();
  }
}

seed().catch((error) => {
  console.error('Demo seed failed:', error.message);
  process.exitCode = 1;
});
