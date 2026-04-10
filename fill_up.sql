-- ============================================================
-- Скрипт заполнения базы данных исследовательского отдела
-- (исправленная версия)
-- ============================================================

-- Отключаем проверку внешних ключей для очистки
SET session_replication_role = replica;

-- Очистка таблиц в порядке, обратном зависимостям
TRUNCATE TABLE Action_users CASCADE;
TRUNCATE TABLE Action CASCADE;
TRUNCATE TABLE Citation CASCADE;
TRUNCATE TABLE Foreign_Authorship CASCADE;
TRUNCATE TABLE Authorship CASCADE;
TRUNCATE TABLE Paper CASCADE;
TRUNCATE TABLE Conference_Work CASCADE;
TRUNCATE TABLE Conference_Theme CASCADE;
TRUNCATE TABLE Conference CASCADE;
TRUNCATE TABLE Event_Researcher CASCADE;
TRUNCATE TABLE Event_Theme CASCADE;
TRUNCATE TABLE Event CASCADE;
TRUNCATE TABLE Researcher_Work CASCADE;
TRUNCATE TABLE Work CASCADE;
TRUNCATE TABLE Theme CASCADE;
TRUNCATE TABLE Researcher CASCADE;
TRUNCATE TABLE Paycheck CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE Rank CASCADE;
TRUNCATE TABLE WType CASCADE;
TRUNCATE TABLE Lang CASCADE;
TRUNCATE TABLE TAction CASCADE;
TRUNCATE TABLE Foreign_author CASCADE;
TRUNCATE TABLE Foreign_work CASCADE;

-- Включаем проверку внешних ключей обратно
SET session_replication_role = DEFAULT;

-- Сброс последовательностей (чтобы ID начинали с 1)
SELECT setval(pg_get_serial_sequence('users', 'user_id'), 1, false);
SELECT setval(pg_get_serial_sequence('rank', 'rank_id'), 1, false);
SELECT setval(pg_get_serial_sequence('wtype', 'wtype_id'), 1, false);
SELECT setval(pg_get_serial_sequence('lang', 'lang_id'), 1, false);
SELECT setval(pg_get_serial_sequence('taction', 'taction_id'), 1, false);
SELECT setval(pg_get_serial_sequence('foreign_author', 'foreign_id'), 1, false);
SELECT setval(pg_get_serial_sequence('foreign_work', 'for_work_id'), 1, false);
SELECT setval(pg_get_serial_sequence('researcher', 'researcher_id'), 1, false);
SELECT setval(pg_get_serial_sequence('theme', 'theme_id'), 1, false);
SELECT setval(pg_get_serial_sequence('work', 'work_id'), 1, false);
SELECT setval(pg_get_serial_sequence('event', 'event_id'), 1, false);
SELECT setval(pg_get_serial_sequence('conference', 'conference_id'), 1, false);
SELECT setval(pg_get_serial_sequence('paper', 'paper_id'), 1, false);
SELECT setval(pg_get_serial_sequence('action', 'action_id'), 1, false);
SELECT setval(pg_get_serial_sequence('paycheck', 'paycheck_id'), 1, false);

-- ============================================================
-- 1. Заполнение независимых справочников
-- ============================================================

INSERT INTO users (user_id, name, date_of_birth, sex, create_date, email, password_hash, phone)
VALUES
    (1, 'Иван Петров', '1985-03-15', 'M', '2023-01-10 09:00:00', 'ivan.petrov@example.com', 'hash_pwd_1', '+79001234567'),
    (2, 'Мария Смирнова', '1990-07-22', 'F', '2023-02-14 10:30:00', 'maria.smirnova@example.com', 'hash_pwd_2', NULL),
    (3, 'Алексей Иванов', '1978-11-02', 'M', '2022-11-05 14:15:00', NULL, 'hash_pwd_3', '+79119876543'),
    (4, 'Елена Козлова', '1982-05-30', 'F', '2023-03-20 11:20:00', 'elena.kozlova@example.com', 'hash_pwd_4', '+79211223344'),
    (5, 'Дмитрий Соколов', '1995-09-18', 'M', '2023-04-01 09:45:00', 'dmitry.sokolov@example.com', 'hash_pwd_5', NULL);

INSERT INTO Rank (rank_id, description, name)
VALUES
    (1, 'Младший научный сотрудник', 'МНС'),
    (2, 'Старший научный сотрудник', 'СНС'),
    (3, 'Ведущий научный сотрудник', 'ВНС'),
    (4, 'Главный научный сотрудник', 'ГНС'),
    (5, 'Академик', 'Академик');

INSERT INTO WType (wtype_id, description, name)
VALUES
    (1, 'Научная статья в журнале', 'Статья'),
    (2, 'Доклад на конференции', 'Доклад'),
    (3, 'Монография', 'Монография'),
    (4, 'Препринт', 'Препринт'),
    (5, 'Технический отчёт', 'Отчёт');

INSERT INTO Lang (lang_id, description, name)
VALUES
    (1, 'Русский язык', 'Русский'),
    (2, 'Английский язык', 'English'),
    (3, 'Немецкий язык', 'Deutsch'),
    (4, 'Французский язык', 'Français');

INSERT INTO TAction (taction_id, description, name)
VALUES
    (1, 'Добавление новой публикации', 'Добавление работы'),
    (2, 'Редактирование профиля', 'Редактирование'),
    (3, 'Участие в конференции', 'Участие в конференции'),
    (4, 'Получение гранта', 'Грант'),
    (5, 'Назначение руководителем', 'Назначение');

INSERT INTO Foreign_author (foreign_id, name, date_of_birth, sex, h_index, workplace)
VALUES
    (1, 'John Smith', '1975-06-12', 'M', 25, 'MIT'),
    (2, 'Anna Müller', '1980-11-23', 'F', 18, 'TU Munich'),
    (3, 'Pierre Dubois', '1968-04-05', 'M', 30, 'Sorbonne');

INSERT INTO Foreign_work (for_work_id, pub_date, name)
VALUES
    (1, '2020-05-10', 'Advanced Machine Learning Techniques'),
    (2, '2021-08-15', 'Quantum Computing: A Review'),
    (3, '2019-12-01', 'Climate Change Models');

-- ============================================================
-- 2. Заполнение Researcher
-- ============================================================
INSERT INTO Researcher (researcher_id, score, h_index, res_status, lead_researcher_id, rank_id, user_id)
VALUES
    (1, 150.75, 12, 'активный', NULL, 2, 1),
    (2, 210.50, 18, 'активный', 1, 3, 2),
    (3, 95.20,  8, 'активный', 1, 1, 3),
    (4, 320.00, 25, 'активный', NULL, 4, 4),
    (5, 45.80,  3, 'в отпуске', 4, 1, 5);

-- ============================================================
-- 3. Заполнение Theme
-- ============================================================
INSERT INTO Theme (theme_id, description, name, user_id, parent_theme_id)
VALUES
    (1, 'Исследования в области искусственного интеллекта', 'ИИ', 1, NULL),
    (2, 'Машинное обучение и нейросети', 'Машинное обучение', 2, 1),
    (3, 'Компьютерное зрение', 'Компьютерное зрение', 3, 2),
    (4, 'Обработка естественного языка', 'NLP', 2, 2),
    (5, 'Квантовые вычисления', 'Квантовые вычисления', 4, NULL),
    (6, 'Квантовые алгоритмы', 'Квантовые алгоритмы', 5, 5);

-- ============================================================
-- 4. Заполнение Work (исправлено название 2-й работы)
-- ============================================================
INSERT INTO Work (work_id, result, name, start_date, fin_date, wtype_id, lang_id, theme_id)
VALUES
    (1, 'Опубликована статья в журнале "AI Today"', 'Нейросети для распознавания', '2023-02-01', '2023-05-30', 1, 2, 2),
    (2, 'Доклад представлен на конференции CVPR', 'Методы компьютерного зрения', '2023-03-10', '2023-06-15', 2, 2, 3),
    (3, 'Монография издана', 'Введение в квантовые вычисления', '2022-09-01', '2023-01-20', 3, 1, 5),
    (4, 'Технический отчёт сдан заказчику', 'Анализ тональности текстов', '2023-04-01', '2023-07-01', 5, 1, 4),
    (5, 'Препринт выложен на arXiv', 'Квантовые алгоритмы оптимизации', '2023-08-01', NULL, 4, 2, 6);

-- ============================================================
-- 5. Заполнение Event
-- ============================================================
INSERT INTO Event (event_id, duration, start_date, result, name, location)
VALUES
    (1, '2 days', '2023-05-20', 'Успешно проведён семинар', 'Семинар по ИИ', 'Москва'),
    (2, '3 days', '2023-06-10', 'Опубликован сборник тезисов', 'Конференция молодых учёных', 'Санкт-Петербург'),
    (3, '1 day', '2023-07-05', NULL, 'Воркшоп по квантовым вычислениям', 'Казань');

-- ============================================================
-- 6. Заполнение Conference
-- ============================================================
INSERT INTO Conference (conference_id, name, is_free, duration, start_date, location, prev_con_id)
VALUES
    (1, 'Международная конференция по ИИ 2023', FALSE, '4 days', '2023-09-10', 'Москва', NULL),
    (2, 'Международная конференция по ИИ 2024', FALSE, '4 days', '2024-09-15', 'Санкт-Петербург', 1),
    (3, 'Летняя школа по квантовым технологиям', TRUE, '5 days', '2023-08-01', 'Новосибирск', NULL),
    (4, 'Семинар по NLP', TRUE, '1 day', '2023-10-20', 'Екатеринбург', NULL);

-- ============================================================
-- 7. Заполнение Paper
-- ============================================================
INSERT INTO Paper (paper_id, name, pub_date, last_visit, VERSION, content, lang_id, con_id)
VALUES
    (1, 'Глубокие нейронные сети для анализа изображений', '2023-06-01', '2023-06-15', 1, 'Текст статьи...', 1, 1),
    (2, 'Quantum Machine Learning: A Survey', '2023-07-10', '2023-07-20', 1, 'Content in English...', 2, 3),
    (3, 'Методы обработки естественного языка', '2023-05-05', '2023-05-10', 1, 'Полный текст...', 1, NULL),
    (4, 'Квантовые алгоритмы для оптимизации', '2023-08-01', '2023-08-05', 1, 'Paper content...', 2, 2),
    (5, 'Обзор современных подходов в компьютерном зрении', '2023-09-01', '2023-09-02', 1, 'Текст обзора...', 1, 1);

-- ============================================================
-- 8. Связующие таблицы
-- ============================================================
INSERT INTO Event_Theme (event_id, theme_id)
VALUES
    (1, 1), (1, 2),
    (2, 2), (2, 3), (2, 4),
    (3, 5), (3, 6);

INSERT INTO Event_Researcher (event_id, researcher_id)
VALUES
    (1, 1), (1, 2), (1, 3),
    (2, 2), (2, 4), (2, 5),
    (3, 4), (3, 5);

INSERT INTO Researcher_Work (researcher_id, work_id)
VALUES
    (1, 1), (2, 1), (3, 2), (4, 3), (4, 4), (5, 5), (2, 2);

INSERT INTO Conference_Work (conference_id, work_id)
VALUES
    (1, 1), (1, 2), (2, 5), (3, 3);

INSERT INTO Conference_Theme (conference_id, theme_id)
VALUES
    (1, 1), (1, 2), (1, 3),
    (2, 1), (2, 2),
    (3, 5), (3, 6),
    (4, 4);

INSERT INTO Authorship (researcher_id, paper_id)
VALUES
    (1, 1), (2, 1), (3, 3), (4, 2), (4, 4), (5, 5);

INSERT INTO Foreign_Authorship (foreign_id, paper_id)
VALUES
    (1, 2), (2, 4);

INSERT INTO Citation (citation_id, parent_paper_id, quoted_paper_id)
VALUES
    (1, 1, 3),
    (2, 2, 4),
    (3, 4, 2),
    (4, 5, 1);

-- ============================================================
-- 9. Заполнение Action и Action_users
-- ============================================================
INSERT INTO Action (action_id, add_info, time, taction_id)
VALUES
    (1, 'Добавлена работа "Нейросети для распознавания"', '2023-02-01 10:30:00', 1),
    (2, 'Обновлён профиль исследователя', '2023-03-15 14:20:00', 2),
    (3, 'Участие в семинаре по ИИ', '2023-05-20 09:00:00', 3),
    (4, 'Получен грант РФФИ', '2023-06-01 11:00:00', 4),
    (5, 'Назначен новый руководитель', '2023-07-01 16:00:00', 5);

INSERT INTO Action_users (action_id, user_id)
VALUES
    (1, 1), (1, 2),
    (2, 2),
    (3, 1), (3, 2), (3, 3),
    (4, 4),
    (5, 1), (5, 5);

-- ============================================================
-- 10. Заполнение Paycheck
-- ============================================================
INSERT INTO Paycheck (paycheck_id, date, amount, currency, description, sender_id, recipient_id, con_id)
VALUES
    (1, '2023-05-25 12:00:00', 50000.00, 'RUB', 'Зарплата за май', NULL, 1, NULL),
    (2, '2023-06-25 12:00:00', 60000.00, 'RUB', 'Зарплата за июнь', NULL, 2, NULL),
    (3, '2023-07-01 10:00:00', 150000.00, 'RUB', 'Оплата участия в конференции', 3, 4, 1),
    (4, '2023-08-01 09:30:00', 200000.00, 'RUB', 'Грант для исследования', 5, 1, NULL),
    (5, '2023-09-01 14:00:00', 75000.00, 'RUB', 'Премия за публикацию', NULL, 5, 3);

-- ============================================================
-- Конец скрипта заполнения
-- ============================================================