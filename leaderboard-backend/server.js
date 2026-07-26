import express from 'express';
import cors from 'cors';
import { getTopScores, insertOrUpdateScore, checkUsernameExists } from './database.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins (important for Godot Web/Desktop exports)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));

app.use(express.json());

// Request logger middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

/**
 * GET /leaderboard
 * Returns high scores list. Optional query parameter "limit" (default 100).
 */
app.get('/leaderboard', (req, res) => {
  try {
    let limit = 100;
    if (req.query.limit) {
      const parsedLimit = parseInt(req.query.limit, 10);
      if (!isNaN(parsedLimit) && parsedLimit > 0) {
        limit = Math.min(parsedLimit, 1000); // cap at 1000 MAX
      }
    }
    const scores = getTopScores(limit);
    res.json(scores);
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

/**
 * GET /check-username/:username
 * Returns whether a username is already taken.
 */
app.get('/check-username/:username', (req, res) => {
  try {
    const username = req.params.username ? req.params.username.trim() : '';
    if (!username) {
      return res.status(400).json({ error: 'Username is required' });
    }
    const exists = checkUsernameExists(username);
    res.json({ exists });
  } catch (error) {
    console.error('Error checking username:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

/**
 * POST /score
 * Accepts payload { "username": string, "score": number }
 */
app.post('/score', (req, res) => {
  try {
    const { username, score } = req.body;

    // Validate username presence
    if (typeof username !== 'string') {
      return res.status(400).json({ error: 'Username must be a string' });
    }

    const trimmedUsername = username.trim();
    if (!trimmedUsername) {
      return res.status(400).json({ error: 'Username is required' });
    }

    // Limit length (max 16 chars)
    if (trimmedUsername.length > 16) {
      return res.status(400).json({ error: 'Username must be 16 characters or less' });
    }

    // Basic alphanumeric/safe characters check (optional but recommended for sanitization)
    const safeUsernameRegex = /^[a-zA-Z0-9_\-\s]+$/;
    if (!safeUsernameRegex.test(trimmedUsername)) {
      return res.status(400).json({ error: 'Username contains invalid characters. Use letters, numbers, spaces, underscores, or hyphens.' });
    }

    // Validate score is a valid number
    const numericScore = Number(score);
    if (score === undefined || score === null || isNaN(numericScore)) {
      return res.status(400).json({ error: 'Valid numeric score is required' });
    }

    // Check integer/non-negative range
    if (!Number.isInteger(numericScore) || numericScore < 0) {
      return res.status(400).json({ error: 'Score must be a non-negative integer' });
    }

    // Insert or update score
    insertOrUpdateScore(trimmedUsername, numericScore);
    
    console.log(`[Success] Recorded score for "${trimmedUsername}": ${numericScore}`);
    res.json({ success: true, message: 'Score successfully recorded' });
  } catch (error) {
    console.error('Error saving score:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Start Express Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Leaderboard REST Backend running on http://localhost:${PORT}`);
});
