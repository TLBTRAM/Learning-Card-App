const pool = require('../config/db');
const axios = require('axios');

const ensureSessionExists = async (userId, sessionId, firstMessage) => {
  const [rows] = await pool.query('SELECT id FROM chat_sessions WHERE id = ?', [sessionId]);
  if (rows.length === 0) {
    const title = firstMessage.length > 40 ? firstMessage.substring(0, 37) + '...' : firstMessage;
    await pool.query(
      'INSERT INTO chat_sessions (id, user_id, title) VALUES (?, ?, ?)',
      [sessionId, userId, title]
    );
  } else {
    await pool.query(
      'UPDATE chat_sessions SET updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [sessionId]
    );
  }
};

const saveChatMessage = async (userId, sessionId, role, message) => {
  await pool.query(
    'INSERT INTO chat_history (user_id, session_id, role, message) VALUES (?, ?, ?, ?)',
    [userId, sessionId, role, message]
  );
};

const callGemini = async (messages) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('LỖI: Biến môi trường GEMINI_API_KEY chưa được cấu hình trong file .env');
    return { content: 'Hệ thống AI chưa được cấu hình khóa API (API Key). Vui lòng cấu hình lại file .env ở Backend.' };
  }

  const systemInstruction = 'Bạn là một trợ lý hỗ trợ học tập đắc lực tích hợp trong ứng dụng Flashcard thông minh.';
  
  const contents = messages.map((m) => {
    const geminiRole = m.role === 'assistant' ? 'model' : 'user';
    return {
      role: geminiRole,
      parts: [{ text: m.content }],
    };
  });

  const requestBody = {
    contents: contents,
    generationConfig: { temperature: 0.7 },
    systemInstruction: { parts: [{ text: systemInstruction }] }
  };

  try {
    // model: gemini-3.1-flash-lite
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1/models/gemini-3.1-flash-lite:generateContent?key=${apiKey}`,
      requestBody,
      { 
        headers: { 'Content-Type': 'application/json' },
        timeout: 15000 // Phản hồi tối đa 15 giây
      }
    );

    const reply = response.data?.candidates?.[0]?.content?.parts?.[0]?.text || 'Trợ lý chưa kịp nghĩ ra câu trả lời.';
    return { content: reply };
  } catch (error) {
    console.error('Lỗi khi kết nối tới API Gemini (Model: gemini-3.1-flash-lite):', error.response?.data || error.message);
    try {
      console.log('Đang thử kết nối lại qua cổng v1beta...');
      const responseFallback = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${apiKey}`,
        requestBody,
        { 
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000 
        }
      );
      const replyFallback = responseFallback.data?.candidates?.[0]?.content?.parts?.[0]?.text || 'Trợ lý chưa kịp nghĩ ra câu trả lời.';
      return { content: replyFallback };
    } catch (fallbackError) {
      console.error('Thất bại ở cả cổng dự phòng:', fallbackError.response?.data || fallbackError.message);
      return { 
        content: 'Hiện tại cổng kết nối tới máy chủ AI của Google đang bận hoặc khóa API đã đạt giới hạn cuộc gọi. Bạn vui lòng thử lại sau vài giây nhé!' 
      };
    }
  }
};

const chatWithAI = async ({ userId, sessionId, message }) => {
  await ensureSessionExists(userId, sessionId, message);
  const [rows] = await pool.query(
    'SELECT role, message FROM chat_history WHERE session_id = ? ORDER BY created_at DESC LIMIT 10',
    [sessionId]
  );
  
  const contextHistory = rows && rows.length > 0 
    ? [...rows].reverse().map(r => ({ role: r.role, content: r.message }))
    : [];
  await saveChatMessage(userId, sessionId, 'user', message);
  const geminiResponse = await callGemini([
    ...contextHistory,
    { role: 'user', content: message },
  ]);
  const cleanContent = geminiResponse.content.replace(/\*\*/g, '');
  await saveChatMessage(userId, sessionId, 'assistant', cleanContent);
  return cleanContent;
};

const getUserSessions = async (userId) => {
  const [rows] = await pool.query(
    'SELECT id, title, created_at FROM chat_sessions WHERE user_id = ? ORDER BY updated_at DESC',
    [userId]
  );
  return rows.map(r => ({
    id: r.id,
    title: r.title,
    createdAt: r.created_at,
  }));
};

const getSessionMessages = async (userId, sessionId) => {
  const [rows] = await pool.query(
    'SELECT role, message, created_at FROM chat_history WHERE user_id = ? AND session_id = ? ORDER BY created_at ASC',
    [userId, sessionId]
  );
  return rows.map(r => ({
    role: r.role,
    message: r.message,
    createdAt: r.created_at,
  }));
};

const deleteUserSession = async (userId, sessionId) => {
  await pool.query('DELETE FROM chat_sessions WHERE user_id = ? AND id = ?', [userId, sessionId]);
};

module.exports = {
  chatWithAI,
  getUserSessions,
  getSessionMessages,
  deleteUserSession,
};