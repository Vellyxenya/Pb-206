import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize DB in the same directory
const dbPath = path.join(__dirname, 'leaderboard.db');
const db = new DatabaseSync(dbPath);

// Create table on startup
db.exec(`
  CREATE TABLE IF NOT EXISTS scores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    score INTEGER NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  CREATE INDEX IF NOT EXISTS idx_scores_lh ON scores(score DESC, timestamp ASC);
`);

/**
 * Checks if a username already exists in the database.
 * @param {string} username 
 * @returns {boolean}
 */
export function checkUsernameExists(username) {
  const stmt = db.prepare('SELECT 1 FROM scores WHERE LOWER(username) = LOWER(?) LIMIT 1');
  const result = stmt.all(username.trim());
  return result.length > 0;
}

/**
 * Inserts a score or updates it if the new score is higher.
 * @param {string} username 
 * @param {number} score 
 */
export function insertOrUpdateScore(username, score) {
  const trimmed = username.trim();
  
  // Use SQLite UPSERT to update only if the new score is higher, or insert if not exists
  const stmt = db.prepare(`
    INSERT INTO scores (username, score, timestamp)
    VALUES (?, ?, CURRENT_TIMESTAMP)
    ON CONFLICT(username) DO UPDATE SET
      score = CASE WHEN ? > score THEN ? ELSE score END,
      timestamp = CASE WHEN ? > score THEN CURRENT_TIMESTAMP ELSE timestamp END
  `);
  
  stmt.run(trimmed, score, score, score, score);
}

/**
 * Gets top scores descending.
 * @param {number} limit 
 * @returns {Array} List of scores (id, username, score, timestamp)
 */
export function getTopScores(limit = 100) {
  const stmt = db.prepare('SELECT id, username, score, timestamp FROM scores ORDER BY score DESC, timestamp ASC LIMIT ?');
  return stmt.all(limit);
}
