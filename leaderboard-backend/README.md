# Leaderboard REST Backend

A clean, lightweight backend written in **Node.js (Express)** using **SQLite** (via Node's native `node:sqlite` module). Designed specifically for storing and fetching online leaderboard scores for Godot 4 games.

## Quick Start

### 1. Install Dependencies
Navigate to this directory in your terminal and install packages:
```bash
npm install
```

### 2. Start the Server
Run the development/production server:
```bash
npm start
```
By default, the server will list on **http://localhost:3000**.

---

## API Endpoints

### 1. Get Top Scores
Returns the top high scores list sorted by score descending, then timestamp ascending.
* **URL:** `/leaderboard`
* **Method:** `GET`
* **Query Params:** `limit` (Optional, defaults to 100, max 1000)
* **Response (JSON):**
  ```json
  [
    {
      "id": 1,
      "username": "AlphaAtom",
      "score": 1250,
      "timestamp": "2026-07-26 10:20:00"
    }
  ]
  ```

### 2. Check Username
Checks if a username has already been registered in the database, ignoring casing.
* **URL:** `/check-username/:username`
* **Method:** `GET`
* **Response (JSON):**
  ```json
  {
    "exists": true
  }
  ```

### 3. Post Score
Submit a score for a player. If the player username already exists, it will only update their high score if the new score is *higher* than their previous record.
* **URL:** `/score`
* **Method:** `POST`
* **Headers:** `Content-Type: application/json`
* **Payload (JSON):**
  ```json
  {
    "username": "AlphaAtom",
    "score": 1250
  }
  ```
* **Response (JSON):**
  ```json
  {
    "success": true,
    "message": "Score successfully recorded"
  }
  ```
