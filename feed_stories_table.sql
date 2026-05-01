-- Table for stories
CREATE TABLE IF NOT EXISTS feed_stories (
    id CHAR(36) PRIMARY KEY,
    user_id INT NOT NULL,
    media_url VARCHAR(255) NOT NULL,
    media_type ENUM('image', 'video') DEFAULT 'image',
    caption TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (user_id),
    INDEX (created_at)
);

-- Table for tracking story views
CREATE TABLE IF NOT EXISTS story_views (
    story_id CHAR(36),
    user_id INT,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (story_id, user_id),
    INDEX (story_id),
    INDEX (user_id)
);

-- Table for story reactions
CREATE TABLE IF NOT EXISTS story_reactions (
    id CHAR(36) PRIMARY KEY,
    story_id CHAR(36) NOT NULL,
    user_id INT NOT NULL,
    emoji VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (story_id) REFERENCES feed_stories(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES cinecircle(id) ON DELETE CASCADE,
    INDEX (story_id)
);
