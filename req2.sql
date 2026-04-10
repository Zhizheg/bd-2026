WITH
    paper_author_count AS (
        SELECT a.paper_id, COUNT(a.researcher_id) AS count
        FROM Authorship a
        GROUP BY a.paper_id
    ),
    theme_list AS (
        SELECT ct.conference_id AS cid, STRING_AGG(t.name, ', ') AS themes
        FROM Conference_Theme ct
        JOIN Theme t ON t.theme_id = ct.theme_id
        GROUP BY ct.conference_id
    )
SELECT
    c.name,
    c.start_date,
    tl.themes,
    CASE WHEN c.prev_con_id IS NOT NULL THEN 1 ELSE 0 END AS is_periodic,
    (
        SELECT COUNT(*)
        FROM Paper p
        WHERE p.con_id = c.conference_id
    ) AS papers_count,
    (
        SELECT COUNT(DISTINCT a.researcher_id)
        FROM Authorship a
        JOIN Paper p ON p.paper_id = a.paper_id
        WHERE p.con_id = c.conference_id
    ) AS author_count,
    (
        SELECT COUNT(*)
        FROM Paper p
        JOIN paper_author_count pac ON pac.paper_id = p.paper_id
        WHERE (p.con_id = c.conference_id) AND (pac.count = 1)
    ) AS papers_from_1_author,
    (
        SELECT COUNT(*)
        FROM Paper p
        JOIN paper_author_count pac ON pac.paper_id = p.paper_id
        WHERE (p.con_id = c.conference_id) AND (pac.count >= 2) AND (pac.count <= 4)
    ) AS papers_from_2_to_4_authors,
    (
        SELECT COUNT(*)
        FROM Paper p
        JOIN paper_author_count pac ON pac.paper_id = p.paper_id
        WHERE (p.con_id = c.conference_id) AND (pac.count >= 5)
    ) AS papers_from_5_and_more_authors,
    CASE
        WHEN CURRENT_DATE < c.start_date THEN 'Not started'
        WHEN CURRENT_TIMESTAMP > (c.start_date + c.duration) THEN 'Ended'
        ELSE 'In progress'
    END AS status
FROM Conference c
JOIN theme_list tl ON tl.cid = c.conference_id;