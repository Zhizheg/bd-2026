WITH researcher_info AS (
    SELECT u.name AS researcher_name
    FROM Researcher r
    JOIN users u ON r.user_id = u.user_id
    WHERE r.researcher_id = :researcher_id
)
SELECT
    w.name AS activity_name,
    wt.name AS activity_type,
    w.start_date AS activity_date,
    (SELECT researcher_name FROM researcher_info) AS participants,
    t.name AS direction
FROM Work w
JOIN Researcher_Work rw ON w.work_id = rw.work_id AND rw.researcher_id = :researcher_id
JOIN WType wt ON w.wtype_id = wt.wtype_id
JOIN Theme t ON w.theme_id = t.theme_id

UNION ALL

SELECT
    p.name AS activity_name,
    'Статья' AS activity_type,
    p.pub_date AS activity_date,
    (
        SELECT STRING_AGG(u.name, ', ')
        FROM Authorship a
        JOIN Researcher r ON a.researcher_id = r.researcher_id
        JOIN users u ON r.user_id = u.user_id
        WHERE a.paper_id = p.paper_id
    ) AS participants,
    NULL AS direction
FROM Paper p
JOIN Authorship a ON p.paper_id = a.paper_id AND a.researcher_id = :researcher_id