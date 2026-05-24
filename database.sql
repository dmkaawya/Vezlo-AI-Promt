-- ============================================
-- Vezlo AI Prompt — Database Schema
-- ============================================

CREATE DATABASE IF NOT EXISTS vezlo_ai_prompt
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE vezlo_ai_prompt;

-- Prompt categories
CREATE TABLE categories (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL UNIQUE,
  slug        VARCHAR(100) NOT NULL UNIQUE,
  icon_class  VARCHAR(100) DEFAULT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Core prompts table
CREATE TABLE prompts (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(255) NOT NULL,
  caption       VARCHAR(500) DEFAULT NULL,
  prompt_text   TEXT NOT NULL,
  category_id   INT NOT NULL,
  is_original   TINYINT(1) DEFAULT 1,
  copy_count    INT UNSIGNED DEFAULT 0,
  view_count    INT UNSIGNED DEFAULT 0,
  avg_rating    DECIMAL(3,2) DEFAULT 0.00,
  status        ENUM('pending','approved','rejected') DEFAULT 'pending',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
  INDEX idx_category (category_id),
  INDEX idx_status (status),
  INDEX idx_created (created_at),
  FULLTEXT idx_search (title, caption, prompt_text)
) ENGINE=InnoDB;

-- Prompt images (1-to-many)
CREATE TABLE prompt_images (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  prompt_id   INT NOT NULL,
  image_url   VARCHAR(500) NOT NULL,
  sort_order  TINYINT UNSIGNED DEFAULT 0,
  FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Prompt tags (many-to-many)
CREATE TABLE tags (
  id   INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE prompt_tags (
  prompt_id INT NOT NULL,
  tag_id    INT NOT NULL,
  PRIMARY KEY (prompt_id, tag_id),
  FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id)    REFERENCES tags(id)    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Users / Creators
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  display_name  VARCHAR(100) NOT NULL,
  real_name     VARCHAR(100) DEFAULT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  age           TINYINT UNSIGNED DEFAULT NULL,
  country       VARCHAR(100) DEFAULT NULL,
  address       VARCHAR(255) DEFAULT NULL,
  role          ENUM('user','author','admin') DEFAULT 'user',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (email)
) ENGINE=InnoDB;

-- Link prompts to their creator
CREATE TABLE prompt_creators (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  prompt_id        INT NOT NULL,
  user_id          INT NOT NULL,
  original_creator VARCHAR(100) DEFAULT NULL,
  original_link    VARCHAR(500) DEFAULT NULL,
  FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE CASCADE
) ENGINE=InnoDB;

-- Favorites
CREATE TABLE favorites (
  user_id   INT NOT NULL,
  prompt_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, prompt_id),
  FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE CASCADE,
  FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Reports
CREATE TABLE reports (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  prompt_id   INT NOT NULL,
  reporter_id INT DEFAULT NULL,
  reason      VARCHAR(255) NOT NULL,
  details     TEXT DEFAULT NULL,
  status      ENUM('open','reviewed','resolved') DEFAULT 'open',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (prompt_id)   REFERENCES prompts(id) ON DELETE CASCADE,
  FOREIGN KEY (reporter_id) REFERENCES users(id)   ON DELETE SET NULL
) ENGINE=InnoDB;

-- Contact messages
CREATE TABLE contact_messages (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(255) NOT NULL,
  subject    VARCHAR(255) DEFAULT NULL,
  message    TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
