SET @schema_name = DATABASE();

SET @has_daily_goal = (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = @schema_name AND table_name = 'users' AND column_name = 'daily_goal'
);
SET @sql = IF(@has_daily_goal = 0,
  'ALTER TABLE users ADD COLUMN daily_goal INT NOT NULL DEFAULT 20 AFTER avatar_url',
  'SELECT 1');
PREPARE statement FROM @sql; EXECUTE statement; DEALLOCATE PREPARE statement;

SET @has_set_visibility = (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = @schema_name AND table_name = 'flashcard_sets' AND column_name = 'visibility'
);
SET @sql = IF(@has_set_visibility = 0,
  "ALTER TABLE flashcard_sets ADD COLUMN visibility ENUM('private','public') NOT NULL DEFAULT 'private' AFTER color",
  'SELECT 1');
PREPARE statement FROM @sql; EXECUTE statement; DEALLOCATE PREPARE statement;

SET @has_note_visibility = (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = @schema_name AND table_name = 'notes' AND column_name = 'visibility'
);
SET @sql = IF(@has_note_visibility = 0,
  "ALTER TABLE notes ADD COLUMN visibility ENUM('private','public') NOT NULL DEFAULT 'private' AFTER drawing_data",
  'SELECT 1');
PREPARE statement FROM @sql; EXECUTE statement; DEALLOCATE PREPARE statement;

CREATE TABLE IF NOT EXISTS flashcard_set_shares (
  id INT AUTO_INCREMENT PRIMARY KEY,
  set_id INT NOT NULL,
  shared_with_user_id INT NOT NULL,
  shared_by_user_id INT NOT NULL,
  permission ENUM('viewer','editor') NOT NULL DEFAULT 'viewer',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_set_recipient (set_id, shared_with_user_id),
  INDEX idx_set_shares_recipient (shared_with_user_id),
  CONSTRAINT fk_set_shares_set FOREIGN KEY (set_id) REFERENCES flashcard_sets(id) ON DELETE CASCADE,
  CONSTRAINT fk_set_shares_recipient FOREIGN KEY (shared_with_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_set_shares_sender FOREIGN KEY (shared_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS note_shares (
  id INT AUTO_INCREMENT PRIMARY KEY,
  note_id INT NOT NULL,
  shared_with_user_id INT NOT NULL,
  shared_by_user_id INT NOT NULL,
  permission ENUM('viewer','editor') NOT NULL DEFAULT 'viewer',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_note_recipient (note_id, shared_with_user_id),
  INDEX idx_note_shares_recipient (shared_with_user_id),
  CONSTRAINT fk_note_shares_note FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
  CONSTRAINT fk_note_shares_recipient FOREIGN KEY (shared_with_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_note_shares_sender FOREIGN KEY (shared_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS study_sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  set_id INT NOT NULL,
  total_cards INT NOT NULL DEFAULT 0,
  learned_cards INT NOT NULL DEFAULT 0,
  correct_answers INT NOT NULL DEFAULT 0,
  wrong_answers INT NOT NULL DEFAULT 0,
  studied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sessions_user_date (user_id, studied_at),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_sessions_set FOREIGN KEY (set_id) REFERENCES flashcard_sets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS card_reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  card_id INT NOT NULL,
  set_id INT NOT NULL,
  rating ENUM('forgotten','learning','remembered') NOT NULL DEFAULT 'learning',
  repetitions INT NOT NULL DEFAULT 0,
  interval_days INT NOT NULL DEFAULT 1,
  next_review_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_card_review (user_id, card_id),
  INDEX idx_reviews_due (user_id, next_review_at),
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_card FOREIGN KEY (card_id) REFERENCES flashcards(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_set FOREIGN KEY (set_id) REFERENCES flashcard_sets(id) ON DELETE CASCADE
);
