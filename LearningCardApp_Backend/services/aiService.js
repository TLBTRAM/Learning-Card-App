const pool = require('../config/db');

const saveChatMessage = async (userId, role, message) => {
  await pool.query('INSERT INTO chat_history (user_id, role, message) VALUES (?, ?, ?)', [userId, role, message]);
};

const callOpenAI = async (messages) => {
  const apiKey = process.env.OPENAI_API_KEY;
  const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

  if (!apiKey) {
    return {
      content: 'OPENAI_API_KEY is not configured yet. This is a sample fallback response so you can continue building and testing the app UI.',
    };
  }

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.7,
    }),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error?.message || 'AI request failed');
  }

  return {
    content: data.choices?.[0]?.message?.content || 'No AI response received.',
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
    example: `Derived from input text segment ${index + 1}`,
  }));
};

const chatWithAI = async ({ userId, message }) => {
  await saveChatMessage(userId, 'user', message);
  const result = await callOpenAI([
    {
      role: 'system',
      content: 'You are a helpful study assistant for a flashcard learning app. Answer clearly for students.',
    },
    { role: 'user', content: message },
  ]);
  await saveChatMessage(userId, 'assistant', result.content);
  return result.content;
};

const explainTopic = async (topic) => {
  const result = await callOpenAI([
    {
      role: 'system',
      content: 'Explain academic content simply for beginners. Use examples when helpful.',
    },
    { role: 'user', content: `Please explain this topic clearly: ${topic}` },
  ]);
  return result.content;
};

const summarizeNotes = async (notes) => {
  const result = await callOpenAI([
    {
      role: 'system',
      content: 'Summarize notes into short study bullets and keep the meaning clear.',
    },
    { role: 'user', content: `Summarize these notes:\n${notes}` },
  ]);
  return result.content;
};

const generateFlashcards = async (text) => {
  if (!process.env.OPENAI_API_KEY) {
    return buildFlashcardsFromText(text);
  }

  const result = await callOpenAI([
    {
      role: 'system',
      content: 'Convert study text into JSON array flashcards. Return only valid JSON with keys front, back, example.',
    },
    {
      role: 'user',
      content: `Create up to 5 flashcards from this text. Return JSON only. Text: ${text}`,
    },
  ]);

  try {
    const cleaned = result.content.replace(/```json|```/g, '').trim();
    return JSON.parse(cleaned);
  } catch (error) {
    return buildFlashcardsFromText(text);
  }
};

module.exports = {
  chatWithAI,
  explainTopic,
  summarizeNotes,
  generateFlashcards,
};
