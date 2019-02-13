SELECT	oh.code_4,
		o.organization_title
FROM	coa_db.orgnhier_table AS oh
		LEFT JOIN coa_db.organization AS o ON oh.code_4 = o.organization
WHERE	oh.code_3='JBAA03'
		AND oh.code_4<>''
		AND o.most_recent_flag='Y'
GROUP BY	oh.code_4,
			o.organization_title