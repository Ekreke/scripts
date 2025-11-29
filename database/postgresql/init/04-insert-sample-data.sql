-- Insert sample data (optional)
-- This script will be executed when the database is first created

-- Insert sample users
INSERT INTO users (username, email) VALUES
    ('john_doe', 'john@example.com'),
    ('jane_smith', 'jane@example.com'),
    ('bob_wilson', 'bob@example.com')
ON CONFLICT (username) DO NOTHING;

-- Insert sample posts
INSERT INTO posts (title, content, user_id) VALUES
    ('First Post', 'This is the first post in our blog!', 1),
    ('Welcome', 'Welcome to our PostgreSQL database!', 1),
    ('Database Setup', 'Successfully set up PostgreSQL with Docker!', 2),
    ('Sample Content', 'This is some sample content for testing.', 3)
ON CONFLICT DO NOTHING;