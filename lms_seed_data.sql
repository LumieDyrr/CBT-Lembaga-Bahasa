-- =========================================================
-- SEED DATA LMS
-- Contoh data untuk mengisi seluruh 20 tabel pada lms_db
-- Jalankan SETELAH lms_mysql_schema.sql berhasil di-import.
-- MySQL 8.0+
--
-- Akun demo:
-- admin@example.com       / password
-- instructor@example.com  / password
-- siswa1@example.com      / password
-- siswa2@example.com      / password
--
-- Catatan: password_hash di bawah adalah contoh bcrypt hash
-- untuk kata sandi "password". Ganti dengan hash yang dibuat
-- oleh backend Anda sebelum digunakan di lingkungan nyata.
-- =========================================================

USE lms_db;
START TRANSACTION;

-- 1. USERS
INSERT INTO users
(id, name, email, password_hash, role, status, email_verified_at, created_at)
VALUES
(1, 'Administrator LMS', 'admin@example.com',
 '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
 'admin', 'active', NOW(), NOW()),
(2, 'Budi Santoso', 'instructor@example.com',
 '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
 'instructor', 'active', NOW(), NOW()),
(3, 'Andi Saputra', 'siswa1@example.com',
 '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
 'student', 'active', NOW(), NOW()),
(4, 'Siti Aminah', 'siswa2@example.com',
 '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
 'student', 'active', NOW(), NOW());

-- 2. INSTRUCTOR PROFILES
INSERT INTO instructor_profiles
(id, user_id, bio, expertise, verification_status, verified_by, verified_at)
VALUES
(1, 2, 'Pengajar bidang pengembangan web dan backend.',
 'Web Development, Go, REST API', 'approved', 1, NOW());

-- 3. CATEGORIES
INSERT INTO categories (id, name, slug)
VALUES
(1, 'Programming', 'programming'),
(2, 'Database', 'database');

-- 4. COURSES
INSERT INTO courses
(id, instructor_id, category_id, title, slug, description, level, price,
 status, reviewed_by, published_at, created_at)
VALUES
(1, 1, 1, 'Belajar Dasar Pemrograman Go', 'belajar-dasar-pemrograman-go',
 'Pengenalan bahasa Go, variabel, fungsi, struktur data, dan pembuatan REST API.',
 'beginner', 150000.00, 'published', 1, NOW(), NOW()),
(2, 1, 2, 'Dasar-Dasar MySQL', 'dasar-dasar-mysql',
 'Mempelajari SQL, relasi tabel, JOIN, dan pengelolaan database MySQL.',
 'beginner', 0.00, 'published', 1, NOW(), NOW());

-- 5. SECTIONS
INSERT INTO sections (id, course_id, title, order_no)
VALUES
(1, 1, 'Pengenalan Go', 1),
(2, 1, 'Struktur Program Go', 2),
(3, 2, 'Pengenalan Database', 1);

-- 6. LESSONS
INSERT INTO lessons
(id, section_id, title, lesson_type, content_url, content_body, duration_minutes, order_no)
VALUES
(1, 1, 'Apa Itu Golang?', 'article', NULL,
 'Go adalah bahasa pemrograman yang dikembangkan oleh Google.',
 15, 1),
(2, 1, 'Instalasi Go', 'video', 'https://example.com/videos/instalasi-go',
 NULL, 20, 2),
(3, 2, 'Membuat Program Pertama', 'article', NULL,
 'Pelajari struktur package, func main, dan penggunaan fmt.',
 25, 1),
(4, 3, 'Konsep Database Relasional', 'article', NULL,
 'Database relasional menyimpan data dalam tabel yang saling berhubungan.',
 20, 1);

-- 7. ENROLLMENTS
-- Enrollment siswa 1 pada kursus Go sudah selesai.
-- Enrollment siswa 2 pada kursus MySQL masih aktif.
INSERT INTO enrollments
(id, user_id, course_id, status, progress_percent, enrolled_at, completed_at)
VALUES
(1, 3, 1, 'completed', 100.00, NOW(), NOW()),
(2, 4, 2, 'active', 0.00, NOW(), NULL);

-- 8. LESSON PROGRESS
INSERT INTO lesson_progress
(id, enrollment_id, lesson_id, is_completed, completed_at)
VALUES
(1, 1, 1, TRUE, NOW()),
(2, 1, 2, TRUE, NOW()),
(3, 1, 3, TRUE, NOW());

-- 9. PAYMENTS
INSERT INTO payments
(id, enrollment_id, reference_no, amount, method, status, paid_at)
VALUES
(1, 1, 'PAY-LMS-2026-0001', 150000.00, 'bank_transfer', 'paid', NOW());

-- 10. CERTIFICATES
INSERT INTO certificates
(id, enrollment_id, certificate_no, issued_at)
VALUES
(1, 1, 'CERT-LMS-2026-0001', NOW());

-- 11. REVIEWS
INSERT INTO reviews
(id, user_id, course_id, rating, comment, created_at)
VALUES
(1, 3, 1, 5, 'Materi tersusun dengan baik dan mudah dipahami.', NOW()),
(2, 4, 2, 4, 'Materi pengenalan database cukup jelas.', NOW());

-- 12. QUIZZES
INSERT INTO quizzes
(id, section_id, title, passing_score, time_limit_minutes, max_attempts)
VALUES
(1, 1, 'Kuis Pengenalan Go', 70, 20, 3);

-- 13. QUESTIONS
INSERT INTO questions
(id, quiz_id, question_text, question_type, points)
VALUES
(1, 1, 'Go dikembangkan oleh perusahaan apa?', 'single_choice', 10),
(2, 1, 'Manakah ekstensi file source code Go?', 'single_choice', 10);

-- 14. QUESTION OPTIONS
INSERT INTO question_options
(id, question_id, option_text, is_correct)
VALUES
(1, 1, 'Google', TRUE),
(2, 1, 'Microsoft', FALSE),
(3, 1, 'Apple', FALSE),
(4, 1, 'Meta', FALSE),
(5, 2, '.go', TRUE),
(6, 2, '.java', FALSE),
(7, 2, '.py', FALSE),
(8, 2, '.php', FALSE);

-- 15. QUIZ ATTEMPTS
INSERT INTO quiz_attempts
(id, quiz_id, user_id, score, started_at, submitted_at)
VALUES
(1, 1, 3, 100.00, NOW(), NOW());

-- 16. QUIZ ANSWERS
INSERT INTO quiz_answers
(id, attempt_id, question_id, selected_option_id, is_correct)
VALUES
(1, 1, 1, 1, TRUE),
(2, 1, 2, 5, TRUE);

-- 17. ASSIGNMENTS
INSERT INTO assignments
(id, section_id, title, instructions, due_at, max_score)
VALUES
(1, 2, 'Membuat Program Go Sederhana',
 'Buat program Go yang menampilkan nama dan umur menggunakan fmt.Println.',
 DATE_ADD(NOW(), INTERVAL 7 DAY), 100);

-- 18. SUBMISSIONS
INSERT INTO submissions
(id, assignment_id, user_id, file_url, submitted_at, score, feedback, graded_by, graded_at)
VALUES
(1, 1, 3, 'https://example.com/submissions/tugas-go-andi.zip',
 NOW(), 90.00, 'Program berjalan dengan baik. Perhatikan kerapian kode.',
 2, NOW());

-- 19. ANNOUNCEMENTS
INSERT INTO announcements
(id, course_id, author_id, title, body, created_at)
VALUES
(1, 1, 2, 'Selamat Datang di Kursus Go',
 'Silakan pelajari materi secara berurutan dan kerjakan kuis setelah materi selesai.',
 NOW()),
(2, 2, 2, 'Informasi Kursus MySQL',
 'Kursus ini dimulai dari konsep database relasional hingga query JOIN.',
 NOW());

-- 20. DISCUSSIONS
-- Baris kedua merupakan balasan dari diskusi pertama.
INSERT INTO discussions
(id, course_id, user_id, parent_id, body, created_at)
VALUES
(1, 1, 3, NULL, 'Apakah Go cocok digunakan untuk membangun REST API?',
 NOW()),
(2, 1, 2, 1, 'Ya. Go banyak digunakan untuk membangun backend dan REST API.',
 NOW()),
(3, 2, 4, NULL, 'Apa perbedaan PRIMARY KEY dan FOREIGN KEY?',
 NOW());

COMMIT;

-- =========================================================
-- VERIFIKASI: tampilkan jumlah data pada seluruh tabel
-- =========================================================
SELECT 'users' AS table_name, COUNT(*) AS total FROM users
UNION ALL SELECT 'instructor_profiles', COUNT(*) FROM instructor_profiles
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'courses', COUNT(*) FROM courses
UNION ALL SELECT 'sections', COUNT(*) FROM sections
UNION ALL SELECT 'lessons', COUNT(*) FROM lessons
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL SELECT 'lesson_progress', COUNT(*) FROM lesson_progress
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'certificates', COUNT(*) FROM certificates
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'quizzes', COUNT(*) FROM quizzes
UNION ALL SELECT 'questions', COUNT(*) FROM questions
UNION ALL SELECT 'question_options', COUNT(*) FROM question_options
UNION ALL SELECT 'quiz_attempts', COUNT(*) FROM quiz_attempts
UNION ALL SELECT 'quiz_answers', COUNT(*) FROM quiz_answers
UNION ALL SELECT 'assignments', COUNT(*) FROM assignments
UNION ALL SELECT 'submissions', COUNT(*) FROM submissions
UNION ALL SELECT 'announcements', COUNT(*) FROM announcements
UNION ALL SELECT 'discussions', COUNT(*) FROM discussions;
