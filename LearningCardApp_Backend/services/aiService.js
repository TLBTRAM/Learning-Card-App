const pool = require('../config/db');

const saveChatMessage = async (userId, role, message) => {
  await pool.query('INSERT INTO chat_history (user_id, role, message) VALUES (?, ?, ?)', [
    userId,
    role,
    message,
  ]);
};

const callGemini = async (messages) => {
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    return {
      content: 'GEMINI_API_KEY chưa được cấu hình hệ thống. Vui lòng kiểm tra file .env.',
    };
  }

  const systemMessage = messages.find((m) => m.role === 'system');
  const systemInstruction = systemMessage ? systemMessage.content : '';

  const contents = messages
    .filter((m) => m.role !== 'system')
    .map((m) => {
      const geminiRole = m.role === 'assistant' ? 'model' : 'user';
      return {
        role: geminiRole,
        parts: [{ text: m.content }],
      };
    });

  const requestBody = {
    contents: contents,
    generationConfig: {
      temperature: 0.7,
    },
  };

  if (systemInstruction) {
    requestBody.systemInstruction = {
      parts: [{ text: systemInstruction }],
    };
  }

  // Sử dụng model gemini-3.1-flash-lite 
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    }
  );

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error?.message || 'Yêu cầu tới API Gemini thất bại');
  }

  const reply = data.candidates?.[0]?.content?.parts?.[0]?.text || 'Không nhận được phản hồi từ trợ lý AI.';

  return {
    content: reply,
  };
};

const buildFlashcardsFromText = (text) => {
  const sentences = text
    .split(/[.!?]+/)
    .map((item) => item.trim())
    .filter(Boolean)
    .slice(0, 5);

  return sentences.map((sentence, index) => ({
    front: `Flashcard ${index + 1}`,
    back: sentence,
    example: `Được trích xuất từ phân đoạn văn bản thứ ${index + 1}`,
  }));
};

const chatWithAI = async ({ userId, message }) => {
  const [rows] = await pool.query(
    'SELECT role, message FROM chat_history WHERE user_id = ? ORDER BY created_at DESC LIMIT 6',
    [userId]
  );
  
  const formattedHistory = rows.reverse().map(r => ({
    role: r.role,
    content: r.message
  }));

  await saveChatMessage(userId, 'user', message);

  const result = await callGemini([
    {
      role: 'system',
      content: 'You are a helpful study assistant for a flashcard learning app. Answer clearly for students.',
    },
    ...formattedHistory,
    { role: 'user', content: message },
  ]);

  await saveChatMessage(userId, 'assistant', result.content);
  return result.content;
};

const explainTopic = async (topic) => {
  const result = await callGemini([
    {
      role: 'system',
      content: 'Explain academic content simply for beginners. Use examples when helpful.',
    },
    { role: 'user', content: `Please explain this topic clearly: ${topic}` },
  ]);
  return result.content;
};

const summarizeNotes = async (notes) => {
  const result = await callGemini([
    {
      role: 'system',
      content: 'Summarize notes into short study bullets and keep the meaning clear.',
    },
    { role: 'user', content: `Summarize these notes:\n${notes}` },
  ]);
  return result.content;
};

const generateFlashcards = async (text) => {
  if (!process.env.GEMINI_API_KEY) {
    return buildFlashcardsFromText(text);
  }

  const result = await callGemini([
    {
      role: 'system',
      content:
        'You are an expert educator. Convert the provided text into a JSON array of flashcards. Return ONLY a valid JSON array, do not include markdown blocks like ```json or any conversational text. Each object in the array must have exactly three keys: "front", "back", and "example". Keep content highly educational.',
    },
    {
      role: 'user',
      content: `Create up to 5 flashcards from this text: ${text}`,
    },
  ]);

  try {
    return JSON.parse(result.content);
  } catch (error) {
    console.error('Lỗi phân tích cú pháp JSON Flashcard:', error);
    return buildFlashcardsFromText(text);
  }
};

module.exports = {
  chatWithAI,
  explainTopic,
  summarizeNotes,
  generateFlashcards,
};