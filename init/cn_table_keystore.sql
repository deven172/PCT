/* auto-generated sql/sqlserver/keystore/cn_table_keystore.sql by dbc 1.0.24-snapshot */
/* for ITS version 24.0.0.0-dev build 9999 */
USE [its]
GO

CREATE TABLE AUTH_KEYS (
	pkid NVARCHAR(15) COLLATE Latin1_General_BIN CONSTRAINT DF_AUTH_KEYS_pkid DEFAULT '               ' NOT NULL,
	keyAlias NVARCHAR(35) COLLATE Latin1_General_BIN CONSTRAINT DF_AUTH_KEYS_keyAlias DEFAULT '                                   ' NOT NULL,
	keyId NVARCHAR(128) COLLATE Latin1_General_BIN,
	algorithm NVARCHAR(35) COLLATE Latin1_General_BIN,
	dataContent NVARCHAR(4) COLLATE Latin1_General_BIN CONSTRAINT DF_AUTH_KEYS_dataContent DEFAULT 'CERT' NOT NULL CONSTRAINT CK_AUTH_KEYS_dataContent CHECK (dataContent IN ('CERT','PUB','PRIV')),
	issuer NVARCHAR(128) COLLATE Latin1_General_BIN,
	audience NVARCHAR(128) COLLATE Latin1_General_BIN,
	consumer NVARCHAR(128) COLLATE Latin1_General_BIN,
	globKeyStoreId NVARCHAR(15) COLLATE Latin1_General_BIN,
	addCertKeyStoreId NVARCHAR(15) COLLATE Latin1_General_BIN,
	dbSignature NVARCHAR(512) COLLATE Latin1_General_BIN,
	objectVersion ROWVERSION,
	CONSTRAINT PK_AUTH_KEYS PRIMARY KEY (pkid)
);
GO

CREATE TABLE EPH_KEY_STORE (
	purpose NVARCHAR(35) COLLATE Latin1_General_BIN CONSTRAINT DF_EPH_KEY_STORE_purpose DEFAULT '                                   ' NOT NULL,
	keyUsage NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_EPH_KEY_STORE_keyUsage DEFAULT 'S' NOT NULL CONSTRAINT CK_EPH_KEY_STORE_keyUsage CHECK (keyUsage IN ('S','V','E','D')),
	keyId NVARCHAR(12) COLLATE Latin1_General_BIN CONSTRAINT DF_EPH_KEY_STORE_keyId DEFAULT '            ' NOT NULL,
	expirationTime DATETIME CONSTRAINT DF_EPH_KEY_STORE_expirationTime DEFAULT convert(datetime,'1753-01-02 00:00:00',120) NOT NULL,
	keyType NVARCHAR(3) COLLATE Latin1_General_BIN CONSTRAINT DF_EPH_KEY_STORE_keyType DEFAULT 'SEC' NOT NULL CONSTRAINT CK_EPH_KEY_STORE_keyType CHECK (keyType IN ('SEC','PUB','PRV')),
	algorithm NVARCHAR(35) COLLATE Latin1_General_BIN,
	data VARBINARY(MAX) CONSTRAINT DF_EPH_KEY_STORE_data DEFAULT CONVERT([varbinary],(0x),(0)) NOT NULL,
	dbSignature NVARCHAR(512) COLLATE Latin1_General_BIN,
	objectVersion ROWVERSION,
	CONSTRAINT PK_EPH_KEY_STORE PRIMARY KEY (purpose,keyUsage,keyId)
);
GO

CREATE TABLE GLOB_KEY_STORE (
	pkid NVARCHAR(15) COLLATE Latin1_General_BIN CONSTRAINT DF_GLOB_KEY_STORE_pkid DEFAULT '               ' NOT NULL,
	data VARBINARY(MAX) CONSTRAINT DF_GLOB_KEY_STORE_data DEFAULT CONVERT([varbinary],(0x),(0)) NOT NULL,
	dbSignature NVARCHAR(512) COLLATE Latin1_General_BIN,
	CONSTRAINT PK_GLOB_KEY_STORE PRIMARY KEY (pkid)
);
GO

CREATE TABLE KEYMGT (
	pkid NVARCHAR(15) COLLATE Latin1_General_BIN CONSTRAINT DF_KEYMGT_pkid DEFAULT '               ' NOT NULL,
	keyAlias NVARCHAR(35) COLLATE Latin1_General_BIN,
	keyDescription NVARCHAR(35) COLLATE Latin1_General_BIN CONSTRAINT DF_KEYMGT_keyDescription DEFAULT '                                   ' NOT NULL,
	keyId NVARCHAR(128) COLLATE Latin1_General_BIN,
	keyUsage NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_KEYMGT_keyUsage DEFAULT 'S' NOT NULL CONSTRAINT CK_KEYMGT_keyUsage CHECK (keyUsage IN ('S','V','E','D')),
	keyPurpose NUMERIC(9) CONSTRAINT DF_KEYMGT_keyPurpose DEFAULT 1 NOT NULL CONSTRAINT CK_KEYMGT_keyPurpose CHECK (keyPurpose IN (1,2,3,4,5)),
	algorithm NVARCHAR(35) COLLATE Latin1_General_BIN,
	dataContent NVARCHAR(4) COLLATE Latin1_General_BIN CONSTRAINT DF_KEYMGT_dataContent DEFAULT 'CERT' NOT NULL CONSTRAINT CK_KEYMGT_dataContent CHECK (dataContent IN ('CERT','PUB','PRIV')),
	issuer NVARCHAR(128) COLLATE Latin1_General_BIN,
	subject NVARCHAR(128) COLLATE Latin1_General_BIN,
	effectiveDate DATETIME CONSTRAINT DF_KEYMGT_effectiveDate DEFAULT convert(datetime,'1753-01-02 00:00:00',120) NOT NULL,
	expirationDate DATETIME CONSTRAINT DF_KEYMGT_expirationDate DEFAULT convert(datetime,'1753-01-02 00:00:00',120) NOT NULL,
	globKeyStoreId NVARCHAR(15) COLLATE Latin1_General_BIN,
	addCertKeyStoreId NVARCHAR(15) COLLATE Latin1_General_BIN,
	dbSignature NVARCHAR(512) COLLATE Latin1_General_BIN,
	objectVersion ROWVERSION,
	CONSTRAINT PK_KEYMGT PRIMARY KEY (pkid)
);
GO

CREATE TABLE OAUTH_TOKEN (
	tokenUuid NVARCHAR(50) COLLATE Latin1_General_BIN CONSTRAINT DF_OAUTH_TOKEN_tokenUuid DEFAULT '                                                  ' NOT NULL,
	token NVARCHAR(500) COLLATE Latin1_General_BIN,
	tokenType NVARCHAR(3) COLLATE Latin1_General_BIN CONSTRAINT DF_OAUTH_TOKEN_tokenType DEFAULT 'BEA' NOT NULL CONSTRAINT CK_OAUTH_TOKEN_tokenType CHECK (tokenType IN ('BEA')),
	tokenExpiry DATETIME,
	scope NVARCHAR(500) COLLATE Latin1_General_BIN,
	refreshToken NVARCHAR(500) COLLATE Latin1_General_BIN,
	oAuthCfgId NVARCHAR(15) COLLATE Latin1_General_BIN,
	CONSTRAINT PK_OAUTH_TOKEN PRIMARY KEY (tokenUuid)
);
GO

CREATE TABLE SEC_MFA (
	pkid NVARCHAR(15) COLLATE Latin1_General_BIN CONSTRAINT DF_SEC_MFA_pkid DEFAULT '               ' NOT NULL,
	siteId NVARCHAR(12) COLLATE Latin1_General_BIN CONSTRAINT DF_SEC_MFA_siteId DEFAULT '            ' NOT NULL,
	mcode NVARCHAR(3) COLLATE Latin1_General_BIN CONSTRAINT DF_SEC_MFA_mcode DEFAULT '   ' NOT NULL,
	login NVARCHAR(32) COLLATE Latin1_General_BIN CONSTRAINT DF_SEC_MFA_login DEFAULT '                                ' NOT NULL,
	data VARBINARY(MAX) CONSTRAINT DF_SEC_MFA_data DEFAULT CONVERT([varbinary],(0x),(0)) NOT NULL,
	dbSignature NVARCHAR(512) COLLATE Latin1_General_BIN,
	CONSTRAINT PK_SEC_MFA PRIMARY KEY (pkid)
);
GO

CREATE TABLE TOKENSINUSE (
	tokenId NVARCHAR(256) COLLATE Latin1_General_BIN CONSTRAINT DF_TOKENSINUSE_tokenId DEFAULT '                                                                                                                                                                                                                                                                ' NOT NULL,
	tokenType NUMERIC(9) CONSTRAINT DF_TOKENSINUSE_tokenType DEFAULT 1 NOT NULL CONSTRAINT CK_TOKENSINUSE_tokenType CHECK (tokenType IN (1,2,3,4,5,6)),
	expirationDate DATETIME CONSTRAINT DF_TOKENSINUSE_expirationDate DEFAULT convert(datetime,'1753-01-02 00:00:00',120) NOT NULL,
	objectVersion ROWVERSION,
	CONSTRAINT PK_TOKENSINUSE PRIMARY KEY (tokenId,tokenType)
);
GO

CREATE TABLE TRUSTREL (
	pkid NVARCHAR(15) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_pkid DEFAULT '               ' NOT NULL,
	relationshipType NUMERIC(9) CONSTRAINT DF_TRUSTREL_relationshipType DEFAULT 1 NOT NULL CONSTRAINT CK_TRUSTREL_relationshipType CHECK (relationshipType IN (1,2)),
	shortcut NVARCHAR(35) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_shortcut DEFAULT '                                   ' NOT NULL,
	relationshipDesc NVARCHAR(35) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_relationshipDesc DEFAULT '                                   ' NOT NULL,
	authProtocol NUMERIC(9) CONSTRAINT DF_TRUSTREL_authProtocol DEFAULT 1 NOT NULL CONSTRAINT CK_TRUSTREL_authProtocol CHECK (authProtocol IN (1,2,3,4,5,6)),
	authContextControl NUMERIC(9) CONSTRAINT DF_TRUSTREL_authContextControl DEFAULT 2 NOT NULL CONSTRAINT CK_TRUSTREL_authContextControl CHECK (authContextControl IN (1,2,3)),
	issuer NVARCHAR(128) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_issuer DEFAULT '                                                                                                                                ' NOT NULL,
	audience NVARCHAR(128) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_audience DEFAULT '                                                                                                                                ' NOT NULL,
	authURL NVARCHAR(128) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_authURL DEFAULT '                                                                                                                                ' NOT NULL,
	endpointApi NVARCHAR(128) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_endpointApi DEFAULT '                                                                                                                                ' NOT NULL,
	endpointWeb NVARCHAR(128) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_endpointWeb DEFAULT '                                                                                                                                ' NOT NULL,
	endpointFocus NVARCHAR(128) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_endpointFocus DEFAULT '                                                                                                                                ' NOT NULL,
	isEnabled NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_isEnabled DEFAULT 'N' NOT NULL CONSTRAINT CK_TRUSTREL_isEnabled CHECK (isEnabled IN ('N','Y')),
	isDefault NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_isDefault DEFAULT 'N' NOT NULL CONSTRAINT CK_TRUSTREL_isDefault CHECK (isDefault IN ('N','Y')),
	signedRequest NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_signedRequest DEFAULT 'N' NOT NULL CONSTRAINT CK_TRUSTREL_signedRequest CHECK (signedRequest IN ('N','Y')),
	encryptedAssertion NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_encryptedAssertion DEFAULT 'N' NOT NULL CONSTRAINT CK_TRUSTREL_encryptedAssertion CHECK (encryptedAssertion IN ('N','Y')),
	forceAuthn NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_forceAuthn DEFAULT 'N' NOT NULL CONSTRAINT CK_TRUSTREL_forceAuthn CHECK (forceAuthn IN ('N','Y')),
	isOneTimeToken NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_isOneTimeToken DEFAULT 'N' NOT NULL CONSTRAINT CK_TRUSTREL_isOneTimeToken CHECK (isOneTimeToken IN ('N','Y')),
	isRestricted NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTREL_isRestricted DEFAULT 'N' NOT NULL CONSTRAINT CK_TRUSTREL_isRestricted CHECK (isRestricted IN ('N','Y')),
	dbSignature NVARCHAR(512) COLLATE Latin1_General_BIN,
	objectVersion ROWVERSION,
	CONSTRAINT PK_TRUSTREL PRIMARY KEY (pkid)
);
GO

CREATE TABLE TRUSTRELPOS (
	pkid NVARCHAR(15) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTRELPOS_pkid DEFAULT '               ' NOT NULL,
	parentId NVARCHAR(15) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTRELPOS_parentId DEFAULT '               ' NOT NULL,
	keyId NVARCHAR(128) COLLATE Latin1_General_BIN,
	algorithm NVARCHAR(35) COLLATE Latin1_General_BIN,
	keyUsage NVARCHAR(1) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTRELPOS_keyUsage DEFAULT 'S' NOT NULL CONSTRAINT CK_TRUSTRELPOS_keyUsage CHECK (keyUsage IN ('S','V','E','D')),
	subject NVARCHAR(128) COLLATE Latin1_General_BIN,
	issuer NVARCHAR(128) COLLATE Latin1_General_BIN,
	effectiveDate DATETIME CONSTRAINT DF_TRUSTRELPOS_effectiveDate DEFAULT convert(datetime,'1753-01-02 00:00:00',120) NOT NULL,
	expirationDate DATETIME CONSTRAINT DF_TRUSTRELPOS_expirationDate DEFAULT convert(datetime,'1753-01-02 00:00:00',120) NOT NULL,
	dataContent NVARCHAR(4) COLLATE Latin1_General_BIN CONSTRAINT DF_TRUSTRELPOS_dataContent DEFAULT 'CERT' NOT NULL CONSTRAINT CK_TRUSTRELPOS_dataContent CHECK (dataContent IN ('CERT','PUB','PRIV')),
	dbSignature NVARCHAR(512) COLLATE Latin1_General_BIN,
	globKeyStoreId NVARCHAR(15) COLLATE Latin1_General_BIN,
	objectVersion ROWVERSION,
	CONSTRAINT PK_TRUSTRELPOS PRIMARY KEY (pkid)
);
GO

