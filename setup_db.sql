DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    sex BOOLEAN NOT NULL,
    create_date TIMESTAMP DEFAULT CURRENT_DATE,
    email VARCHAR(255),
    password_hash TEXT NOT NULL,
    phone VARCHAR(20),

    CONSTRAINT chk_contact
        CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE TABLE Rank (
    rank_id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE Researcher (
    researcher_id SERIAL PRIMARY KEY,
    score DECIMAL(10, 2) CHECK (score > 0),
    h_index DECIMAL(5) CHECK (h_index > 0),
    res_status VARCHAR(30),
    lead_researcher_id INT,
    rank_id INT,
    user_id INT,

    CONSTRAINT fk_lead_researcher
        FOREIGN KEY (lead_researcher_id)
        REFERENCES Researcher(researcher_id)
        ON DELETE SET NULL,
    
    CONSTRAINT fk_rank
        FOREIGN KEY (rank_id)
        REFERENCES Rank(rank_id)
        ON DELETE SET NULL,
    
    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE Theme (
    theme_id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    name VARCHAR(30) NOT NULL,
    user_id INT,
    parent_theme_id INT,

    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL,
    
    CONSTRAINT fk_parent_theme
        FOREIGN KEY (parent_theme_id)
        REFERENCES Theme(theme_id)
        ON DELETE SET NULL
);

CREATE TABLE WType (
    wtype_id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE Lang (
    lang_id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE Work (
    work_id SERIAL PRIMARY KEY,
    result TEXT NOT NULL,
    name VARCHAR(30) NOT NULL,
    start_date DATE DEFAULT CURRENT_DATE,
    fin_date DATE,

    wtype_id INT,
    lang_id INT,
    theme_id INT,

    CONSTRAINT fk_wtype
        FOREIGN KEY (wtype_id)
        REFERENCES WType(wtype_id)
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_theme
        FOREIGN KEY (theme_id)
        REFERENCES Theme(theme_id)
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_lang
        FOREIGN KEY (lang_id)
        REFERENCES Lang(lang_id)
        ON DELETE RESTRICT,
    
    CONSTRAINT chk_dates
        CHECK (start_date <= fin_date)
);

CREATE TABLE Event (
    event_id SERIAL PRIMARY KEY,
    duration INTERVAL,
    start_date DATE NOT NULL,
    result TEXT,
    name VARCHAR(100) NOT NULL,
    location TEXT
);

CREATE TABLE Event_Theme (
    event_id INT,
    theme_id INT,

    PRIMARY KEY (event_id, theme_id),

    FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE,

    FOREIGN KEY (theme_id)
        REFERENCES Theme(theme_id)
);

CREATE TABLE Event_Researcher (
    event_id INT,
    researcher_id INT,

    PRIMARY KEY (event_id, researcher_id),

    FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE,

    FOREIGN KEY (researcher_id)
        REFERENCES Researcher(researcher_id)
        ON DELETE CASCADE
);

CREATE TABLE Researcher_Work (
    researcher_id INT,
    work_id INT,

    PRIMARY KEY (researcher_id, work_id),

    FOREIGN KEY (researcher_id)
        REFERENCES Researcher(researcher_id)
        ON DELETE CASCADE,

    FOREIGN KEY (work_id)
        REFERENCES Work(work_id)
        ON DELETE CASCADE
);

CREATE TABLE TAction (
    taction_id SERIAL PRIMARY KEY,
    description TEXT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Action (
    action_id SERIAL PRIMARY KEY,
    add_info TEXT,
    time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    taction_id INT,

    CONSTRAINT fk_action_type
        FOREIGN KEY (taction_id)
        REFERENCES TAction(taction_id)
        ON DELETE RESTRICT
);

CREATE TABLE Action_users (
    action_id INT NOT NULL,
    user_id INT NOT NULL,

    PRIMARY KEY (action_id, user_id),

    FOREIGN KEY (action_id)
        REFERENCES Action(action_id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE Conference (
    conference_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    is_free BOOLEAN NOT NULL,
    duration INTERVAL,
    start_date DATE NOT NULL,
    location TEXT,
    prev_con_id INT,

    CONSTRAINT fk_prev_conference
        FOREIGN KEY (prev_con_id)
        REFERENCES Conference(conference_id)
        ON DELETE SET NULL
);

CREATE TABLE Conference_Work (
    conference_id INT NOT NULL,
    work_id INT NOT NULL,

    PRIMARY KEY (conference_id, work_id),

    FOREIGN KEY (conference_id)
        REFERENCES Conference(conference_id)
        ON DELETE CASCADE,

    FOREIGN KEY (work_id)
        REFERENCES Work(work_id)
        ON DELETE CASCADE
);

CREATE TABLE Conference_Theme (
    conference_id INT NOT NULL,
    theme_id INT NOT NULL,

    PRIMARY KEY (conference_id, theme_id),

    FOREIGN KEY (conference_id)
        REFERENCES Conference(conference_id)
        ON DELETE CASCADE,

    FOREIGN KEY (theme_id)
        REFERENCES Theme(theme_id)
        ON DELETE CASCADE
);

CREATE TABLE Paycheck (
    paycheck_id SERIAL PRIMARY KEY,
    date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount INT NOT NULL,
    currency VARCHAR(30) NOT NULL,
    description TEXT,

    sender_id INT DEFAULT 0,
    recipient_id INT DEFAULT 0,
    con_id INT DEFAULT 0,

    CONSTRAINT fk_sender_id
        FOREIGN KEY (sender_id)
        REFERENCES Researcher(researcher_id)
        ON DELETE SET DEFAULT,

    CONSTRAINT fk_recipient_id
        FOREIGN KEY (recipient_id)
        REFERENCES Researcher(researcher_id)
        ON DELETE SET DEFAULT,
    
    CONSTRAINT fk_con_id
        FOREIGN KEY (con_id)
        REFERENCES Conference(conference_id)
        ON DELETE SET DEFAULT
);

CREATE TABLE Paper (
    paper_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    pub_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_researcher DATE DEFAULT CURRENT_DATE,
    VERSION DECIMAL(3) DEFAULT 1,
    content TEXT NOT NULL,
    
    lang_id INT,
    con_id INT,

    CONSTRAINT fk_lang
        FOREIGN KEY (lang_id)
        REFERENCES Lang(lang_id)
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_conference
        FOREIGN KEY (con_id)
        REFERENCES Conference(conference_id)
        ON DELETE SET NULL
);

CREATE TABLE Citation (
    citation_id SERIAL PRIMARY KEY,
    parent_paper_id INT NOT NULL,
    quoted_paper_id INT NOT NULL,

    FOREIGN KEY (parent_paper_id)
        REFERENCES Paper(paper_id)
        ON DELETE CASCADE,

    FOREIGN KEY (quoted_paper_id)
        REFERENCES Paper(paper_id)
        ON DELETE CASCADE
);

CREATE TABLE Authorship (
    researcher_id INT NOT NULL,
    paper_id INT NOT NULL,

    PRIMARY KEY (researcher_id, paper_id),

    FOREIGN KEY (researcher_id)
        REFERENCES Researcher(researcher_id)
        ON DELETE CASCADE,

    FOREIGN KEY (paper_id)
        REFERENCES Paper(paper_id)
        ON DELETE CASCADE
);

CREATE TABLE Foreign_author (
    foreign_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    sex BOOLEAN NOT NULL,
    h_index DECIMAL(5) CHECK (h_index > 0),
    workplace TEXT
);

CREATE TABLE Foreign_Authorship (
    foreign_id INT NOT NULL,
    paper_id INT NOT NULL,

    PRIMARY KEY (foreign_id, paper_id),

    FOREIGN KEY (foreign_id)
        REFERENCES Foreign_author(foreign_id)
        ON DELETE CASCADE,

    FOREIGN KEY (paper_id)
        REFERENCES Paper(paper_id)
        ON DELETE CASCADE
);

CREATE TABLE Foreign_work (
    for_work_id SERIAL PRIMARY KEY,
    pub_date DATE NOT NULL,
    name VARCHAR(100) NOT NULL
);