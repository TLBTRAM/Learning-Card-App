const aiService = require('../services/aiService');

const chat = async (req, res) => {
  try {
    const { message, sessionId } = req.body;
    if (!message || !sessionId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Thiếu nội dung tin nhắn hoặc mã phiên trò chuyện (sessionId).' 
      });
    }

    const answer = await aiService.chatWithAI({
      userId: req.user.id,
      sessionId,
      message,
    });

    return res.json({ 
      success: true, 
      message: 'AI phản hồi thành công.', 
      data: { answer } 
    });
  } catch (error) {
    console.error('========= LỖI XỬ LÝ CHAT (BACKEND) =========');
    console.error(error); 
    console.error('============================================');

    return res.status(500).json({ 
      success: false, 
      message: 'Gửi tin nhắn tới AI thất bại.', 
      error: error.message 
    });
  }
};

const getSessions = async (req, res) => {
  try {
    const sessions = await aiService.getUserSessions(req.user.id);
    return res.json({ 
      success: true, 
      data: sessions 
    });
  } catch (error) {
    console.error('Lỗi lấy Sessions:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Không thể lấy danh sách phiên trò chuyện.', 
      error: error.message 
    });
  }
};

const getSessionDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const messages = await aiService.getSessionMessages(req.user.id, id);
    return res.json({ 
      success: true, 
      data: messages 
    });
  } catch (error) {
    console.error('Lỗi lấy chi tiết Session:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Không thể tải chi tiết phiên trò chuyện.', 
      error: error.message 
    });
  }
};

const deleteSession = async (req, res) => {
  try {
    const { id } = req.params;
    await aiService.deleteUserSession(req.user.id, id);
    return res.json({ 
      success: true, 
      message: 'Đã xóa phiên trò chuyện thành công.' 
    });
  } catch (error) {
    console.error('Lỗi xóa Session:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Xóa phiên trò chuyện thất bại.', 
      error: error.message 
    });
  }
};

module.exports = {
  chat,
  getSessions,
  getSessionDetails,
  deleteSession,
};