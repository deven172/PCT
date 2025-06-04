/* auto-generated sql/sqlserver/pl_sql.sql by dbc 1.0.24-snapshot */
/* for ITS version 24.0.0.0 build 671 */

USE [its]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CALCAMOUNT2]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[CALCAMOUNT2]
GO

CREATE FUNCTION [dbo].[CALCAMOUNT2](
	@p_client nvarchar(3),
	@p_currency1 nvarchar(3),
	@p_currency2 nvarchar(3),
	@p_kutyp nvarchar(2),
	@p_gulta datetime,
	@p_value numeric(18,4),
	@p_kursr nvarchar(1),
	@p_keinh int,
	@p_keinr int
	) returns numeric(18,4)
BEGIN
	DECLARE
	@kurs numeric(17,8),
	@rv numeric(18,4);

	if (@p_currency1 != @p_currency2) begin
		select @kurs = itdb970.mitlk from itdb970 where
					itdb970.mcode=@p_client and
					itdb970.wcod1=@p_currency1 and
					itdb970.wcod2=@p_currency2 and
					itdb970.kutyp=@p_kutyp and
					itdb970.gulta=(select max(b.gulta) from itdb970 b where
								b.mcode=itdb970.mcode and
								b.wcod1=itdb970.wcod1 and
								b.wcod2=itdb970.wcod2 and
								b.kutyp=itdb970.kutyp and
								b.gulta<=@p_gulta);

        if (@kurs <> 0)
		    if (@p_kursr='P') begin
			    set @rv = @kurs * @p_value / @p_keinh;
		    end;
		    else if (@p_kursr='M') begin
			    set @rv = @p_keinr * @p_value / @kurs;
		    end;
        else
            set @rv = @p_value;

	end;
	if (@p_currency1 = @p_currency2) begin
		set @rv = @p_value;
	end;

	return @rv;
END;
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_GRPHDR_PATH_V]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_GRPHDR_PATH_V]
GO

CREATE FUNCTION [dbo].[FN_CAMT_GRPHDR_PATH_V]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_GRPHDR p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid

	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
	UNION ALL SELECT 	p.mcode, p.headerid,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,

	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,

	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_NTRY_PATH_V_801]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_NTRY_PATH_V_801]
GO

CREATE FUNCTION [dbo].[FN_CAMT_NTRY_PATH_V_801]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_NTRY p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb
	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
   AND p.entrynb IN (SELECT consn FROM itdb801 i WHERE mcode = @p_client AND mstmtid = @p_mstmtid
	 AND i.azpos >= @p_azpos_from
		AND i.azpos <=  @p_azpos_to
)	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_NTRY_PATH_V_804]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_NTRY_PATH_V_804]
GO

CREATE FUNCTION [dbo].[FN_CAMT_NTRY_PATH_V_804]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_NTRY p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb
	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
   AND p.entrynb IN (SELECT consn FROM itdb804 i WHERE mcode = @p_client AND mstmtid = @p_mstmtid
	 AND i.azpos >= @p_azpos_from
		AND i.azpos <=  @p_azpos_to
)	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_NTRY_PATH_V_804A]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_NTRY_PATH_V_804A]
GO

CREATE FUNCTION [dbo].[FN_CAMT_NTRY_PATH_V_804A]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_NTRY p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb
	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
   AND p.entrynb IN (SELECT consn FROM itdb804A i WHERE mcode = @p_client AND mstmtid = @p_mstmtid
	 AND i.azpos >= @p_azpos_from
		AND i.azpos <=  @p_azpos_to
)	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_NTRYDTLS_PATH_V_801]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_NTRYDTLS_PATH_V_801]
GO

CREATE FUNCTION [dbo].[FN_CAMT_NTRYDTLS_PATH_V_801]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		detailnb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_NTRYDTLS p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb
	JOIN (
		SELECT DISTINCT p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb
		FROM CAMT_TXNDTLS p
		JOIN CAMT_LINK l ON l.impMcode = p.mcode AND l.headerId = p.headerid 	AND l.stmtNb = p.stmtNb
		JOIN
 	ITDB801
	i  ON l.mcode=i.mcode AND l.mstmtid=i.mstmtid AND p.entrynb=i.consn
			AND ((i.zlsam=0 and p.txnnb=i.azpos) OR (i.zlsam<>0 and p.txnNb=1))
		WHERE i.mcode = @p_client AND i.mstmtid = @p_mstmtid
			AND i.azpos >= @p_azpos_from
			AND i.azpos <= @p_azpos_to
	) DISTINCT_TXNDTLS ON (
		p.mcode=DISTINCT_TXNDTLS.mcode and p.headerId=DISTINCT_TXNDTLS.headerId and p.stmtnb=DISTINCT_TXNDTLS.stmtnb
		and p.entrynb=DISTINCT_TXNDTLS.entrynb and p.detailnb=DISTINCT_TXNDTLS.detailnb)

	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb, detailnb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	detailnb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.detailnb AS detailNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_NTRYDTLS_PATH_V_804]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_NTRYDTLS_PATH_V_804]
GO

CREATE FUNCTION [dbo].[FN_CAMT_NTRYDTLS_PATH_V_804]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		detailnb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_NTRYDTLS p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb
	JOIN (
		SELECT DISTINCT p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb
		FROM CAMT_TXNDTLS p
		JOIN CAMT_LINK l ON l.impMcode = p.mcode AND l.headerId = p.headerid 	AND l.stmtNb = p.stmtNb
		JOIN
 	ITDB804
	i  ON l.mcode=i.mcode AND l.mstmtid=i.mstmtid AND p.entrynb=i.consn
			AND ((i.zlsam=0 and p.txnnb=i.azpos) OR (i.zlsam<>0 and p.txnNb=1))
		WHERE i.mcode = @p_client AND i.mstmtid = @p_mstmtid
			AND i.azpos >= @p_azpos_from
			AND i.azpos <= @p_azpos_to
	) DISTINCT_TXNDTLS ON (
		p.mcode=DISTINCT_TXNDTLS.mcode and p.headerId=DISTINCT_TXNDTLS.headerId and p.stmtnb=DISTINCT_TXNDTLS.stmtnb
		and p.entrynb=DISTINCT_TXNDTLS.entrynb and p.detailnb=DISTINCT_TXNDTLS.detailnb)

	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb, detailnb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	detailnb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.detailnb AS detailNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_NTRYDTLS_PATH_V_804A]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_NTRYDTLS_PATH_V_804A]
GO

CREATE FUNCTION [dbo].[FN_CAMT_NTRYDTLS_PATH_V_804A]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		detailnb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_NTRYDTLS p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb
	JOIN (
		SELECT DISTINCT p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb
		FROM CAMT_TXNDTLS p
		JOIN CAMT_LINK l ON l.impMcode = p.mcode AND l.headerId = p.headerid 	AND l.stmtNb = p.stmtNb
		JOIN
 	ITDB804A
	i  ON l.mcode=i.mcode AND l.mstmtid=i.mstmtid AND p.entrynb=i.consn
			AND ((i.zlsam=0 and p.txnnb=i.azpos) OR (i.zlsam<>0 and p.txnNb=1))
		WHERE i.mcode = @p_client AND i.mstmtid = @p_mstmtid
			AND i.azpos >= @p_azpos_from
			AND i.azpos <= @p_azpos_to
	) DISTINCT_TXNDTLS ON (
		p.mcode=DISTINCT_TXNDTLS.mcode and p.headerId=DISTINCT_TXNDTLS.headerId and p.stmtnb=DISTINCT_TXNDTLS.stmtnb
		and p.entrynb=DISTINCT_TXNDTLS.entrynb and p.detailnb=DISTINCT_TXNDTLS.detailnb)

	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb, detailnb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	detailnb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.detailnb AS detailNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_STMT_PATH_V]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_STMT_PATH_V]
GO

CREATE FUNCTION [dbo].[FN_CAMT_STMT_PATH_V]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN


WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_STMT p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb
	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid
	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,

	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,

	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_TXNDTLS_PATH_V_801]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_TXNDTLS_PATH_V_801]
GO

CREATE FUNCTION [dbo].[FN_CAMT_TXNDTLS_PATH_V_801]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		detailnb numeric(9,0),
		txnnb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_TXNDTLS p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb JOIN ITDB801 i
	 ON l.mcode=i.mcode AND l.mstmtid=i.mstmtid
		AND p.entrynb=i.consn
	AND ((i.zlsam=0 and p.txnnb=i.azpos) OR (i.zlsam<>0 and p.txnNb=1))
	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid

	 AND i.azpos >= @p_azpos_from
		AND i.azpos <=  @p_azpos_to
	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb, detailnb, txnnb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	detailnb,
	txnnb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.detailnb AS detailNb,
	cte2.txnnb AS txnNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_TXNDTLS_PATH_V_804]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_TXNDTLS_PATH_V_804]
GO

CREATE FUNCTION [dbo].[FN_CAMT_TXNDTLS_PATH_V_804]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		detailnb numeric(9,0),
		txnnb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_TXNDTLS p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb JOIN ITDB804 i
	 ON l.mcode=i.mcode AND l.mstmtid=i.mstmtid
		AND p.entrynb=i.consn
	AND ((i.zlsam=0 and p.txnnb=i.azpos) OR (i.zlsam<>0 and p.txnNb=1))
	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid

	 AND i.azpos >= @p_azpos_from
		AND i.azpos <=  @p_azpos_to
	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb, detailnb, txnnb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	detailnb,
	txnnb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.detailnb AS detailNb,
	cte2.txnnb AS txnNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FN_CAMT_TXNDTLS_PATH_V_804A]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[FN_CAMT_TXNDTLS_PATH_V_804A]
GO

CREATE FUNCTION [dbo].[FN_CAMT_TXNDTLS_PATH_V_804A]

(
	@p_client nvarchar(3),
	@p_mstmtid nvarchar(13),
	@p_azpos_from nvarchar(9),
	@p_azpos_to nvarchar(9)
)
RETURNS
	@retTable TABLE(
		mcode nvarchar(3) collate Latin1_General_BIN,
		mstmtId nvarchar(13) collate Latin1_General_BIN,
		stmtId nvarchar(13) collate Latin1_General_BIN,
		impMcode nvarchar(3) collate Latin1_General_BIN,
		headerId nvarchar(15) collate Latin1_General_BIN,
		stmtNb numeric(9,0),
		entryNb numeric(9,0),
		detailnb numeric(9,0),
		txnnb numeric(9,0),
		Node_Id nvarchar(100) collate Latin1_General_BIN,
		Node_Path nvarchar(1000) collate Latin1_General_BIN,
		Node_Value nvarchar(1000) collate Latin1_General_BIN,
		Node_Type nvarchar(10) collate Latin1_General_BIN,
		objectVersion bigint
	)
AS
BEGIN

WITH cte AS (
SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST (N'/' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	x.query('.') AS this,
	x.query('*') AS t,
	CAST ('1' AS NVARCHAR(100)) AS Node_Id
	FROM CAMT_TXNDTLS p

	JOIN CAMT_LINK l ON l.impMcode = p.mcode
		AND l.headerId = p.headerid
	AND l.stmtNb = p.stmtNb JOIN ITDB804A i
	 ON l.mcode=i.mcode AND l.mstmtid=i.mstmtid
		AND p.entrynb=i.consn
	AND ((i.zlsam=0 and p.txnnb=i.azpos) OR (i.zlsam<>0 and p.txnNb=1))
	CROSS APPLY p.xml_data.nodes('*') AS a(x)
	WHERE l.mcode = @p_client AND l.mstmtid = @p_mstmtid

	 AND i.azpos >= @p_azpos_from
		AND i.azpos <=  @p_azpos_to
	UNION ALL SELECT 	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	p.lvl + 1 AS lvl,
	CAST(N'Elem' AS NVARCHAR(10)) AS Node_Type,
	CAST(p.Node_Path + N'/' + c.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	c.value('text()[1]','NVARCHAR(1000)') AS Node_Value,
	c.query('.') AS this,
	c.query('*') AS t,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id
	FROM cte p
	CROSS APPLY p.t.nodes('*') b(c)
),
cte2 AS (
SELECT
	mcode, headerid, stmtnb, entrynb, detailnb, txnnb,
	CAST(Node_Id AS NVARCHAR(100)) AS Node_Id,
	CAST(Node_Path AS NVARCHAR(1000)) AS Node_Path,
	Node_Value,
	Node_Type
	FROM cte
UNION ALL
	SELECT
	p.mcode, p.headerid, p.stmtnb, p.entrynb, p.detailnb, p.txnnb,
	CAST(p.Node_Id + '.' + CAST((ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS NVARCHAR(10)) AS NVARCHAR(100)) AS Node_Id,
	CAST(p.Node_Path + N'/@' + x.value('local-name(.)','NVARCHAR(1000)') AS NVARCHAR(1000)) AS Node_Path,
	x.value('.','NVARCHAR(1000)') AS Node_Value,
	CAST(N'Attr' AS NVARCHAR(10)) AS Node_Type
	FROM cte p
	CROSS APPLY this.nodes('/*/@*') a(x)
)
INSERT INTO @retTable (
	mcode,
	mstmtId,
	stmtId,
	impMcode,
	headerId,
	stmtNb,
	entryNb,
	detailnb,
	txnnb,
	Node_Id,
	Node_Path,
	Node_Value,
	Node_Type,
	objectVersion
)
SELECT
	l.mcode AS mcode,
	l.mstmtId AS mstmtId,
	l.stmtId AS stmtId,
	l.impMcode AS impMcode,
	l.headerid AS headerId,
	l.stmtnb AS stmtNb,
	cte2.entrynb AS entryNb,
	cte2.detailnb AS detailNb,
	cte2.txnnb AS txnNb,
	cte2.node_id AS Node_Id,
	cte2.node_path AS Node_Path,
	cte2.node_value AS Node_Value,
	cte2.node_type AS Node_Type,
	CAST(0 AS BIGINT) AS objectVersion

	FROM CAMT_LINK l
	JOIN cte2 ON cte2.mcode = l.impMcode
		AND cte2.headerid = l.headerId
		AND cte2.stmtNb = l.stmtNb;

return;

END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_formatted_recidcurr]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_formatted_recidcurr]
GO

CREATE FUNCTION fn_formatted_recidcurr
(@pi_seqname varchar(100))
RETURNS VARCHAR(15)
BEGIN
	DECLARE @sysinstval varchar(3), @curval decimal, @retval varchar(15)
	SET @sysinstval = (select substring(dbc_sys_inst.ValA,1,3) from dbc_sys_inst where dbc_sys_inst.keya='INST')
	SET @curval = dbo.fn_Sequence_Currval (@pi_seqname)
	SET @retval = @sysinstval + replicate ('0',12-len(convert(varchar,@curval))) + convert(varchar,@curval)
	RETURN @retval
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_PKG_ITS_TREASURY_get_fxlzvon]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_PKG_ITS_TREASURY_get_fxlzvon]
GO

CREATE FUNCTION fn_PKG_ITS_TREASURY_get_fxlzvon(@pi_fxlzvon datetime) RETURNS datetime AS
  BEGIN
    RETURN CAST(@pi_fxlzvon AS DATE)
  END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_PKG_ITS_TREASURY_get_state]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_PKG_ITS_TREASURY_get_state]
GO

CREATE FUNCTION fn_PKG_ITS_TREASURY_get_state
      (
        @pi_endkz varchar(1),
        @pi_storno datetime,
        @pi_storno_anf datetime,
        @pi_abgleich datetime = '1970-01-01',
        @pi_bestaet datetime = '1970-01-01',
        @pi_kontr datetime = '1970-01-01',
        @pi_erfasst datetime
      )
      RETURNS varchar(3)
    AS
      BEGIN
        DECLARE
          /*  DECLARE  */
          @status varchar(3)

        BEGIN
          IF (@pi_storno > '1970-01-02')
            SET @status = 'STO'
          ELSE
            IF (@pi_storno_anf > '1970-01-02')
              SET @status = 'STA'
            ELSE
              IF (@pi_endkz = 'Y')
                SET @status = 'END'
              ELSE
                IF (@pi_abgleich > '1970-01-02')
                  SET @status = 'ABG'
                ELSE
                  IF (@pi_bestaet > '1970-01-02')
                    SET @status = 'BES'
                  ELSE
                    IF (@pi_kontr > '1970-01-02')
                      SET @status = 'KON'
                    ELSE
                      IF (@pi_erfasst > '1970-01-02')
                        SET @status = 'ERF'
          RETURN @status
        END
        RETURN null
      END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_PKG_ITS_TREASURY_get_trheadid]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_PKG_ITS_TREASURY_get_trheadid]
GO

CREATE FUNCTION fn_PKG_ITS_TREASURY_get_trheadid
      (
        @pi_mcode varchar(3),
        @pi_firma varchar(12),
        @pi_bkonr varchar(10),
        @pi_konra varchar(10),
        @pi_koart varchar(3)
      )
      RETURNS varchar(15)
    AS
      BEGIN

        DECLARE
          /*  DECLARE  */
          @l_headid varchar(45),
          @l_modul varchar(9),
          @l_emiss varchar(3)

        SET @l_headid =  NULL

        BEGIN

          IF (@pi_koart IN ('00', '01', '02', '10', '11', '12', '13', '20', '21' ))
            BEGIN

              IF (@pi_koart IN ('20', '21' ))
                SET @l_modul = 'LM'
              ELSE IF (@pi_koart = '12')
				SET @l_modul = 'KRL'
			  ELSE IF (@pi_koart = '13')
				SET @l_modul = 'LIM'
			  ELSE
                SET @l_modul = 'KM'

              SELECT @l_headid = dbo.ITDB331.RECID
                FROM dbo.ITDB331
                WHERE ((dbo.ITDB331.MCODE = @pi_mcode) AND
                        (dbo.ITDB331.FIRMA = @pi_firma) AND
                        (dbo.ITDB331.BKONR = @pi_bkonr) AND
                        (dbo.ITDB331.KONRA = @pi_konra))
            END
          ELSE
            IF (@pi_koart = '60')
              BEGIN

                SET @l_modul = 'DP'

                SELECT @l_headid = dbo.ITDB334.RECID
                  FROM dbo.ITDB334
                  WHERE ((dbo.ITDB334.MCODE = @pi_mcode) AND
                          (dbo.ITDB334.FIRMA = @pi_firma) AND
                          (dbo.ITDB334.KONRA = @pi_konra) AND
                          (dbo.ITDB334.BKONR = @pi_bkonr))
              END
            ELSE
              IF ((@pi_koart >= '30') AND
                              (@pi_koart <= '43'))
                BEGIN

                  SET @l_modul = 'ZM'

                  SELECT @l_headid = dbo.ITDB332.RECID
                    FROM dbo.ITDB332
                    WHERE ((dbo.ITDB332.MCODE = @pi_mcode) AND
                            (dbo.ITDB332.FIRMA = @pi_firma) AND
                            (dbo.ITDB332.BKONR = @pi_bkonr) AND
                            (dbo.ITDB332.KONRA = @pi_konra))
                END
              ELSE
                IF ((@pi_koart = '59') OR
                                ((@pi_koart >= '61') AND
                                        (@pi_koart <= '79')))
                  BEGIN

                    SELECT @l_headid = dbo.ITDB335.RECID, @l_emiss = dbo.ITDB335.EMISS
                      FROM dbo.ITDB335
                      WHERE ((dbo.ITDB335.MCODE = @pi_mcode) AND
                              (dbo.ITDB335.FIRMA = @pi_firma) AND
                              (dbo.ITDB335.BKONR = @pi_bkonr) AND
                              (dbo.ITDB335.KONRA = @pi_konra))
                    IF (@l_emiss = 'Y')
                      SET @l_modul = 'WPE'
                    ELSE
                      SET @l_modul = 'WP'

                  END

          RETURN @l_headid

        END


        RETURN null
      END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_Sequence_Currval]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_Sequence_Currval]
GO

CREATE FUNCTION fn_Sequence_Currval
(@sequenceName varchar(30))
RETURNS decimal
AS
BEGIN
   RETURN (IDENT_CURRENT(@sequenceName))
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetIntRateFromFixing]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[GetIntRateFromFixing]
GO

CREATE FUNCTION [dbo].[GetIntRateFromFixing](
	@p_mcode nvarchar(3),
	@p_firma nvarchar(13),
	@p_bkonr nvarchar(11),
	@p_konra nvarchar(11),
	@p_gulta datetime,
	@p_point nvarchar(3)
	) returns numeric(16,7)
BEGIN
	DECLARE
	@closingDate datetime,
	@zicod nvarchar(15),
	@zityp nvarchar(2),
	@rv numeric(16,7);

	select TOP 1 @closingDate = zbvon, @zicod = refzi, @zityp = zityp from itdb345 where itdb345.mcode=@p_mcode and itdb345.firma=@p_firma and itdb345.bkonr=@p_bkonr and itdb345.konra=@p_konra and itdb345.zbvon < @p_gulta+1 and itdb345.kzsto='N' order by itdb345.zbvon desc;

	if (@p_point='1D') begin
		select TOP 1 @rv = zin01 from itdb972 where itdb972.mcode=@p_mcode and itdb972.zicod=@zicod and itdb972.zityp=@zityp and itdb972.gulta < @p_gulta+1 order by itdb972.gulta desc;
	end;
	else if (@p_point='1M') begin
		select TOP 1 @rv = zin04 from itdb972 where itdb972.mcode=@p_mcode and itdb972.zicod=@zicod and itdb972.zityp=@zityp and itdb972.gulta < @p_gulta+1 order by itdb972.gulta desc;
	end;

	return @rv;
END;
GO

-- Function fuer INSTR like Oracle 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[INSTR]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[INSTR]
GO

CREATE FUNCTION [dbo].[INSTR](@str1 as varchar(8000), @str2 as varchar(8000), @pos as int, @occurrence as int)
returns int
begin
    if( @str1 is NULL) or (@str2 is NULL) or (@pos is NULL) or (@pos = 0) or (@occurrence is NULL) or ( @occurrence < 1 )
        return NULL

    if( @pos < 0 )
    begin --the case when @pos is negative
        while( (dbo.LENGTH(@str2)-@pos-1) <= dbo.LENGTH(@str1) )
        begin

            if( SUBSTRING(@str1, dbo.LENGTH(@str1) + @pos + 1, dbo.LENGTH(@str2)) = @str2 )
            begin
                select @occurrence = @occurrence-1
                if @occurrence < 1
                    return dbo.LENGTH(@str1) + @pos + 1
            end
            select @pos = @pos-1
        end
        return 0
    end
    --the case when @pos is positive
    select @pos = @pos-1
    while @occurrence > 0
    begin
        set @pos = charindex(@str2, @str1, @pos+1)
        if @pos = 0
            return 0
        select @occurrence = @occurrence-1
    end
    return @pos
end;
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ISOweek]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[ISOweek]
GO

CREATE FUNCTION ISOweek (@DATE datetime)
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN
     DECLARE @ISOweek int
     SET @ISOweek= DATEPART(wk,@DATE)+1
          -DATEPART(wk,CAST(DATEPART(yy,@DATE) as CHAR(4))+'0104')
--Special cases: Jan 1-3 may belong to the previous year
     IF (@ISOweek=0)
          SET @ISOweek=dbo.ISOweek(CAST(DATEPART(yy,@DATE)-1
               AS CHAR(4))+'12'+ CAST(24+DATEPART(DAY,@DATE) AS CHAR(2)))+1
--Special case: Dec 29-31 may belong to the next year
     IF ((DATEPART(mm,@DATE)=12) AND
          ((DATEPART(dd,@DATE)-DATEPART(dw,@DATE))>= 28))
          SET @ISOweek=1
     RETURN(@ISOweek)
END;
GO

-- Function fuer LENGTH like Oracle 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LENGTH]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[LENGTH]
GO

CREATE FUNCTION [dbo].[LENGTH] (@s varchar(8000))
returns int
as
begin
  return len(replace(@s, ' ', '.'))
end;
GO

-- Function fuer LPAD like Oracle 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LPAD]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[LPAD]
GO

Create FUNCTION [dbo].[LPAD](
    @left as nvarchar(4000),
    @n as int,
    @pad as nvarchar(4000) = ' ')
returns nvarchar(4000)
begin

    declare @retval as nvarchar(4000), @TempPad nvarchar(4000), @LenLeft Integer, @LenPad Integer

    Set @LenLeft = len(replace(@left,' ','.'))
    Set @LenPad = len(replace(@pad,' ','.'))

    If @LenLeft = 0 Or @LenPad = 0 Or IsNull(@n, 0) = 0
      Begin
        Set @retval = null
        return @retval
      End;

    If @LenLeft >= @n
      Begin
        Set @retval = Left(@left, @n)
        return @retval
      End

    Set @TempPad = Replicate(@pad, Ceiling((@n - @LenLeft) / @LenPad))

    Set @retval = Left(@TempPad, @n - @LenLeft) + @left

    return @retval
end;
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MMFClosingUnits]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[MMFClosingUnits]
GO

CREATE FUNCTION [dbo].[MMFClosingUnits](
	@p_mcode nvarchar(3),
	@p_firma nvarchar(13),
	@p_bkonr nvarchar(11),
	@p_konra nvarchar(11),
	@p_date datetime
	) returns numeric(18,4)
BEGIN
	DECLARE
	@rv numeric(18,4);

	select TOP 1 @rv = stuek from itdb339 where itdb339.mcode=@p_mcode and itdb339.firma=@p_firma and itdb339.bkonr=@p_bkonr and itdb339.konra=@p_konra and itdb339.termi < @p_date+1 and itdb339.stodz<'1900-01-01' order by itdb339.termi desc, itdb339.ldnum desc;

	return @rv;
END;

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MMFGetPeriodActivity]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[MMFGetPeriodActivity]
GO

CREATE FUNCTION [dbo].[MMFGetPeriodActivity](
	@p_mcode nvarchar(3),
	@p_firma nvarchar(13),
	@p_bkonr nvarchar(11),
	@p_konra nvarchar(11),
	@p_termi datetime
	) returns numeric(18,4)
BEGIN
	DECLARE
	@fromTermi datetime,
	@rv numeric(16,7);

	select TOP 1 @fromTermi = termi from itdb337 where itdb337.mcode=@p_mcode and itdb337.firma=@p_firma and itdb337.bkonr=@p_bkonr and itdb337.konra=@p_konra and itdb337.termc='INTP' and itdb337.termi < @p_termi order by itdb337.termi desc;

	if (@fromTermi is null) begin
		select @rv = sum(itdb339.zuast) from itdb339 where itdb339.mcode=@p_mcode and itdb339.firma=@p_firma and itdb339.bkonr=@p_bkonr and itdb339.konra=@p_konra and itdb339.stodz<'1900-01-01' and itdb339.termi<=@p_termi;
	end;
	else if (@fromTermi>'1900-01-01') begin
		select @rv = sum(itdb339.zuast) from itdb339 where itdb339.mcode=@p_mcode and itdb339.firma=@p_firma and itdb339.bkonr=@p_bkonr and itdb339.konra=@p_konra and itdb339.stodz<'1900-01-01' and itdb339.termi>@fromTermi and itdb339.termi<=@p_termi;
	end;

	if(@rv is null) begin
		set @rv = 0;
	end;

	return @rv;
END;
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MMFGetPeriodEnding]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[MMFGetPeriodEnding]
GO

CREATE FUNCTION [dbo].[MMFGetPeriodEnding](
	@p_mcode nvarchar(3),
	@p_firma nvarchar(13),
	@p_bkonr nvarchar(11),
	@p_konra nvarchar(11),
	@p_termi datetime
	) returns datetime
BEGIN
	DECLARE
	@periodEnding datetime;

	select TOP 1 @periodEnding = termi from itdb337 where itdb337.mcode=@p_mcode and itdb337.firma=@p_firma and itdb337.bkonr=@p_bkonr and itdb337.konra=@p_konra and itdb337.termc='INTP' and itdb337.termi >= @p_termi order by itdb337.termi asc;

	return @periodEnding;
END;
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MMFOpeningUnits]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[MMFOpeningUnits]
GO

CREATE FUNCTION [dbo].[MMFOpeningUnits](
	@p_mcode nvarchar(3),
	@p_firma nvarchar(13),
	@p_bkonr nvarchar(11),
	@p_konra nvarchar(11),
	@p_date datetime
	) returns numeric(18,4)
BEGIN
	DECLARE
	@closingDate datetime,
	@stuek numeric(18,4),
	@rv numeric(18,4);


	select TOP 1 @closingDate = termi, @stuek = stuek from itdb339 where itdb339.mcode=@p_mcode and itdb339.firma=@p_firma and itdb339.bkonr=@p_bkonr and itdb339.konra=@p_konra and itdb339.termi < @p_date+1 and itdb339.stodz<'1900-01-01' order by itdb339.termi desc, itdb339.ldnum desc;

	if (@closingDate!=@p_date) begin
		set @rv = @stuek;
	end;
	else if (@closingDate=@p_date) begin
		select TOP 1 @rv = stuek from itdb339 where itdb339.mcode=@p_mcode and itdb339.firma=@p_firma and itdb339.bkonr=@p_bkonr and itdb339.konra=@p_konra and itdb339.termi < @closingDate and itdb339.stodz<'1900-01-01' order by itdb339.termi desc, itdb339.ldnum desc;
	end;

	return @rv;
END;

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[POINT2DAYS]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[POINT2DAYS]
GO

CREATE FUNCTION [dbo].[POINT2DAYS](
	@point as varchar(5)
	) returns int
begin
	DECLARE @len INTEGER, @c VARCHAR(1)

    if( @point is NULL)
        return NULL

	select @len = dbo.LENGTH(@point)
	if (@len = 0)
		return 0

	select @c = SUBSTRING(@point,@len,1)

	return CAST(SUBSTRING(@point,1,@len-1) AS INT)
		* (case when (@c='D') then 1
				when (@c='W') then 7
				when (@c='M') then 30
				when (@c='Y') then 365
				else NULL
			end)
end;
GO

-- Function fuer TRANSLATE like Oracle 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TRANSLATE]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[TRANSLATE]
GO

Create FUNCTION [dbo].[TRANSLATE] (
@source as varchar(8000),
@from as varchar(8000),
@to as varchar(8000)
) returns varchar(8000)
Begin
  Declare @retval varchar(8000), @LenFrom Integer, @LenTo Integer, @ind Integer, @StrInd Integer
  Set @LenFrom = datalength(@from)
  Set @LenTo = datalength(@to)
  Set @retval = @source

  If datalength(@retval) = 0 Or @LenFrom = 0 Or @LenTo = 0
    Begin
      Set @retval = null
      return @retval
    End

  Set @StrInd = 1
  While @StrInd <= datalength(@retval)
    Begin
      Set @ind = CharIndex(SubString(@retval, @StrInd, 1) COLLATE Latin1_General_BIN, @from COLLATE Latin1_General_BIN)
      If @ind > 0
        Begin
          Set @retval = Stuff(@retval, @StrInd, 1,  SubString(@to, @ind, 1))
          If @ind > @LenTo Set @StrInd = @StrInd - 1
        End
      Set @StrInd = @StrInd + 1
    End  -- While

  return @retval
End;
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CFF_SP_GetNextId]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[CFF_SP_GetNextId]
GO

CREATE PROCEDURE [dbo].[CFF_SP_GetNextId]
(@PI_seqname VARCHAR(10), @PI_howmany DECIMAL, @PO_nextval DECIMAL output)
AS
BEGIN
	DECLARE @msg NVARCHAR(100)
	DECLARE @curr_val decimal(15, 0)
	DECLARE @min_val decimal(15, 0)
	DECLARE @max_val decimal(15, 0)
	DECLARE @next_val decimal(15,0) = -1

	SET NOCOUNT ON;

	SELECT @curr_val = next_val, @min_val = min_val, @max_val = max_val
	FROM CFF_SEQ WITH (ROWLOCK,UPDLOCK)
	WHERE seq_name = @PI_seqname;

	IF (@@ROWCOUNT = 0) BEGIN
		SET @min_val = 1
		SET @max_val = 999999999999999
		SET @next_val = @min_val + @PI_howmany

		INSERT INTO CFF_SEQ (seq_name,min_val,max_val,next_val) VALUES
		(@PI_seqname, @min_val, @max_val, @next_val)

		SET @PO_nextval = 1
	--	print 'New Seq ' + @PI_seqname + ': min_val=1, max_val=99, next_val=' + convert(varchar, @next_val)

		RETURN
	END

	SET @next_val = @curr_val + @PI_howmany;
	IF (@next_val <= @max_val +1 )
	BEGIN

		UPDATE CFF_SEQ SET next_val = @next_val
		WHERE seq_name = @PI_seqname

		SET @PO_nextval = @curr_val

	--	print 'Seq ' + @PI_seqname + ' get ' + convert(varchar, @PI_howmany) + ': firstval=' + convert(varchar, @curr_val) + ' nextval=' + convert(varchar, @next_val)

	END
	ELSE BEGIN
		SET  @msg = 'Seq ' + @PI_seqname + ' overflow. Only ' + convert(varchar, @max_val-@curr_val+1) + ' numbers left'
		RAISERROR ( @msg, 16, 1)
	END

	RETURN
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_add_ObjectVersion]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_add_ObjectVersion]
GO

CREATE PROCEDURE [dbo].[sp_add_ObjectVersion]
@PI_table VARCHAR(32)
AS
BEGIN
	DECLARE @SQLString  NVARCHAR(4000);
	DECLARE @havecol	INT;
	DECLARE @havetable	INT;
	DECLARE @ErrNum     INT;

	SET NOCOUNT ON;

	SET @havecol = 0
	SET @havetable = 0

	SELECT @havetable = COUNT(t.name)
		FROM
			sys.tables t
		WHERE t.name = @PI_table;
	SELECT @havecol = COUNT(ISNULL(c.name,0))
		FROM sys.tables t JOIN sys.columns c ON C.object_id=t.object_id
		WHERE t.name = @PI_table
		AND UPPER(c.name)='OBJECTVERSION';

	IF (@havetable = 0)
	BEGIN
		PRINT 'Invalid table: ' + @PI_table
		RETURN
	END

	IF (@havecol = 0)
	BEGIN
		SET @SQLString = 'ALTER TABLE ' + @PI_table + ' ADD ObjectVersion ROWVERSION'
		-- PRINT 'Stmt: ' + @SQLString
		EXECUTE sp_executesql @SQLString
		SELECT @Errnum = @@ERROR
		IF @Errnum <> 0
		BEGIN
			PRINT 'Error adding ObjectVersion column to table ' + @PI_table
		END
		ELSE
		BEGIN
			PRINT 'Add ObjectVersion column to table ' + @PI_table
		END
	END
	ELSE
	BEGIN
		PRINT 'ObjectVersion column already present in table ' + @PI_table
	END
END
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_delete_itprodctl]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_delete_itprodctl]
GO

CREATE PROCEDURE [dbo].[sp_delete_itprodctl]
@svrDb varchar(30),
@svrMachine varchar(64)

AS
BEGIN
	DELETE FROM ITPRODCTL WHERE SvrMachine = @svrMachine and SvrDB = @svrDb;
END
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_delete_itprodctlp]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_delete_itprodctlp]
GO

CREATE PROCEDURE [dbo].[sp_delete_itprodctlp]
@mcode varchar(3),
@module varchar(30),
@svrDb varchar(30),
@svrMachine varchar(64)

AS
BEGIN
	DELETE FROM ITPRODCTLP WHERE mcode = @mcode and module = @module and SvrMachine = @svrMachine and SvrDB = @svrDb;
END
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_drop_ObjectVersion]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_drop_ObjectVersion]
GO

CREATE PROCEDURE [dbo].[sp_drop_ObjectVersion]
@PI_table VARCHAR(32)
AS
BEGIN
	DECLARE @SQLString  NVARCHAR(4000);
	DECLARE @havecol	INT;
	DECLARE @havetable	INT;
	DECLARE @ErrNum     INT;

	SET NOCOUNT ON;

	SET @havecol = 0
	SET @havetable = 0

	SELECT @havetable = COUNT(t.name)
		FROM
			sys.tables t
		WHERE t.name = @PI_table;
	SELECT @havecol = COUNT(ISNULL(c.name,0))
		FROM sys.tables t JOIN sys.columns c ON C.object_id=t.object_id
		WHERE t.name = @PI_table
		AND UPPER(c.name)='OBJECTVERSION';

	IF (@havetable = 0)
	BEGIN
		PRINT 'Invalid table: ' + @PI_table
		RETURN
	END

	IF (@havecol = 1)
	BEGIN
		SET @SQLString = 'ALTER TABLE ' + @PI_table + ' DROP COLUMN ObjectVersion'
		-- PRINT 'Stmt: ' + @SQLString
		EXECUTE sp_executesql @SQLString
		SELECT @Errnum = @@ERROR
		IF @Errnum <> 0
		BEGIN
			PRINT 'Error dropping ObjectVersion column from table ' + @PI_table
		END
		ELSE
		BEGIN
			PRINT 'Drop ObjectVersion column from table ' + @PI_table
		END
	END
	ELSE
	BEGIN
		PRINT 'ObjectVersion column not present in table ' + @PI_table
	END
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_formatted_recid]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_formatted_recid]
GO

CREATE PROCEDURE sp_formatted_recid
(@pi_seqname varchar(100), @retval varchar(15) output)
AS
BEGIN
	DECLARE @sysinstval varchar(3),@nextval decimal
	SET NOCOUNT ON;
	SET @sysinstval = (select substring(dbc_sys_inst.ValA,1,3) from dbc_sys_inst where dbc_sys_inst.keya='INST')
	EXEC sp_Sequence_Nextval @pi_seqname, @nextval OUTPUT
	SET @retval = @sysinstval + replicate ('0',12-len(convert(varchar,@nextval))) + convert(varchar,@nextval)
	SET NOCOUNT OFF
	RETURN
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_get_LoginSession]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_get_LoginSession]
GO

CREATE PROCEDURE sp_get_LoginSession
	@PO_SessId  varchar(13) output,
	@PI_Prefix  varchar(1) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @newid DECIMAL
	DECLARE @prefix VARCHAR(1)
	DECLARE @id VARCHAR(12)

	EXEC sp_Sequence_Nextval 'SEQ_SESSIONID', @newid OUTPUT

	SET @id = CONVERT(varchar(12),@newid );

	SET @prefix = SUBSTRING(ISNULL(@PI_Prefix, 'S'),1,1);

	SET @PO_SessId = @prefix + REPLICATE('0', 12-LEN(@id)) + @id;

END
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_insert_itprodctl]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_insert_itprodctl]
GO

CREATE PROCEDURE [dbo].[sp_insert_itprodctl]
@svrDb varchar(30),
@svrMachine varchar(64),
@isProductiveSystem varchar(1)

AS
BEGIN
	INSERT INTO ITPRODCTL (SvrMachine, SvrDB, isProductive)
	VALUES (@svrMachine, @svrDb, @isProductiveSystem);
END
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_insert_itprodctlp]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_insert_itprodctlp]
GO

CREATE PROCEDURE [dbo].[sp_insert_itprodctlp]
@mcode varchar(3),
@module varchar(30),
@svrDb varchar(30),
@svrMachine varchar(64),
@isProductiveModule varchar(1)

AS
BEGIN
	INSERT INTO ITPRODCTLP (mcode, module, isProductive, SvrMachine, SvrDB)
	VALUES (@mcode, @module, @isProductiveModule, @svrMachine, @svrDb);
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ITSUPD_ExecuteSql]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_ITSUPD_ExecuteSql]
GO

CREATE PROCEDURE [dbo].[sp_ITSUPD_ExecuteSql]
    (
      @PI_version NVARCHAR(32),
	  @PI_buildnr INT,
	  @PI_steptype VARCHAR(1),
	  @PI_step INT ,
      @PI_msg NVARCHAR(512) ,
      @PI_statement NVARCHAR(MAX) ,
      @PI_startstep INT = 1 ,
      @PI_err INT = 0,
	  @PO_ret INT OUTPUT
    )
AS
    DECLARE @errmsg NVARCHAR(1000);
BEGIN
	  EXEC sp_ITSUPD_ExecuteSqlExt @PI_version,@PI_buildnr,@PI_steptype,
							@PI_step,@PI_msg,@PI_statement,
							@PI_startstep,@PI_err,1,
							@PO_ret OUTPUT, @PO_retmsg=@errmsg OUTPUT
END
GO


-- procedure executes a statement or batch
-- if PI_err is set, execution is skipped
-- if PI_startstep > 0, then execution only if actual step >= start step
-- if PI_err > 0, then execution is skipped and PI_err is returned

-- return:
--   0 ... step executed without error
--	-1 ... step not executed (skipped)
--  >0 ... step executed with error, error number returned

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ITSUPD_ExecuteSqlExt]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_ITSUPD_ExecuteSqlExt]
GO

CREATE PROCEDURE [dbo].[sp_ITSUPD_ExecuteSqlExt]
    (
      @PI_version NVARCHAR(32),
	  @PI_buildnr INT,
	  @PI_steptype VARCHAR(1),
	  @PI_step INT ,
      @PI_msg NVARCHAR(512) ,
      @PI_statement NVARCHAR(MAX) ,
      @PI_startstep INT = 1 ,
      @PI_err INT = 0,
      @PI_raiseerr INT = 1,
	  @PO_ret INT OUTPUT,
	  @PO_retmsg NVARCHAR(1000) OUTPUT
    )
AS
    DECLARE @ret INT;
    DECLARE @errmsg NVARCHAR(1000);
    BEGIN
        SET NOCOUNT ON
        SET @ret = 0;

        IF ( @PI_err > 0 )
            BEGIN
                PRINT N'Step ' + CONVERT(NVARCHAR, @PI_step)
                    + ' skipped due to previous errors' ;
                SET @PO_ret = @PI_err;
                SET @PO_retmsg = 'Skipped due to previous errors';
                RETURN;
            END
        IF ( @PI_step < @PI_startstep )
            BEGIN
                PRINT N'Step ' + CONVERT(NVARCHAR, @PI_step) + ' (' + @PI_msg
                    + ') skipped' ;
                SET @PO_ret = -1;
                SET @PO_retmsg = 'Skipped';
                RETURN;
            END

        BEGIN TRY
			-- insert steptable entry
            BEGIN TRANSACTION ;
				INSERT INTO ITSUPDSTEPS (version,buildnr,steptype,step,laststate,execstart,msg)
				VALUES (@PI_version,@PI_buildnr,@PI_steptype,@PI_step,'R',GETDATE(),@PI_msg);
			COMMIT TRANSACTION ;

			BEGIN TRANSACTION ;
				EXECUTE sp_executesql @PI_statement ;

    -- If the statement/batch succeeds, commit the transaction.

				PRINT N'Step ' + CONVERT(NVARCHAR, @PI_step) + N' ('
					+ @PI_msg + ') succeeded' ; -- + ' (' + CONVERT(NVARCHAR,@@ROWCOUNT) + ')' ;

			-- update steptable entry to (F)inished
				UPDATE ITSUPDSTEPS SET execend=GETDATE(),laststate='F'
				WHERE version=@PI_version AND buildnr=@PI_buildnr AND steptype=@PI_steptype AND step=@PI_step;

			SET @errmsg = 'Ok';

			COMMIT TRANSACTION ;

        END TRY

        BEGIN CATCH

            PRINT N'Step ' + CONVERT(NVARCHAR, @PI_step) + N' ('
                + @PI_msg + ') failed'
			--EXEC usp_RethrowError;
--            EXECUTE sp_ITSUPD_GetErrorInfo ;
	--PRINT @@TRANCOUNT
    -- Test XACT_STATE for 1 or -1.
    -- XACT_STATE = 0 means there is no transaction and
    -- a commit or rollback operation would generate an error.

    -- Test whether the transaction is uncommittable.
            IF ( XACT_STATE() ) = -1
                BEGIN
                    PRINT N'The transaction is in an uncommittable state. Rolling back transaction.'
                    ROLLBACK TRANSACTION ;
                END ;

    -- Test whether the transaction is active and valid.
            IF ( XACT_STATE() ) = 1
                BEGIN
                    PRINT N'The transaction is committable. Committing transaction.'
                    COMMIT TRANSACTION ;
                END ;

            EXEC @ret = sp_ITSUPD_RethrowError @PI_raiseerr, @errmsg OUTPUT;
    --PRINT @@TRANCOUNT
        END CATCH ;

        SET @PO_ret = @ret;
        SET @PO_retmsg = @errmsg;
        RETURN;
    END
GO


-- determine status of last execution
-- return step and type of last successful step
-- type 'A': last step from same buildnr
-- type 'M': last step of version (man. changes are additive)

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ITSUPD_GetLastStep]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_ITSUPD_GetLastStep]
GO
CREATE PROCEDURE [dbo].[sp_ITSUPD_GetLastStep]
    (
      @PI_version NVARCHAR(32) ,
      @PI_buildnr INT ,
      @PI_steptype NVARCHAR(1) ,
      @PO_step INT OUTPUT
    )
AS
    DECLARE @laststep INT;
    DECLARE @laststate VARCHAR;
    BEGIN
        SET NOCOUNT ON
		SET @laststep = 0 ;
		SET @laststate = 'F'
        IF ( @PI_steptype = 'A' )
            BEGIN
                SELECT  @laststep = MAX(STEP)
                FROM    ITSUPDSTEPS
                WHERE   version = @PI_version
                        AND buildnr = @PI_buildnr
                        AND steptype = @PI_steptype ;
            END
        ELSE
            BEGIN
                SELECT  @laststep = MAX(STEP)
                FROM    ITSUPDSTEPS
                WHERE   version = @PI_version
                        AND steptype = @PI_steptype ;
            END

        IF ( @laststep IS NULL )
            BEGIN
                PRINT 'Get LastStep version/build/type: '
                    + @PI_version + '/' + CONVERT(NVARCHAR, @PI_buildnr) + '/' + @PI_steptype +
                    + ': no run found';
                 SET @PO_step = 1 ;
           END
        ELSE
             BEGIN
				IF ( @PI_steptype = 'A' )
				BEGIN
					SELECT  @laststate = laststate
					FROM    ITSUPDSTEPS
					WHERE   version = @PI_version
							AND buildnr = @PI_buildnr
							AND steptype = @PI_steptype
							AND step = @laststep ;
				END
				ELSE
				BEGIN
					SELECT  @laststate = laststate
					FROM    ITSUPDSTEPS
					WHERE   version = @PI_version
							AND steptype = @PI_steptype
							AND step = @laststep ;
				END

                PRINT 'Get LastStep version/build/type: ' + @PI_version + '/' + CONVERT(NVARCHAR, @PI_buildnr) + '/'
                + @PI_steptype + ': ' + CONVERT(VARCHAR, @laststep) + ' state ' + @laststate ;
                IF (@laststate = 'F')
                BEGIN
                   SET @PO_step = @laststep + 1;
                END
                ELSE
				BEGIN
					BEGIN TRANSACTION;
				    	IF ( @PI_steptype = 'A' )
					    BEGIN
						    DELETE FROM ITSUPDSTEPS WHERE version = @PI_version
							    AND buildnr = @PI_buildnr
							    AND steptype = @PI_steptype
							    AND step = @laststep ;
					    END
					    ELSE
					    BEGIN
						    DELETE FROM ITSUPDSTEPS WHERE version = @PI_version
    							AND steptype = @PI_steptype
	    						AND step = @laststep ;
		    			END
					COMMIT TRANSACTION;

					PRINT 'Delete last unsuccessful step ' + CONVERT(VARCHAR, @laststep) + ' status ' + @laststate
							+ ' = ' + CONVERT(VARCHAR,@@ROWCOUNT);

					SET @PO_step = @laststep ;
				END
            END
    END
GO


-- Stored procedure to generate an error using
-- RAISERROR. The original error information is used to
-- construct the msg_str for RAISERROR.

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ITSUPD_RethrowError]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_ITSUPD_RethrowError]
GO
CREATE PROCEDURE sp_ITSUPD_RethrowError
	(
		@PI_raiseerr INT,
		@PO_retmsg NVARCHAR(1000) OUTPUT
	)
AS -- Return if there is no error information to retrieve.
    IF ERROR_NUMBER() IS NULL
        RETURN 0 ;

    DECLARE @ErrorMessage NVARCHAR(4000) ,
        @ErrorNumber INT ,
        @ErrorSeverity INT ,
        @ErrorState INT ,
        @ErrorLine INT ,
        @ErrorProcedure NVARCHAR(200) ;

    -- Assign variables to error-handling functions that
    -- capture information for RAISERROR.
    SELECT  @ErrorNumber = ERROR_NUMBER() ,
            @ErrorSeverity = ERROR_SEVERITY() ,
            @ErrorState = ERROR_STATE() ,
            @ErrorLine = ERROR_LINE() ,
            @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-') ;

    -- Build the message string that will contain original
    -- error information.
    SELECT  @ErrorMessage = N'Original Error %d, Level %d, State %d, Procedure %s, Line %d, '
            + 'Message: ' + ERROR_MESSAGE() ;
	SET @PO_retmsg = SUBSTRING(ERROR_MESSAGE(),1,1000);

    -- Raise an error: msg_str parameter of RAISERROR will contain
    -- the original error information.
	IF ( @PI_raiseerr = 1)
		BEGIN
			RAISERROR
				(
				@ErrorMessage,
				@ErrorSeverity,
				127,             -- state 127 causes sqlcmd to exit
				@ErrorNumber,    -- parameter: original error number.
				@ErrorSeverity,  -- parameter: original error severity.
				@ErrorState,     -- parameter: original error state.
				@ErrorProcedure, -- parameter: original error procedure name.
				@ErrorLine       -- parameter: original error line number.
				) ;
		END
    RETURN @ErrorNumber
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_PKG_ITS_TREASURY_get_cohead]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_PKG_ITS_TREASURY_get_cohead]
GO

CREATE PROCEDURE sp_PKG_ITS_TREASURY_get_cohead
	    @pi_mcode varchar(3),
        @pi_recid varchar(15),
		@MCODE varchar(3) OUTPUT,
        @FIRMA varchar(12) OUTPUT,
        @ORDOP varchar(10) OUTPUT,
        @KHTNR varchar(13) OUTPUT,
        @HAEND varchar(35) OUTPUT,
        @ABSTS datetime OUTPUT,
        @BEEUS varchar(10) OUTPUT,
        @ERFDZ datetime OUTPUT,
        @FREDZ datetime OUTPUT,
        @BESDZ datetime OUTPUT,
        @ABGDZ datetime OUTPUT,
        @STODZ datetime OUTPUT,
        @ANFSTOT datetime OUTPUT,
        @HZNUM varchar(10) OUTPUT,
        @RECID varchar(15) OUTPUT,
        @IDPRJ varchar(15) OUTPUT,
		@GGRDC varchar(6) OUTPUT,
		@ACODE varchar(6) OUTPUT,
		@GCODE varchar(10) OUTPUT,
		@PLANG varchar(1) OUTPUT,
		@ENDDT datetime OUTPUT
      AS
        BEGIN
			SET NOCOUNT ON
            SELECT
                @MCODE = dbo.ITDB200.MCODE,
                @FIRMA = dbo.ITDB200.FIRMA,
                @ORDOP = dbo.ITDB200.ORDOP,
/*                 @GACOD = dbo.ITDB101.GACOD,   */
                @KHTNR = dbo.ITDB200.KHTNR,
                @HAEND = dbo.ITDB200.HAEND,
                @ABSTS = dbo.ITDB200.ABSTS,
                @BEEUS = dbo.ITDB200.beeuser,
                @ERFDZ = dbo.ITDB200.erftime,
                @FREDZ = dbo.ITDB200.kontime,
                @BESDZ = dbo.ITDB200.bestime,
                @ABGDZ = dbo.ITDB200.abgtime,
                @STODZ = dbo.ITDB200.stotime,
                @ANFSTOT = dbo.ITDB200.anfstot,
                @HZNUM = dbo.ITDB200.HZNUM,
		        @RECID = dbo.ITDB200.RECID,
		        @IDPRJ = dbo.ITDB200.IDPRJ,
				@GGRDC = dbo.ITDB200.GGRDC,
				@ACODE = dbo.ITDB200.ACODE,
				@GCODE = dbo.ITDB200.GCODE,
				@PLANG = dbo.ITDB200.PLANG,
				@ENDDT = dbo.ITDB200.BEETIME
              FROM dbo.ITDB200
              WHERE ((dbo.ITDB200.MCODE = @pi_mcode) AND
                      (dbo.ITDB200.RECID = @pi_recid))

	RETURN
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_PKG_ITS_TREASURY_get_fxhead]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_PKG_ITS_TREASURY_get_fxhead]
GO

CREATE PROCEDURE sp_PKG_ITS_TREASURY_get_fxhead
	    @pi_mcode varchar(3),
        @pi_firma varchar(12),
        @pi_ordop varchar(10),
		@MCODE varchar(3) OUTPUT,
        @FIRMA varchar(12) OUTPUT,
        @ORDOP varchar(10) OUTPUT,
		@GACOD varchar(13) OUTPUT,
        @KHTNR varchar(13) OUTPUT,
        @HAEND varchar(35) OUTPUT,
        @ABSTS datetime OUTPUT,
        @ENDCD varchar(1) OUTPUT,
        @ERFDZ datetime OUTPUT,
        @FREDZ datetime OUTPUT,
        @BESDZ datetime OUTPUT,
        @ABGDZ datetime OUTPUT,
        @STODZ datetime OUTPUT,
        @HZNUM varchar(10) OUTPUT,
        @RECID varchar(15) OUTPUT,
        @IDPRJ varchar(15) OUTPUT,
		@GGRDC varchar(6) OUTPUT,
		@ACODE varchar(6) OUTPUT,
		@GCODE varchar(10) OUTPUT,
		@PLANG varchar(1) OUTPUT,
		@ENDDT datetime OUTPUT
      AS
        BEGIN
			SET NOCOUNT ON
            SELECT
                @MCODE = dbo.ITDB101.MCODE,
                @FIRMA = dbo.ITDB101.FIRMA,
                @ORDOP = dbo.ITDB101.ORDOP,
                @GACOD = dbo.ITDB101.GACOD,
                @KHTNR = dbo.ITDB101.KHTNR,
                @HAEND = dbo.ITDB101.HAEND,
                @ABSTS = dbo.ITDB101.ABSTS,
                @ENDCD = dbo.ITDB101.ENDCD,
                @ERFDZ = dbo.ITDB101.ERFDZ,
                @FREDZ = dbo.ITDB101.FREDZ,
                @BESDZ = dbo.ITDB101.BESDZ,
                @ABGDZ = dbo.ITDB101.ABGDZ,
                @STODZ = dbo.ITDB101.STODZ,
                @HZNUM = dbo.ITDB101.HZNUM,
		        @RECID = dbo.ITDB101.RECID,
		        @IDPRJ = dbo.ITDB101.IDPRJ,
				@GGRDC = dbo.ITDB101.GGRDC,
				@ACODE = dbo.ITDB101.ACODE,
				@GCODE = dbo.ITDB101.GCODE,
				@PLANG = dbo.ITDB101.PLANG,
				@ENDDT = dbo.ITDB101.ENDTS
              FROM dbo.ITDB101
              WHERE ((dbo.ITDB101.MCODE = @pi_mcode) AND
                      (dbo.ITDB101.FIRMA = @pi_firma) AND
                      (dbo.ITDB101.ORDOP = @pi_ordop))

	RETURN
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_PKG_ITS_TREASURY_upd_treasury_bewertung]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_PKG_ITS_TREASURY_upd_treasury_bewertung]
GO

CREATE PROCEDURE sp_PKG_ITS_TREASURY_upd_treasury_bewertung
        @pi_mode varchar(3),
        @pi_mcode varchar(3),
        @pi_recid varchar(15),
        @pi_firma varchar(12),
        @pi_bkonr varchar(10),
        @pi_konra varchar(10),
        @pi_koart varchar(2) = 'XX'
    AS
      DECLARE
        /*  DECLARE  */
        @l_recid varchar(15),
        @l_mode varchar(1),
        @l_headid varchar(15),
        @l_modul varchar(3),
        @l_dummy int
      SET @l_headid =  NULL
      SET @l_modul =  NULL
      SET @l_mode = @pi_mode
      SET @l_recid = @pi_recid
      SET @l_dummy = 0
      BEGIN
		SET NOCOUNT ON

		IF ((@pi_recid LIKE ' %') OR (ISNULL((@pi_recid + '.'), '.') = '.'))
		  BEGIN
            RAISERROR ( 'upd_treasury_bewertung: Empty input-variable RECID not allowed - please check application code!', 16, 1)
		    RETURN
		  END

        /*   for update read id  */

        IF (@l_mode = 'U')
		BEGIN
           SELECT @l_dummy = 1
             FROM TRBEW
             WHERE ((TRBEW.MCODE = @pi_mcode) AND (TRBEW.RECID = @pi_recid))
			IF (@l_dummy = 0)
					SET @l_mode = 'I'
        END

        /*   Bei Neuinsert muss der passende Geschaeftskopf gefunden werden  */

        IF (@l_mode = 'I')
          BEGIN
            SET @l_headid = dbo.fn_PKG_ITS_TREASURY_get_trheadid(@pi_mcode, @pi_firma, @pi_bkonr, @pi_konra, @pi_koart)
            IF (ISNULL((@l_headid + '.'), '.') = '.')
              RETURN
          END

        IF (@l_mode = 'D')
            BEGIN TRY
              DELETE FROM TRBEW
                WHERE ((TRBEW.MCODE = @pi_mcode) AND (TRBEW.RECID = @pi_recid))
            END TRY
            BEGIN CATCH

              DECLARE
                @ErrorMessage nvarchar(4000),
                @ErrorNumber int

              SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER()
            END CATCH

        IF (@l_mode = 'I')
            INSERT INTO dbo.TRBEW
              (
                dbo.TRBEW.MCODE,
                dbo.TRBEW.RECID,
                dbo.TRBEW.TRHEADID,
                dbo.TRBEW.UPDTS
              )
              VALUES
                (
                  @pi_mcode,
                  @l_recid,
                  @l_headid,
                  GETDATE()
                )

        IF (@l_mode = 'U')
            UPDATE dbo.TRBEW
              SET dbo.TRBEW.UPDTS = GETDATE() WHERE ((dbo.TRBEW.MCODE = @pi_mcode) AND (dbo.TRBEW.RECID = @l_recid))

      END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_PKG_ITS_TREASURY_upd_treasury_cashflow]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_PKG_ITS_TREASURY_upd_treasury_cashflow]
GO

CREATE PROCEDURE sp_PKG_ITS_TREASURY_upd_treasury_cashflow
        @pi_mode varchar(3),
        @pi_mcode varchar(3),
        @pi_recid varchar(15),
        @pi_firma varchar(12),
        @pi_bkonr varchar(10),
        @pi_konra varchar(10),
        @pi_termi datetime,
        @pi_term1 datetime =  NULL,
        @pi_termc varchar(4),
        @pi_ldnum numeric(3),
        @pi_wckon varchar(3) =  NULL,
        @pi_konsw varchar(35) = 0.0,
        @pi_kobkw numeric(17, 2) = 0.0,
        @pi_kobbw numeric(17, 2) = 0.0,
        @pi_kobew numeric(17, 2) = 0.0,
        @pi_kkwbw numeric(19,10) = 0.0,
        @pi_kutyp varchar(3) =  NULL,
        @pi_kutxt varchar(50) =  NULL,
        @pi_dispo varchar(1) =  NULL,
        @pi_kzeia varchar(1) =  NULL,
        @pi_chkdp int = 0,
        @pi_flag1 varchar(1) =  NULL,
        @pi_koart varchar(2) = 'XX'
    AS
      DECLARE
        /*  DECLARE  */
        @l_recid varchar(15),
        @l_mode varchar(1),
        @l_headid varchar(15),
        @l_modul varchar(3),
        @l_mult numeric(17, 2),
        @l_dispo varchar(1),
        @l_fixie varchar(1),
        @l_notdi varchar(1),
        @l_dummy int
      SET @l_headid =  NULL
      SET @l_modul =  NULL
      SET @l_mult = 1.0
      SET @l_dispo = 'N'
      SET @l_fixie = 'N'
      SET @l_notdi = 'Y'
      SET @l_mode = @pi_mode
      SET @l_recid = @pi_recid
      SET @l_dummy = 0
      BEGIN
		SET NOCOUNT ON

		IF ((@pi_recid LIKE ' %') OR (ISNULL((@pi_recid + '.'), '.') = '.'))
		  BEGIN
            RAISERROR ( 'upd_treasury_cashflow: Empty input-variable RECID not allowed - please check application code!', 16, 1)
		    RETURN
		  END

        /*   Ein/Ausgang fuer Vorzeichen auswerten  */

        IF (@pi_kzeia = 'A')
          SET @l_mult =  -1.0

        /*   Ermittle Dispokennzeichen aus Dispopattern  */

        IF (@pi_chkdp != 0)
          SET @l_dispo = 'Y'

        /*   Ermittle Fixiert-Flag  */

        IF (@pi_flag1 = '0')
          SET @l_fixie = 'Y'

        IF (@pi_dispo = 'Y')
          SET @l_notdi = 'N'

        /*   for update read id  */

        IF (@l_mode = 'U')
		BEGIN
           SELECT @l_dummy = 1
             FROM TRCF
             WHERE ((TRCF.MCODE = @pi_mcode) AND
                    (TRCF.RECID = @pi_recid))
			IF (@l_dummy = 0)
					SET @l_mode = 'I'
        END

        /*   Bei Neuinsert muss der passende Geschaeftskopf gefunden werden  */

        IF (@l_mode = 'I')
          BEGIN
            SET @l_headid = dbo.fn_PKG_ITS_TREASURY_get_trheadid(@pi_mcode, @pi_firma, @pi_bkonr, @pi_konra, @pi_koart)
            IF (ISNULL((@l_headid + '.'), '.') = '.')
              RETURN
          END

        IF (@l_mode = 'D')
            BEGIN TRY
              DELETE FROM TRCF
                WHERE ((TRCF.MCODE = @pi_mcode) AND
                                (TRCF.RECID = @pi_recid))
            END TRY
            BEGIN CATCH

              DECLARE
                @ErrorMessage nvarchar(4000),
                @ErrorNumber int

              SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER()
            END CATCH

        IF (@l_mode = 'I')
            INSERT INTO dbo.TRCF
              (
                dbo.TRCF.MCODE,
                dbo.TRCF.RECID,
                dbo.TRCF.TRHEADID,
                dbo.TRCF.TERMI,
                dbo.TRCF.TERM1,
                dbo.TRCF.TERMC,
                dbo.TRCF.LDNUM,
                dbo.TRCF.WCKON,
                dbo.TRCF.KONSW,
                dbo.TRCF.KOBKW,
                dbo.TRCF.KOBBW,
                dbo.TRCF.KOBEW,
                dbo.TRCF.KKWBW,
                dbo.TRCF.KUTYP,
                dbo.TRCF.KUTXT,
                dbo.TRCF.DISPO,
                dbo.TRCF.FIXIE,
                dbo.TRCF.NOTDI,
                dbo.TRCF.UPDTS
              )
              VALUES
                (
                  @pi_mcode,
                  @l_recid,
                  @l_headid,
                  @pi_termi,
                  @pi_term1,
                  @pi_termc,
                  @pi_ldnum,
                  @pi_wckon,
                  @pi_konsw,
                  (@pi_kobkw * @l_mult),
                  (@pi_kobbw * @l_mult),
                  (@pi_kobew * @l_mult),
                  @pi_kkwbw,
                  @pi_kutyp,
                  @pi_kutxt,
                  @l_dispo,
                  @l_fixie,
                  @l_notdi,
                  GETDATE()
                )

        IF (@l_mode = 'U')
            UPDATE dbo.TRCF
              SET
                dbo.TRCF.MCODE = @pi_mcode,
                dbo.TRCF.TERMI = @pi_termi,
                dbo.TRCF.TERM1 = @pi_term1,
                dbo.TRCF.TERMC = @pi_termc,
                dbo.TRCF.LDNUM = @pi_ldnum,
                dbo.TRCF.WCKON = @pi_wckon,
                dbo.TRCF.KONSW = @pi_konsw,
                dbo.TRCF.KOBKW = (@pi_kobkw * @l_mult),
                dbo.TRCF.KOBBW = (@pi_kobbw * @l_mult),
                dbo.TRCF.KOBEW = (@pi_kobew * @l_mult),
                dbo.TRCF.KKWBW = @pi_kkwbw,
                dbo.TRCF.KUTYP = @pi_kutyp,
                dbo.TRCF.KUTXT = @pi_kutxt,
                dbo.TRCF.DISPO = @l_dispo,
                dbo.TRCF.FIXIE = @l_fixie,
                dbo.TRCF.NOTDI = @l_notdi,
                dbo.TRCF.UPDTS = GETDATE()
              WHERE ((dbo.TRCF.MCODE = @pi_mcode) AND
                              (dbo.TRCF.RECID = @l_recid))

      END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_PKG_ITS_TREASURY_upd_treasury_head]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_PKG_ITS_TREASURY_upd_treasury_head]
GO

CREATE PROCEDURE sp_PKG_ITS_TREASURY_upd_treasury_head
        @pi_mode varchar(1),
        @pi_modul varchar(3),
        @pi_mcode varchar(3),
        @pi_recid varchar(15),
        @pi_firma varchar(12),
        @pi_bkonr varchar(10),
        @pi_konra varchar(10),
        @pi_khtnr varchar(13) =  NULL,
        @pi_abdat datetime =  NULL,
        @pi_lzvon datetime =  NULL,
        @pi_lzbis datetime =  NULL,
        @pi_wcod1 varchar(3) =  NULL,
        @pi_betr1 numeric(15, 2) = 0.0,
        @pi_wcod2 varchar(3) =  NULL,
        @pi_betr2 numeric(15, 2) = 0.0,
        @pi_zins1 numeric(16, 7) = 0.0,
        @pi_mar11 numeric(16, 7) = 0.0,
        @pi_mar12 numeric(16, 7) = 0.0,
        @pi_zins2 numeric(16, 7) = 0.0,
        @pi_mar21 numeric(16, 7) = 0.0,
        @pi_mar22 numeric(16, 7) = 0.0,
        @pi_kurs numeric(19,10) = 0.0,
        @pi_getyp varchar(15) =  NULL,
        @pi_ggart varchar(1) =  NULL,
        @pi_haend varchar(35) =  NULL,
        @pi_hznum varchar(10) =  NULL,
        @pi_state varchar(3) =  NULL,
        @pi_kutxt varchar(50) =  NULL,
        @pi_idsze varchar(15) = NULL,
		@pi_bterm datetime = NULL,
        @pi_idprj varchar(15) = NULL,
		@pi_ggrdc varchar(6) = NULL,
		@pi_acode varchar(6) = NULL,
		@pi_gcode varchar(10) = NULL,
		@pi_plang varchar(1) = NULL,
		@pi_dkont varchar(2) = NULL,
		@pi_enddt datetime =  NULL,
		@pi_koart varchar(2) = NULL,
		@pi_total numeric(15, 2) = 0.0

    AS
      DECLARE
        /*  DECLARE  */
        @l_recid varchar(15),
        @l_mode varchar(1),
        @l_mult1 numeric(17, 2),
        @l_mult2 numeric(17, 2),
        @l_nirt1 numeric(16, 7),
        @l_nirt2 numeric(16, 7),
		@l_dummy int
      SET @l_recid = @pi_recid
      SET @l_mult1 = 1.0
      SET @l_mult2 =  -1.0
      SET @l_nirt1 = 0.0
      SET @l_nirt2 = 0.0
	  SET @l_dummy = 0
      BEGIN

		SET NOCOUNT ON
        SET @l_mode = 'U'

        IF ((@pi_recid LIKE ' %') OR (ISNULL((@pi_recid + '.'), '.') = '.'))
		BEGIN
          RAISERROR ( 'upd_treasury_head: Empty input-variable RECID not allowed - please check application code!', 16, 1)
		  RETURN
		END

        /*   delete old head-record  */

        IF (@pi_mode = 'D')
		BEGIN
           DELETE FROM dbo.TRCF
                WHERE ((dbo.TRCF.MCODE = @pi_mcode) AND
                                (dbo.TRCF.TRHEADID = @pi_recid))

           DELETE FROM dbo.ITDB137
                WHERE ((dbo.ITDB137.MCODE = @pi_mcode) AND
                                (dbo.ITDB137.IDGES = @pi_recid))

           DELETE FROM dbo.TRHEAD
                WHERE ((dbo.TRHEAD.MCODE = @pi_mcode) AND
                                (dbo.TRHEAD.RECID = @pi_recid))
			RETURN
		END

     /* try to read with id, if exists and mode='I' --> do update */
		IF (@pi_mode IN ('I','U'))
		BEGIN
           SELECT @l_dummy = 1
             FROM TRHEAD
             WHERE ((TRHEAD.MCODE = @pi_mcode) AND
                    (TRHEAD.RECID = @pi_recid))
			IF (@l_dummy = 0)
					SET @l_mode = 'I'
        END

        /*   Bei Aufnahme und Sell die Betraege negativ  */

        IF (@pi_ggart IN ('2', 'S' ))
          BEGIN
            SET @l_mult1 =  -1.0
            SET @l_mult2 = 1.0
          END

        /*   nominal interest rate (GM, ZM)  */

        SET @l_nirt1 = (@pi_zins1 + @pi_mar11 + @pi_mar12)

        SET @l_nirt2 = (@pi_zins2 + @pi_mar21 + @pi_mar22)

        IF (@l_mode = 'I')
            INSERT INTO dbo.TRHEAD
              (
                dbo.TRHEAD.MCODE,
                dbo.TRHEAD.RECID,
                dbo.TRHEAD.MODUL,
                dbo.TRHEAD.FIRMA,
                dbo.TRHEAD.BKONR,
                dbo.TRHEAD.KONRA,
                dbo.TRHEAD.KHTNR,
                dbo.TRHEAD.ABSTS,
                dbo.TRHEAD.LZVON,
                dbo.TRHEAD.LZBIS,
                dbo.TRHEAD.WCOD1,
                dbo.TRHEAD.BTRW1,
                dbo.TRHEAD.WCOD2,
                dbo.TRHEAD.BTRW2,
                dbo.TRHEAD.ZINS1,
                dbo.TRHEAD.MAR11,
                dbo.TRHEAD.MAR12,
                dbo.TRHEAD.NIRT1,
                dbo.TRHEAD.ZINS2,
                dbo.TRHEAD.MAR21,
                dbo.TRHEAD.MAR22,
                dbo.TRHEAD.NIRT2,
                dbo.TRHEAD.KWERT,
                dbo.TRHEAD.GETYP,
                dbo.TRHEAD.GGART,
                dbo.TRHEAD.HAEND,
                dbo.TRHEAD.HZNUM,
                dbo.TRHEAD.STATE,
                dbo.TRHEAD.KUTXT,
				dbo.TRHEAD.IDSZE,
				dbo.TRHEAD.BTERM,
				dbo.TRHEAD.IDPRJ,
				dbo.TRHEAD.GGRDC,
				dbo.TRHEAD.ACODE,
				dbo.TRHEAD.GCODE,
				dbo.TRHEAD.PLANG,
				dbo.TRHEAD.DKONT,
                dbo.TRHEAD.UPDTS,
				dbo.TRHEAD.ENDDT,
				dbo.TRHEAD.KOART,
				dbo.TRHEAD.TOTAL
              )
              VALUES
                (
                  @pi_mcode,
                  @l_recid,
                  @pi_modul,
                  @pi_firma,
                  @pi_bkonr,
                  @pi_konra,
                  @pi_khtnr,
                  @pi_abdat,
                  @pi_lzvon,
                  @pi_lzbis,
                  @pi_wcod1,
                  (@pi_betr1 * @l_mult1),
                  @pi_wcod2,
                  (@pi_betr2 * @l_mult2),
                  @pi_zins1,
                  @pi_mar11,
                  @pi_mar12,
                  @l_nirt1,
                  @pi_zins2,
                  @pi_mar21,
                  @pi_mar22,
                  @l_nirt2,
                  @pi_kurs,
                  @pi_getyp,
                  @pi_ggart,
                  @pi_haend,
                  @pi_hznum,
                  @pi_state,
                  @pi_kutxt,
				  @pi_idsze,
				  @pi_bterm,
				  @pi_idprj,
				  @pi_ggrdc,
				  @pi_acode,
				  @pi_gcode,
				  @pi_plang,
				  @pi_dkont,
                  GETDATE(),
				  @pi_enddt,
				  @pi_koart,
				  @pi_total
	)

        IF (@l_mode = 'U')
            UPDATE dbo.TRHEAD
              SET
                dbo.TRHEAD.MODUL = @pi_modul,
                dbo.TRHEAD.FIRMA = @pi_firma,
                dbo.TRHEAD.BKONR = @pi_bkonr,
                dbo.TRHEAD.KONRA = @pi_konra,
                dbo.TRHEAD.KHTNR = @pi_khtnr,
                dbo.TRHEAD.ABSTS = @pi_abdat,
                dbo.TRHEAD.LZVON = @pi_lzvon,
                dbo.TRHEAD.LZBIS = @pi_lzbis,
                dbo.TRHEAD.WCOD1 = @pi_wcod1,
                dbo.TRHEAD.BTRW1 = (@pi_betr1 * @l_mult1),
                dbo.TRHEAD.WCOD2 = @pi_wcod2,
                dbo.TRHEAD.BTRW2 = (@pi_betr2 * @l_mult2),
                dbo.TRHEAD.ZINS1 = @pi_zins1,
                dbo.TRHEAD.MAR11 = @pi_mar11,
                dbo.TRHEAD.MAR12 = @pi_mar12,
                dbo.TRHEAD.NIRT1 = @l_nirt1,
                dbo.TRHEAD.ZINS2 = @pi_zins2,
                dbo.TRHEAD.MAR21 = @pi_mar21,
                dbo.TRHEAD.MAR22 = @pi_mar22,
                dbo.TRHEAD.NIRT2 = @l_nirt2,
                dbo.TRHEAD.KWERT = @pi_kurs,
                dbo.TRHEAD.GETYP = @pi_getyp,
                dbo.TRHEAD.GGART = @pi_ggart,
                dbo.TRHEAD.HAEND = @pi_haend,
                dbo.TRHEAD.HZNUM = @pi_hznum,
                dbo.TRHEAD.STATE = @pi_state,
                dbo.TRHEAD.KUTXT = @pi_kutxt,
                dbo.TRHEAD.IDSZE = @pi_idsze,
                dbo.TRHEAD.BTERM = @pi_bterm,
                dbo.TRHEAD.IDPRJ = @pi_idprj,
				dbo.TRHEAD.GGRDC = @pi_ggrdc,
				dbo.TRHEAD.ACODE = @pi_acode,
				dbo.TRHEAD.GCODE = @pi_gcode,
				dbo.TRHEAD.PLANG = @pi_plang,
				dbo.TRHEAD.DKONT = @pi_dkont,
                dbo.TRHEAD.UPDTS = GETDATE(),
				dbo.TRHEAD.ENDDT = @pi_enddt,
				dbo.TRHEAD.KOART = @pi_koart,
				dbo.TRHEAD.TOTAL = @pi_total
              WHERE ((dbo.TRHEAD.MCODE = @pi_mcode) AND
                              (dbo.TRHEAD.RECID = @l_recid))

      END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_PKG_ITS_TREASURY_upd_treasury_head_co]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_PKG_ITS_TREASURY_upd_treasury_head_co]
GO

CREATE PROCEDURE sp_PKG_ITS_TREASURY_upd_treasury_head_co
        @pi_mode varchar(1),
        @pi_modul varchar(3),
        @pi_mcode varchar(3),
        @pi_recid varchar(15),
        @pi_firma varchar(12),
        @pi_ordop varchar(10),
        @pi_khtnr varchar(13) =  NULL,
        @pi_abdat datetime =  NULL,
        @pi_lzvon datetime =  NULL,
        @pi_getyp varchar(12) =  NULL,
        @pi_haend varchar(35) =  NULL,
        @pi_hznum varchar(10) =  NULL,
        @pi_state varchar(3) =  NULL,
        @pi_idprj varchar(15) =  NULL,
		@pi_ggrdc varchar(6) = NULL,
		@pi_acode varchar(6) = NULL,
		@pi_gcode varchar(10) = NULL,
		@pi_plang varchar(1) = NULL,
		@pi_enddt datetime = NULL
    AS
        BEGIN
		  SET NOCOUNT ON
          DECLARE
            @rec201$MCODE varchar(3),
            @rec201$RECID varchar(15),
            @rec201$DEALID varchar(15),
            @rec201$REIHE numeric(5,0),
            @rec201$ANZLOS numeric(15,2),
            @rec201$UNKURS numeric(15,6),
            @rec201$UNSPOT numeric(15,6),
            @rec201$UNSWAP numeric(15,6),
            @rec201$UNWCODE varchar(3),
            @rec201$UNWERT numeric(15,2),
            @rec201$ABWCODE varchar(3),
            @rec201$ABKURS numeric(19,10),
            @rec201$ABWERT numeric(15,2),
            @rec201$VALUTA datetime,
            @rec201$ACTDAY datetime,
            @rec201$KTEXT varchar(35),
			@rec201$ORDNR varchar(10),
            @rec201$MORDN varchar(35),
            @rec201$OPTPRAEMVALUTA datetime,
            @rec201$OPTPRAEMPZT numeric(15,6),
            @rec201$OPTPRAEMWERT numeric(15,2),
            @rec201$OPTPRAEMABRWERT numeric(15,2),
            @rec201$OPTDEKLD datetime,
            @rec201$OPTDEKLT datetime,
            @rec201$OPTDEKLO varchar(3),
            @rec201$MARGINM numeric(15,2),
            @rec201$MARGINI numeric(15,2),
            @rec201$MARGINTS datetime,
            @rec201$IDSZE varchar(15),
            @rec201$BTERM datetime,
			@buysell varchar(1)

          DECLARE
            DB_IMPLICIT_CURSOR_FOR_rec201 CURSOR LOCAL
             FOR

              SELECT
				p.MCODE,
				p.RECID,
				p.DEALID,
				p.REIHE,
				p.ANZLOS,
				p.UNKURS,
				p.UNSPOT,
				p.UNSWAP,
				p.UNWCODE,
				p.UNWERT,
				p.ABWCODE,
				p.ABKURS,
				p.ABWERT,
				p.VALUTA,
				p.ACTDAY,
				p.KTEXT,
				p.ORDNR,
				p.MORDN,
				p.OPTPRAEMVALUTA,
				p.OPTPRAEMPZT,
				p.OPTPRAEMWERT,
				p.OPTPRAEMABRWERT,
				p.OPTDEKLD,
				p.OPTDEKLT,
				p.OPTDEKLO,
				p.MARGINM,
				p.MARGINI,
				p.MARGINTS,
				p.IDSZE,
				p.BTERM
                FROM ITDB201 p
                WHERE ((p.MCODE = @pi_mcode) AND
                        (p.dealid = @pi_recid))
              ORDER BY p.ORDNR

          OPEN DB_IMPLICIT_CURSOR_FOR_rec201

          FETCH NEXT FROM DB_IMPLICIT_CURSOR_FOR_rec201
            INTO
				@rec201$MCODE,
				@rec201$RECID,
				@rec201$DEALID,
				@rec201$REIHE,
				@rec201$ANZLOS,
				@rec201$UNKURS,
				@rec201$UNSPOT,
				@rec201$UNSWAP,
				@rec201$UNWCODE,
				@rec201$UNWERT,
				@rec201$ABWCODE,
				@rec201$ABKURS,
				@rec201$ABWERT,
				@rec201$VALUTA,
				@rec201$ACTDAY,
				@rec201$KTEXT,
				@rec201$ORDNR,
				@rec201$MORDN,
				@rec201$OPTPRAEMVALUTA,
				@rec201$OPTPRAEMPZT,
				@rec201$OPTPRAEMWERT,
				@rec201$OPTPRAEMABRWERT,
				@rec201$OPTDEKLD,
				@rec201$OPTDEKLT,
				@rec201$OPTDEKLO,
				@rec201$MARGINM,
				@rec201$MARGINI,
				@rec201$MARGINTS,
				@rec201$IDSZE,
				@rec201$BTERM

          WHILE  NOT(@@FETCH_STATUS = -1)
			  BEGIN
		  		SET @buysell = (SELECT x.gaic2 FROM itdb918d x WHERE x.mcode = @pi_mcode
						 AND x.gacod = @pi_recid AND x.reihe=@rec201$REIHE)

                EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @pi_mode = @pi_mode, @pi_modul = 'CO', @pi_mcode = @pi_mcode, @pi_recid = @rec201$RECID, @pi_firma = @pi_firma, @pi_bkonr = @pi_ordop, @pi_konra = @rec201$ORDNR, @pi_khtnr = @pi_khtnr, @pi_abdat = @pi_abdat, @pi_lzvon = @pi_lzvon, @pi_lzbis = @rec201$VALUTA, @pi_wcod1 = @rec201$UNWCODE, @pi_betr1 = @rec201$UNWERT, /*@pi_wcod2 = @rec102$WCOD2, @pi_betr2 = @rec102$BTRW2,*/ @pi_kurs = @rec201$UNKURS, /*@pi_getyp = @pi_getyp,*/ @pi_ggart = @buysell, @pi_haend = @pi_haend, @pi_hznum = @pi_hznum, @pi_state = @pi_state, @pi_kutxt = @rec201$KTEXT, @pi_idsze = @rec201$IDSZE, @pi_bterm = @rec201$BTERM, @pi_idprj = @pi_idprj, @pi_ggrdc = @pi_ggrdc, @pi_acode = @pi_acode, @pi_gcode = @pi_gcode, @pi_plang = @pi_plang, @pi_enddt = @pi_enddt, @pi_total = @rec201$UNWERT

              FETCH NEXT FROM DB_IMPLICIT_CURSOR_FOR_rec201
                INTO
				@rec201$MCODE,
				@rec201$RECID,
				@rec201$DEALID,
				@rec201$REIHE,
				@rec201$ANZLOS,
				@rec201$UNKURS,
				@rec201$UNSPOT,
				@rec201$UNSWAP,
				@rec201$UNWCODE,
				@rec201$UNWERT,
				@rec201$ABWCODE,
				@rec201$ABKURS,
				@rec201$ABWERT,
				@rec201$VALUTA,
				@rec201$ACTDAY,
				@rec201$KTEXT,
				@rec201$ORDNR,
				@rec201$MORDN,
				@rec201$OPTPRAEMVALUTA,
				@rec201$OPTPRAEMPZT,
				@rec201$OPTPRAEMWERT,
				@rec201$OPTPRAEMABRWERT,
				@rec201$OPTDEKLD,
				@rec201$OPTDEKLT,
				@rec201$OPTDEKLO,
				@rec201$MARGINM,
				@rec201$MARGINI,
				@rec201$MARGINTS,
				@rec201$IDSZE,
				@rec201$BTERM
            END

          CLOSE DB_IMPLICIT_CURSOR_FOR_rec201

          DEALLOCATE DB_IMPLICIT_CURSOR_FOR_rec201

        END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_PKG_ITS_TREASURY_upd_treasury_head_fx]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_PKG_ITS_TREASURY_upd_treasury_head_fx]
GO

CREATE PROCEDURE sp_PKG_ITS_TREASURY_upd_treasury_head_fx
        @pi_mode varchar(1),
        @pi_modul varchar(3),
        @pi_mcode varchar(3),
        @pi_recid varchar(15),
        @pi_firma varchar(12),
        @pi_ordop varchar(10),
        @pi_khtnr varchar(13) =  NULL,
        @pi_abdat datetime =  NULL,
        @pi_lzvon datetime =  NULL,
        @pi_getyp varchar(12) =  NULL,
        @pi_haend varchar(35) =  NULL,
        @pi_hznum varchar(10) =  NULL,
        @pi_state varchar(3) =  NULL,
        @pi_idprj varchar(15) =  NULL,
		@pi_ggrdc varchar(6) = NULL,
		@pi_acode varchar(6) = NULL,
		@pi_gcode varchar(10) = NULL,
		@pi_plang varchar(1) = NULL,
		@pi_enddt datetime =  NULL
    AS
        BEGIN
		  SET NOCOUNT ON
          DECLARE
            @rec102$MCODE varchar(3),
            @rec102$FIRMA varchar(12),
            @rec102$ORDOP varchar(10),
            @rec102$ORDNR varchar(10),
            @rec102$SWPCF numeric(19,10),
            @rec102$MORDN varchar(35),
            @rec102$GACD1 varchar(1),
            @rec102$KAUVK varchar(1),
            @rec102$FAELD datetime,
            @rec102$WCOD1 varchar(3),
            @rec102$BTRW1 numeric(15,2),
            @rec102$WCOD2 varchar(3),
            @rec102$BTRW2 numeric(15,2),
            @rec102$KWERT numeric(19,10),
            @rec102$KEINH numeric(5),
            @rec102$KURSR varchar(1),
            @rec102$WCODL varchar(3),
            @rec102$WCODV varchar(3),
            @rec102$WCODK varchar(3),
            @rec102$BETRL numeric(15,2),
            @rec102$KWRTL numeric(19,10),
            @rec102$BETRV numeric(15,2),
            @rec102$KWRTV numeric(19,10),
            @rec102$BETRK numeric(15,2),
            @rec102$KWRTK numeric(15,2),
            @rec102$KTEXT varchar(35),
            @rec102$ANSCH varchar(1),
            @rec102$RZPRK varchar(1),
            @rec102$UPDTS datetime,
            @rec102$UPDUS varchar(10),
            @rec102$CHKDP numeric(9),
            @rec102$KFAEL datetime,
            @rec102$KKURS numeric(19,10),
            @rec102$ESKRS numeric(19,10),
            @rec102$SWAPS numeric(19,10),
            @rec102$KUNDF numeric(19,10),
            @rec102$DANDF datetime,
            @rec102$GUVBE numeric(15,2),
            @rec102$GUVTS datetime,
            @rec102$CBKO1 varchar(13),
            @rec102$CBKU1 numeric(19,10),
            @rec102$CBBM1 varchar(200),
            @rec102$CBKO2 varchar(13),
            @rec102$CBKU2 numeric(19,10),
            @rec102$CBBM2 varchar(200),
            @rec102$CBKO3 varchar(13),
            @rec102$CBKU3 numeric(19,10),
            @rec102$CBBM3 varchar(200),
            @rec102$CBKO4 varchar(13),
            @rec102$CBKU4 numeric(19,10),
            @rec102$CBBM4 varchar(200),
            @rec102$CBKO5 varchar(13),
            @rec102$CBKU5 numeric(19,10),
            @rec102$CBBM5 varchar(200),
            @rec102$CBSW1 numeric(19,10),
            @rec102$CBKK1 numeric(19,10),
            @rec102$CBSW2 numeric(19,10),
            @rec102$CBKK2 numeric(19,10),
            @rec102$CBSW3 numeric(19,10),
            @rec102$CBKK3 numeric(19,10),
            @rec102$CBSW4 numeric(19,10),
            @rec102$CBKK4 numeric(19,10),
            @rec102$CBSW5 numeric(19,10),
            @rec102$CBKK5 numeric(19,10),
            @rec102$ACTDY datetime,
            @rec102$RECID varchar(15),
            @rec102$ALTERNATIVERATE numeric(19,10),
            @rec102$UPPERLIMIT numeric(19,10),
            @rec102$LOWERLIMIT numeric(19,10),
            @rec102$LIMITREACHED datetime,
            @rec102$FORWARDTYPE varchar(1),
            @rec102$DFNDF datetime,
			@rec102$IDSZE varchar(15),
			@rec102$BTERM datetime


          DECLARE
            DB_IMPLICIT_CURSOR_FOR_rec102 CURSOR LOCAL
             FOR

              SELECT
                  p.MCODE,
                  p.FIRMA,
                  p.ORDOP,
                  p.ORDNR,
                  p.SWPCF,
                  p.MORDN,
                  p.GACD1,
                  p.KAUVK,
                  p.FAELD,
                  p.WCOD1,
                  p.BTRW1,
                  p.WCOD2,
                  p.BTRW2,
                  p.KWERT,
                  p.KEINH,
                  p.KURSR,
                  p.WCODL,
                  p.WCODV,
                  p.WCODK,
                  p.BETRL,
                  p.KWRTL,
                  p.BETRV,
                  p.KWRTV,
                  p.BETRK,
                  p.KWRTK,
                  p.KTEXT,
                  p.ANSCH,
                  p.RZPRK,
                  p.UPDTS,
                  p.UPDUS,
                  p.CHKDP,
                  p.KFAEL,
                  p.KKURS,
                  p.ESKRS,
                  p.SWAPS,
                  p.KUNDF,
                  p.DANDF,
                  p.GUVBE,
                  p.GUVTS,
                  p.CBKO1,
                  p.CBKU1,
                  p.CBBM1,
                  p.CBKO2,
                  p.CBKU2,
                  p.CBBM2,
                  p.CBKO3,
                  p.CBKU3,
                  p.CBBM3,
                  p.CBKO4,
                  p.CBKU4,
                  p.CBBM4,
                  p.CBKO5,
                  p.CBKU5,
                  p.CBBM5,
                  p.CBSW1,
                  p.CBKK1,
                  p.CBSW2,
                  p.CBKK2,
                  p.CBSW3,
                  p.CBKK3,
                  p.CBSW4,
                  p.CBKK4,
                  p.CBSW5,
                  p.CBKK5,
                  p.ACTDY,
                  p.RECID,
                  p.ALTERNATIVERATE,
                  p.UPPERLIMIT,
                  p.LOWERLIMIT,
                  p.LIMITREACHED,
                  p.FORWARDTYPE,
                  p.DFNDF,
				  p.IDSZE,
				  p.bterm
                FROM ITDB102 p
                WHERE ((p.MCODE = @pi_mcode) AND
                        (p.FIRMA = @pi_firma) AND
                        (p.ORDOP = @pi_ordop))
              ORDER BY p.ORDNR


          OPEN DB_IMPLICIT_CURSOR_FOR_rec102

          FETCH NEXT FROM DB_IMPLICIT_CURSOR_FOR_rec102
            INTO
              @rec102$MCODE,
              @rec102$FIRMA,
              @rec102$ORDOP,
              @rec102$ORDNR,
              @rec102$SWPCF,
              @rec102$MORDN,
              @rec102$GACD1,
              @rec102$KAUVK,
              @rec102$FAELD,
              @rec102$WCOD1,
              @rec102$BTRW1,
              @rec102$WCOD2,
              @rec102$BTRW2,
              @rec102$KWERT,
              @rec102$KEINH,
              @rec102$KURSR,
              @rec102$WCODL,
              @rec102$WCODV,
              @rec102$WCODK,
              @rec102$BETRL,
              @rec102$KWRTL,
              @rec102$BETRV,
              @rec102$KWRTV,
              @rec102$BETRK,
              @rec102$KWRTK,
              @rec102$KTEXT,
              @rec102$ANSCH,
              @rec102$RZPRK,
              @rec102$UPDTS,
              @rec102$UPDUS,
              @rec102$CHKDP,
              @rec102$KFAEL,
              @rec102$KKURS,
              @rec102$ESKRS,
              @rec102$SWAPS,
              @rec102$KUNDF,
              @rec102$DANDF,
              @rec102$GUVBE,
              @rec102$GUVTS,
              @rec102$CBKO1,
              @rec102$CBKU1,
              @rec102$CBBM1,
              @rec102$CBKO2,
              @rec102$CBKU2,
              @rec102$CBBM2,
              @rec102$CBKO3,
              @rec102$CBKU3,
              @rec102$CBBM3,
              @rec102$CBKO4,
              @rec102$CBKU4,
              @rec102$CBBM4,
              @rec102$CBKO5,
              @rec102$CBKU5,
              @rec102$CBBM5,
              @rec102$CBSW1,
              @rec102$CBKK1,
              @rec102$CBSW2,
              @rec102$CBKK2,
              @rec102$CBSW3,
              @rec102$CBKK3,
              @rec102$CBSW4,
              @rec102$CBKK4,
              @rec102$CBSW5,
              @rec102$CBKK5,
              @rec102$ACTDY,
              @rec102$RECID,
              @rec102$ALTERNATIVERATE,
              @rec102$UPPERLIMIT,
              @rec102$LOWERLIMIT,
              @rec102$LIMITREACHED,
              @rec102$FORWARDTYPE,
              @rec102$DFNDF,
			  @rec102$IDSZE,
			  @rec102$BTERM

          WHILE  NOT(@@FETCH_STATUS = -1)
            BEGIN
                EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @pi_mode = @pi_mode, @pi_modul = 'FX', @pi_mcode = @pi_mcode, @pi_recid = @rec102$RECID, @pi_firma = @pi_firma, @pi_bkonr = @pi_ordop, @pi_konra = @rec102$ORDNR, @pi_khtnr = @pi_khtnr, @pi_abdat = @pi_abdat, @pi_lzvon = @pi_lzvon, @pi_lzbis = @rec102$FAELD, @pi_wcod1 = @rec102$WCOD1, @pi_betr1 = @rec102$BTRW1, @pi_wcod2 = @rec102$WCOD2, @pi_betr2 = @rec102$BTRW2, @pi_kurs = @rec102$KWERT, @pi_getyp = @pi_getyp, @pi_ggart = @rec102$KAUVK, @pi_haend = @pi_haend, @pi_hznum = @pi_hznum, @pi_state = @pi_state, @pi_kutxt = @rec102$KTEXT, @pi_idsze = @rec102$IDSZE, @pi_bterm = @rec102$BTERM, @pi_idprj = @pi_idprj, @pi_ggrdc = @pi_ggrdc, @pi_acode = @pi_acode, @pi_gcode = @pi_gcode, @pi_plang = @pi_plang, @pi_enddt = @pi_enddt, @pi_total = @rec102$BTRW1

              FETCH NEXT FROM DB_IMPLICIT_CURSOR_FOR_rec102
                INTO
                  @rec102$MCODE,
                  @rec102$FIRMA,
                  @rec102$ORDOP,
                  @rec102$ORDNR,
                  @rec102$SWPCF,
                  @rec102$MORDN,
                  @rec102$GACD1,
                  @rec102$KAUVK,
                  @rec102$FAELD,
                  @rec102$WCOD1,
                  @rec102$BTRW1,
                  @rec102$WCOD2,
                  @rec102$BTRW2,
                  @rec102$KWERT,
                  @rec102$KEINH,
                  @rec102$KURSR,
                  @rec102$WCODL,
                  @rec102$WCODV,
                  @rec102$WCODK,
                  @rec102$BETRL,
                  @rec102$KWRTL,
                  @rec102$BETRV,
                  @rec102$KWRTV,
                  @rec102$BETRK,
                  @rec102$KWRTK,
                  @rec102$KTEXT,
                  @rec102$ANSCH,
                  @rec102$RZPRK,
                  @rec102$UPDTS,
                  @rec102$UPDUS,
                  @rec102$CHKDP,
                  @rec102$KFAEL,
                  @rec102$KKURS,
                  @rec102$ESKRS,
                  @rec102$SWAPS,
                  @rec102$KUNDF,
                  @rec102$DANDF,
                  @rec102$GUVBE,
                  @rec102$GUVTS,
                  @rec102$CBKO1,
                  @rec102$CBKU1,
                  @rec102$CBBM1,
                  @rec102$CBKO2,
                  @rec102$CBKU2,
                  @rec102$CBBM2,
                  @rec102$CBKO3,
                  @rec102$CBKU3,
                  @rec102$CBBM3,
                  @rec102$CBKO4,
                  @rec102$CBKU4,
                  @rec102$CBBM4,
                  @rec102$CBKO5,
                  @rec102$CBKU5,
                  @rec102$CBBM5,
                  @rec102$CBSW1,
                  @rec102$CBKK1,
                  @rec102$CBSW2,
                  @rec102$CBKK2,
                  @rec102$CBSW3,
                  @rec102$CBKK3,
                  @rec102$CBSW4,
                  @rec102$CBKK4,
                  @rec102$CBSW5,
                  @rec102$CBKK5,
                  @rec102$ACTDY,
                  @rec102$RECID,
                  @rec102$ALTERNATIVERATE,
                  @rec102$UPPERLIMIT,
                  @rec102$LOWERLIMIT,
                  @rec102$LIMITREACHED,
                  @rec102$FORWARDTYPE,
                  @rec102$DFNDF,
				  @rec102$IDSZE,
				  @rec102$BTERM
            END

          CLOSE DB_IMPLICIT_CURSOR_FOR_rec102

          DEALLOCATE DB_IMPLICIT_CURSOR_FOR_rec102

        END


        BEGIN

          DECLARE
            @rec103$MCODE varchar(3),
            @rec103$FIRMA varchar(12),
            @rec103$ORDOP varchar(10),
            @rec103$ORDNR varchar(10),
            @rec103$MORDN varchar(35),
            @rec103$GACD1 varchar(1),
            @rec103$KAUVK varchar(1),
            @rec103$OPART varchar(2),
            @rec103$FAELD datetime,
            @rec103$WCOD1 varchar(3),
            @rec103$BTRW1 numeric(15,2),
            @rec103$WCOD2 varchar(3),
            @rec103$BTRW2 numeric(15,2),
            @rec103$KWERT numeric(19,10),
            @rec103$KEINH numeric(6),
            @rec103$KURSR varchar(1),
            @rec103$WCODL varchar(3),
            @rec103$WCODV varchar(3),
            @rec103$WCODK varchar(3),
            @rec103$BETRL numeric(15,2),
            @rec103$KWRTL numeric(19,10),
            @rec103$BETRV numeric(15,2),
            @rec103$KWRTV numeric(19,10),
            @rec103$BETRK numeric(15,2),
            @rec103$KWRTK numeric(19,10),
            @rec103$KTEXT varchar(35),
            @rec103$OPAUS varchar(1),
            @rec103$OPEIN numeric(5),
            @rec103$PRMBT numeric(15,2),
            @rec103$PRMPZ numeric(15,6),
            @rec103$OGEBF numeric(15,2),
            @rec103$OGEBL numeric(15,2),
            @rec103$PRMWC varchar(3),
            @rec103$PRMKW numeric(19,10),
            @rec103$PRMKE numeric(5),
            @rec103$PRMKR varchar(1),
            @rec103$PRMVA datetime,
            @rec103$BOERS varchar(1),
            @rec103$KRSL1 numeric(19,10),
            @rec103$KRSL2 numeric(19,10),
            @rec103$KIKTS datetime,
            @rec103$DEKLD datetime,
            @rec103$DEKLT datetime,
            @rec103$DEKLO varchar(3),
            @rec103$ANSCH varchar(1),
            @rec103$RZPRK varchar(1),
            @rec103$UPDTS datetime,
            @rec103$UPDUS varchar(10),
            @rec103$CHKDP numeric(9),
            @rec103$KKURS numeric(19,10),
            @rec103$ESKRS numeric(19,10),
            @rec103$GUVBE numeric(15,2),
            @rec103$GUVTS datetime,
            @rec103$RATIO numeric(15,3),
            @rec103$CBKO1 varchar(13),
            @rec103$CBKU1 numeric(19,10),
            @rec103$CBBM1 varchar(200),
            @rec103$CBKO2 varchar(13),
            @rec103$CBKU2 numeric(19,10),
            @rec103$CBBM2 varchar(200),
            @rec103$CBKO3 varchar(13),
            @rec103$CBKU3 numeric(19,10),
            @rec103$CBBM3 varchar(200),
            @rec103$CBKO4 varchar(13),
            @rec103$CBKU4 numeric(19,10),
            @rec103$CBBM4 varchar(200),
            @rec103$CBKO5 varchar(13),
            @rec103$CBKU5 numeric(19,10),
            @rec103$CBBM5 varchar(200),
            @rec103$OPTYP varchar(1),
            @rec103$PTYPE varchar(1),
            @rec103$AUSUE datetime,
            @rec103$AUPER varchar(1),
            @rec103$MOPER varchar(1),
            @rec103$KIKT2 datetime,
            @rec103$KRUE1 numeric(19,10),
            @rec103$KRUE2 numeric(19,10),
            @rec103$MONTS datetime,
            @rec103$EINTK numeric(19,10),
            @rec103$DAYL1 numeric(4),
            @rec103$DAYL2 numeric(4),
            @rec103$FAKT1 numeric(19,10),
            @rec103$FAKT2 numeric(19,10),
            @rec103$BWART varchar(1),
            @rec103$FIXIT varchar(1),
            @rec103$DSCHK numeric(19,10),
            @rec103$INTVL varchar(1),
            @rec103$DSCHD datetime,
            @rec103$RECID varchar(15),
			@rec103$IDSZE varchar(15),
			@rec103$BTERM datetime

          DECLARE
            DB_IMPLICIT_CURSOR_FOR_rec103 CURSOR LOCAL
             FOR

              SELECT
                  p.MCODE,
                  p.FIRMA,
                  p.ORDOP,
                  p.ORDNR,
                  p.MORDN,
                  p.GACD1,
                  p.KAUVK,
                  p.OPART,
                  p.FAELD,
                  p.WCOD1,
                  p.BTRW1,
                  p.WCOD2,
                  p.BTRW2,
                  p.KWERT,
                  p.KEINH,
                  p.KURSR,
                  p.WCODL,
                  p.WCODV,
                  p.WCODK,
                  p.BETRL,
                  p.KWRTL,
                  p.BETRV,
                  p.KWRTV,
                  p.BETRK,
                  p.KWRTK,
                  p.KTEXT,
                  p.OPAUS,
                  p.OPEIN,
                  p.PRMBT,
                  p.PRMPZ,
                  p.OGEBF,
                  p.OGEBL,
                  p.PRMWC,
                  p.PRMKW,
                  p.PRMKE,
                  p.PRMKR,
                  p.PRMVA,
                  p.BOERS,
                  p.KRSL1,
                  p.KRSL2,
                  p.KIKTS,
                  p.DEKLD,
                  p.DEKLT,
                  p.DEKLO,
                  p.ANSCH,
                  p.RZPRK,
                  p.UPDTS,
                  p.UPDUS,
                  p.CHKDP,
                  p.KKURS,
                  p.ESKRS,
                  p.GUVBE,
                  p.GUVTS,
                  p.RATIO,
                  p.CBKO1,
                  p.CBKU1,
                  p.CBBM1,
                  p.CBKO2,
                  p.CBKU2,
                  p.CBBM2,
                  p.CBKO3,
                  p.CBKU3,
                  p.CBBM3,
                  p.CBKO4,
                  p.CBKU4,
                  p.CBBM4,
                  p.CBKO5,
                  p.CBKU5,
                  p.CBBM5,
                  p.OPTYP,
                  p.PTYPE,
                  p.AUSUE,
                  p.AUPER,
                  p.MOPER,
                  p.KIKT2,
                  p.KRUE1,
                  p.KRUE2,
                  p.MONTS,
                  p.EINTK,
                  p.DAYL1,
                  p.DAYL2,
                  p.FAKT1,
                  p.FAKT2,
                  p.BWART,
                  p.FIXIT,
                  p.DSCHK,
                  p.INTVL,
                  p.DSCHD,
                  p.RECID,
				  p.IDSZE,
				  p.BTERM
                FROM ITDB103 p
                WHERE ((p.MCODE = @pi_mcode) AND
                        (p.FIRMA = @pi_firma) AND
                        (p.ORDOP = @pi_ordop))
              ORDER BY p.ORDNR


          OPEN DB_IMPLICIT_CURSOR_FOR_rec103

          FETCH NEXT FROM DB_IMPLICIT_CURSOR_FOR_rec103
            INTO
              @rec103$MCODE,
              @rec103$FIRMA,
              @rec103$ORDOP,
              @rec103$ORDNR,
              @rec103$MORDN,
              @rec103$GACD1,
              @rec103$KAUVK,
              @rec103$OPART,
              @rec103$FAELD,
              @rec103$WCOD1,
              @rec103$BTRW1,
              @rec103$WCOD2,
              @rec103$BTRW2,
              @rec103$KWERT,
              @rec103$KEINH,
              @rec103$KURSR,
              @rec103$WCODL,
              @rec103$WCODV,
              @rec103$WCODK,
              @rec103$BETRL,
              @rec103$KWRTL,
              @rec103$BETRV,
              @rec103$KWRTV,
              @rec103$BETRK,
              @rec103$KWRTK,
              @rec103$KTEXT,
              @rec103$OPAUS,
              @rec103$OPEIN,
              @rec103$PRMBT,
              @rec103$PRMPZ,
              @rec103$OGEBF,
              @rec103$OGEBL,
              @rec103$PRMWC,
              @rec103$PRMKW,
              @rec103$PRMKE,
              @rec103$PRMKR,
              @rec103$PRMVA,
              @rec103$BOERS,
              @rec103$KRSL1,
              @rec103$KRSL2,
              @rec103$KIKTS,
              @rec103$DEKLD,
              @rec103$DEKLT,
              @rec103$DEKLO,
              @rec103$ANSCH,
              @rec103$RZPRK,
              @rec103$UPDTS,
              @rec103$UPDUS,
              @rec103$CHKDP,
              @rec103$KKURS,
              @rec103$ESKRS,
              @rec103$GUVBE,
              @rec103$GUVTS,
              @rec103$RATIO,
              @rec103$CBKO1,
              @rec103$CBKU1,
              @rec103$CBBM1,
              @rec103$CBKO2,
              @rec103$CBKU2,
              @rec103$CBBM2,
              @rec103$CBKO3,
              @rec103$CBKU3,
              @rec103$CBBM3,
              @rec103$CBKO4,
              @rec103$CBKU4,
              @rec103$CBBM4,
              @rec103$CBKO5,
              @rec103$CBKU5,
              @rec103$CBBM5,
              @rec103$OPTYP,
              @rec103$PTYPE,
              @rec103$AUSUE,
              @rec103$AUPER,
              @rec103$MOPER,
              @rec103$KIKT2,
              @rec103$KRUE1,
              @rec103$KRUE2,
              @rec103$MONTS,
              @rec103$EINTK,
              @rec103$DAYL1,
              @rec103$DAYL2,
              @rec103$FAKT1,
              @rec103$FAKT2,
              @rec103$BWART,
              @rec103$FIXIT,
              @rec103$DSCHK,
              @rec103$INTVL,
              @rec103$DSCHD,
              @rec103$RECID,
              @rec103$IDSZE,
              @rec103$BTERM

          WHILE  NOT(@@FETCH_STATUS = -1)
            BEGIN
                EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @pi_mode = @pi_mode, @pi_modul = 'FX', @pi_mcode = @pi_mcode, @pi_recid = @rec103$RECID, @pi_firma = @pi_firma, @pi_bkonr = @pi_ordop, @pi_konra = @rec103$ORDNR, @pi_khtnr = @pi_khtnr, @pi_abdat = @pi_abdat, @pi_lzvon = @pi_lzvon, @pi_lzbis = @rec103$FAELD, @pi_wcod1 = @rec103$WCOD1, @pi_betr1 = @rec103$BTRW1, @pi_wcod2 = @rec103$WCOD2, @pi_betr2 = @rec103$BTRW2, @pi_kurs = @rec103$KWERT, @pi_getyp = @pi_getyp, @pi_ggart = @rec103$KAUVK, @pi_haend = @pi_haend, @pi_hznum = @pi_hznum, @pi_state = @pi_state, @pi_kutxt = @rec103$KTEXT, @pi_idsze = @rec103$IDSZE, @pi_bterm = @rec103$BTERM, @pi_idprj = @pi_idprj, @pi_ggrdc = @pi_ggrdc, @pi_acode = @pi_acode, @pi_gcode = @pi_gcode, @pi_plang = @pi_plang, @pi_enddt = @pi_enddt, @pi_total = @rec103$BTRW1

              FETCH NEXT FROM DB_IMPLICIT_CURSOR_FOR_rec103
                INTO
                  @rec103$MCODE,
                  @rec103$FIRMA,
                  @rec103$ORDOP,
                  @rec103$ORDNR,
                  @rec103$MORDN,
                  @rec103$GACD1,
                  @rec103$KAUVK,
                  @rec103$OPART,
                  @rec103$FAELD,
                  @rec103$WCOD1,
                  @rec103$BTRW1,
                  @rec103$WCOD2,
                  @rec103$BTRW2,
                  @rec103$KWERT,
                  @rec103$KEINH,
                  @rec103$KURSR,
                  @rec103$WCODL,
                  @rec103$WCODV,
                  @rec103$WCODK,
                  @rec103$BETRL,
                  @rec103$KWRTL,
                  @rec103$BETRV,
                  @rec103$KWRTV,
                  @rec103$BETRK,
                  @rec103$KWRTK,
                  @rec103$KTEXT,
                  @rec103$OPAUS,
                  @rec103$OPEIN,
                  @rec103$PRMBT,
                  @rec103$PRMPZ,
                  @rec103$OGEBF,
                  @rec103$OGEBL,
                  @rec103$PRMWC,
                  @rec103$PRMKW,
                  @rec103$PRMKE,
                  @rec103$PRMKR,
                  @rec103$PRMVA,
                  @rec103$BOERS,
                  @rec103$KRSL1,
                  @rec103$KRSL2,
                  @rec103$KIKTS,
                  @rec103$DEKLD,
                  @rec103$DEKLT,
                  @rec103$DEKLO,
                  @rec103$ANSCH,
                  @rec103$RZPRK,
                  @rec103$UPDTS,
                  @rec103$UPDUS,
                  @rec103$CHKDP,
                  @rec103$KKURS,
                  @rec103$ESKRS,
                  @rec103$GUVBE,
                  @rec103$GUVTS,
                  @rec103$RATIO,
                  @rec103$CBKO1,
                  @rec103$CBKU1,
                  @rec103$CBBM1,
                  @rec103$CBKO2,
                  @rec103$CBKU2,
                  @rec103$CBBM2,
                  @rec103$CBKO3,
                  @rec103$CBKU3,
                  @rec103$CBBM3,
                  @rec103$CBKO4,
                  @rec103$CBKU4,
                  @rec103$CBBM4,
                  @rec103$CBKO5,
                  @rec103$CBKU5,
                  @rec103$CBBM5,
                  @rec103$OPTYP,
                  @rec103$PTYPE,
                  @rec103$AUSUE,
                  @rec103$AUPER,
                  @rec103$MOPER,
                  @rec103$KIKT2,
                  @rec103$KRUE1,
                  @rec103$KRUE2,
                  @rec103$MONTS,
                  @rec103$EINTK,
                  @rec103$DAYL1,
                  @rec103$DAYL2,
                  @rec103$FAKT1,
                  @rec103$FAKT2,
                  @rec103$BWART,
                  @rec103$FIXIT,
                  @rec103$DSCHK,
                  @rec103$INTVL,
                  @rec103$DSCHD,
                  @rec103$RECID,
				  @rec103$IDSZE,
				  @rec103$BTERM
		END

          CLOSE DB_IMPLICIT_CURSOR_FOR_rec103

          DEALLOCATE DB_IMPLICIT_CURSOR_FOR_rec103

        END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_Sequence_Create]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_Sequence_Create]
GO

CREATE PROCEDURE sp_Sequence_Create
(
	@sequenceName varchar(30),
	@startVal decimal =1,
	@minVal decimal =0,
	@maxVal decimal =0,
	@increment int =1
)
AS
BEGIN
   DECLARE @sqlStmt varchar(500)
   SET NOCOUNT ON
   SET @sqlStmt = 'CREATE TABLE ' + @sequenceName +
      ' ( last_number numeric(13,0) IDENTITY (' + convert (varchar(13),@startVal) +
	',' + convert (varchar(10),@increment) + ') primary key' +
	',' + 'min_value numeric(13,0) DEFAULT (' + convert (varchar(13),@minVal) + ')' +
	',' + 'max_value numeric(13,0) DEFAULT (' + convert (varchar(13),@maxVal) + ')' +
	',' + 'increment_by numeric(13,0) DEFAULT (' + convert (varchar(10),@increment) + ')' +
	')'
   EXEC (@sqlStmt)

   SET NOCOUNT OFF
   RETURN
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_Sequence_Drop]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_Sequence_Drop]
GO

CREATE PROCEDURE sp_Sequence_Drop
(
	@sequenceName varchar(30)
)
AS
BEGIN
   DECLARE @sqlStmt varchar(500)
   SET NOCOUNT ON
   SET @sqlStmt = 'DROP TABLE ' + @sequenceName
   EXEC (@sqlStmt)
   SET NOCOUNT OFF
   RETURN
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_Sequence_Nextval]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_Sequence_Nextval]
GO

CREATE PROCEDURE sp_Sequence_Nextval
(
	@sequenceName VARCHAR(30),
	@nextVal DECIMAL OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sqlStmt NVARCHAR(1000)
	DECLARE @ParamDef NVARCHAR(1000)
	DECLARE @identityColumn NVARCHAR(1000)
	DECLARE @return_status INT

	SELECT @identityColumn = name FROM sys.identity_columns WITH (NOLOCK) WHERE object_id = object_id(@sequenceName)
	SELECT @ParamDef = '@sequenceName VARCHAR(30), @nextVal DECIMAL OUTPUT'

	SET @sqlStmt = 'DECLARE @nextValTbl TABLE( nextVal DECIMAL );'
				+ ' INSERT [' + @sequenceName + '] OUTPUT inserted.[' + @identityColumn + '] INTO @nextValTbl DEFAULT VALUES;'
				+ ' SET @nextVal = (SELECT TOP (1) nextVal FROM @nextValTbl);'
				+ ' DELETE FROM [' + @sequenceName + '] WITH (READPAST) WHERE [' + @identityColumn + '] = @nextVal';
	EXEC @return_status = sp_executesql @sqlStmt, @ParamDef, @sequenceName = @sequenceName, @nextVal = @nextVal OUTPUT

	SET NOCOUNT OFF
	RETURN
END
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_update_itprodctl]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_update_itprodctl]
GO

CREATE PROCEDURE [dbo].[sp_update_itprodctl]
@svrDb varchar(30),
@svrMachine varchar(64),
@isProductiveSystem varchar(1)

AS
BEGIN
	UPDATE ITPRODCTL SET isProductive = @isProductiveSystem WHERE SvrMachine = @svrMachine and SvrDB = @svrDb;
END
GO


IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_update_itprodctlp]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[sp_update_itprodctlp]
GO

CREATE PROCEDURE [dbo].[sp_update_itprodctlp]
@mcode varchar(3),
@module varchar(30),
@svrDb varchar(30),
@svrMachine varchar(64),
@isProductiveModule varchar(1)

AS
BEGIN
	UPDATE ITPRODCTLP SET isProductive = @isProductiveModule WHERE mcode = @mcode and module = @module and SvrMachine = @svrMachine and SvrDB = @svrDb;
END
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBC_SEQ_EVENTID]'))
	EXEC sp_Sequence_Create 'DBC_SEQ_EVENTID',0,0,999999999999,1
GO

-- Sequences (SQL-Server) 

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBC_SEQ_FILEID]'))
	EXEC sp_Sequence_Create 'DBC_SEQ_FILEID',0,0,999999999999,1
GO

-- Sequences (SQL-Server) 

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBC_SEQ_HIST]'))
	EXEC sp_Sequence_Create 'DBC_SEQ_HIST',0,0,999999999999,1
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBC_SEQ_LOGID]'))
	EXEC sp_Sequence_Create 'DBC_SEQ_LOGID',0,0,999999999999,1
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DBC_SEQ_RECID]'))
	EXEC sp_Sequence_Create 'DBC_SEQ_RECID',0,0,999999999999,1
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SEQ_SESSIONID]'))
	EXEC sp_Sequence_Create 'SEQ_SESSIONID',0,0,999999999999,1
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB101_AU]'))
	DROP TRIGGER [dbo].[trg_ITDB101_AU]
GO

CREATE TRIGGER trg_ITDB101_AU ON dbo.ITDB101
    AFTER UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(6),
        @column_new_value$5 varchar(13),
        @column_new_value$6 varchar(35),
        @column_new_value$18 datetime,
        @column_new_value$33 varchar(1),
        @column_new_value$40 datetime,
        @column_new_value$42 datetime,
        @column_new_value$44 datetime,
        @column_new_value$46 datetime,
        @column_new_value$48 datetime,
        @column_new_value$55 varchar(10),
        @column_new_value$78 varchar(15),
        @column_new_value$idprj varchar(15),
		@column_new_value$ggrdc varchar(6),
		@column_new_value$acode varchar(6),
		@column_new_value$gcode varchar(10),
		@column_new_value$plang varchar(1),
		@column_new_value$enddt datetime

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, ORDOP, GACOD, KHTNR, HAEND, ABSTS, ENDCD, ERFDZ, FREDZ, BESDZ, ABGDZ, STODZ, HZNUM, RECID, IDPRJ, GGRDC, ACODE, GCODE, PLANG, ENDTS FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$18, @column_new_value$33, @column_new_value$40, @column_new_value$42, @column_new_value$44, @column_new_value$46, @column_new_value$48, @column_new_value$55, @column_new_value$78, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB101_AU implementation: begin */
        BEGIN

          DECLARE
            @fx_state varchar(9),
			@fx_lzvon datetime;

          IF ((@column_new_value$78 LIKE ' %') OR
                          (ISNULL((@column_new_value$78 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          SET @fx_state = dbo.fn_PKG_ITS_TREASURY_get_state(@column_new_value$33, @column_new_value$48, '1970-01-01',@column_new_value$46, @column_new_value$44, @column_new_value$42, @column_new_value$40)

		  SET @fx_lzvon = dbo.fn_PKG_ITS_TREASURY_get_fxlzvon(@column_new_value$18)

          /*  Spezialversion, die intern die 102/103-Beine liest  */

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head_fx @pi_mode = 'U', @pi_modul = 'FX', @pi_mcode = @column_new_value$1, @pi_recid = @column_new_value$78, @pi_firma = @column_new_value$2, @pi_ordop = @column_new_value$3, @pi_khtnr = @column_new_value$5, @pi_abdat = @column_new_value$18, @pi_lzvon = @fx_lzvon, @pi_getyp = @column_new_value$4, @pi_haend = @column_new_value$6, @pi_hznum = @column_new_value$55, @pi_state = @fx_state, @pi_idprj = @column_new_value$idprj, @pi_ggrdc = @column_new_value$ggrdc, @pi_acode = @column_new_value$acode, @pi_gcode = @column_new_value$gcode, @pi_plang = @column_new_value$plang, @pi_enddt = @column_new_value$enddt

        END
        /* Oracle-trigger dbo.TRG_ITDB101_AU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$18, @column_new_value$33, @column_new_value$40, @column_new_value$42, @column_new_value$44, @column_new_value$46, @column_new_value$48, @column_new_value$55, @column_new_value$78, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB102_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB102_AD]
GO

CREATE TRIGGER trg_ITDB102_AD ON dbo.ITDB102
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$66 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, ORDOP, ORDNR, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$66

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB102_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = 'FX', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$66, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$3, @PI_konra = @column_old_value$4
        END
        /* Oracle-trigger dbo.TRG_ITDB102_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$66
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB102_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB102_AIU]
GO

CREATE TRIGGER trg_ITDB102_AIU ON dbo.ITDB102
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$mcode varchar(3),
        @column_new_value$mcode varchar(3),
        @column_new_value$firma varchar(12),
        @column_new_value$ordop varchar(10),
        @column_new_value$ordnr varchar(10),
        @column_new_value$kauvk varchar(1),
        @column_new_value$faeld datetime,
        @column_new_value$wcod1 varchar(3),
        @column_new_value$btrw1 numeric(15, 2),
        @column_new_value$wcod2 varchar(3),
        @column_new_value$btrw2 numeric(15, 2),
        @column_new_value$kwert numeric(19, 10),
        @column_new_value$ktext varchar(35),
        @column_new_value$recid varchar(15),
        @column_new_value$idsze varchar(15),
        @column_new_value$bterm datetime

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, ORDOP, ORDNR, KAUVK, FAELD, WCOD1, BTRW1, WCOD2, BTRW2, KWERT, KTEXT, RECID, IDSZE, BTERM FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$mcode, @column_new_value$firma, @column_new_value$ordop, @column_new_value$ordnr, @column_new_value$kauvk, @column_new_value$faeld, @column_new_value$wcod1, @column_new_value$btrw1, @column_new_value$wcod2, @column_new_value$btrw2, @column_new_value$kwert, @column_new_value$ktext, @column_new_value$recid, @column_new_value$idsze, @column_new_value$bterm

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$mcode = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$mcode AND
		  		recid = @column_new_value$recid
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB102_AIU implementation: begin */
        BEGIN

          DECLARE
            @fx_state varchar(9),
			@fx_lzvon datetime,
            @op varchar(1),
			@rec101$MCODE varchar(3),
			@rec101$FIRMA varchar(12),
			@rec101$ORDOP varchar(10),
			@rec101$GACOD varchar(13),
			@rec101$KHTNR varchar(13),
			@rec101$HAEND varchar(35),
			@rec101$ABSTS datetime,
			@rec101$ENDCD varchar(1),
			@rec101$ERFDZ datetime,
			@rec101$FREDZ datetime,
			@rec101$BESDZ datetime,
			@rec101$ABGDZ datetime,
			@rec101$STODZ datetime,
			@rec101$HZNUM varchar(10),
			@rec101$RECID varchar(15),
			@rec101$IDPRJ varchar(15),
			@rec101$GGRDC varchar(6),
			@rec101$ACODE varchar(6),
			@rec101$GCODE varchar(10),
			@rec101$PLANG varchar(1),
			@rec101$ENDTS datetime

          IF ((@column_new_value$recid LIKE ' %') OR
                          (ISNULL((@column_new_value$recid + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END


          EXEC dbo.sp_PKG_ITS_TREASURY_get_fxhead @pi_mcode = @column_new_value$mcode, @pi_firma = @column_new_value$firma, @pi_ordop = @column_new_value$ordop,
												@MCODE = @rec101$MCODE OUTPUT,
												@FIRMA = @rec101$FIRMA OUTPUT,
												@ORDOP = @rec101$ORDOP OUTPUT,
												@GACOD = @rec101$GACOD OUTPUT,
												@KHTNR = @rec101$KHTNR OUTPUT,
												@HAEND = @rec101$HAEND OUTPUT,
												@ABSTS = @rec101$ABSTS OUTPUT,
												@ENDCD = @rec101$ENDCD OUTPUT,
												@ERFDZ = @rec101$ERFDZ OUTPUT,
												@FREDZ = @rec101$FREDZ OUTPUT,
												@BESDZ = @rec101$BESDZ OUTPUT,
												@ABGDZ = @rec101$ABGDZ OUTPUT,
												@STODZ = @rec101$STODZ OUTPUT,
												@HZNUM = @rec101$HZNUM OUTPUT,
												@RECID = @rec101$RECID OUTPUT,
												@IDPRJ = @rec101$IDPRJ OUTPUT,
												@GGRDC = @rec101$GGRDC OUTPUT,
												@ACODE = @rec101$ACODE OUTPUT,
												@GCODE = @rec101$GCODE OUTPUT,
												@PLANG = @rec101$PLANG OUTPUT,
												@ENDDT = @rec101$ENDTS OUTPUT


          SET @fx_state = dbo.fn_PKG_ITS_TREASURY_get_state(@rec101$ENDCD, @rec101$STODZ,'1970-01-01', @rec101$ABGDZ, @rec101$BESDZ, @rec101$FREDZ, @rec101$ERFDZ)

		  SET @fx_lzvon = dbo.fn_PKG_ITS_TREASURY_get_fxlzvon(@rec101$ABSTS)

          IF (ISNULL((@column_old_value$mcode + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @pi_mode = @op, @pi_modul = 'FX', @pi_mcode = @rec101$MCODE, @pi_recid = @column_new_value$recid, @pi_firma = @rec101$FIRMA, @pi_bkonr = @rec101$ORDOP, @pi_konra = @column_new_value$ordnr, @pi_khtnr = @rec101$KHTNR, @pi_abdat = @rec101$ABSTS, @pi_lzvon = @fx_lzvon, @pi_lzbis = @column_new_value$faeld, @pi_wcod1 = @column_new_value$wcod1, @pi_betr1 = @column_new_value$btrw1, @pi_wcod2 = @column_new_value$wcod2, @pi_betr2 = @column_new_value$btrw2, @pi_kurs = @column_new_value$kwert, @pi_getyp = @rec101$GACOD, @pi_ggart = @column_new_value$kauvk, @pi_haend = @rec101$HAEND, @pi_hznum = @rec101$HZNUM, @pi_state = @fx_state, @pi_kutxt = @column_new_value$ktext, @pi_idsze = @column_new_value$idsze, @pi_bterm = @column_new_value$bterm, @pi_idprj = @rec101$IDPRJ, @pi_ggrdc = @rec101$GGRDC, @pi_acode = @rec101$ACODE, @pi_gcode = @rec101$GCODE, @pi_plang = @rec101$PLANG, @pi_enddt = @rec101$ENDTS, @pi_total = @column_new_value$btrw1

        END
        /* Oracle-trigger dbo.TRG_ITDB102_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$mcode, @column_new_value$firma, @column_new_value$ordop, @column_new_value$ordnr, @column_new_value$kauvk, @column_new_value$faeld, @column_new_value$wcod1, @column_new_value$btrw1, @column_new_value$wcod2, @column_new_value$btrw2, @column_new_value$kwert, @column_new_value$ktext, @column_new_value$recid, @column_new_value$idsze, @column_new_value$bterm
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB103_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB103_AD]
GO

CREATE TRIGGER trg_ITDB103_AD ON dbo.ITDB103
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$89 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, ORDOP, ORDNR, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$89

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB103_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = 'FX', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$89, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$3, @PI_konra = @column_old_value$4
        END
        /* Oracle-trigger dbo.TRG_ITDB103_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$89
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB103_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB103_AIU]
GO

CREATE TRIGGER trg_ITDB103_AIU ON dbo.ITDB103
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$7 varchar(1),
        @column_new_value$9 datetime,
        @column_new_value$10 varchar(3),
        @column_new_value$btrw1 numeric(15, 2),
        @column_new_value$12 varchar(3),
        @column_new_value$btrw2 numeric(15, 2),
        @column_new_value$kwert numeric(19, 10),
        @column_new_value$26 varchar(35),
        @column_new_value$89 varchar(15),
        @column_new_value$idsze varchar(15),
        @column_new_value$bterm datetime

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, ORDOP, ORDNR, KAUVK, FAELD, WCOD1, BTRW1, WCOD2, BTRW2, KWERT, KTEXT, RECID, IDSZE, BTERM FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$7, @column_new_value$9, @column_new_value$10, @column_new_value$btrw1, @column_new_value$12, @column_new_value$btrw2, @column_new_value$kwert, @column_new_value$26, @column_new_value$89, @column_new_value$idsze, @column_new_value$bterm

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$1 = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				recid = @column_new_value$89
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB103_AIU implementation: begin */
        BEGIN

          DECLARE
            @fx_state varchar(3),
			@fx_lzvon datetime,
            @op varchar(1),
			@rec101$MCODE varchar(3),
			@rec101$FIRMA varchar(12),
			@rec101$ORDOP varchar(10),
			@rec101$GACOD varchar(13),
			@rec101$KHTNR varchar(13),
			@rec101$HAEND varchar(35),
			@rec101$ABSTS datetime,
			@rec101$ENDCD varchar(1),
			@rec101$ERFDZ datetime,
			@rec101$FREDZ datetime,
			@rec101$BESDZ datetime,
			@rec101$ABGDZ datetime,
			@rec101$STODZ datetime,
			@rec101$HZNUM varchar(10),
			@rec101$RECID varchar(15),
			@rec101$IDPRJ varchar(15),
			@rec101$GGRDC varchar(6),
			@rec101$ACODE varchar(6),
			@rec101$GCODE varchar(10),
			@rec101$PLANG varchar(1),
			@rec101$ENDTS datetime

          IF ((@column_new_value$89 LIKE ' %') OR
                          (ISNULL((@column_new_value$89 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          EXEC dbo.sp_PKG_ITS_TREASURY_get_fxhead @pi_mcode = @column_new_value$1, @pi_firma = @column_new_value$2, @pi_ordop = @column_new_value$3,
												@MCODE = @rec101$MCODE OUTPUT,
												@FIRMA = @rec101$FIRMA OUTPUT,
												@ORDOP = @rec101$ORDOP OUTPUT,
												@GACOD = @rec101$GACOD OUTPUT,
												@KHTNR = @rec101$KHTNR OUTPUT,
												@HAEND = @rec101$HAEND OUTPUT,
												@ABSTS = @rec101$ABSTS OUTPUT,
												@ENDCD = @rec101$ENDCD OUTPUT,
												@ERFDZ = @rec101$ERFDZ OUTPUT,
												@FREDZ = @rec101$FREDZ OUTPUT,
												@BESDZ = @rec101$BESDZ OUTPUT,
												@ABGDZ = @rec101$ABGDZ OUTPUT,
												@STODZ = @rec101$STODZ OUTPUT,
												@HZNUM = @rec101$HZNUM OUTPUT,
												@RECID = @rec101$RECID OUTPUT,
												@IDPRJ = @rec101$IDPRJ OUTPUT,
												@GGRDC = @rec101$GGRDC OUTPUT,
												@ACODE = @rec101$ACODE OUTPUT,
												@GCODE = @rec101$GCODE OUTPUT,
												@PLANG = @rec101$PLANG OUTPUT,
												@ENDDT = @rec101$ENDTS OUTPUT


          SET @fx_state = dbo.fn_PKG_ITS_TREASURY_get_state(@rec101$ENDCD, @rec101$STODZ, '1970-01-01',@rec101$ABGDZ, @rec101$BESDZ, @rec101$FREDZ, @rec101$ERFDZ)

		  SET @fx_lzvon = dbo.fn_PKG_ITS_TREASURY_get_fxlzvon(@rec101$ABSTS)

          IF (ISNULL((@column_old_value$1 + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @pi_mode = @op, @pi_modul = 'FX', @pi_mcode = @rec101$MCODE, @pi_recid = @column_new_value$89, @pi_firma = @rec101$FIRMA, @pi_bkonr = @rec101$ORDOP, @pi_konra = @column_new_value$4, @pi_khtnr = @rec101$KHTNR, @pi_abdat = @rec101$ABSTS, @pi_lzvon = @fx_lzvon, @pi_lzbis = @column_new_value$9, @pi_wcod1 = @column_new_value$10, @pi_betr1 = @column_new_value$btrw1, @pi_wcod2 = @column_new_value$12, @pi_betr2 = @column_new_value$btrw2, @pi_kurs = @column_new_value$kwert, @pi_getyp = @rec101$GACOD, @pi_ggart = @column_new_value$7, @pi_haend = @rec101$HAEND, @pi_hznum = @rec101$HZNUM, @pi_state = @fx_state, @pi_kutxt = @column_new_value$26, @pi_idsze = @column_new_value$idsze, @pi_bterm = @column_new_value$bterm, @pi_idprj = @rec101$IDPRJ, @pi_ggrdc = @rec101$GGRDC, @pi_acode = @rec101$ACODE, @pi_gcode = @rec101$GCODE, @pi_plang = @rec101$PLANG, @pi_enddt = @rec101$ENDTS, @pi_total = @column_new_value$btrw1

        END
        /* Oracle-trigger dbo.TRG_ITDB103_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$7, @column_new_value$9, @column_new_value$10, @column_new_value$btrw1, @column_new_value$12, @column_new_value$btrw2, @column_new_value$kwert, @column_new_value$26, @column_new_value$89, @column_new_value$idsze, @column_new_value$bterm
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB200_AU]'))
	DROP TRIGGER [dbo].[trg_ITDB200_AU]
GO

CREATE TRIGGER trg_ITDB200_AU ON dbo.ITDB200
    AFTER UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_new_value$mcode varchar(3),
        @column_new_value$firma varchar(12),
        @column_new_value$ordop varchar(10),
        @column_new_value$khtnr varchar(13),
        @column_new_value$haend varchar(35),
        @column_new_value$absts datetime,
        @column_new_value$beeus varchar(10),
        @column_new_value$erfdz datetime,
        @column_new_value$fredz datetime,
        @column_new_value$besdz datetime,
        @column_new_value$abgdz datetime,
        @column_new_value$stodz datetime,
		@column_new_value$anfstot datetime,
        @column_new_value$hznum varchar(10),
        @column_new_value$recid varchar(15),
        @column_new_value$idprj varchar(15),
		@column_new_value$ggrdc varchar(6),
		@column_new_value$acode varchar(6),
		@column_new_value$gcode varchar(10),
		@column_new_value$plang varchar(1),
		@column_new_value$enddt datetime


      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, ORDOP, KHTNR, HAEND, ABSTS, BEEUSER, ERFTIME, KONTIME, BESTIME, ABGTIME, STOTIME,ANFSTOT, HZNUM, RECID, IDPRJ, GGRDC, ACODE, GCODE, PLANG, BEETIME FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$mcode, @column_new_value$firma, @column_new_value$ordop, @column_new_value$khtnr, @column_new_value$haend, @column_new_value$absts, @column_new_value$beeus, @column_new_value$erfdz, @column_new_value$fredz, @column_new_value$besdz, @column_new_value$abgdz, @column_new_value$stodz, @column_new_value$anfstot,@column_new_value$hznum, @column_new_value$recid, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB200_AU implementation: begin */
        BEGIN

          DECLARE
            @co_state varchar(9),
            @co_endcd varchar(1)

          IF ((@column_new_value$recid LIKE ' %') OR
                          (ISNULL((@column_new_value$recid + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

		  SET @co_endcd = 'Y'
		  IF (@column_new_value$beeus = '          ')
			  SET @co_endcd = 'N'

          SET @co_state = dbo.fn_PKG_ITS_TREASURY_get_state(@co_endcd, @column_new_value$stodz,@column_new_value$anfstot, @column_new_value$abgdz, @column_new_value$besdz, @column_new_value$fredz, @column_new_value$erfdz)

          /*  Spezialversion, die intern die 201-Beine liest  */

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head_co @pi_mode = 'U', @pi_modul = 'CO', @pi_mcode = @column_new_value$mcode, @pi_recid = @column_new_value$recid, @pi_firma = @column_new_value$firma, @pi_ordop = @column_new_value$ordop, @pi_khtnr = @column_new_value$khtnr, @pi_abdat = @column_new_value$absts, @pi_lzvon = @column_new_value$absts, /*@pi_getyp = @column_new_value$4,*/ @pi_haend = @column_new_value$haend, @pi_hznum = @column_new_value$hznum, @pi_state = @co_state, @pi_idprj = @column_new_value$idprj, @pi_ggrdc = @column_new_value$ggrdc, @pi_acode = @column_new_value$acode, @pi_gcode = @column_new_value$gcode, @pi_plang = @column_new_value$plang, @pi_enddt = @column_new_value$enddt

        END
        /* Oracle-trigger dbo.TRG_ITDB200_AU implementation: end */
--------------------------------------------------------------------------------------------------------

		FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$mcode, @column_new_value$firma, @column_new_value$ordop, @column_new_value$khtnr, @column_new_value$haend, @column_new_value$absts, @column_new_value$beeus, @column_new_value$erfdz, @column_new_value$fredz, @column_new_value$besdz, @column_new_value$abgdz, @column_new_value$stodz, @column_new_value$anfstot,@column_new_value$hznum, @column_new_value$recid, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB201_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB201_AD]
GO

CREATE TRIGGER trg_ITDB201_AD ON dbo.ITDB201
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB201_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = 'CO', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$2, @PI_firma = 'x', @PI_bkonr = 'x', @PI_konra = 'x'
        END
        /* Oracle-trigger dbo.TRG_ITDB201_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB201_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB201_AIU]
GO

CREATE TRIGGER trg_ITDB201_AIU ON dbo.ITDB201
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_new_value$1 varchar(3),
        @column_new_value$dealid varchar(15),
        @column_new_value$2 varchar(12),
        @column_new_value$3 datetime,
        @column_new_value$4 varchar(3),
        @column_new_value$unwert numeric(15, 2),
        @column_new_value$unkurs numeric(15, 6),
        @column_new_value$7 varchar(35),
        @column_new_value$8 varchar(15),
        @column_new_value$idsze varchar(15),
        @column_new_value$bterm datetime,
        @column_new_value$gulta datetime,
		@buysell varchar(1),
		@reihe numeric(5)


      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, DEALID, REIHE, ORDNR, VALUTA, UNWCODE, UNWERT, UNKURS, KTEXT, RECID, IDSZE, BTERM, GULTA FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$dealid,  @reihe, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$unwert, @column_new_value$unkurs, @column_new_value$7, @column_new_value$8, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$gulta

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$1 = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				recid = @column_new_value$8
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB201_AIU implementation: begin */
        BEGIN

          DECLARE
            @co_state varchar(9),
            @op varchar(1),
			@rec200$MCODE varchar(3),
			@rec200$FIRMA varchar(12),
			@rec200$ORDOP varchar(10),
			@rec200$KHTNR varchar(13),
			@rec200$HAEND varchar(35),
			@rec200$ABSTS datetime,
			@rec200$BEEUS varchar(10),
			@rec200$ERFTIME datetime,
			@rec200$KONTIME datetime,
			@rec200$BESTIME datetime,
			@rec200$ABGTIME datetime,
			@rec200$STOTIME datetime,
			@rec200$ANFSTOT datetime,
			@rec200$HZNUM varchar(10),
			@rec200$RECID varchar(15),
			@rec200$IDPRJ varchar(15),
			@rec200$GGRDC varchar(6),
			@rec200$ACODE varchar(6),
			@rec200$GCODE varchar(10),
			@rec200$PLANG varchar(1),
			@rec200$BEETIME datetime,
			@co_endcd varchar(1),
			@lzvon datetime


          IF ((@column_new_value$8 LIKE ' %') OR
                          (ISNULL((@column_new_value$8 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          EXEC dbo.sp_PKG_ITS_TREASURY_get_cohead @pi_mcode = @column_new_value$1, @pi_recid = @column_new_value$dealid,
												@MCODE  = @rec200$MCODE OUTPUT,
												@FIRMA = @rec200$FIRMA OUTPUT,
												@ORDOP = @rec200$ORDOP OUTPUT,
												@KHTNR = @rec200$KHTNR OUTPUT,
												@HAEND = @rec200$HAEND OUTPUT,
												@ABSTS = @rec200$ABSTS OUTPUT,
												@BEEUS = @rec200$BEEUS OUTPUT,
												@ERFDZ = @rec200$ERFTIME OUTPUT,
												@FREDZ = @rec200$KONTIME OUTPUT,
												@BESDZ = @rec200$BESTIME OUTPUT,
												@ABGDZ = @rec200$ABGTIME OUTPUT,
												@STODZ = @rec200$STOTIME OUTPUT,
												@anfstot =@rec200$ANFSTOT OUTPUT,
												@HZNUM = @rec200$HZNUM OUTPUT,
												@RECID = @rec200$RECID OUTPUT,
												@IDPRJ = @rec200$IDPRJ OUTPUT,
												@GGRDC = @rec200$GGRDC OUTPUT,
												@ACODE = @rec200$ACODE OUTPUT,
												@GCODE = @rec200$GCODE OUTPUT,
												@PLANG = @rec200$PLANG OUTPUT,
												@ENDDT = @rec200$BEETIME OUTPUT


		  SET @co_endcd = 'Y'
		  IF (@rec200$beeus = '          ')
			  SET @co_endcd = 'N'

          SET @co_state = dbo.fn_PKG_ITS_TREASURY_get_state(@co_endcd, @rec200$STOTIME, @rec200$ANFSTOT, @rec200$ABGTIME, @rec200$BESTIME, @rec200$KONTIME, @rec200$ERFTIME)

          IF (ISNULL((@column_old_value$1 + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'
		  IF (@column_new_value$gulta > '1753-01-02')
			SET @lzvon = @column_new_value$gulta
		  ELSE
			SET @lzvon = @rec200$ABSTS

		  SET @buysell = (SELECT x.gaic2 FROM itdb918d x WHERE x.mcode = @rec200$MCODE
						 AND x.gacod = @rec200$RECID AND x.reihe=@reihe)

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @pi_mode = @op, @pi_modul = 'CO', @pi_mcode = @rec200$MCODE, @pi_recid = @column_new_value$8, @pi_firma = @rec200$FIRMA, @pi_bkonr = @rec200$ORDOP, @pi_konra = @column_new_value$2, @pi_khtnr = @rec200$KHTNR, @pi_abdat = @rec200$ABSTS, @pi_lzvon = @lzvon, @pi_lzbis = @column_new_value$3, @pi_wcod1 = @column_new_value$4, @pi_betr1 = @column_new_value$unwert, /*@pi_wcod2 = @column_new_value$12, @pi_betr2 = @column_new_value$btrw2,*/ @pi_kurs = @column_new_value$unkurs, /*@pi_getyp = @rec101$GACOD, */ @pi_ggart = @buysell, @pi_haend = @rec200$HAEND, @pi_hznum = @rec200$HZNUM, @pi_state = @co_state, @pi_kutxt = @column_new_value$7, @pi_idsze = @column_new_value$idsze, @pi_bterm = @column_new_value$bterm, @pi_idprj = @rec200$IDPRJ, @pi_ggrdc = @rec200$GGRDC, @pi_acode = @rec200$ACODE, @pi_gcode = @rec200$GCODE, @pi_plang = @rec200$PLANG, @pi_enddt = @rec200$BEETIME, @pi_total = @column_new_value$unwert

        END
        /* Oracle-trigger dbo.TRG_ITDB201_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

		FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$dealid,  @reihe, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$unwert, @column_new_value$unkurs, @column_new_value$7, @column_new_value$8, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$gulta
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB301_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB301_AD]
GO

CREATE TRIGGER trg_ITDB301_AD ON ITDB301
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$124 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, GMNUF, GMNUM, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$124

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB301_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = 'GM', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$124, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$3, @PI_konra = @column_old_value$4
        END
        /* Oracle-trigger dbo.TRG_ITDB301_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$124
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB301_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB301_AIU]
GO

CREATE TRIGGER trg_ITDB301_AIU ON dbo.ITDB301
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_new_value$1 varchar(12),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$10 varchar(13),
        @column_new_value$12 varchar(10),
        @column_new_value$13 varchar(1),
        @column_new_value$14 varchar(3),
        @column_new_value$nomin numeric(15, 2),
        @column_new_value$zintz numeric(16, 7),
        @column_new_value$22 datetime,
        @column_new_value$23 datetime,
        @column_new_value$36 varchar(35),
        @column_new_value$43 varchar(35),
        @column_new_value$63 varchar(1),
        @column_new_value$67 varchar(10),
        @column_new_value$68 datetime,
        @column_new_value$70 datetime,
        @column_new_value$72 datetime,
        @column_new_value$74 datetime,
        @column_new_value$76 datetime,
        @column_new_value$78 datetime,
        @column_new_value$marg1 numeric(16, 7),
        @column_new_value$marg2 numeric(16, 7),
        @column_new_value$124 varchar(15),
        @column_new_value$idsze varchar(15),
        @column_new_value$bterm datetime,
        @column_new_value$idprj varchar(15),
		@column_new_value$ggrdc varchar(6),
		@column_new_value$acode varchar(6),
		@column_new_value$gcode varchar(10),
		@column_new_value$plang varchar(1),
		@column_new_value$enddt datetime,
		@column_new_value$astoz datetime

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, GMNUF, GMNUM, KHTNR, GGART, GARTG, WCOD1, NOMIN, ZINTZ, GULTA, GULTB, KTEXT, HAEND, ENDCD, HZNUM, ABSTS, ERFDZ, FREDZ, BESDZ, ABGDZ, STODZ, MARG1, MARG2, RECID, IDSZE, BTERM, IDPRJ, GGRDC, ACODE, GCODE, PLANG, ENDDT,ASTOZ FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$10, @column_new_value$12, @column_new_value$13, @column_new_value$14, @column_new_value$nomin, @column_new_value$zintz, @column_new_value$22, @column_new_value$23, @column_new_value$36, @column_new_value$43, @column_new_value$63, @column_new_value$67, @column_new_value$68, @column_new_value$70, @column_new_value$72, @column_new_value$74, @column_new_value$76, @column_new_value$78, @column_new_value$marg1, @column_new_value$marg2, @column_new_value$124, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$astoz

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$1 = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				recid = @column_new_value$124
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB301_AIU implementation: begin */
        BEGIN

          DECLARE
            @gm_state varchar(9),
            @op varchar(1)

          IF ((@column_new_value$124 LIKE ' %') OR
                          (ISNULL((@column_new_value$124 + '.'), '.') = '.'))
			BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          SET @gm_state = dbo.fn_PKG_ITS_TREASURY_get_state(@column_new_value$63, @column_new_value$78,@column_new_value$astoz, @column_new_value$76, @column_new_value$74, @column_new_value$72, @column_new_value$70)

          IF (ISNULL((@column_old_value$1 + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = @op, @PI_modul = 'GM', @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$124, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_khtnr = @column_new_value$10, @PI_abdat = @column_new_value$68, @PI_lzvon = @column_new_value$22, @PI_lzbis = @column_new_value$23, @PI_wcod1 = @column_new_value$14, @PI_betr1 = @column_new_value$nomin, @PI_zins1 = @column_new_value$zintz, @PI_mar11 = @column_new_value$marg1, @PI_mar12 = @column_new_value$marg2, @PI_getyp = @column_new_value$12, @PI_ggart = @column_new_value$13, @PI_haend = @column_new_value$43, @PI_hznum = @column_new_value$67, @PI_state = @gm_state, @PI_kutxt = @column_new_value$36, @PI_idsze = @column_new_value$idsze, @PI_bterm = @column_new_value$bterm, @PI_idprj = @column_new_value$idprj, @PI_ggrdc = @column_new_value$ggrdc, @PI_acode = @column_new_value$acode, @PI_gcode = @column_new_value$gcode, @PI_plang = @column_new_value$plang, @PI_enddt = @column_new_value$enddt, @PI_total = @column_new_value$nomin

        END
        /* Oracle-trigger dbo.TRG_ITDB301_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$10, @column_new_value$12, @column_new_value$13, @column_new_value$14, @column_new_value$nomin, @column_new_value$zintz, @column_new_value$22, @column_new_value$23, @column_new_value$36, @column_new_value$43, @column_new_value$63, @column_new_value$67, @column_new_value$68, @column_new_value$70, @column_new_value$72, @column_new_value$74, @column_new_value$76, @column_new_value$78, @column_new_value$marg1, @column_new_value$marg2, @column_new_value$124, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$astoz
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB331_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB331_AD]
GO

CREATE TRIGGER trg_ITDB331_AD ON ITDB331
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$6 varchar(2),
        @column_old_value$281 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, KOART, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$6, @column_old_value$281

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB331_AD implementation: begin */
        BEGIN
          DECLARE
            @l_modul varchar(3)
          IF (@column_old_value$6 IN ('00', '01', '02', '10', '11', '12', '13', '20', '21' ))
            BEGIN
              IF (@column_old_value$6 IN ('00', '01', '02', '10', '11' ))
                SET @l_modul = 'KM'
              ELSE IF (@column_old_value$6 = '12')
		        SET @l_modul = 'KRL'
              ELSE IF (@column_old_value$6 = '13')
				SET @l_modul = 'LIM'
			  ELSE
                SET @l_modul = 'LM'
              EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = @l_modul, @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$281, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$3, @PI_konra = @column_old_value$4
            END
        END
        /* Oracle-trigger dbo.TRG_ITDB331_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$6, @column_old_value$281
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB331_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB331_AIU]
GO

CREATE TRIGGER trg_ITDB331_AIU ON ITDB331
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 varchar(1),
        @column_new_value$6 varchar(2),
        @column_new_value$7 varchar(10),
        @column_new_value$8 varchar(35),
        @column_new_value$9 datetime,
        @column_new_value$10 varchar(13),
        @column_new_value$20 varchar(50),
        @column_new_value$23 datetime,
        @column_new_value$24 datetime,
        @column_new_value$56 varchar(3),
        @column_new_value$kobkw numeric(15, 2),
        @column_new_value$119 varchar(1),
        @column_new_value$121 datetime,
        @column_new_value$125 datetime,
        @column_new_value$127 datetime,
        @column_new_value$129 datetime,
        @column_new_value$131 datetime,
        @column_new_value$281 varchar(15),
		@column_new_value$idsze varchar(15),
        @column_new_value$bterm datetime,
        @column_new_value$idprj varchar(15),
		@column_new_value$ggrdc varchar(6),
		@column_new_value$acode varchar(6),
		@column_new_value$gcode varchar(10),
		@column_new_value$plang varchar(1),
		@column_new_value$enddt datetime,
		@column_new_value$koart varchar(2),
		@column_new_value$totalcosts numeric(15, 2),
		@column_new_value$astoz datetime
    IF(UPDATE(MCODE) or UPDATE(FIRMA) or UPDATE(BKONR) or UPDATE(KONRA) or UPDATE(AKTPA) or UPDATE(KOART) or UPDATE(KOTYP) or UPDATE(ZNAME) or UPDATE(ABDAT) or
        UPDATE(KHTNR) or UPDATE(KUTXT) or UPDATE(GULTA) or UPDATE(GULTB) or UPDATE(WCKON) or UPDATE(KOBKW) or UPDATE(ENDCD) or UPDATE(ANLTS) or UPDATE(FREDZ) or
        UPDATE(BSTTS) or UPDATE(ABGDZ) or UPDATE(STODZ) or UPDATE(RECID) or UPDATE(IDSZE) or UPDATE(BTERM) or UPDATE(IDPRJ) or UPDATE(GGRDC) or UPDATE(ACODE) or
        UPDATE(GCODE) or UPDATE(PLANG) or UPDATE(ENDDT) or UPDATE(KOART) or UPDATE(TOTALCOSTS) or UPDATE(ASTOZ))
    BEGIN

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, AKTPA, KOART, KOTYP, ZNAME, ABDAT, KHTNR, KUTXT, GULTA, GULTB, WCKON, KOBKW, ENDCD, ANLTS, FREDZ, BSTTS, ABGDZ, STODZ, RECID, IDSZE, BTERM, IDPRJ, GGRDC, ACODE, GCODE, PLANG, ENDDT, KOART, TOTALCOSTS, ASTOZ FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$9, @column_new_value$10, @column_new_value$20, @column_new_value$23, @column_new_value$24, @column_new_value$56, @column_new_value$kobkw, @column_new_value$119, @column_new_value$121, @column_new_value$125, @column_new_value$127, @column_new_value$129, @column_new_value$131, @column_new_value$281, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$koart, @column_new_value$totalcosts, @column_new_value$astoz

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$1 = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				recid = @column_new_value$281
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB331_AIU implementation: begin */
        BEGIN

          DECLARE
            @km_state varchar(9),
            @op varchar(1),
            @l_modul varchar(3)

          IF ((@column_new_value$281 LIKE ' %') OR
                          (ISNULL((@column_new_value$281 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          IF (@column_new_value$6 IN ('00', '01', '02', '10', '11', '12', '13', '20', '21' ))
            BEGIN

              SET @km_state = dbo.fn_PKG_ITS_TREASURY_get_state(@column_new_value$119, @column_new_value$131, @column_new_value$astoz, @column_new_value$129, @column_new_value$127, @column_new_value$125, @column_new_value$121)

              IF (ISNULL((@column_old_value$1 + '.'), '.') = '.')
                SET @op = 'I'
              ELSE
                SET @op = 'U'

              IF (@column_new_value$6 IN ('00', '01', '02', '10', '11' ))
                SET @l_modul = 'KM'
			  ELSE IF (@column_new_value$6 = '12')
		        SET @l_modul = 'KRL'
			  ELSE IF (@column_new_value$6 = '13')
		        SET @l_modul = 'LIM'
              ELSE
                SET @l_modul = 'LM'

              EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = @op, @PI_modul = @l_modul, @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$281, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_khtnr = @column_new_value$10, @PI_abdat = @column_new_value$9, @PI_lzvon = @column_new_value$23, @PI_lzbis = @column_new_value$24, @PI_wcod1 = @column_new_value$56, @PI_betr1 = @column_new_value$kobkw, @PI_getyp = @column_new_value$7, @PI_ggart = @column_new_value$5, @PI_haend = @column_new_value$8, @PI_state = @km_state, @PI_kutxt = @column_new_value$20, @PI_idsze = @column_new_value$idsze, @PI_bterm = @column_new_value$bterm, @PI_idprj = @column_new_value$idprj, @PI_ggrdc = @column_new_value$ggrdc, @PI_acode = @column_new_value$acode, @PI_gcode = @column_new_value$gcode, @PI_plang = @column_new_value$plang, @PI_enddt = @column_new_value$enddt, @PI_koart = @column_new_value$koart, @PI_total = @column_new_value$totalcosts

            END

        END
        /* Oracle-trigger dbo.TRG_ITDB331_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$9, @column_new_value$10, @column_new_value$20, @column_new_value$23, @column_new_value$24, @column_new_value$56, @column_new_value$kobkw, @column_new_value$119, @column_new_value$121, @column_new_value$125, @column_new_value$127, @column_new_value$129, @column_new_value$131, @column_new_value$281, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$koart, @column_new_value$totalcosts, @column_new_value$astoz
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor
  END
      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB332_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB332_AD]
GO

CREATE TRIGGER trg_ITDB332_AD ON ITDB332
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$230 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$230

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB332_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = 'ZM', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$230, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$3, @PI_konra = @column_old_value$4
        END
        /* Oracle-trigger dbo.TRG_ITDB332_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$230
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB332_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB332_AIU]
GO

CREATE TRIGGER trg_ITDB332_AIU ON dbo.ITDB332
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 varchar(1),
        @column_new_value$6 varchar(15),
        @column_new_value$7 varchar(35),
        @column_new_value$8 datetime,
        @column_new_value$9 varchar(13),
        @column_new_value$20 varchar(50),
        @column_new_value$25 datetime,
        @column_new_value$26 datetime,
        @column_new_value$kkwbw numeric(19, 10),
        @column_new_value$43 varchar(3),
        @column_new_value$kbkw1 numeric(15, 2),
        @column_new_value$azis1 numeric(16, 7),
        @column_new_value$marr1 numeric(16, 7),
        @column_new_value$76 varchar(3),
        @column_new_value$kbkw2 numeric(15, 2),
        @column_new_value$azis2 numeric(16, 7),
        @column_new_value$marr2 numeric(16, 7),
        @column_new_value$124 datetime,
        @column_new_value$128 datetime,
        @column_new_value$132 datetime,
        @column_new_value$134 datetime,
        @column_new_value$138 varchar(1),
        @column_new_value$139 datetime,
        @column_new_value$mar11 numeric(16, 7),
        @column_new_value$mar22 numeric(16, 7),
        @column_new_value$230 varchar(15),
        @column_new_value$idsze varchar(15),
        @column_new_value$bterm datetime,
        @column_new_value$idprj varchar(15),
		@column_new_value$ggrdc varchar(6),
		@column_new_value$acode varchar(6),
		@column_new_value$gcode varchar(10),
		@column_new_value$plang varchar(1),
		@column_new_value$enddt datetime,
		@column_new_value$astoz datetime


      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, KAUVK, ZGARTID, ZNAME, ABDAT, KHTNR, KUTXT, GULTA, GULTB, KKWBW, WCKO1, KBKW1, AZIS1, MARR1, WCKO2, KBKW2, AZIS2, MARR2, ANLTS, FREDZ, BSTTS, ABGDZ, ENDCD, STODZ, MAR11, MAR22, RECID, IDSZE, BTERM, IDPRJ, GGRDC, ACODE, GCODE, PLANG, ENDTS, ASTOZ FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$9, @column_new_value$20, @column_new_value$25, @column_new_value$26, @column_new_value$kkwbw, @column_new_value$43, @column_new_value$kbkw1, @column_new_value$azis1, @column_new_value$marr1, @column_new_value$76, @column_new_value$kbkw2, @column_new_value$azis2, @column_new_value$marr2, @column_new_value$124, @column_new_value$128, @column_new_value$132, @column_new_value$134, @column_new_value$138, @column_new_value$139, @column_new_value$mar11, @column_new_value$mar22, @column_new_value$230, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$astoz

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$1 = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				recid = @column_new_value$230
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB332_AIU implementation: begin */
        BEGIN

          DECLARE
            @km_state varchar(9),
            @op varchar(1)

          IF ((@column_new_value$230 LIKE ' %') OR
                          (ISNULL((@column_new_value$230 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          SET @km_state = dbo.fn_PKG_ITS_TREASURY_get_state(@column_new_value$138, @column_new_value$139, @column_new_value$astoz, @column_new_value$134, @column_new_value$132, @column_new_value$128, @column_new_value$124)

          IF (ISNULL((@column_old_value$1 + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = @op, @PI_modul = 'ZM', @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$230, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_khtnr = @column_new_value$9, @PI_abdat = @column_new_value$8, @PI_lzvon = @column_new_value$25, @PI_lzbis = @column_new_value$26, @PI_wcod1 = @column_new_value$43, @PI_betr1 = @column_new_value$kbkw1, @PI_wcod2 = @column_new_value$76, @PI_betr2 = @column_new_value$kbkw2, @PI_zins1 = @column_new_value$azis1, @PI_mar11 = @column_new_value$marr1, @PI_mar12 = @column_new_value$mar11, @PI_zins2 = @column_new_value$azis2, @PI_mar21 = @column_new_value$marr2, @PI_mar22 = @column_new_value$mar22, @PI_kurs = @column_new_value$kkwbw, @PI_getyp = @column_new_value$6, @PI_ggart = @column_new_value$5, @PI_haend = @column_new_value$7, @PI_state = @km_state, @PI_kutxt = @column_new_value$20, @PI_idsze = @column_new_value$idsze, @PI_bterm = @column_new_value$bterm, @PI_idprj = @column_new_value$idprj, @PI_ggrdc = @column_new_value$ggrdc, @PI_acode = @column_new_value$acode, @PI_gcode = @column_new_value$gcode, @PI_plang = @column_new_value$plang, @PI_enddt = @column_new_value$enddt, @PI_total = @column_new_value$kbkw1

        END
        /* Oracle-trigger dbo.TRG_ITDB332_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$9, @column_new_value$20, @column_new_value$25, @column_new_value$26, @column_new_value$kkwbw, @column_new_value$43, @column_new_value$kbkw1, @column_new_value$azis1, @column_new_value$marr1, @column_new_value$76, @column_new_value$kbkw2, @column_new_value$azis2, @column_new_value$marr2, @column_new_value$124, @column_new_value$128, @column_new_value$132, @column_new_value$134, @column_new_value$138, @column_new_value$139, @column_new_value$mar11, @column_new_value$mar22, @column_new_value$230, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$astoz
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB334_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB334_AD]
GO

CREATE TRIGGER trg_ITDB334_AD ON dbo.ITDB334
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$84 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, KONRA, BKONR, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$84

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB334_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = 'DP', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$84, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$4, @PI_konra = @column_old_value$3
        END
        /* Oracle-trigger dbo.TRG_ITDB334_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$84
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB334_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB334_AIU]
GO

CREATE TRIGGER trg_ITDB334_AIU ON dbo.ITDB334
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 varchar(13),
        @column_new_value$8 varchar(2),
        @column_new_value$9 varchar(3),
        @column_new_value$ldepo numeric(15, 2),
        @column_new_value$22 varchar(35),
        @column_new_value$23 datetime,
        @column_new_value$24 datetime,
        @column_new_value$36 varchar(50),
        @column_new_value$37 datetime,
        @column_new_value$71 varchar(1),
        @column_new_value$72 datetime,
        @column_new_value$79 datetime,
        @column_new_value$84 varchar(15),
        @column_new_value$idprj varchar(15),
		@column_new_value$ggrdc varchar(6),
		@column_new_value$acode varchar(6),
		@column_new_value$gcode varchar(10),
		@column_new_value$plang varchar(1),
		@column_new_value$enddt datetime,
		@column_new_value$koart varchar(2)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, KONRA, BKONR, KHTNR, KOART, WCKON, LDEPO, ZNAME, GULTA, GULTB, KUTXT, ABDAT, ENDCD, ANLTS, STODZ, RECID, IDPRJ, GGRDC, ACODE, GCODE, ' ', ENDDT, KOART FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$8, @column_new_value$9, @column_new_value$ldepo, @column_new_value$22, @column_new_value$23, @column_new_value$24, @column_new_value$36, @column_new_value$37, @column_new_value$71, @column_new_value$72, @column_new_value$79, @column_new_value$84, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$koart

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$1 = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				recid = @column_new_value$84
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB334_AIU implementation: begin */
        BEGIN

          DECLARE
            @dp_state varchar(9),
            @op varchar(1),
            @modul varchar(3)

          IF ((@column_new_value$84 LIKE ' %') OR
                          (ISNULL((@column_new_value$84 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

            SET @dp_state = dbo.fn_PKG_ITS_TREASURY_get_state(@column_new_value$71, @column_new_value$79, '1970-01-01', '1970-01-01','1970-01-01','1970-01-01', @column_new_value$72)

          IF (ISNULL((@column_old_value$1 + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = @op, @PI_modul = 'DP', @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$84, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$4, @PI_konra = @column_new_value$3, @PI_khtnr = @column_new_value$5, @PI_abdat = @column_new_value$37, @PI_lzvon = @column_new_value$23, @PI_lzbis = @column_new_value$24, @PI_wcod1 = @column_new_value$9, @PI_betr1 = @column_new_value$ldepo, @PI_getyp = @column_new_value$8, @PI_ggart = '1', @PI_haend = @column_new_value$22, @PI_state = @dp_state, @PI_kutxt = @column_new_value$36, @PI_idprj = @column_new_value$idprj, @PI_ggrdc = @column_new_value$ggrdc, @PI_acode = @column_new_value$acode, @PI_gcode = @column_new_value$gcode, @PI_plang = @column_new_value$plang, @PI_enddt = @column_new_value$enddt, @PI_koart = @column_new_value$koart, @PI_total = @column_new_value$ldepo

        END
        /* Oracle-trigger dbo.TRG_ITDB334_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$8, @column_new_value$9, @column_new_value$ldepo, @column_new_value$22, @column_new_value$23, @column_new_value$24, @column_new_value$36, @column_new_value$37, @column_new_value$71, @column_new_value$72, @column_new_value$79, @column_new_value$84, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$enddt, @column_new_value$koart
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB335_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB335_AD]
GO

CREATE TRIGGER trg_ITDB335_AD ON dbo.ITDB335
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$160 varchar(1),
        @column_old_value$186 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, KONRA, BKONR, EMISS, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$160, @column_old_value$186

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB335_AD implementation: begin */
        BEGIN

          DECLARE
            @modul varchar(3)

          IF (@column_old_value$160 = 'Y')
            SET @modul = 'WPE'
          ELSE
            SET @modul = 'WP'

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = @modul, @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$186, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$4, @PI_konra = @column_old_value$3

        END
        /* Oracle-trigger dbo.TRG_ITDB335_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$160, @column_old_value$186
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB335_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB335_AIU]
GO

CREATE TRIGGER trg_ITDB335_AIU ON dbo.ITDB335
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 varchar(13),
        @column_new_value$6 varchar(12),
        @column_new_value$10 varchar(1),
        @column_new_value$12 varchar(35),
        @column_new_value$13 datetime,
        @column_new_value$21 varchar(50),
        @column_new_value$24 datetime,
        @column_new_value$25 datetime,
        @column_new_value$28 varchar(3),
        @column_new_value$kwert numeric(15, 2),
        @column_new_value$120 varchar(1),
        @column_new_value$122 datetime,
        @column_new_value$126 datetime,
        @column_new_value$128 datetime,
        @column_new_value$144 datetime,
        @column_new_value$146 datetime,
        @column_new_value$160 varchar(1),
        @column_new_value$186 varchar(15),
        @column_new_value$idsze varchar(15),
        @column_new_value$bterm datetime,
        @column_new_value$idprj varchar(15),
		@column_new_value$ggrdc varchar(6),
		@column_new_value$acode varchar(6),
		@column_new_value$gcode varchar(10),
		@column_new_value$plang varchar(1),
		@column_new_value$abskw numeric(15, 2),
		@betrl numeric(15,2),
		@column_new_value$enddt datetime,
		@column_new_value$koart varchar(2),
		@column_new_value$totalcosts numeric(15, 2),
		@kwert numeric(15,2),
		@column_new_value$astoz datetime



      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, KONRA, BKONR, KHTNR, WPGRP, AKTPA, ZNAME, ABDAT, KUTXT, GULTA, GULTB, WCKON, KWERT, ENDCD, ANLTS, BSTTS, STODZ, FREDZ, ABGDZ, EMISS, RECID, IDSZE, BTERM, IDPRJ, GGRDC, ACODE, GCODE, PLANG, ABSKW, ENDDT, KOART, TOTALCOSTS, ASTOZ FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$10, @column_new_value$12, @column_new_value$13, @column_new_value$21, @column_new_value$24, @column_new_value$25, @column_new_value$28, @column_new_value$kwert, @column_new_value$120, @column_new_value$122, @column_new_value$126, @column_new_value$128, @column_new_value$144, @column_new_value$146, @column_new_value$160, @column_new_value$186, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$abskw, @column_new_value$enddt, @column_new_value$koart, @column_new_value$totalcosts, @column_new_value$astoz

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_value$1 = MCODE
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				recid = @column_new_value$186
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB335_AIU implementation: begin */
        BEGIN

          DECLARE
            @wp_state varchar(9),
            @op varchar(1),
            @modul varchar(3)

          IF ((@column_new_value$186 LIKE ' %') OR
                          (ISNULL((@column_new_value$186 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          SET @wp_state = dbo.fn_PKG_ITS_TREASURY_get_state(@column_new_value$120, @column_new_value$128, @column_new_value$astoz, @column_new_value$146, @column_new_value$126, @column_new_value$144, @column_new_value$122)

          IF (ISNULL((@column_old_value$1 + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'

          IF (@column_new_value$160 = 'Y')
          BEGIN
            SET @modul = 'WPE'
            SET @betrl = @column_new_value$abskw
			SET @kwert = 0.0
          END
          ELSE BEGIN
            SET @modul = 'WP'
            SET @betrl = @column_new_value$kwert
			SET @kwert = @column_new_value$kwert
          END;

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = @op, @PI_modul = @modul, @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$186, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$4, @PI_konra = @column_new_value$3, @PI_khtnr = @column_new_value$5, @PI_abdat = @column_new_value$13, @PI_lzvon = @column_new_value$24, @PI_lzbis = @column_new_value$25, @PI_wcod1 = @column_new_value$28, @PI_betr1 = @betrl, @PI_getyp = @column_new_value$6, @PI_ggart = @column_new_value$10, @PI_haend = @column_new_value$12, @PI_state = @wp_state, @PI_kutxt = @column_new_value$21, @PI_idsze = @column_new_value$idsze, @PI_bterm = @column_new_value$bterm, @PI_idprj = @column_new_value$idprj, @PI_ggrdc = @column_new_value$ggrdc, @PI_acode = @column_new_value$acode, @PI_gcode = @column_new_value$gcode, @PI_plang = @column_new_value$plang, @PI_enddt = @column_new_value$enddt, @PI_koart = @column_new_value$koart, @PI_total = @column_new_value$totalcosts

        END
        /* Oracle-trigger dbo.TRG_ITDB335_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$10, @column_new_value$12, @column_new_value$13, @column_new_value$21, @column_new_value$24, @column_new_value$25, @column_new_value$28, @column_new_value$kwert, @column_new_value$120, @column_new_value$122, @column_new_value$126, @column_new_value$128, @column_new_value$144, @column_new_value$146, @column_new_value$160, @column_new_value$186, @column_new_value$idsze, @column_new_value$bterm, @column_new_value$idprj, @column_new_value$ggrdc, @column_new_value$acode, @column_new_value$gcode, @column_new_value$plang, @column_new_value$abskw, @column_new_value$enddt, @column_new_value$koart, @column_new_value$totalcosts, @column_new_value$astoz
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB337_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB337_AD]
GO

CREATE TRIGGER trg_ITDB337_AD ON dbo.ITDB337
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$5 datetime,
        @column_old_value$6 numeric(3, 0),
        @column_old_value$7 varchar(4),
        @column_old_value$14 varchar(2),
        @column_old_value$48 varchar(15)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, TERMI, LDNUM, TERMC, KOART, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$5, @column_old_value$6, @column_old_value$7, @column_old_value$14, @column_old_value$48

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB337_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_cashflow @PI_mode = 'D', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$48, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$3, @PI_konra = @column_old_value$4, @PI_termi = @column_old_value$5, @PI_termc = @column_old_value$7, @PI_ldnum = @column_old_value$6, @PI_koart = @column_old_value$14
        END
        /* Oracle-trigger dbo.TRG_ITDB337_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$5, @column_old_value$6, @column_old_value$7, @column_old_value$14, @column_old_value$48
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB337_AI]'))
	DROP TRIGGER [dbo].[trg_ITDB337_AI]
GO

CREATE TRIGGER trg_ITDB337_AI ON dbo.ITDB337
    AFTER INSERT
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 datetime,
        @column_new_value$ldnum numeric(3, 0),
        @column_new_value$7 varchar(4),
        @column_new_value$8 datetime,
        @column_new_value$11 varchar(3),
        @column_new_value$12 varchar(35),
        @column_new_value$14 varchar(2),
        @column_new_value$15 varchar(1),
        @column_new_value$kobkw numeric(15, 2),
        @column_new_value$kobbw numeric(15, 2),
        @column_new_value$kobew numeric(15, 2),
        @column_new_value$kkwbw numeric(19, 10),
        @column_new_value$22 varchar(3),
        @column_new_value$23 varchar(50),
        @column_new_value$chkdp numeric(9, 0),
        @column_new_value$37 varchar(1),
        @column_new_value$48 varchar(15),
        @column_new_value$49 varchar(1),
		@op varchar(1);

	  SET @op = 'I'

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, TERMI, LDNUM, TERMC, TERM1, WCKON, KONSW, KOART, KZEIA, KOBKW, KOBBW, KOBEW, KKWBW, KUTYP, KUTXT, CHKDP, FLAG1, RECID, DISPO FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$ldnum, @column_new_value$7, @column_new_value$8, @column_new_value$11, @column_new_value$12, @column_new_value$14, @column_new_value$15, @column_new_value$kobkw, @column_new_value$kobbw, @column_new_value$kobew, @column_new_value$kkwbw, @column_new_value$22, @column_new_value$23, @column_new_value$chkdp, @column_new_value$37, @column_new_value$48, @column_new_value$49

      WHILE @@fetch_status = 0
      BEGIN
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB337_AIU implementation: begin */
        BEGIN

          IF ((@column_new_value$48 LIKE ' %') OR
                          (ISNULL((@column_new_value$48 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_cashflow @PI_mode = @op, @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$48, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_termi = @column_new_value$5, @PI_term1 = @column_new_value$8, @PI_termc = @column_new_value$7, @PI_ldnum = @column_new_value$ldnum, @PI_wckon = @column_new_value$11, @PI_konsw = @column_new_value$12, @PI_kobkw = @column_new_value$kobkw, @PI_kobbw = @column_new_value$kobbw, @PI_kobew = @column_new_value$kobew, @PI_kkwbw = @column_new_value$kkwbw, @PI_kutyp = @column_new_value$22, @PI_kutxt = @column_new_value$23, @PI_dispo = @column_new_value$49, @PI_kzeia = @column_new_value$15, @PI_chkdp = @column_new_value$chkdp, @PI_flag1 = @column_new_value$37, @PI_koart = @column_new_value$14

        END
        /* Oracle-trigger dbo.TRG_ITDB337_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$ldnum, @column_new_value$7, @column_new_value$8, @column_new_value$11, @column_new_value$12, @column_new_value$14, @column_new_value$15, @column_new_value$kobkw, @column_new_value$kobbw, @column_new_value$kobew, @column_new_value$kkwbw, @column_new_value$22, @column_new_value$23, @column_new_value$chkdp, @column_new_value$37, @column_new_value$48, @column_new_value$49
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB337_AU]'))
	DROP TRIGGER [dbo].[trg_ITDB337_AU]
GO

CREATE TRIGGER trg_ITDB337_AU ON dbo.ITDB337
    AFTER UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_recid	varchar(15),
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 datetime,
        @column_new_value$6 numeric(3, 0),
        @column_new_value$7 varchar(4),
        @column_new_value$8 datetime,
        @column_new_value$11 varchar(3),
        @column_new_value$12 varchar(35),
        @column_new_value$14 varchar(2),
        @column_new_value$15 varchar(1),
        @column_new_value$16 numeric(15, 2),
        @column_new_value$18 numeric(15, 2),
        @column_new_value$20 numeric(15, 2),
        @column_new_value$21 numeric(19, 10),
        @column_new_value$22 varchar(3),
        @column_new_value$23 varchar(50),
        @column_new_value$36 numeric(9, 0),
        @column_new_value$37 varchar(1),
        @column_new_value$48 varchar(15),
        @column_new_value$49 varchar(1),
		@op varchar(1);

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, TERMI, LDNUM, TERMC, TERM1, WCKON, KONSW, KOART, KZEIA, KOBKW, KOBBW, KOBEW, KKWBW, KUTYP, KUTXT, CHKDP, FLAG1, RECID, DISPO FROM inserted

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$11, @column_new_value$12, @column_new_value$14, @column_new_value$15, @column_new_value$16, @column_new_value$18, @column_new_value$20, @column_new_value$21, @column_new_value$22, @column_new_value$23, @column_new_value$36, @column_new_value$37, @column_new_value$48, @column_new_value$49

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_recid = RECID
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				firma = @column_new_value$2 AND
				bkonr = @column_new_value$3 AND
				konra = @column_new_value$4 AND
				termi = @column_new_value$5 AND
				ldnum = @column_new_value$6 AND
				termc = @column_new_value$7

--------------------------------------------------------------------------------------------------------
        BEGIN

          IF ((@column_new_value$48 LIKE ' %') OR
                          (ISNULL((@column_new_value$48 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          SET @op = 'U'
		  IF UPDATE(recid)
			BEGIN
			  SELECT @column_old_recid = RECID
				  FROM deleted
				  WHERE mcode = @column_new_value$1 AND
						firma = @column_new_value$2 AND
						bkonr = @column_new_value$3 AND
						konra = @column_new_value$4 AND
						termi = @column_new_value$5 AND
						ldnum = @column_new_value$6 AND
						termc = @column_new_value$7

			  EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_cashflow @PI_mode = 'D', @PI_mcode = @column_new_value$1, @PI_recid = @column_old_recid, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_termi = @column_new_value$5, @PI_termc = @column_new_value$7, @PI_ldnum = @column_new_value$6, @PI_koart = @column_new_value$14
    		  SET @op = 'I'
			END

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_cashflow @PI_mode = @op, @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$48, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_termi = @column_new_value$5, @PI_term1 = @column_new_value$8, @PI_termc = @column_new_value$7, @PI_ldnum = @column_new_value$6, @PI_wckon = @column_new_value$11, @PI_konsw = @column_new_value$12, @PI_kobkw = @column_new_value$16, @PI_kobbw = @column_new_value$18, @PI_kobew = @column_new_value$20, @PI_kkwbw = @column_new_value$21, @PI_kutyp = @column_new_value$22, @PI_kutxt = @column_new_value$23, @PI_dispo = @column_new_value$49, @PI_kzeia = @column_new_value$15, @PI_chkdp = @column_new_value$36, @PI_flag1 = @column_new_value$37, @PI_koart = @column_new_value$14

        END
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$11, @column_new_value$12, @column_new_value$14, @column_new_value$15, @column_new_value$16, @column_new_value$18, @column_new_value$20, @column_new_value$21, @column_new_value$22, @column_new_value$23, @column_new_value$36, @column_new_value$37, @column_new_value$48, @column_new_value$49
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB340_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB340_AD]
GO

CREATE TRIGGER trg_ITDB340_AD ON dbo.ITDB340
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$1 varchar(3),
        @column_old_value$2 varchar(12),
        @column_old_value$3 varchar(10),
        @column_old_value$4 varchar(10),
        @column_old_value$5 datetime,
        @column_old_value$6 numeric(3, 0),
        @column_old_value$7 varchar(4),
        @column_old_value$14 varchar(2),
        @column_old_value$48 varchar(15),
        @koart varchar(2);

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, TERMI, LDNUM, TERMC, RECID FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$5, @column_old_value$6, @column_old_value$7, @column_old_value$48

      WHILE @@fetch_status = 0
      BEGIN

        IF (@column_old_value$3 LIKE '%K%')
		  SET @koart = '00'
		IF (@column_old_value$3 LIKE '%Z%')
		  SET @koart = '30'
		IF (@column_old_value$3 LIKE '%D%')
		  SET @koart = '60'
		IF (@column_old_value$3 LIKE '%W%')
		  SET @koart = '61'
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB340_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_bewertung @PI_mode = 'D', @PI_mcode = @column_old_value$1, @PI_recid = @column_old_value$48, @PI_firma = @column_old_value$2, @PI_bkonr = @column_old_value$3, @PI_konra = @column_old_value$4, @PI_koart = @koart
        END
        /* Oracle-trigger dbo.TRG_ITDB340_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$1, @column_old_value$2, @column_old_value$3, @column_old_value$4, @column_old_value$5, @column_old_value$6, @column_old_value$7, @column_old_value$48
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB340_AI]'))
	DROP TRIGGER [dbo].[trg_ITDB340_AI]
GO

CREATE TRIGGER trg_ITDB340_AI ON dbo.ITDB340
    AFTER INSERT
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 datetime,
        @column_new_value$ldnum numeric(3, 0),
        @column_new_value$7 varchar(4),
        @column_new_value$8 datetime,
        @column_new_value$48 varchar(15),
		@op varchar(1),
		@koart varchar(2);

	  SET @op = 'I'

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, TERMI, LDNUM, TERMC, TERM1, RECID FROM inserted where termc='DEB' and (bkonr like '%K%' or bkonr like '%Z%' or bkonr like '%D%' or bkonr like '%W%')

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$ldnum, @column_new_value$7, @column_new_value$8, @column_new_value$48

      WHILE @@fetch_status = 0
      BEGIN
--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB340_AIU implementation: begin */
        BEGIN

          IF (@column_new_value$3 LIKE '%K%')
			SET @koart = '00'
		  IF (@column_new_value$3 LIKE '%Z%')
			SET @koart = '30'
		  IF (@column_new_value$3 LIKE '%D%')
			SET @koart = '60'
		  IF (@column_new_value$3 LIKE '%W%')
			SET @koart = '61'

          IF ((@column_new_value$48 LIKE ' %') OR
                          (ISNULL((@column_new_value$48 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_bewertung @PI_mode = @op, @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$48, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_koart = @koart

        END
        /* Oracle-trigger dbo.TRG_ITDB340_AIU implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$ldnum, @column_new_value$7, @column_new_value$8, @column_new_value$48
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB340_AU]'))
	DROP TRIGGER [dbo].[trg_ITDB340_AU]
GO

CREATE TRIGGER trg_ITDB340_AU ON dbo.ITDB340
    AFTER UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_recid	varchar(15),
        @column_new_value$1 varchar(3),
        @column_new_value$2 varchar(12),
        @column_new_value$3 varchar(10),
        @column_new_value$4 varchar(10),
        @column_new_value$5 datetime,
        @column_new_value$6 numeric(3, 0),
        @column_new_value$7 varchar(4),
        @column_new_value$8 datetime,
        @column_new_value$48 varchar(15),
		@op varchar(1),
        @koart varchar(2);

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, FIRMA, BKONR, KONRA, TERMI, LDNUM, TERMC, TERM1, RECID FROM inserted where termc='DEB' and (bkonr like '%K%' or bkonr like '%Z%' or bkonr like '%D%' or bkonr like '%W%')

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$48

      WHILE @@fetch_status = 0
      BEGIN
        /* synchronize inserted row with deleted row */
        SELECT @column_old_recid = RECID
          FROM deleted
          WHERE mcode = @column_new_value$1 AND
				firma = @column_new_value$2 AND
				bkonr = @column_new_value$3 AND
				konra = @column_new_value$4 AND
				termi = @column_new_value$5 AND
				ldnum = @column_new_value$6 AND
				termc = @column_new_value$7

--------------------------------------------------------------------------------------------------------
        BEGIN

          IF (@column_new_value$3 LIKE '%K%')
			SET @koart = '00'
		  IF (@column_new_value$3 LIKE '%Z%')
			SET @koart = '30'
		  IF (@column_new_value$3 LIKE '%D%')
			SET @koart = '60'
		  IF (@column_new_value$3 LIKE '%W%')
			SET @koart = '61'

          IF ((@column_new_value$48 LIKE ' %') OR (ISNULL((@column_new_value$48 + '.'), '.') = '.'))
            BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          SET @op = 'U'
		  IF UPDATE(recid)
			BEGIN
			  SELECT @column_old_recid = RECID
				  FROM deleted
				  WHERE mcode = @column_new_value$1 AND
						firma = @column_new_value$2 AND
						bkonr = @column_new_value$3 AND
						konra = @column_new_value$4 AND
						termi = @column_new_value$5 AND
						ldnum = @column_new_value$6 AND
						termc = @column_new_value$7

			  EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_bewertung @PI_mode = 'D', @PI_mcode = @column_new_value$1, @PI_recid = @column_old_recid, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_koart = @koart
    		  SET @op = 'I'
			END

          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_bewertung @PI_mode = @op, @PI_mcode = @column_new_value$1, @PI_recid = @column_new_value$48, @PI_firma = @column_new_value$2, @PI_bkonr = @column_new_value$3, @PI_konra = @column_new_value$4, @PI_koart = @koart

        END
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$1, @column_new_value$2, @column_new_value$3, @column_new_value$4, @column_new_value$5, @column_new_value$6, @column_new_value$7, @column_new_value$8, @column_new_value$48
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TRG_ITDB813_BI]'))
	DROP TRIGGER [dbo].[TRG_ITDB813_BI]
GO

CREATE TRIGGER TRG_ITDB813_BI
ON dbo.ITDB813
INSTEAD OF INSERT
AS
BEGIN
SET  NOCOUNT  ON
DECLARE
	@new$MCODE varchar(3),
	@new$MAPMO varchar(20),
	@new$MAPKZ varchar(1),
	@new$MAPF0 varchar(50),
	@new$MAPF1 varchar(100),
	@new$MAPF2 varchar(500),
	@new$KZAKT varchar(1),
	@new$MAPDA varchar(200),
	@new$TXTFD varchar(35),
	@new$STAK0 varchar(1),
	@new$STAK1 varchar(1),
	@new$STAK2 varchar(1),
	@new$SORTX int,
	@new$UPDKZ varchar(3),
	@new$UPDTS datetime,
	@new$UPDUS varchar(10),
	@new$RECID varchar(15),
	@new$HISTID varchar(15),
  @sysinstval varchar(3),@nextval decimal

DECLARE
	ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
	  SELECT
		  MCODE, MAPMO, MAPKZ, MAPF0, MAPF1, MAPF2,
		  KZAKT, MAPDA, TXTFD, STAK0, STAK1, STAK2,
		  SORTX, UPDKZ, UPDTS, UPDUS, RECID, HISTID
	  FROM inserted
OPEN ForEachInsertedRowTriggerCursor
FETCH ForEachInsertedRowTriggerCursor
	INTO
	  @new$MCODE, @new$MAPMO, @new$MAPKZ, @new$MAPF0, @new$MAPF1, @new$MAPF2,
	  @new$KZAKT, @new$MAPDA, @new$TXTFD, @new$STAK0, @new$STAK1, @new$STAK2,
	  @new$SORTX, @new$UPDKZ, @new$UPDTS, @new$UPDUS, @new$RECID, @new$HISTID

WHILE @@fetch_status = 0
	BEGIN
	  /* row-level triggers implementation: begin*/
	  BEGIN
	  BEGIN
			IF (@new$RECID IS NULL OR substring(@new$RECID, 1, 1) = ' ')
				BEGIN

			  SET @sysinstval = (select substring(dbc_sys_inst.ValA,1,3)
				  from dbc_sys_inst where dbc_sys_inst.keya='INST')
			  EXEC sp_Sequence_Nextval 'DBC_SEQ_RECID', @nextval OUTPUT
			  SET @new$RECID = @sysinstval + replicate ('0',12-len(convert(varchar,@nextval))) + convert(varchar,@nextval)
				END
			/* end if;*/
		END
	  END
	  /* row-level triggers implementation: end*/

	  /* DML-operation emulation*/
	  INSERT dbo.ITDB813(
		  MCODE, MAPMO, MAPKZ, MAPF0, MAPF1, MAPF2,
		  KZAKT, MAPDA, TXTFD, STAK0, STAK1, STAK2,
		  SORTX, UPDKZ, UPDTS, UPDUS, RECID, HISTID)
		  VALUES (
			@new$MCODE, @new$MAPMO, @new$MAPKZ, @new$MAPF0, @new$MAPF1, @new$MAPF2,
			@new$KZAKT, @new$MAPDA, @new$TXTFD, @new$STAK0, @new$STAK1, @new$STAK2,
			@new$SORTX, @new$UPDKZ, @new$UPDTS, @new$UPDUS,
			@new$RECID, @new$HISTID)

	  FETCH ForEachInsertedRowTriggerCursor
		  INTO
			@new$MCODE, @new$MAPMO, @new$MAPKZ, @new$MAPF0, @new$MAPF1, @new$MAPF2,
			@new$KZAKT, @new$MAPDA, @new$TXTFD, @new$STAK0, @new$STAK1, @new$STAK2,
			@new$SORTX, @new$UPDKZ, @new$UPDTS, @new$UPDUS, @new$RECID, @new$HISTID
	END

CLOSE ForEachInsertedRowTriggerCursor

DEALLOCATE ForEachInsertedRowTriggerCursor
END
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB925_AD]'))
	DROP TRIGGER [dbo].[trg_ITDB925_AD]
GO

CREATE TRIGGER trg_ITDB925_AD ON ITDB925
    AFTER DELETE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

      /* column variables declaration */
      DECLARE
        @column_old_value$mcode varchar(3),
		@column_old_value$recid varchar(15),
        @column_old_value$firma varchar(12),
        @column_old_value$khtnr varchar(13),
        @column_old_value$dkont varchar(2),
        @column_old_value$tradeid varchar(20),
        @column_old_value$exportst varchar(1)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachDeletedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT MCODE, RECID, FIRMA, KHTNR, DKONT, TRADEID, EXPORTST FROM deleted

      OPEN ForEachDeletedRowTriggerCursor
      FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$mcode, @column_old_value$recid, @column_old_value$firma, @column_old_value$khtnr, @column_old_value$dkont, @column_old_value$tradeid, @column_old_value$exportst

      WHILE @@fetch_status = 0
      BEGIN

--------------------------------------------------------------------------------------------------------
        /* Oracle-trigger dbo.TRG_ITDB925_AD implementation: begin */
        BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = 'D', @PI_modul = 'CM', @PI_mcode = @column_old_value$mcode, @PI_recid = @column_old_value$recid, @PI_firma = @column_old_value$firma, @PI_khtnr = @column_old_value$khtnr, @PI_dkont = @column_old_value$dkont, @PI_bkonr = '          ', @PI_konra = '          '

          IF ((@column_old_value$exportst IN ('S','E')) AND (NOT ISNULL((@column_old_value$tradeid + '.'), '.') = '.') AND (@column_old_value$tradeid NOT LIKE ' %'))
          BEGIN
              INSERT INTO PENDING_TRADE_DEL (mcode,exportType,importId,tradeId) values
                 (@column_old_value$mcode, 'AC', @column_old_value$recid, @column_old_value$tradeid);
          END
        END
        /* Oracle-trigger dbo.TRG_ITDB925_AD implementation: end */
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachDeletedRowTriggerCursor INTO @column_old_value$mcode, @column_old_value$recid, @column_old_value$firma, @column_old_value$khtnr, @column_old_value$dkont, @column_old_value$tradeid, @column_old_value$exportst
      END

      CLOSE ForEachDeletedRowTriggerCursor
      DEALLOCATE ForEachDeletedRowTriggerCursor

      /*  end of trigger implementation */
GO


IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_ITDB925_AIU]'))
	DROP TRIGGER [dbo].[trg_ITDB925_AIU]
GO

CREATE TRIGGER trg_ITDB925_AIU ON dbo.ITDB925
    AFTER INSERT,UPDATE
    AS
      /*  begin of trigger implementation */
      SET NOCOUNT ON

    IF (UPDATE(mcode) OR UPDATE(firma) OR UPDATE(khtnr) OR UPDATE(dkont) OR UPDATE(recid) OR UPDATE(gcode) OR UPDATE(wcod1))
	BEGIN
      /* column variables declaration */
      DECLARE
        @oldmcode varchar(3),
        @column_new_value$mcode varchar(3),
		@column_new_value$recid varchar(15),
		@column_new_value$firma varchar(12),
		@column_new_value$khtnr varchar(13),
		@column_new_value$dkont varchar(2),
		@column_new_value$wcod1 varchar(3),
		@column_new_value$gcode varchar(10),
		@column_new_value$jobnr varchar(12),
		@oldwcod1 varchar(3),
		@oldgcode varchar(10),
        @oldjobnr varchar(12),
        @op varchar(1)

      /* iterate for each for from inserted/updated table(s) */
      DECLARE ForEachInsertedRowTriggerCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
        SELECT i.MCODE, i.RECID, i.FIRMA, i.KHTNR, i.DKONT, i.WCOD1, i.GCODE, i.JOBNR, d.mcode, d.wcod1,d.gcode,d.jobnr
		FROM inserted i	left join deleted d
		ON d.mcode=i.mcode and d.firma=i.firma and d.khtnr=i.khtnr and d.dkont=i.dkont

      OPEN ForEachInsertedRowTriggerCursor
      FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$mcode, @column_new_value$recid, @column_new_value$firma, @column_new_value$khtnr, @column_new_value$dkont,
        @column_new_value$wcod1, @column_new_value$gcode, @column_new_value$jobnr, @oldmcode, @oldwcod1, @oldgcode, @oldjobnr

      WHILE @@fetch_status = 0
      BEGIN

           IF ((@column_new_value$recid LIKE ' %') OR
                          (ISNULL((@column_new_value$recid + '.'), '.') = '.'))
			BEGIN
				RAISERROR ( 'Empty Recid not allowed', 16, 1)
				RETURN
			END

          IF (ISNULL((@oldmcode + '.'), '.') = '.')
            SET @op = 'I'
          ELSE
            SET @op = 'U'

		  IF (@op = 'I' OR
             (@oldjobnr=@column_new_value$jobnr and
		     (@column_new_value$wcod1 <> @oldwcod1 OR
			  @column_new_value$gcode <> @oldgcode))
		  ) BEGIN
          EXEC dbo.sp_PKG_ITS_TREASURY_upd_treasury_head @PI_mode = @op, @PI_modul = 'CM', @PI_mcode = @column_new_value$mcode, @PI_recid = @column_new_value$recid, @PI_firma = @column_new_value$firma, @PI_khtnr = @column_new_value$khtnr, @PI_dkont = @column_new_value$dkont, @PI_bkonr = '          ', @PI_konra = '          ',  @PI_wcod1 = @column_new_value$wcod1, @PI_gcode = @column_new_value$gcode, @PI_plang = ' '
            print @op + ' trhead'
        END
--------------------------------------------------------------------------------------------------------

        FETCH NEXT FROM ForEachInsertedRowTriggerCursor INTO @column_new_value$mcode, @column_new_value$recid, @column_new_value$firma, @column_new_value$khtnr, @column_new_value$dkont,
		@column_new_value$wcod1, @column_new_value$gcode, @column_new_value$jobnr, @oldmcode, @oldwcod1, @oldgcode, @oldjobnr
      END

      CLOSE ForEachInsertedRowTriggerCursor
      DEALLOCATE ForEachInsertedRowTriggerCursor

    END
      /*  end of trigger implementation */
GO

