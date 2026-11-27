-- =========================================================
-- DATABASE LMS (Learning Management System)
-- Implementasi ERD dari USE Case.pdf halaman 5-6
-- Target: MySQL 8.0+
-- Catatan: Nilai ENUM ditetapkan berdasarkan alur bisnis pada
--          dokumen karena nilai enum tidak dirinci di ERD.
-- =========================================================

CREATE DATABASE IF NOT EXISTS lms_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE lms_db;

-- ---------------------------------------------------------
-- 1. USERS
-- Akun siswa, instruktur, dan admin.
-- Admin dibuat melalui seeding sesuai catatan use case.
-- ---------------------------------------------------------
CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('student', 'instructor', 'admin') NOT NULL,
    status ENUM('pending', 'active', 'rejected', 'suspended') NOT NULL DEFAULT 'pending',
    email_verified_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_role_status (role, status)
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 2. INSTRUCTOR PROFILES
-- user_id unik: satu akun instruktur memiliki satu profil.
-- verified_by menunjuk users.id (admin yang memverifikasi).
-- ---------------------------------------------------------
CREATE TABLE instructor_profiles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    bio TEXT NULL,
    expertise VARCHAR(255) NULL,
    verification_status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    verified_by BIGINT UNSIGNED NULL,
    verified_at DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_instructor_profiles_user (user_id),
    KEY idx_instructor_verified_by (verified_by),
    CONSTRAINT fk_instructor_profile_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_instructor_profile_verified_by
        FOREIGN KEY (verified_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 3. CATEGORIES
-- ---------------------------------------------------------
CREATE TABLE categories (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_categories_name (name),
    UNIQUE KEY uq_categories_slug (slug)
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 4. COURSES
-- instructor_id mengacu ke instructor_profiles.id.
-- reviewed_by mengacu ke users.id (admin reviewer).
-- ---------------------------------------------------------
CREATE TABLE courses (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    instructor_id BIGINT UNSIGNED NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(220) NOT NULL,
    description TEXT NULL,
    level ENUM('beginner', 'intermediate', 'advanced') NOT NULL DEFAULT 'beginner',
    price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status ENUM('draft', 'pending_review', 'published', 'revision', 'rejected', 'archived')
        NOT NULL DEFAULT 'draft',
    reviewed_by BIGINT UNSIGNED NULL,
    published_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_courses_slug (slug),
    KEY idx_courses_instructor (instructor_id),
    KEY idx_courses_category (category_id),
    KEY idx_courses_status (status),
    KEY idx_courses_reviewed_by (reviewed_by),
    CONSTRAINT chk_courses_price CHECK (price >= 0),
    CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id) REFERENCES instructor_profiles(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_courses_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_courses_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 5. SECTIONS
-- Bab/modul dalam sebuah kursus.
-- ---------------------------------------------------------
CREATE TABLE sections (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    course_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL,
    order_no INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_sections_course_order (course_id, order_no),
    CONSTRAINT fk_sections_course
        FOREIGN KEY (course_id) REFERENCES courses(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 6. LESSONS
-- Materi dalam sebuah bab.
-- ---------------------------------------------------------
CREATE TABLE lessons (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    section_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL,
    lesson_type ENUM('video', 'article', 'document', 'link') NOT NULL,
    content_url VARCHAR(2048) NULL,
    content_body LONGTEXT NULL,
    duration_minutes INT UNSIGNED NOT NULL DEFAULT 0,
    order_no INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_lessons_section_order (section_id, order_no),
    CONSTRAINT fk_lessons_section
        FOREIGN KEY (section_id) REFERENCES sections(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 7. ENROLLMENTS
-- Satu siswa hanya dapat memiliki satu enrollment per kursus.
-- ---------------------------------------------------------
CREATE TABLE enrollments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    course_id BIGINT UNSIGNED NOT NULL,
    status ENUM('active', 'completed', 'cancelled') NOT NULL DEFAULT 'active',
    progress_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    enrolled_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_enrollments_user_course (user_id, course_id),
    KEY idx_enrollments_course (course_id),
    KEY idx_enrollments_status (status),
    CONSTRAINT chk_enrollments_progress CHECK (progress_percent BETWEEN 0 AND 100),
    CONSTRAINT fk_enrollments_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES courses(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 8. LESSON PROGRESS
-- Progres setiap materi pada enrollment siswa.
-- ---------------------------------------------------------
CREATE TABLE lesson_progress (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    enrollment_id BIGINT UNSIGNED NOT NULL,
    lesson_id BIGINT UNSIGNED NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_lesson_progress_enrollment_lesson (enrollment_id, lesson_id),
    KEY idx_lesson_progress_lesson (lesson_id),
    CONSTRAINT fk_lesson_progress_enrollment
        FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_lesson_progress_lesson
        FOREIGN KEY (lesson_id) REFERENCES lessons(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 9. PAYMENTS
-- Satu record pembayaran untuk satu enrollment (sesuai UK).
-- ---------------------------------------------------------
CREATE TABLE payments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    enrollment_id BIGINT UNSIGNED NOT NULL,
    reference_no VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    method VARCHAR(50) NOT NULL,
    status ENUM('pending', 'paid', 'failed', 'refunded', 'expired') NOT NULL DEFAULT 'pending',
    paid_at DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_payments_enrollment (enrollment_id),
    UNIQUE KEY uq_payments_reference (reference_no),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0),
    CONSTRAINT fk_payments_enrollment
        FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 10. CERTIFICATES
-- Satu sertifikat untuk satu enrollment.
-- ---------------------------------------------------------
CREATE TABLE certificates (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    enrollment_id BIGINT UNSIGNED NOT NULL,
    certificate_no VARCHAR(100) NOT NULL,
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_certificates_enrollment (enrollment_id),
    UNIQUE KEY uq_certificates_number (certificate_no),
    CONSTRAINT fk_certificates_enrollment
        FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 11. REVIEWS
-- ---------------------------------------------------------
CREATE TABLE reviews (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    course_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL,
    comment TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_reviews_user (user_id),
    KEY idx_reviews_course (course_id),
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reviews_course
        FOREIGN KEY (course_id) REFERENCES courses(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 12. QUIZZES
-- ---------------------------------------------------------
CREATE TABLE quizzes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    section_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL,
    passing_score INT UNSIGNED NOT NULL DEFAULT 0,
    time_limit_minutes INT UNSIGNED NULL,
    max_attempts INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_quizzes_section (section_id),
    CONSTRAINT chk_quizzes_passing_score CHECK (passing_score BETWEEN 0 AND 100),
    CONSTRAINT fk_quizzes_section
        FOREIGN KEY (section_id) REFERENCES sections(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 13. QUESTIONS
-- ---------------------------------------------------------
CREATE TABLE questions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    quiz_id BIGINT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('single_choice', 'multiple_choice', 'true_false') NOT NULL,
    points INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_questions_quiz (quiz_id),
    CONSTRAINT fk_questions_quiz
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 14. QUESTION OPTIONS
-- ---------------------------------------------------------
CREATE TABLE question_options (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    question_id BIGINT UNSIGNED NOT NULL,
    option_text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id),
    KEY idx_question_options_question (question_id),
    CONSTRAINT fk_question_options_question
        FOREIGN KEY (question_id) REFERENCES questions(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 15. QUIZ ATTEMPTS
-- ---------------------------------------------------------
CREATE TABLE quiz_attempts (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    quiz_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    score DECIMAL(7,2) NULL,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    submitted_at DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_quiz_attempts_quiz_user (quiz_id, user_id),
    KEY idx_quiz_attempts_user (user_id),
    CONSTRAINT fk_quiz_attempts_quiz
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_quiz_attempts_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 16. QUIZ ANSWERS
-- selected_option_id boleh NULL untuk jawaban teks/pertanyaan
-- yang belum dijawab; ERD hanya memodelkan opsi terpilih.
-- ---------------------------------------------------------
CREATE TABLE quiz_answers (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    attempt_id BIGINT UNSIGNED NOT NULL,
    question_id BIGINT UNSIGNED NOT NULL,
    selected_option_id BIGINT UNSIGNED NULL,
    is_correct BOOLEAN NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_quiz_answers_attempt_question (attempt_id, question_id),
    KEY idx_quiz_answers_question (question_id),
    KEY idx_quiz_answers_option (selected_option_id),
    CONSTRAINT fk_quiz_answers_attempt
        FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_quiz_answers_question
        FOREIGN KEY (question_id) REFERENCES questions(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_quiz_answers_selected_option
        FOREIGN KEY (selected_option_id) REFERENCES question_options(id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 17. ASSIGNMENTS
-- Tugas yang berada di dalam sebuah section/bab.
-- ---------------------------------------------------------
CREATE TABLE assignments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    section_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL,
    instructions TEXT NULL,
    due_at DATETIME NULL,
    max_score INT UNSIGNED NOT NULL DEFAULT 100,
    PRIMARY KEY (id),
    KEY idx_assignments_section (section_id),
    CONSTRAINT fk_assignments_section
        FOREIGN KEY (section_id) REFERENCES sections(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 18. SUBMISSIONS
-- graded_by menunjuk users.id (instruktur/penilai).
-- ---------------------------------------------------------
CREATE TABLE submissions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    assignment_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    file_url VARCHAR(2048) NULL,
    submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    score DECIMAL(7,2) NULL,
    feedback TEXT NULL,
    graded_by BIGINT UNSIGNED NULL,
    graded_at DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_submissions_assignment_user (assignment_id, user_id),
    KEY idx_submissions_user (user_id),
    KEY idx_submissions_graded_by (graded_by),
    CONSTRAINT fk_submissions_assignment
        FOREIGN KEY (assignment_id) REFERENCES assignments(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_submissions_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_submissions_grader
        FOREIGN KEY (graded_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 19. ANNOUNCEMENTS
-- Pengumuman pada kursus yang ditulis oleh user (umumnya instruktur).
-- ---------------------------------------------------------
CREATE TABLE announcements (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    course_id BIGINT UNSIGNED NOT NULL,
    author_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_announcements_course_created (course_id, created_at),
    KEY idx_announcements_author (author_id),
    CONSTRAINT fk_announcements_course
        FOREIGN KEY (course_id) REFERENCES courses(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_announcements_author
        FOREIGN KEY (author_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- 20. DISCUSSIONS
-- parent_id menunjuk discussions.id untuk balasan/thread.
-- ---------------------------------------------------------
CREATE TABLE discussions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    course_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    parent_id BIGINT UNSIGNED NULL,
    body TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_discussions_course_created (course_id, created_at),
    KEY idx_discussions_user (user_id),
    KEY idx_discussions_parent (parent_id),
    CONSTRAINT fk_discussions_course
        FOREIGN KEY (course_id) REFERENCES courses(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_discussions_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_discussions_parent
        FOREIGN KEY (parent_id) REFERENCES discussions(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- =========================================================
-- SELESAI
-- Catatan implementasi:
-- 1. Password harus disimpan sebagai hash (mis. bcrypt/Argon2),
--    bukan plaintext.
-- 2. Buat akun admin melalui proses seeding.
-- 3. Verifikasi role/status tetap harus divalidasi di backend.
-- 4. Transaksi pembayaran dan perubahan enrollment sebaiknya
--    diproses dalam database transaction.
-- =========================================================
