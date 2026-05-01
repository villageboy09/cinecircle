-- =============================================================
-- CineCircle: feed_reports table
-- Run this SQL on your database (u893187665_team_manager)
-- =============================================================

CREATE TABLE IF NOT EXISTS `feed_reports` (
    `id`         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `post_id`    VARCHAR(36)      NOT NULL,
    `user_id`    VARCHAR(36)      NOT NULL,
    `reason`     VARCHAR(100)     NOT NULL DEFAULT 'Inappropriate content',
    `details`    TEXT             NULL,
    `status`     ENUM('pending','reviewed','dismissed','actioned')
                                  NOT NULL DEFAULT 'pending',
    `created_at` DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    -- One report per user per post (duplicates silently ignored)
    UNIQUE KEY `uq_report` (`post_id`, `user_id`),
    KEY `idx_post_id` (`post_id`),
    KEY `idx_status`  (`status`),
    CONSTRAINT `fk_report_post` FOREIGN KEY (`post_id`) REFERENCES `feed_posts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
