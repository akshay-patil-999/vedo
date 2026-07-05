// server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const GROQ_KEY = process.env.GROQ_API_KEY; // .env मधून येईल
const GROQ_MODEL = 'llama-3.3-70b-versatile';

app.post('/api/ai-chat', async (req, res) => {
  try {
    const { messages } = req.body; // frontend फक्त messages पाठवेल, key नाही
    const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_KEY}` // key इथेच वापरली जाते, कधीच frontend ला जात नाही
      },
      body: JSON.stringify({ model: GROQ_MODEL, messages, temperature: 0.4, max_tokens: 600 })
    });
    const data = await groqRes.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`Vedo AI backend running on port ${PORT}`));