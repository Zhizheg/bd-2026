SELECT 
    t.name,
    COALESCE(wc.count, 0) AS work_count,
    COALESCE(cc.count, 0) AS conference_count,
    COALESCE(rc.count, 0) AS reseacrher_count,
    clos_con.closest_conference_date
FROM Theme t
LEFT JOIN (
    SELECT theme_id, COUNT(work_id) AS count
    FROM Work
    GROUP BY theme_id
) wc ON wc.theme_id = t.theme_id
LEFT JOIN (
    SELECT theme_id, COUNT(conference_id) AS count
    FROM Conference_Theme
    GROUP BY theme_id
) cc ON cc.theme_id = t.theme_id
LEFT JOIN (
    SELECT w.theme_id, COUNT(DISTINCT rw.researcher_id) AS count
    FROM Work w
    JOIN Researcher_Work rw ON rw.work_id = w.work_id
    GROUP BY w.theme_id
) rc ON rc.theme_id = t.theme_id
LEFT JOIN (
    SELECT t.theme_id, t.start_date AS closest_conference_date
        FROM (
            SELECT theme_id, start_date,
            ROW_NUMBER() OVER(
                PARTITION BY theme_id
                ORDER BY start_date
            ) AS date_rank
            FROM (
                SELECT ct.theme_id, c.start_date
                FROM Conference_Theme ct
                JOIN Conference c ON c.conference_id = ct.conference_id
                WHERE c.start_date > CURRENT_DATE
            )
        ) t
        WHERE t.date_rank = 1
) AS clos_con ON clos_con.theme_id = t.theme_id;