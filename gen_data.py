#!/usr/bin/env python3
"""
Генератор тестовых данных для базы данных исследовательского отдела.
Генерирует реалистичные данные для всех таблиц с учётом связей и ограничений.
Использует библиотеки: psycopg2, Faker, random.
"""

import random
import sys
from datetime import date, timedelta
from faker import Faker
import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values

# ======================== НАСТРОЙКИ ========================
DB_CONFIG = {
    'dbname': 'research_center',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': 5432
}

# Количество генерируемых записей (можно изменить)
N_USERS = 50
N_FOREIGN_AUTHORS = 20
N_FOREIGN_WORKS = 15
N_RESEARCHERS = 40      # <= N_USERS, т.к. user_id UNIQUE
N_THEMES = 30
N_WORKS = 60
N_EVENTS = 20
N_CONFERENCES = 15
N_PAPERS = 50
N_ACTIONS = 30
N_PAYCHECKS = 40

# Справочные данные (можно расширить)
RANK_DATA = [
    ('Младший научный сотрудник', 'МНС'),
    ('Старший научный сотрудник', 'СНС'),
    ('Ведущий научный сотрудник', 'ВНС'),
    ('Главный научный сотрудник', 'ГНС'),
    ('Академик', 'Академик')
]

WTYPE_DATA = [
    ('Научная статья в журнале', 'Статья'),
    ('Доклад на конференции', 'Доклад'),
    ('Монография', 'Монография'),
    ('Препринт', 'Препринт'),
    ('Технический отчёт', 'Отчёт')
]

LANG_DATA = [
    ('Русский язык', 'Русский'),
    ('Английский язык', 'English'),
    ('Немецкий язык', 'Deutsch'),
    ('Французский язык', 'Français')
]

TACTION_DATA = [
    ('Добавление новой публикации', 'Добавление работы'),
    ('Редактирование профиля', 'Редактирование'),
    ('Участие в конференции', 'Участие в конференции'),
    ('Получение гранта', 'Грант'),
    ('Назначение руководителем', 'Назначение')
]

# ======================== ИНИЦИАЛИЗАЦИЯ ========================
fake = Faker('ru_RU')  # русские имена для реализма
Faker.seed(42)         # для воспроизводимости
random.seed(42)

# ======================== ФУНКЦИИ ГЕНЕРАЦИИ ========================
def insert_dictionaries(cur):
    """Вставка справочных данных (Rank, WType, Lang, TAction)"""
    print("Заполнение справочников...")
    execute_values(cur, """
        INSERT INTO Rank (description, name) VALUES %s
        ON CONFLICT (name) DO NOTHING
    """, RANK_DATA)
    execute_values(cur, """
        INSERT INTO WType (description, name) VALUES %s
        ON CONFLICT (name) DO NOTHING
    """, WTYPE_DATA)
    execute_values(cur, """
        INSERT INTO Lang (description, name) VALUES %s
        ON CONFLICT (name) DO NOTHING
    """, LANG_DATA)
    execute_values(cur, """
        INSERT INTO TAction (description, name) VALUES %s
        ON CONFLICT (name) DO NOTHING
    """, TACTION_DATA)
    print(f"  - Rank: {len(RANK_DATA)}")
    print(f"  - WType: {len(WTYPE_DATA)}")
    print(f"  - Lang: {len(LANG_DATA)}")
    print(f"  - TAction: {len(TACTION_DATA)}")

def generate_users(cur, n):
    """Генерация пользователей"""
    users = []
    for _ in range(n):
        name = fake.name()
        birth = fake.date_of_birth(minimum_age=25, maximum_age=70)
        sex = random.choice(['M', 'F'])
        create_date = fake.date_time_between(start_date='-2y', end_date='now')
        email = fake.email() if random.random() > 0.2 else None
        phone = fake.phone_number() if random.random() > 0.3 else None
        # Хотя бы email или phone
        if email is None and phone is None:
            email = fake.email()
        password_hash = f"hash_{fake.md5()}"
        users.append((name, birth, sex, create_date, email, password_hash, phone))
    execute_values(cur, """
        INSERT INTO users (name, date_of_birth, sex, create_date, email, password_hash, phone)
        VALUES %s RETURNING user_id
    """, users)
    # Получаем список созданных user_id
    user_ids = [row[0] for row in cur.fetchall()]
    print(f"  - users: {len(user_ids)}")
    return user_ids

def generate_foreign_authors(cur, n):
    """Генерация внешних авторов"""
    authors = []
    for _ in range(n):
        name = fake.name()
        birth = fake.date_of_birth(minimum_age=25, maximum_age=80)
        sex = random.choice(['M', 'F'])
        h_index = random.randint(1, 80)
        workplace = fake.company() if random.random() > 0.2 else None
        authors.append((name, birth, sex, h_index, workplace))
    execute_values(cur, """
        INSERT INTO Foreign_author (name, date_of_birth, sex, h_index, workplace)
        VALUES %s RETURNING foreign_id
    """, authors)
    ids = [row[0] for row in cur.fetchall()]
    print(f"  - foreign_author: {len(ids)}")
    return ids

def generate_foreign_works(cur, n):
    """Генерация внешних работ"""
    works = []
    for _ in range(n):
        pub_date = fake.date_between(start_date='-5y', end_date='today')
        name = fake.sentence(nb_words=5)[:100]
        works.append((pub_date, name))
    execute_values(cur, """
        INSERT INTO Foreign_work (pub_date, name) VALUES %s RETURNING for_work_id
    """, works)
    ids = [row[0] for row in cur.fetchall()]
    print(f"  - foreign_work: {len(ids)}")
    return ids

def generate_researchers(cur, user_ids, n):
    """Генерация исследователей (связь с пользователями)"""
    # Берём случайных пользователей, но не более n
    selected_users = random.sample(user_ids, min(n, len(user_ids)))
    # Получаем существующие rank_id
    cur.execute("SELECT rank_id FROM Rank")
    rank_ids = [row[0] for row in cur.fetchall()]
    researchers = []
    for user_id in selected_users:
        score = round(random.uniform(10, 500), 2)
        h_index = random.randint(1, 50)
        status = random.choice(['активный', 'в отпуске', 'в командировке'])
        # lead_researcher_id будет задан позже, пока NULL
        rank_id = random.choice(rank_ids)
        researchers.append((score, h_index, status, None, rank_id, user_id))
    execute_values(cur, """
        INSERT INTO Researcher (score, h_index, res_status, lead_researcher_id, rank_id, user_id)
        VALUES %s RETURNING researcher_id
    """, researchers)
    researcher_ids = [row[0] for row in cur.fetchall()]
    print(f"  - researcher: {len(researcher_ids)}")
    return researcher_ids

def assign_leaders(cur, researcher_ids):
    """Назначение руководителей для части исследователей"""
    # Обновляем lead_researcher_id для случайной части записей (кроме первых)
    # Руководителем может быть другой существующий исследователь
    for rid in researcher_ids:
        if random.random() < 0.6:  # 60% имеют руководителя
            # Выбираем руководителя, отличного от себя
            possible_leaders = [r for r in researcher_ids if r != rid]
            if possible_leaders:
                leader = random.choice(possible_leaders)
                cur.execute(
                    "UPDATE Researcher SET lead_researcher_id = %s WHERE researcher_id = %s",
                    (leader, rid)
                )
    print("  - назначены руководители")

def generate_themes(cur, user_ids, n):
    """Генерация тем исследований (гарантированно уникальные имена)"""
    themes = []
    for i in range(n):
        # Уникальное имя через номер и случайное слово
        name = f"Тема_{i+1}_{fake.word()}"[:30]
        description = fake.paragraph(nb_sentences=2)
        user_id = random.choice(user_ids) if user_ids else None
        themes.append((description, name, user_id, None))
    
    execute_values(cur, """
        INSERT INTO Theme (description, name, user_id, parent_theme_id)
        VALUES %s ON CONFLICT (name) DO NOTHING RETURNING theme_id
    """, themes)
    theme_ids = [row[0] for row in cur.fetchall()]
    
    # Если по какой-то причине не вставилось ни одной темы, делаем повторную вставку
    if not theme_ids:
        print("  - Повторная попытка вставки тем...")
        for i in range(n):
            name = f"Unique_Theme_{i+1}_{random.randint(1, 1000000)}"[:30]
            description = fake.paragraph(nb_sentences=2)
            user_id = random.choice(user_ids) if user_ids else None
            cur.execute("""
                INSERT INTO Theme (description, name, user_id, parent_theme_id)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (name) DO NOTHING
                RETURNING theme_id
            """, (description, name, user_id, None))
            row = cur.fetchone()
            if row:
                theme_ids.append(row[0])
    
    # Назначаем родительские темы (если есть хотя бы две темы)
    if len(theme_ids) > 1:
        for tid in theme_ids:
            if random.random() < 0.4:
                parent = random.choice([t for t in theme_ids if t != tid])
                cur.execute(
                    "UPDATE Theme SET parent_theme_id = %s WHERE theme_id = %s",
                    (parent, tid)
                )
    print(f"  - theme: {len(theme_ids)}")
    return theme_ids

def generate_works(cur, researcher_ids, wtype_ids, lang_ids, theme_ids, n):
    """Генерация работ"""
    works = []
    for _ in range(n):
        result = fake.paragraph(nb_sentences=3)
        name = fake.sentence(nb_words=4)[:30]
        start_date = fake.date_between(start_date='-3y', end_date='today')
        fin_date = fake.date_between(start_date=start_date, end_date='+1y') if random.random() > 0.3 else None
        wtype_id = random.choice(wtype_ids)
        lang_id = random.choice(lang_ids)
        theme_id = random.choice(theme_ids) if theme_ids else None
        works.append((result, name, start_date, fin_date, wtype_id, lang_id, theme_id))
    execute_values(cur, """
        INSERT INTO Work (result, name, start_date, fin_date, wtype_id, lang_id, theme_id)
        VALUES %s RETURNING work_id
    """, works)
    work_ids = [row[0] for row in cur.fetchall()]
    print(f"  - work: {len(work_ids)}")
    return work_ids

def generate_events(cur, n):
    """Генерация мероприятий"""
    events = []
    for _ in range(n):
        duration = f"{random.randint(1, 5)} days"
        start_date = fake.date_between(start_date='-2y', end_date='+1y')
        result = fake.sentence() if random.random() > 0.5 else None
        name = fake.catch_phrase()[:100]
        location = fake.city()
        events.append((duration, start_date, result, name, location))
    execute_values(cur, """
        INSERT INTO Event (duration, start_date, result, name, location)
        VALUES %s RETURNING event_id
    """, events)
    event_ids = [row[0] for row in cur.fetchall()]
    print(f"  - event: {len(event_ids)}")
    return event_ids

def generate_conferences(cur, n, prev_con_ids=None):
    """Генерация конференций"""
    confs = []
    for _ in range(n):
        name = fake.company()[:200]
        is_free = random.choice([True, False])
        duration = f"{random.randint(1, 5)} days"
        start_date = fake.date_between(start_date='-1y', end_date='+2y')
        location = fake.city()
        prev_con_id = random.choice(prev_con_ids) if prev_con_ids and random.random() < 0.3 else None
        confs.append((name, is_free, duration, start_date, location, prev_con_id))
    execute_values(cur, """
        INSERT INTO Conference (name, is_free, duration, start_date, location, prev_con_id)
        VALUES %s RETURNING conference_id
    """, confs)
    conf_ids = [row[0] for row in cur.fetchall()]
    print(f"  - conference: {len(conf_ids)}")
    return conf_ids

def generate_papers(cur, researcher_ids, foreign_author_ids, lang_ids, conf_ids, n):
    """Генерация статей"""
    papers = []
    for _ in range(n):
        name = fake.sentence(nb_words=6)[:100]
        pub_date = fake.date_between(start_date='-3y', end_date='today')
        last_visit = pub_date + timedelta(days=random.randint(1, 365))
        version = random.randint(1, 5)
        content = fake.text(max_nb_chars=2000)
        lang_id = random.choice(lang_ids)
        con_id = random.choice(conf_ids) if conf_ids and random.random() > 0.3 else None
        papers.append((name, pub_date, last_visit, version, content, lang_id, con_id))
    execute_values(cur, """
        INSERT INTO Paper (name, pub_date, last_visit, VERSION, content, lang_id, con_id)
        VALUES %s RETURNING paper_id
    """, papers)
    paper_ids = [row[0] for row in cur.fetchall()]
    print(f"  - paper: {len(paper_ids)}")
    return paper_ids

def generate_links(cur, researcher_ids, work_ids, event_ids, theme_ids, conf_ids, paper_ids, foreign_author_ids):
    """Генерация связей многие-ко-многим"""
    print("Генерация связей...")

    # Researcher_Work
    links = set()
    for _ in range(min(len(researcher_ids) * 2, len(work_ids) * 3)):
        rid = random.choice(researcher_ids)
        wid = random.choice(work_ids)
        links.add((rid, wid))
    execute_values(cur, """
        INSERT INTO Researcher_Work (researcher_id, work_id) VALUES %s
        ON CONFLICT DO NOTHING
    """, list(links))
    print(f"  - Researcher_Work: {len(links)}")

    # Event_Theme
    if event_ids and theme_ids:
        links = set()
        for _ in range(len(event_ids) * 2):
            eid = random.choice(event_ids)
            tid = random.choice(theme_ids)
            links.add((eid, tid))
        execute_values(cur, """
            INSERT INTO Event_Theme (event_id, theme_id) VALUES %s
            ON CONFLICT DO NOTHING
        """, list(links))
        print(f"  - Event_Theme: {len(links)}")
    else:
        print("  - Event_Theme: пропущено (нет event_ids или theme_ids)")

    # Event_Researcher
    links = set()
    for _ in range(len(event_ids) * 3):
        eid = random.choice(event_ids)
        rid = random.choice(researcher_ids)
        links.add((eid, rid))
    execute_values(cur, """
        INSERT INTO Event_Researcher (event_id, researcher_id) VALUES %s
        ON CONFLICT DO NOTHING
    """, list(links))
    print(f"  - Event_Researcher: {len(links)}")

    # Conference_Work
    links = set()
    for _ in range(len(conf_ids) * 2):
        cid = random.choice(conf_ids)
        wid = random.choice(work_ids)
        links.add((cid, wid))
    execute_values(cur, """
        INSERT INTO Conference_Work (conference_id, work_id) VALUES %s
        ON CONFLICT DO NOTHING
    """, list(links))
    print(f"  - Conference_Work: {len(links)}")

    # Conference_Theme
    if conf_ids and theme_ids:
        links = set()
        for _ in range(len(conf_ids) * 2):
            cid = random.choice(conf_ids)
            tid = random.choice(theme_ids)
            links.add((cid, tid))
        execute_values(cur, """
            INSERT INTO Conference_Theme (conference_id, theme_id) VALUES %s
            ON CONFLICT DO NOTHING
        """, list(links))
        print(f"  - Conference_Theme: {len(links)}")
    else:
        print("  - Conference_Theme: пропущено (нет conf_ids или theme_ids)")

    # Authorship
    random_links = set()
    for _ in range(len(paper_ids) * 2):
        rid = random.choice(researcher_ids)
        pid = random.choice(paper_ids)
        random_links.add((rid, pid))

    # 2) Коллаборации: группы исследователей, которые вместе пишут несколько статей
    num_collaborations = 5  # количество групп
    collaboration_sizes = [2, 3, 4]  # размер группы
    collaboration_links = set()

    for _ in range(num_collaborations):
        size = random.choice(collaboration_sizes)
        if len(researcher_ids) < size:
            continue
        collaborators = random.sample(researcher_ids, size)
        # Каждая группа пишет от 2 до 4 статей
        num_articles = random.randint(2, 4)
        for _ in range(num_articles):
            # Выбираем случайную статью
            paper = random.choice(paper_ids)
            for rid in collaborators:
                collaboration_links.add((rid, paper))

    # Объединяем случайные и коллаборационные связи
    all_authorship_links = random_links | collaboration_links

    # Вставляем все связи (ON CONFLICT DO NOTHING защищает от дубликатов)
    execute_values(cur, """
        INSERT INTO Authorship (researcher_id, paper_id) VALUES %s
        ON CONFLICT DO NOTHING
    """, list(all_authorship_links))
    print(f"  - Authorship: {len(all_authorship_links)}")
    
    # Citation
    if len(paper_ids) > 1:
        citations = set()
        for _ in range(len(paper_ids) // 2):
            parent = random.choice(paper_ids)
            quoted = random.choice([p for p in paper_ids if p != parent])
            citations.add((parent, quoted))
        execute_values(cur, """
            INSERT INTO Citation (parent_paper_id, quoted_paper_id) VALUES %s
            ON CONFLICT DO NOTHING
        """, list(citations))
        print(f"  - Citation: {len(citations)}")

def generate_actions(cur, user_ids, taction_ids, n):
    """Генерация действий и их связей с пользователями"""
    actions = []
    for _ in range(n):
        add_info = fake.sentence() if random.random() > 0.3 else None
        time = fake.date_time_between(start_date='-2y', end_date='now')
        taction_id = random.choice(taction_ids)
        actions.append((add_info, time, taction_id))
    execute_values(cur, """
        INSERT INTO Action (add_info, time, taction_id)
        VALUES %s RETURNING action_id
    """, actions)
    action_ids = [row[0] for row in cur.fetchall()]
    # Action_users
    links = set()
    for aid in action_ids:
        # Каждое действие связываем с 1-3 пользователями
        num_users = random.randint(1, 3)
        users_selected = random.sample(user_ids, min(num_users, len(user_ids)))
        for uid in users_selected:
            links.add((aid, uid))
    execute_values(cur, """
        INSERT INTO Action_users (action_id, user_id) VALUES %s
        ON CONFLICT DO NOTHING
    """, list(links))
    print(f"  - Action: {len(action_ids)}, Action_users: {len(links)}")
    return action_ids

def generate_paychecks(cur, researcher_ids, conference_ids, n):
    """Генерация зарплатных ведомостей/транзакций"""
    paychecks = []
    for _ in range(n):
        date = fake.date_time_between(start_date='-2y', end_date='now')
        amount = round(random.uniform(1000, 500000), 2)
        currency = random.choice(['RUB', 'USD', 'EUR'])
        description = fake.sentence()
        sender = random.choice(researcher_ids) if random.random() > 0.5 else None
        recipient = random.choice(researcher_ids) if random.random() > 0.2 else None
        con_id = random.choice(conference_ids) if conference_ids and random.random() > 0.6 else None
        paychecks.append((date, amount, currency, description, sender, recipient, con_id))
    execute_values(cur, """
        INSERT INTO Paycheck (date, amount, currency, description, sender_id, recipient_id, con_id)
        VALUES %s
    """, paychecks)
    print(f"  - Paycheck: {len(paychecks)}")

# ======================== ОСНОВНАЯ ФУНКЦИЯ ========================
def main():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        print("Подключение к БД установлено.")

        # 1. Справочники
        insert_dictionaries(cur)

        # 2. Получаем ID справочных записей
        cur.execute("SELECT rank_id FROM Rank")
        rank_ids = [r[0] for r in cur.fetchall()]
        cur.execute("SELECT wtype_id FROM WType")
        wtype_ids = [r[0] for r in cur.fetchall()]
        cur.execute("SELECT lang_id FROM Lang")
        lang_ids = [r[0] for r in cur.fetchall()]
        cur.execute("SELECT taction_id FROM TAction")
        taction_ids = [r[0] for r in cur.fetchall()]

        # 3. Генерация основных сущностей
        user_ids = generate_users(cur, N_USERS)
        foreign_author_ids = generate_foreign_authors(cur, N_FOREIGN_AUTHORS)
        foreign_work_ids = generate_foreign_works(cur, N_FOREIGN_WORKS)
        researcher_ids = generate_researchers(cur, user_ids, N_RESEARCHERS)
        assign_leaders(cur, researcher_ids)
        theme_ids = generate_themes(cur, user_ids, N_THEMES)
        work_ids = generate_works(cur, researcher_ids, wtype_ids, lang_ids, theme_ids, N_WORKS)
        event_ids = generate_events(cur, N_EVENTS)
        conference_ids = generate_conferences(cur, N_CONFERENCES)
        paper_ids = generate_papers(cur, researcher_ids, foreign_author_ids, lang_ids, conference_ids, N_PAPERS)

        # 4. Связи
        generate_links(cur, researcher_ids, work_ids, event_ids, theme_ids, conference_ids, paper_ids, foreign_author_ids)

        # 5. Действия и платежи
        generate_actions(cur, user_ids, taction_ids, N_ACTIONS)
        generate_paychecks(cur, researcher_ids, conference_ids, N_PAYCHECKS)

        conn.commit()
        print("Генерация данных завершена успешно.")
    except Exception as e:
        print(f"Ошибка: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()