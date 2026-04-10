WITH
    h_calc AS (
        SELECT r.researcher_id, COALESCE(h.h_index, 0) AS h_index
        FROM Researcher r
        LEFT JOIN (    
            SELECT researcher_id, MAX(cit_rank) AS h_index
            FROM (
                SELECT t.researcher_id, t.paper_id, t.count, 
                    ROW_NUMBER() OVER(
                        PARTITION BY t.researcher_id
                        ORDER BY t.count DESC
                    ) AS cit_rank
                FROM (
                        SELECT a.researcher_id, a.paper_id, COALESCE(q.cnt, 0) as count
                        FROM Authorship a
                        LEFT JOIN (
                            SELECT quoted_paper_id AS pid, COUNT(parent_paper_id) AS cnt
                            FROM Citation c 
                            GROUP BY quoted_paper_id
                        ) q ON a.paper_id = q.pid
                ) t
            )
            WHERE cit_rank <= count
            GROUP BY researcher_id
        ) h ON h.researcher_id = r.researcher_id
    ),
    research_names AS (
        SELECT r.researcher_id as id, u.name
        FROM Researcher r
        JOIN users u ON r.user_id = u.user_id
    ),
    pcount AS (
        SELECT researcher_id, COUNT(paper_id) AS paper_count
        FROM Authorship
        GROUP BY researcher_id
    ),
    paper_author_count AS (
        SELECT a.paper_id, COUNT(a.researcher_id) AS count
        FROM Authorship a
        GROUP BY a.paper_id
    ),
    pcount_solo AS (
        SELECT 
            r.researcher_id, 
            (
                SELECT COUNT(*)
                FROM Authorship a
                JOIN paper_author_count pac ON pac.paper_id = a.paper_id
                WHERE pac.count = 1 AND a.researcher_id = r.researcher_id
            ) AS count
        FROM Researcher r
    )
SELECT
    r.researcher_id,
    rn.name, 
    h.h_index, 
    COALESCE(rp.paper_count, 0) AS paper_count,
    lp.last_paper_date,
    CASE
        WHEN (rp.paper_count IS NOT NULL) THEN ROUND((ps.count::numeric / rp.paper_count) * 100)
        ELSE 0
    END AS solo_paper_percentage
FROM Researcher r
JOIN h_calc h ON r.researcher_id = h.researcher_id
JOIN research_names rn ON rn.id = r.researcher_id
LEFT JOIN pcount AS rp ON rp.researcher_id = r.researcher_id
LEFT JOIN (
    SELECT t.researcher_id, t.pdate AS last_paper_date
        FROM (
            SELECT researcher_id, pdate,
            ROW_NUMBER() OVER(
                PARTITION BY researcher_id
                ORDER BY pdate DESC
            ) AS date_rank
            FROM (
                SELECT a.researcher_id, p.pub_date as pdate
                FROM Authorship a
                JOIN Paper p ON p.paper_id = a.paper_id
            )
        ) t
        WHERE t.date_rank = 1
) AS lp ON lp.researcher_id = r.researcher_id
LEFT JOIN pcount_solo ps ON ps.researcher_id = r.researcher_id;

