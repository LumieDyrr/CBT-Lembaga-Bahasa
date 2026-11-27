# LMS Database (Learning Management System)

Skema database dan data contoh untuk aplikasi Learning Management System (LMS) dengan tiga aktor: **siswa**, **instruktur**, dan **admin**. Skema ini merupakan implementasi ERD dari dokumen Use Case (halaman 5-6).

- **DBMS:** MySQL 8.0+
- **Engine:** InnoDB
- **Charset:** `utf8mb4` / `utf8mb4_unicode_ci`
- **Nama database:** `lms_db`
- **Jumlah tabel:** 20

## Isi Repository

| File | Fungsi |
|------|--------|
| `lms_mysql_schema.sql` | Membuat database `lms_db` beserta 20 tabel, constraint, dan index |
| `lms_seed_data.sql` | Mengisi seluruh tabel dengan data contoh dan menampilkan jumlah baris per tabel |

## Cara Instalasi

Pastikan MySQL 8.0 atau lebih baru sudah terpasang (fitur `CHECK` constraint memerlukan versi ini).

**1. Import skema**

```bash
mysql -u root -p < lms_mysql_schema.sql
```

**2. Import seed data** (jalankan setelah skema berhasil)

```bash
mysql -u root -p < lms_seed_data.sql
```

Setelah seed selesai, query verifikasi di akhir file akan menampilkan jumlah data pada setiap tabel.

**Alternatif lewat MySQL shell:**

```sql
SOURCE lms_mysql_schema.sql;
SOURCE lms_seed_data.sql;
```

## Akun Demo

| Peran | Email | Password |
|-------|-------|----------|
| Admin | `admin@example.com` | `password` |
| Instruktur | `instructor@example.com` | `password` |
| Siswa 1 | `siswa1@example.com` | `password` |
| Siswa 2 | `siswa2@example.com` | `password` |

> **Penting:** `password_hash` pada seed hanyalah contoh hash bcrypt untuk kata sandi `password`. Jangan dipakai di lingkungan produksi. Buat ulang hash melalui backend Anda.

## Daftar Tabel

### Pengguna
| # | Tabel | Deskripsi |
|---|-------|-----------|
| 1 | `users` | Akun siswa, instruktur, dan admin |
| 2 | `instructor_profiles` | Profil dan status verifikasi instruktur (satu profil per akun) |

### Kursus dan Materi
| # | Tabel | Deskripsi |
|---|-------|-----------|
| 3 | `categories` | Kategori kursus |
| 4 | `courses` | Data kursus, harga, level, dan status review |
| 5 | `sections` | Bab/modul dalam kursus |
| 6 | `lessons` | Materi dalam bab (video, artikel, dokumen, tautan) |

### Pendaftaran dan Progres
| # | Tabel | Deskripsi |
|---|-------|-----------|
| 7 | `enrollments` | Pendaftaran siswa ke kursus (unik per siswa per kursus) |
| 8 | `lesson_progress` | Progres penyelesaian materi per enrollment |
| 9 | `payments` | Pembayaran untuk enrollment (satu pembayaran per enrollment) |
| 10 | `certificates` | Sertifikat kelulusan (satu per enrollment) |
| 11 | `reviews` | Rating dan komentar siswa terhadap kursus |

### Kuis
| # | Tabel | Deskripsi |
|---|-------|-----------|
| 12 | `quizzes` | Kuis pada bab, nilai kelulusan, batas waktu, dan batas percobaan |
| 13 | `questions` | Pertanyaan kuis |
| 14 | `question_options` | Pilihan jawaban dan penanda jawaban benar |
| 15 | `quiz_attempts` | Percobaan pengerjaan kuis oleh siswa |
| 16 | `quiz_answers` | Jawaban siswa pada setiap percobaan |

### Tugas dan Interaksi
| # | Tabel | Deskripsi |
|---|-------|-----------|
| 17 | `assignments` | Tugas pada bab |
| 18 | `submissions` | Pengumpulan tugas, nilai, dan umpan balik |
| 19 | `announcements` | Pengumuman kursus |
| 20 | `discussions` | Forum diskusi dengan dukungan balasan bertingkat (`parent_id`) |

## Relasi Utama

```
users ──┬── instructor_profiles ── courses ── sections ──┬── lessons
        │                            │                   ├── quizzes ── questions ── question_options
        │                            │                   └── assignments ── submissions
        │                            ├── reviews
        │                            ├── announcements
        │                            └── discussions (self-reference via parent_id)
        │
        └── enrollments ──┬── lesson_progress
                          ├── payments
                          └── certificates

quiz_attempts ── quiz_answers
```

Beberapa catatan relasi:

- `courses.instructor_id` mengacu ke `instructor_profiles.id`, bukan langsung ke `users.id`.
- `courses.reviewed_by`, `instructor_profiles.verified_by`, dan `submissions.graded_by` mengacu ke `users.id`.
- `discussions.parent_id` mengacu ke `discussions.id` untuk membentuk thread balasan.
- Penghapusan data induk (kursus, bab, kuis) menggunakan `ON DELETE CASCADE` pada data turunannya, sedangkan data transaksional seperti `enrollments`, `payments`, dan `certificates` memakai `RESTRICT`.

## Nilai ENUM

Nilai ENUM ditetapkan berdasarkan alur bisnis pada dokumen karena tidak dirinci di ERD.

| Kolom | Nilai |
|-------|-------|
| `users.role` | `student`, `instructor`, `admin` |
| `users.status` | `pending`, `active`, `rejected`, `suspended` |
| `instructor_profiles.verification_status` | `pending`, `approved`, `rejected` |
| `courses.level` | `beginner`, `intermediate`, `advanced` |
| `courses.status` | `draft`, `pending_review`, `published`, `revision`, `rejected`, `archived` |
| `lessons.lesson_type` | `video`, `article`, `document`, `link` |
| `enrollments.status` | `active`, `completed`, `cancelled` |
| `payments.status` | `pending`, `paid`, `failed`, `refunded`, `expired` |
| `questions.question_type` | `single_choice`, `multiple_choice`, `true_false` |

## Data Contoh

Seed data menyediakan skenario berikut:

- 1 admin, 1 instruktur (terverifikasi), dan 2 siswa
- 2 kategori: Programming dan Database
- 2 kursus: **Belajar Dasar Pemrograman Go** (berbayar, Rp150.000) dan **Dasar-Dasar MySQL** (gratis)
- Siswa 1 sudah menyelesaikan kursus Go: pembayaran lunas, sertifikat terbit, kuis lulus (skor 100), dan tugas sudah dinilai (90)
- Siswa 2 masih aktif di kursus MySQL
- Contoh pengumuman serta diskusi dengan balasan

Seed dijalankan dalam satu transaksi (`START TRANSACTION` ... `COMMIT`), sehingga jika terjadi error, tidak ada data yang tersimpan setengah-setengah.

## Catatan Implementasi

1. Simpan password sebagai hash (bcrypt/Argon2), bukan plaintext.
2. Buat akun admin melalui proses seeding.
3. Validasi role dan status pengguna tetap harus dilakukan di sisi backend.
4. Proses pembayaran dan perubahan status enrollment sebaiknya dijalankan dalam satu database transaction.
5. Seed data memakai ID eksplisit. Jika dijalankan dua kali pada database yang sama, akan terjadi duplicate key error. Kosongkan database atau import ulang skema terlebih dahulu.
