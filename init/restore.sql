--:SETVAR DB_NAMES --hub,camunda,itgapi,mds,scheduler,ebics,banking,banking_ks,cds,dnc_adapter,dnc,scs,its

SET NOCOUNT ON;

-- Split input db list by a delimiter and get results in a table
DECLARE @DBNamesTable TABLE (Value NVARCHAR(MAX));
DECLARE @Index INT;
DECLARE @Delimiter CHAR(1) = ',';
DECLARE @DBNames varchar(400) = '$(DB_NAMES)'
SET @Index = CHARINDEX(@Delimiter, @DBNames);
WHILE @Index > 0
BEGIN
	INSERT INTO @DBNamesTable (Value) VALUES (TRIM(LEFT(@DBNames, @Index - 1)));
	SET @DBNames = SUBSTRING(@DBNames, @Index + 1, LEN(@DBNames) - @Index);
	SET @Index = CHARINDEX(@Delimiter, @DBNames);
END;
INSERT INTO @DBNamesTable (Value) VALUES (TRIM(@DBNames));

-- Loop through the DB Names in table @DBNamesTable
DECLARE @DBName NVARCHAR(MAX);
DECLARE cur CURSOR FOR
SELECT Value FROM @DBNamesTable;
OPEN cur;
FETCH NEXT FROM cur INTO @DBName;
WHILE @@FETCH_STATUS = 0
    BEGIN
	    -- Get the logical name of data and log file from the back-up
		DECLARE @Table TABLE (LogicalName varchar(128),[PhysicalName] varchar(128), [Type] varchar, [FileGroupName] varchar(128), [Size] varchar(128), 
        [MaxSize] varchar(128), [FileId]varchar(128), [CreateLSN]varchar(128), [DropLSN]varchar(128), [UniqueId]varchar(128), [ReadOnlyLSN]varchar(128), [ReadWriteLSN]varchar(128), 
        [BackupSizeInBytes]varchar(128), [SourceBlockSize]varchar(128), [FileGroupId]varchar(128), [LogGroupGUID]varchar(128), [DifferentialBaseLSN]varchar(128), [DifferentialBaseGUID]varchar(128),
		[IsReadOnly]varchar(128), [IsPresent]varchar(128), [TDEThumbprint]varchar(128), [SnapshotUrl]varchar(128));

		DECLARE @Path varchar(1000)='/var/opt/mssql/backup/' +@DBName+'.bak';
		DECLARE @LogicalNameData varchar(128),@LogicalNameLog varchar(128);
		DECLARE @PhysicalNameData varchar(128),@PhysicalNameLog varchar(128);
		INSERT INTO @Table
		EXEC('
		RESTORE FILELISTONLY 
			FROM DISK=''' +@Path+ '''
			');
			;
		SET @LogicalNameData=(SELECT LogicalName FROM @Table WHERE Type='D');
		SET @LogicalNameLog=(SELECT LogicalName FROM @Table WHERE Type='L');

		SET @PhysicalNameData='/var/opt/mssql/data/'+@DBName+ '.mdf';
		SET @PhysicalNameLog='/var/opt/mssql/data/'+@DBName+'_log.ldf';

		-- Set DB offline
		DECLARE @SETOFFLINESQL nvarchar(200) = N'ALTER DATABASE ' + QUOTENAME(@DBName) + ' SET OFFLINE with rollback immediate;';
		EXEC sp_executesql @SETOFFLINESQL;

		-- Run restore
		restore database @DBName
		from DISK = @Path
		with replace, 
		move @LogicalNameData to @PhysicalNameData,
		move @LogicalNameLog to @PhysicalNameLog;

		-- Create user
		DECLARE @DBUSER varchar(20) = @DBName;
		IF (@DBName = 'scheduler' OR @DBName = 'banking_ks')
			BEGIN
				SET @DBUSER = 'hub';
			END;
		IF (@DBName = 'scs')
			BEGIN
				SET @DBUSER = 'dnc';
			END;

		DECLARE @CREATEUSERSQL nvarchar(200) = N'USE ' + QUOTENAME(@DBName) + ';' +
		'CREATE USER ['+@DBUSER+'] FOR LOGIN [' + @DBUSER + '] WITH DEFAULT_SCHEMA=[dbo];' +
		'EXEC sp_addrolemember N''db_owner'', ' + @DBUSER +';';
		EXEC sp_executesql @CREATEUSERSQL;

		-- Set DB Online
		DECLARE @SETONLINESQL nvarchar(200) = N'ALTER DATABASE ' + QUOTENAME(@DBName) + ' SET ONLINE;';
		EXEC sp_executesql @SETONLINESQL;

		DELETE FROM @Table;
        FETCH NEXT FROM cur INTO @DBName;
    END;
    CLOSE cur;
    DEALLOCATE cur;