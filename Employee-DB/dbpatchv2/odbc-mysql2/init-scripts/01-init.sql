-- Initial setup script for MySQL container
-- This runs automatically when the container is first created

-- Ensure the database exists
CREATE DATABASE IF NOT EXISTS employeedb2;

-- Grant permissions
GRANT ALL PRIVILEGES ON employeedb2.* TO 'dbpatch'@'%';
FLUSH PRIVILEGES;

USE employeedb2;

-- Database is now ready for DBPatch migrations
SELECT 'Database employeedb2 initialized successfully' AS status;
