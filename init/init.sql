USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'hub')
BEGIN
    CREATE DATABASE [hub]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'hub', FILENAME = N'/var/opt/mssql/data/hub.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'hub_log', FILENAME = N'/var/opt/mssql/data/hub_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [hub] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [hub] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [hub] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [hub] SET MULTI_USER 
END

use master
go
if SUSER_ID('hub') IS NULL
  begin
    CREATE LOGIN [hub] WITH PASSWORD=N'hub', DEFAULT_DATABASE=[hub], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [hub]
GO
if USER_ID('hub') IS NULL
  begin
    CREATE USER [hub] FOR LOGIN [hub] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'hub'
GO

USE [master]
GO

/****** Object:  Database [camunda]    Script Date: 29.11.2023 20:53:04 ******/
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'camunda')
BEGIN
    CREATE DATABASE [camunda]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'camunda', FILENAME = N'/var/opt/mssql/data/camunda.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'camunda_log', FILENAME = N'/var/opt/mssql/data/camunda_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [camunda] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [camunda] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [camunda] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [camunda] SET  MULTI_USER 
END

use master
go
if SUSER_ID('camunda') IS NULL
  begin
    CREATE LOGIN [camunda] WITH PASSWORD=N'camunda', DEFAULT_DATABASE=[camunda], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [camunda]
GO
if USER_ID('camunda') IS NULL
  begin
    CREATE USER [camunda] FOR LOGIN [camunda] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'camunda'
GO

USE [master]
GO

/****** Object:  Database [itgapi]    Script Date: 29.11.2023 20:53:04 ******/
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'itgapi')
BEGIN
    CREATE DATABASE [itgapi]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'itgapi', FILENAME = N'/var/opt/mssql/data/itgapi.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'itgapi_log', FILENAME = N'/var/opt/mssql/data/itgapi_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [itgapi] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [itgapi] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [itgapi] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [itgapi] SET  MULTI_USER 
END

use master
go
if SUSER_ID('itgapi') IS NULL
  begin
    CREATE LOGIN [itgapi] WITH PASSWORD=N'itgapi', DEFAULT_DATABASE=[itgapi], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [itgapi]
GO
if USER_ID('itgapi') IS NULL
  begin
    CREATE USER [itgapi] FOR LOGIN [itgapi] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'itgapi'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'mds')
BEGIN
    CREATE DATABASE [mds]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'mds', FILENAME = N'/var/opt/mssql/data/mds.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'mds_log', FILENAME = N'/var/opt/mssql/data/mds_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [mds] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [mds] SET READ_COMMITTED_SNAPSHOT ON 

    ALTER DATABASE [mds] SET RECOVERY SIMPLE

    ALTER DATABASE [mds] SET  MULTI_USER
    
END

use master
go
if SUSER_ID('mds') IS NULL
  begin
    CREATE LOGIN [mds] WITH PASSWORD=N'mds', DEFAULT_DATABASE=[mds], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [mds]
GO
if USER_ID('mds') IS NULL
  begin
    CREATE USER [mds] FOR LOGIN [mds] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'mds'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'scheduler')
BEGIN
    CREATE DATABASE [scheduler]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'scheduler', FILENAME = N'/var/opt/mssql/data/scheduler.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'scheduler_log', FILENAME = N'/var/opt/mssql/data/scheduler_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [scheduler] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [scheduler] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [scheduler] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [scheduler] SET  MULTI_USER 
END

USE [master]
GO

USE [scheduler]
GO
if USER_ID('hub') IS NULL
  begin
    CREATE USER [hub] FOR LOGIN [hub] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'hub'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'ebics')
BEGIN
    CREATE DATABASE [ebics]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'ebics', FILENAME = N'/var/opt/mssql/data/ebics.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'ebics_log', FILENAME = N'/var/opt/mssql/data/ebics_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [ebics] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [ebics] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [ebics] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [ebics] SET  MULTI_USER
END

use master
go
if SUSER_ID('ebics') IS NULL
  begin
    CREATE LOGIN [ebics] WITH PASSWORD=N'ebics', DEFAULT_DATABASE=[ebics], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [ebics]
GO
if USER_ID('ebics') IS NULL
  begin
    CREATE USER [ebics] FOR LOGIN [ebics] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'ebics'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'banking')
BEGIN
    CREATE DATABASE [banking]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'banking', FILENAME = N'/var/opt/mssql/data/banking.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'banking_log', FILENAME = N'/var/opt/mssql/data/banking_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [banking] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [banking] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [banking] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [banking] SET  MULTI_USER 
END

use master
go
if SUSER_ID('banking') IS NULL
  begin
    CREATE LOGIN [banking] WITH PASSWORD=N'banking', DEFAULT_DATABASE=[banking], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [banking]
GO
if USER_ID('banking') IS NULL
  begin
    CREATE USER [banking] FOR LOGIN [banking] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'banking'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'banking_ks')
BEGIN
    CREATE DATABASE [banking_ks]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'banking_ks', FILENAME = N'/var/opt/mssql/data/banking_ks.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'banking_ks_log', FILENAME = N'/var/opt/mssql/data/banking_ks_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [banking_ks] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [banking_ks] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [banking_ks] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [banking_ks] SET  MULTI_USER 
END

USE [master]
GO

USE [banking_ks]
GO
if USER_ID('hub') IS NULL
  begin
    CREATE USER [hub] FOR LOGIN [hub] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'hub'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'cds')
BEGIN
    CREATE DATABASE [cds]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'cds', FILENAME = N'/var/opt/mssql/data/cds.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'cds_log', FILENAME = N'/var/opt/mssql/data/cds_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [cds] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [cds] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [cds] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [cds] SET  MULTI_USER
    
END

use master
go
if SUSER_ID('cds') IS NULL
  begin
    CREATE LOGIN [cds] WITH PASSWORD=N'cds', DEFAULT_DATABASE=[cds], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [cds]
GO
if USER_ID('cds') IS NULL
  begin
    CREATE USER [cds] FOR LOGIN [cds] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'cds'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'dnc_adapter')
BEGIN
    CREATE DATABASE [dnc_adapter]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'dnc_adapter', FILENAME = N'/var/opt/mssql/data/dnc_adapter.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'dnc_adapter_log', FILENAME = N'/var/opt/mssql/data/dnc_adapter_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [dnc_adapter] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [dnc_adapter] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [dnc_adapter] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [dnc_adapter] SET  MULTI_USER 
END

use master
go
if SUSER_ID('dnc_adapter') IS NULL
  begin
    CREATE LOGIN [dnc_adapter] WITH PASSWORD=N'dnc_adapter', DEFAULT_DATABASE=[dnc_adapter], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [dnc_adapter]
GO
if USER_ID('dnc_adapter') IS NULL
  begin
    CREATE USER [dnc_adapter] FOR LOGIN [dnc_adapter] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'dnc_adapter'
GO

USE [master]
GO

/****** Object:  Database [trustpair]    Script Date: 29.11.2023 20:53:04 ******/
IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'trustpair')
BEGIN
    CREATE DATABASE [trustpair]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'trustpair', FILENAME = N'/var/opt/mssql/data/trustpair.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'trustpair_log', FILENAME = N'/var/opt/mssql/data/trustpair_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [trustpair] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [trustpair] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [trustpair] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [trustpair] SET  MULTI_USER 
END

use master
go
if SUSER_ID('trustpair') IS NULL
  begin
    CREATE LOGIN [trustpair] WITH PASSWORD=N'trustpair', DEFAULT_DATABASE=[trustpair], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [trustpair]
GO
if USER_ID('trustpair') IS NULL
  begin
    CREATE USER [trustpair] FOR LOGIN [trustpair] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'trustpair'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'keycloak')
BEGIN
    CREATE DATABASE [keycloak]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'keycloak', FILENAME = N'/var/opt/mssql/data/keycloak.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'keycloak_log', FILENAME = N'/var/opt/mssql/data/keycloak_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF

    ALTER DATABASE [keycloak] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE [keycloak] SET READ_COMMITTED_SNAPSHOT ON 
    
    ALTER DATABASE [keycloak] SET RECOVERY SIMPLE 
    
    ALTER DATABASE [keycloak] SET  MULTI_USER 
END

use master
go
if SUSER_ID('keycloak') IS NULL
  begin
    CREATE LOGIN [keycloak] WITH PASSWORD=N'keycloak', DEFAULT_DATABASE=[keycloak], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [keycloak]
GO
if USER_ID('keycloak') IS NULL
  begin
    CREATE USER [keycloak] FOR LOGIN [keycloak] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'keycloak'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'dnc')
BEGIN
    CREATE DATABASE [dnc]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'dnc', FILENAME = N'/var/opt/mssql/data/dnc.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'dnc_log', FILENAME = N'/var/opt/mssql/data/dnc_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    COLLATE SQL_Latin1_General_CP1_CS_AS

    ALTER DATABASE [dnc] SET COMPATIBILITY_LEVEL = 100

    IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
    begin
    EXEC [dnc].[dbo].[sp_fulltext_database] @action = 'enable'
    end

    ALTER DATABASE [dnc] SET ANSI_NULL_DEFAULT ON

    ALTER DATABASE [dnc] SET ANSI_NULLS ON 

    ALTER DATABASE [dnc] SET ANSI_PADDING OFF 

    ALTER DATABASE [dnc] SET ANSI_WARNINGS OFF 
  
    ALTER DATABASE [dnc] SET ARITHABORT OFF 
  
    ALTER DATABASE [dnc] SET AUTO_CLOSE OFF   

    ALTER DATABASE [dnc] SET AUTO_CREATE_STATISTICS ON 

    ALTER DATABASE [dnc] SET AUTO_SHRINK OFF 
  
    ALTER DATABASE [dnc] SET AUTO_UPDATE_STATISTICS ON   

    ALTER DATABASE [dnc] SET CURSOR_CLOSE_ON_COMMIT OFF 
  
    ALTER DATABASE [dnc] SET CURSOR_DEFAULT  GLOBAL   

    ALTER DATABASE [dnc] SET CONCAT_NULL_YIELDS_NULL OFF 

    ALTER DATABASE [dnc] SET NUMERIC_ROUNDABORT OFF 
  
    ALTER DATABASE [dnc] SET QUOTED_IDENTIFIER OFF 

    ALTER DATABASE [dnc] SET RECURSIVE_TRIGGERS OFF 

    ALTER DATABASE [dnc] SET  DISABLE_BROKER 

    ALTER DATABASE [dnc] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
  
    ALTER DATABASE [dnc] SET DATE_CORRELATION_OPTIMIZATION OFF 
  
    ALTER DATABASE [dnc] SET TRUSTWORTHY OFF 
  
    ALTER DATABASE [dnc] SET ALLOW_SNAPSHOT_ISOLATION ON  

    ALTER DATABASE dnc SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    ALTER DATABASE [dnc] SET PARAMETERIZATION SIMPLE 
  
    ALTER DATABASE [dnc] SET READ_COMMITTED_SNAPSHOT ON
  
    ALTER DATABASE [dnc] SET READ_COMMITTED_SNAPSHOT OFF   

    ALTER DATABASE [dnc] SET HONOR_BROKER_PRIORITY OFF 

    ALTER DATABASE [dnc] SET  READ_WRITE 

    ALTER DATABASE [dnc] SET RECOVERY SIMPLE 
  
    ALTER DATABASE [dnc] SET  MULTI_USER 
  
    ALTER DATABASE [dnc] SET PAGE_VERIFY CHECKSUM    

    ALTER DATABASE [dnc] SET DB_CHAINING OFF 

    EXEC sys.sp_db_vardecimal_storage_format N'dnc', N'ON'
END

USE [master]
GO

use [dnc]
go
if SUSER_ID('dnc') IS NULL
  begin
    CREATE LOGIN [dnc] WITH PASSWORD=N'dnc', DEFAULT_DATABASE=[dnc], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [dnc]
GO
if USER_ID('dnc') IS NULL
  begin
    CREATE USER [dnc] FOR LOGIN [dnc] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'dnc'
GO

USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'scs')
BEGIN
    CREATE DATABASE [scs]
    CONTAINMENT = NONE
    ON  PRIMARY 
    ( NAME = N'scs', FILENAME = N'/var/opt/mssql/data/scs.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
    LOG ON 
    ( NAME = N'scs_log', FILENAME = N'/var/opt/mssql/data/scs_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
    COLLATE SQL_Latin1_General_CP1_CS_AS

    ALTER DATABASE [scs] SET COMPATIBILITY_LEVEL = 100

    IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
    begin
    EXEC [scs].[dbo].[sp_fulltext_database] @action = 'enable'
    end

    ALTER DATABASE [scs] SET ANSI_NULL_DEFAULT ON 

    ALTER DATABASE [scs] SET ANSI_NULLS ON 

    ALTER DATABASE [scs] SET ANSI_PADDING OFF

    ALTER DATABASE [scs] SET ANSI_WARNINGS OFF

    ALTER DATABASE [scs] SET ARITHABORT OFF

    ALTER DATABASE [scs] SET AUTO_CLOSE OFF 

    ALTER DATABASE [scs] SET AUTO_CREATE_STATISTICS ON 

    ALTER DATABASE [scs] SET AUTO_SHRINK OFF 
  
    ALTER DATABASE [scs] SET AUTO_UPDATE_STATISTICS ON  

    ALTER DATABASE [scs] SET CURSOR_CLOSE_ON_COMMIT OFF 
  
    ALTER DATABASE [scs] SET CURSOR_DEFAULT  GLOBAL   

    ALTER DATABASE [scs] SET CONCAT_NULL_YIELDS_NULL OFF 
    
    ALTER DATABASE [scs] SET NUMERIC_ROUNDABORT OFF 

    ALTER DATABASE [scs] SET QUOTED_IDENTIFIER OFF 

    ALTER DATABASE [scs] SET RECURSIVE_TRIGGERS OFF 
    
    ALTER DATABASE [scs] SET  DISABLE_BROKER 

    ALTER DATABASE [scs] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 

    ALTER DATABASE [scs] SET DATE_CORRELATION_OPTIMIZATION OFF 

    ALTER DATABASE [scs] SET TRUSTWORTHY OFF 

    ALTER DATABASE [scs] SET ALLOW_SNAPSHOT_ISOLATION ON 
    
    ALTER DATABASE scs SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    ALTER DATABASE [scs] SET PARAMETERIZATION SIMPLE 

    ALTER DATABASE [scs] SET READ_COMMITTED_SNAPSHOT ON

    ALTER DATABASE [scs] SET READ_COMMITTED_SNAPSHOT OFF 

    ALTER DATABASE [scs] SET HONOR_BROKER_PRIORITY OFF

    ALTER DATABASE [scs] SET  READ_WRITE 
  
    ALTER DATABASE [scs] SET RECOVERY SIMPLE   

    ALTER DATABASE [scs] SET  MULTI_USER 

    ALTER DATABASE [scs] SET PAGE_VERIFY CHECKSUM  

    ALTER DATABASE [scs] SET DB_CHAINING OFF 
  
    EXEC sys.sp_db_vardecimal_storage_format N'scs', N'ON'  
END

USE [master]
GO

use [scs]
go
if SUSER_ID('dnc') IS NULL
  begin
    CREATE LOGIN [dnc] WITH PASSWORD=N'dnc', DEFAULT_DATABASE=[scs], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  end
go

USE [scs]
GO
if USER_ID('dnc') IS NULL
  begin
    CREATE USER [dnc] FOR LOGIN [dnc] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'dnc'
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'its')
BEGIN
	CREATE DATABASE [its]
	CONTAINMENT = NONE
	ON  PRIMARY 
	( NAME = N'its', FILENAME = N'/var/opt/mssql/data/its.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
	LOG ON 
	( NAME = N'its_log', FILENAME = N'/var/opt/mssql/data/its_log.ldf' , SIZE = 139264KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
	COLLATE Latin1_General_CI_AI

	ALTER DATABASE [its] SET ALLOW_SNAPSHOT_ISOLATION ON

	ALTER DATABASE [its] SET READ_COMMITTED_SNAPSHOT ON 

	if SUSER_ID('its') IS NULL
		begin
			CREATE LOGIN [its] WITH PASSWORD=N'its', DEFAULT_DATABASE=[its], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
		end
END

USE [master]
GO

USE [its]
GO
if USER_ID('its') IS NULL
  begin
	CREATE USER [its] FOR LOGIN [its] WITH DEFAULT_SCHEMA=[dbo]
  end
EXEC sp_addrolemember N'db_owner', 'its'
