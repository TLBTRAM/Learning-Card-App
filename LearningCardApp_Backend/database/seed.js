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

    const japaneseN5 = await createSet(connection, minhId, {
      title: 'Tiếng Nhật N5 – Giao tiếp cơ bản',
      description: 'Từ vựng và mẫu câu ngắn dùng trong tình huống hằng ngày.',
      color: '#8C6A9E',
      visibility: 'public',
      cards: [
        {
          front: 'おはようございます',
          back: 'Chào buổi sáng một cách lịch sự.',
          example: '先生、おはようございます。',
        },
        {
          front: 'ありがとうございます',
          back: 'Cảm ơn một cách lịch sự.',
          example: '手伝ってくれて、ありがとうございます。',
        },
        {
          front: 'すみません',
          back: 'Xin lỗi, làm phiền hoặc dùng để gọi người khác.',
          example: 'すみません、駅はどこですか。',
        },
        {
          front: '学生（がくせい）',
          back: 'Học sinh hoặc sinh viên.',
          example: 'わたしは大学の学生です。',
        },
        {
          front: '図書館（としょかん）',
          back: 'Thư viện.',
          example: '図書館で日本語を勉強します。',
        },
        {
          front: 'いくらですか',
          back: 'Cái này giá bao nhiêu?',
          example: 'この本はいくらですか。',
        },
        {
          front: 'わかりません',
          back: 'Tôi không hiểu hoặc tôi không biết.',
          example: 'すみません、まだわかりません。',
        },
        {
          front: 'もう一度お願いします',
          back: 'Vui lòng nói hoặc làm lại một lần nữa.',
          example: 'ゆっくり、もう一度お願いします。',
        },
      ],
    });

    const dataStructures = await createSet(connection, minhId, {
      title: 'Cấu trúc dữ liệu và giải thuật',
      description: 'Kiến thức cốt lõi để ôn phỏng vấn và môn giải thuật.',
      color: '#355C7D',
      cards: [
        {
          front: 'Big O notation',
          back: 'Ký hiệu mô tả tốc độ tăng của thời gian hoặc bộ nhớ theo kích thước đầu vào.',
          example: 'Tìm kiếm nhị phân có độ phức tạp O(log n).',
        },
        {
          front: 'Stack',
          back: 'Cấu trúc LIFO: phần tử vào sau được lấy ra trước.',
          example: 'Call stack lưu trạng thái các hàm đang thực thi.',
        },
        {
          front: 'Queue',
          back: 'Cấu trúc FIFO: phần tử vào trước được lấy ra trước.',
          example: 'Hàng đợi tác vụ thường được xử lý theo thứ tự đến.',
        },
        {
          front: 'Hash table',
          back: 'Lưu cặp khóa–giá trị và dùng hàm băm để xác định vị trí lưu.',
          example: 'Tra cứu trung bình thường đạt O(1).',
        },
        {
          front: 'Binary search tree',
          back: 'Cây trong đó khóa bên trái nhỏ hơn và khóa bên phải lớn hơn nút hiện tại.',
          example: 'Cây cân bằng hỗ trợ tìm kiếm trung bình O(log n).',
        },
        {
          front: 'Breadth-first search',
          back: 'Duyệt đồ thị theo từng lớp bằng hàng đợi.',
          example: 'BFS tìm đường đi ngắn nhất trên đồ thị không trọng số.',
        },
        {
          front: 'Depth-first search',
          back: 'Đi sâu theo một nhánh trước khi quay lui.',
          example: 'DFS có thể dùng stack hoặc đệ quy.',
        },
        {
          front: 'Dynamic programming',
          back: 'Giải bài toán bằng cách lưu kết quả của các bài toán con bị lặp.',
          example: 'Dãy Fibonacci có thể tính tuyến tính bằng memoization.',
        },
      ],
    });

    const modernHistory = await createSet(connection, minhId, {
      title: 'Lịch sử thế giới hiện đại',
      description: 'Các mốc quan trọng từ Cách mạng công nghiệp đến thế kỷ XX.',
      color: '#A56A43',
      cards: [
        {
          front: 'Cách mạng công nghiệp',
          back: 'Quá trình chuyển từ sản xuất thủ công sang cơ giới hóa, bắt đầu tại Anh thế kỷ XVIII.',
          example: 'Máy hơi nước thúc đẩy sản xuất và giao thông.',
        },
        {
          front: 'Chủ nghĩa đế quốc',
          back: 'Chính sách mở rộng quyền lực thông qua chiếm đóng hoặc kiểm soát kinh tế.',
          example: 'Nhiều cường quốc châu Âu mở rộng thuộc địa trong thế kỷ XIX.',
        },
        {
          front: 'Chiến tranh thế giới thứ nhất',
          back: 'Cuộc chiến toàn cầu diễn ra từ năm 1914 đến 1918.',
          example: 'Vụ ám sát Franz Ferdinand là nguyên nhân trực tiếp châm ngòi chiến tranh.',
        },
        {
          front: 'Đại suy thoái',
          back: 'Khủng hoảng kinh tế toàn cầu bắt đầu năm 1929.',
          example: 'Thất nghiệp và sản lượng suy giảm mạnh ở nhiều quốc gia.',
        },
        {
          front: 'Liên Hợp Quốc',
          back: 'Tổ chức quốc tế thành lập năm 1945 nhằm duy trì hòa bình và hợp tác.',
          example: 'Hội đồng Bảo an chịu trách nhiệm chính về hòa bình quốc tế.',
        },
        {
          front: 'Chiến tranh Lạnh',
          back: 'Cạnh tranh chính trị, quân sự và tư tưởng giữa Hoa Kỳ và Liên Xô.',
          example: 'Hai bên tránh đối đầu quân sự trực tiếp trên quy mô lớn.',
        },
        {
          front: 'Toàn cầu hóa',
          back: 'Quá trình tăng cường kết nối kinh tế, văn hóa và công nghệ giữa các quốc gia.',
          example: 'Chuỗi cung ứng hiện đại thường trải rộng qua nhiều nước.',
        },
      ],
    });

    const organicChemistry = await createSet(connection, lanId, {
      title: 'Hóa hữu cơ – Nhóm chức',
      description: 'Nhận diện nhóm chức và tính chất hóa học cơ bản.',
      color: '#49796B',
      cards: [
        {
          front: 'Alkane',
          back: 'Hydrocarbon no chỉ chứa liên kết đơn carbon–carbon.',
          example: 'Methane CH₄ là alkane đơn giản nhất.',
        },
        {
          front: 'Alkene',
          back: 'Hydrocarbon có ít nhất một liên kết đôi carbon–carbon.',
          example: 'Ethene tham gia phản ứng cộng bromine.',
        },
        {
          front: 'Alcohol',
          back: 'Hợp chất hữu cơ chứa nhóm hydroxyl –OH.',
          example: 'Ethanol có công thức C₂H₅OH.',
        },
        {
          front: 'Aldehyde',
          back: 'Hợp chất chứa nhóm carbonyl ở đầu mạch.',
          example: 'Ethanal có thể bị oxi hóa thành ethanoic acid.',
        },
        {
          front: 'Ketone',
          back: 'Hợp chất chứa nhóm carbonyl nằm giữa hai nguyên tử carbon.',
          example: 'Propanone còn được gọi là acetone.',
        },
        {
          front: 'Carboxylic acid',
          back: 'Hợp chất chứa nhóm carboxyl –COOH.',
          example: 'Acetic acid là thành phần tạo vị chua của giấm.',
        },
        {
          front: 'Ester',
          back: 'Sản phẩm thường hình thành từ acid carboxylic và alcohol.',
          example: 'Nhiều ester có mùi thơm giống trái cây.',
        },
        {
          front: 'Isomer',
          back: 'Các chất có cùng công thức phân tử nhưng cấu trúc khác nhau.',
          example: 'Butane và isobutane là đồng phân cấu tạo.',
        },
      ],
    });

    const ieltsCollocations = await createSet(connection, lanId, {
      title: 'IELTS – Academic Collocations',
      description: 'Cụm từ học thuật dùng cho Writing và Speaking.',
      color: '#6F5B8C',
      visibility: 'public',
      cards: [
        {
          front: 'Pose a challenge',
          back: 'Tạo ra hoặc đặt ra một thách thức.',
          example: 'Rapid urbanization poses a challenge for public transport.',
        },
        {
          front: 'Reach a consensus',
          back: 'Đạt được sự đồng thuận.',
          example: 'The committee reached a consensus after a long discussion.',
        },
        {
          front: 'Play a crucial role',
          back: 'Đóng một vai trò then chốt.',
          example: 'Teachers play a crucial role in student motivation.',
        },
        {
          front: 'A growing body of evidence',
          back: 'Ngày càng có nhiều bằng chứng nghiên cứu.',
          example: 'A growing body of evidence links sleep to memory.',
        },
        {
          front: 'Address an issue',
          back: 'Giải quyết hoặc xem xét một vấn đề.',
          example: 'Governments must address the issue of air pollution.',
        },
        {
          front: 'Have a profound impact',
          back: 'Có ảnh hưởng sâu sắc.',
          example: 'Technology has had a profound impact on education.',
        },
        {
          front: 'Draw a conclusion',
          back: 'Đưa ra kết luận dựa trên thông tin hoặc bằng chứng.',
          example: 'It is difficult to draw a conclusion from a small sample.',
        },
        {
          front: 'Raise awareness',
          back: 'Nâng cao nhận thức.',
          example: 'The campaign aims to raise awareness of mental health.',
        },
      ],
    });

    const uxResearch = await createSet(connection, lanId, {
      title: 'UX Research căn bản',
      description: 'Phương pháp nghiên cứu để hiểu nhu cầu và hành vi người dùng.',
      color: '#B37A7A',
      cards: [
        {
          front: 'User interview',
          back: 'Cuộc trò chuyện có cấu trúc nhằm khám phá nhu cầu và trải nghiệm người dùng.',
          example: 'Dùng câu hỏi mở để tránh dẫn dắt người tham gia.',
        },
        {
          front: 'Usability testing',
          back: 'Quan sát người dùng thực hiện nhiệm vụ với sản phẩm.',
          example: 'Ghi lại điểm họ dừng lại, nhầm lẫn hoặc không hoàn thành.',
        },
        {
          front: 'Persona',
          back: 'Chân dung đại diện cho một nhóm người dùng dựa trên dữ liệu nghiên cứu.',
          example: 'Persona không nên chỉ dựa trên giả định của nhóm thiết kế.',
        },
        {
          front: 'Journey map',
          back: 'Sơ đồ mô tả các bước, cảm xúc và điểm chạm trong hành trình người dùng.',
          example: 'Journey map giúp phát hiện pain point giữa nhiều kênh.',
        },
        {
          front: 'Affinity mapping',
          back: 'Nhóm các quan sát hoặc insight có nội dung tương đồng.',
          example: 'Dùng sticky notes để tìm chủ đề lặp lại sau phỏng vấn.',
        },
        {
          front: 'Research bias',
          back: 'Sai lệch có hệ thống ảnh hưởng đến việc thu thập hoặc diễn giải dữ liệu.',
          example: 'Confirmation bias khiến nhà nghiên cứu ưu tiên dữ liệu phù hợp giả thuyết.',
        },
        {
          front: 'Triangulation',
          back: 'Kết hợp nhiều nguồn hoặc phương pháp để kiểm chứng một kết luận.',
          example: 'Kết hợp analytics, phỏng vấn và usability test.',
        },
      ],
    });

    await connection.query(
      `INSERT INTO flashcard_set_shares
         (set_id, shared_with_user_id, shared_by_user_id, permission)
       VALUES (?, ?, ?, 'viewer'), (?, ?, ?, 'viewer'),
              (?, ?, ?, 'viewer'), (?, ?, ?, 'viewer')`,
      [
        cellBiology.id,
        lanId,
        minhId,
        flutterWidgets.id,
        minhId,
        lanId,
        modernHistory.id,
        lanId,
        minhId,
        uxResearch.id,
        minhId,
        lanId,
      ]
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

    const extraNotes = [
      {
        userId: minhId,
        title: 'Lộ trình học tiếng Nhật N5',
        content: 'Tuần 1–2: Hiragana và Katakana.\nTuần 3–4: từ vựng theo chủ đề.\nTuần 5–6: mẫu câu cơ bản.\nMỗi ngày nghe 15 phút và ôn flashcard trước khi học bài mới.',
      },
      {
        userId: minhId,
        title: 'Cheat sheet Big O',
        content: 'Truy cập mảng: O(1).\nTìm kiếm tuyến tính: O(n).\nTìm kiếm nhị phân: O(log n).\nSắp xếp tốt: O(n log n).\nHai vòng lặp lồng nhau thường là O(n²).',
      },
      {
        userId: minhId,
        title: 'Sơ đồ tư duy – Cấu trúc dữ liệu',
        content: 'Phân nhóm: tuyến tính, cây, đồ thị và bảng băm.',
        drawingData: [
          {
            points: [
              { x: 95, y: 90 },
              { x: 150, y: 70 },
              { x: 210, y: 90 },
              { x: 150, y: 120 },
              { x: 95, y: 90 },
            ],
            color: '#7565A7',
            strokeWidth: 4,
          },
          {
            points: [
              { x: 150, y: 120 },
              { x: 150, y: 190 },
              { x: 95, y: 230 },
            ],
            color: '#17233C',
            strokeWidth: 3,
          },
          {
            points: [
              { x: 150, y: 190 },
              { x: 230, y: 230 },
            ],
            color: '#17233C',
            strokeWidth: 3,
          },
        ],
      },
      {
        userId: lanId,
        title: 'Kế hoạch IELTS Writing Task 2',
        content: 'Thứ 2: phân tích đề và lập dàn ý.\nThứ 3: luyện mở bài.\nThứ 4: luyện body paragraph.\nThứ 5: viết bài 40 phút.\nThứ 6: sửa lỗi từ vựng và ngữ pháp.',
      },
      {
        userId: lanId,
        title: 'Quy trình UX Research',
        content: '1. Xác định câu hỏi nghiên cứu.\n2. Chọn đối tượng tham gia.\n3. Chuẩn bị kịch bản.\n4. Thu thập dữ liệu.\n5. Tổng hợp insight.\n6. Chia sẻ khuyến nghị với nhóm.',
      },
      {
        userId: lanId,
        title: 'Nhóm chức Hóa hữu cơ',
        content: '–OH: alcohol.\n–CHO: aldehyde.\n>C=O: ketone.\n–COOH: carboxylic acid.\n–COO–: ester.\nƯu tiên nhận diện nhóm chức trước khi gọi tên hợp chất.',
        visibility: 'public',
      },
    ];
    const extraNoteIds = [];
    for (const note of extraNotes) {
      extraNoteIds.push(await createNote(connection, note.userId, note));
    }

    await connection.query(
      `INSERT INTO note_shares
         (note_id, shared_with_user_id, shared_by_user_id, permission)
       VALUES (?, ?, ?, 'viewer'), (?, ?, ?, 'viewer'),
              (?, ?, ?, 'viewer'), (?, ?, ?, 'viewer')`,
      [
        biologyNote,
        lanId,
        minhId,
        examChecklistNote,
        minhId,
        lanId,
        extraNoteIds[1],
        lanId,
        minhId,
        extraNoteIds[4],
        minhId,
        lanId,
      ]
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

    const extraProgress = [
      { userId: minhId, set: japaneseN5, learned: 6, correct: 24, wrong: 6, daysAgo: 1 },
      { userId: minhId, set: dataStructures, learned: 5, correct: 19, wrong: 5, daysAgo: 2 },
      { userId: minhId, set: modernHistory, learned: 3, correct: 11, wrong: 4, daysAgo: 4 },
      { userId: lanId, set: organicChemistry, learned: 6, correct: 22, wrong: 7, daysAgo: 1 },
      { userId: lanId, set: ieltsCollocations, learned: 5, correct: 18, wrong: 4, daysAgo: 2 },
      { userId: lanId, set: uxResearch, learned: 4, correct: 15, wrong: 3, daysAgo: 3 },
    ];
    for (const item of extraProgress) {
      await connection.query(
        `INSERT INTO study_progress
           (user_id, set_id, total_cards, learned_cards, correct_answers,
            wrong_answers, last_studied_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          item.userId,
          item.set.id,
          item.set.cardIds.length,
          item.learned,
          item.correct,
          item.wrong,
          daysAgo(item.daysAgo),
        ]
      );
    }

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

    const minhOlderSessions = [
      { daysAgo: 13, total: 8, learned: 2, correct: 5, wrong: 3 },
      { daysAgo: 12, total: 8, learned: 3, correct: 6, wrong: 2 },
      { daysAgo: 11, total: 7, learned: 3, correct: 5, wrong: 2 },
      { daysAgo: 10, total: 8, learned: 4, correct: 6, wrong: 2 },
      { daysAgo: 9, total: 8, learned: 4, correct: 7, wrong: 1 },
      { daysAgo: 8, total: 7, learned: 4, correct: 5, wrong: 2 },
      { daysAgo: 7, total: 8, learned: 5, correct: 7, wrong: 1 },
    ];
    for (const session of minhOlderSessions) {
      await createSession(connection, minhId, dataStructures.id, session);
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

    const lanExtraSessions = [
      { daysAgo: 6, total: 8, learned: 2, correct: 5, wrong: 3 },
      { daysAgo: 5, total: 7, learned: 3, correct: 5, wrong: 2 },
      { daysAgo: 4, total: 8, learned: 4, correct: 6, wrong: 2 },
      { daysAgo: 2, total: 8, learned: 5, correct: 7, wrong: 1 },
    ];
    for (const session of lanExtraSessions) {
      await createSession(connection, lanId, organicChemistry.id, session);
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

    const extraReviews = [
      { userId: minhId, set: japaneseN5, card: 0, rating: 'remembered', repetitions: 4, intervalDays: 14, next: 6, last: 8 },
      { userId: minhId, set: japaneseN5, card: 1, rating: 'learning', repetitions: 2, intervalDays: 3, next: 1, last: 2 },
      { userId: minhId, set: japaneseN5, card: 2, rating: 'forgotten', repetitions: 0, intervalDays: 1, next: -1, last: 2 },
      { userId: minhId, set: dataStructures, card: 0, rating: 'remembered', repetitions: 3, intervalDays: 10, next: 5, last: 5 },
      { userId: minhId, set: dataStructures, card: 3, rating: 'learning', repetitions: 1, intervalDays: 3, next: 0, last: 3 },
      { userId: minhId, set: dataStructures, card: 6, rating: 'forgotten', repetitions: 0, intervalDays: 1, next: -2, last: 3 },
      { userId: minhId, set: modernHistory, card: 2, rating: 'learning', repetitions: 2, intervalDays: 3, next: 2, last: 1 },
      { userId: minhId, set: modernHistory, card: 5, rating: 'remembered', repetitions: 3, intervalDays: 12, next: 9, last: 3 },
      { userId: lanId, set: organicChemistry, card: 0, rating: 'remembered', repetitions: 3, intervalDays: 10, next: 7, last: 3 },
      { userId: lanId, set: organicChemistry, card: 3, rating: 'learning', repetitions: 1, intervalDays: 3, next: 1, last: 2 },
      { userId: lanId, set: organicChemistry, card: 6, rating: 'forgotten', repetitions: 0, intervalDays: 1, next: -1, last: 2 },
      { userId: lanId, set: ieltsCollocations, card: 1, rating: 'learning', repetitions: 2, intervalDays: 4, next: 2, last: 2 },
      { userId: lanId, set: ieltsCollocations, card: 4, rating: 'remembered', repetitions: 4, intervalDays: 14, next: 10, last: 4 },
      { userId: lanId, set: uxResearch, card: 0, rating: 'remembered', repetitions: 2, intervalDays: 7, next: 4, last: 3 },
      { userId: lanId, set: uxResearch, card: 5, rating: 'forgotten', repetitions: 0, intervalDays: 1, next: 0, last: 1 },
    ];
    for (const review of extraReviews) {
      await createReview(
        connection,
        review.userId,
        review.set.id,
        review.set.cardIds[review.card],
        {
          rating: review.rating,
          repetitions: review.repetitions,
          intervalDays: review.intervalDays,
          nextReviewAt:
            review.next < 0 ? daysAgo(Math.abs(review.next)) : daysFromNow(review.next),
          lastReviewedAt: daysAgo(review.last),
        }
      );
    }

    await connection.query(
      `INSERT INTO chat_history (user_id, role, message, created_at)
       VALUES (?, 'user', ?, ?), (?, 'assistant', ?, ?),
              (?, 'user', ?, ?), (?, 'assistant', ?, ?)`,
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
    console.log('Inventory: 11 sets, 70 cards, 11 notes, 22 study sessions, 23 card reviews.');
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
