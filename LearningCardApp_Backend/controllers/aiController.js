const aiService = require('../services/aiService');

const chat = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) {
      return res.status(400).json({ success: false, message: 'Tin nhắn yêu cầu không được trống' });
    }

    const answer = await aiService.chatWithAI({
      userId: req.user.id,
      message,
    });

    return res.json({ success: true, message: 'AI answered successfully', data: { answer } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'AI chat failed', error: error.message });
  }
};

const generateFlashcards = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) {
      return res.status(400).json({ success: false, message: 'Dữ liệu văn bản yêu cầu không được trống' });
    }

    const flashcards = await aiService.generateFlashcards(text);
    return res.json({ success: true, message: 'Flashcards generated successfully', data: flashcards });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Generate flashcards failed', error: error.message });
  }
};

const explain = async (req, res) => {
  try {
    const { topic } = req.body;
    if (!topic) {
      return res.status(400).json({ success: false, message: 'Chủ đề yêu cầu không được trống' });
    }

    const explanation = await aiService.explainTopic(topic);
    return res.json({ success: true, message: 'Explanation generated successfully', data: { explanation } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Explain failed', error: error.message });
  }
};

const summarizeNotes = async (req, res) => {
  try {
    const { notes } = req.body;
    if (!notes) {
      return res.status(400).json({ success: false, message: 'Nội dung tóm tắt không được trống' });
    }

    const summary = await aiService.summarizeNotes(notes);
    return res.json({ success: true, message: 'Summary generated successfully', data: { summary } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Summarize notes failed', error: error.message });
  }
};

module.exports = {
  chat,
  generateFlashcards,
  explain,
  summarizeNotes,
};