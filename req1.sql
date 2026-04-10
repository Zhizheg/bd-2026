WITH
    coop_ash AS (
        SELECT ash1.researcher_id as a1, ash2.researcher_id as a2, ash1.paper_id as paper_id
        FROM authorship ash1
        CROSS JOIN authorship ash2
        WHERE (ash1.paper_id = ash2.paper_id
        AND ash1.researcher_id < ash2.researcher_id)
    ),
    uniq_pairs AS (
        SELECT DISTINCT a1, a2
        FROM coop_ash
    ),
    research_names AS (
        SELECT r.researcher_id as id, u.name
        FROM Researcher r
        JOIN users u ON r.user_id = u.user_id
    ),
    pair_names AS (
        SELECT pairs.a1, pairs.a2, r1.name AS name1, r2.name AS name2
        FROM uniq_pairs pairs
        JOIN research_names r1 ON r1.id = pairs.a1
        JOIN research_names r2 ON r2.id = pairs.a2
    ),
    pcount AS (
        SELECT a1, a2, COUNT(*) AS papers_count 
        FROM coop_ash
        GROUP BY a1, a2
    ),
    last_paper AS (
        SELECT t.a1, t.a2, t.pid, t.pname, t.pdate
        FROM (
            SELECT a1, a2, pid, pname, pdate,
            ROW_NUMBER() OVER(
                PARTITION BY a1, a2
                ORDER BY pdate DESC
            ) AS date_rank
            FROM (
                SELECT c.a1, c.a2, c.paper_id as pid, p.name as pname,
                    p.pub_date as pdate
                FROM coop_ash c
                JOIN Paper p ON p.paper_id = c.paper_id
            )
        ) t
        WHERE t.date_rank = 1
    ),
    last_paper_others AS (
        SELECT a.paper_id, STRING_AGG(DISTINCT a.rname, ', ') AS other_authors
        FROM (
            SELECT Authorship.researcher_id, Authorship.paper_id, r.name AS rname
            FROM Authorship 
            JOIN research_names r ON Authorship.researcher_id = r.id
        ) a
        JOIN last_paper l ON l.pid = a.paper_id
        WHERE ((a.researcher_id <> l.a1) AND (a.researcher_id <> l.a2))
        GROUP BY a.paper_id
    ),
    have_own_papers AS (
        SELECT
            un.a1, un.a2,
            CASE WHEN EXISTS (
                SELECT 1
                FROM Authorship a
                WHERE a.researcher_id = un.a1 AND NOT EXISTS (
                    SELECT 1
                    FROM Authorship aa
                    WHERE a.paper_id = aa.paper_id AND aa.researcher_id = un.a2
                )
            ) THEN 1 ELSE 0 END AS a1_has_own_papers,
            CASE WHEN EXISTS (
                SELECT 1
                FROM Authorship a
                WHERE a.researcher_id = un.a2 AND NOT EXISTS (
                    SELECT 1
                    FROM Authorship aa
                    WHERE a.paper_id = aa.paper_id AND aa.researcher_id = un.a1
                )
            ) THEN 1 ELSE 0 END AS a2_has_own_papers
        FROM uniq_pairs un
    )
SELECT 
    pn.name1, 
    pn.name2, 
    pc.papers_count,
    lp.pname AS last_paper_name,
    lp.pdate AS last_paper_date,
    lo.other_authors,
    hop.a1_has_own_papers,
    hop.a2_has_own_papers
FROM uniq_pairs up
JOIN pair_names pn ON up.a1 = pn.a1 AND up.a2 = pn.a2
JOIN pcount pc ON up.a1 = pc.a1 AND up.a2 = pc.a2
JOIN last_paper lp ON up.a1 = lp.a1 AND up.a2 = lp.a2
JOIN last_paper_others lo ON lp.pid = lo.paper_id
JOIN have_own_papers hop ON up.a1 = hop.a1 AND up.a2 = hop.a2;



