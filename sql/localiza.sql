USE [master]
GO
/****** Object:  Database [LOCALIZACION_WS]    Script Date: 06/20/2016 17:42:35 ******/
CREATE DATABASE [LOCALIZACION_WS] ON  PRIMARY 
( NAME = N'LOCALIZACION_WS', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\LOCALIZACION_WS.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'LOCALIZACION_WS_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\LOCALIZACION_WS_log.ldf' , SIZE = 1792KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [LOCALIZACION_WS] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [LOCALIZACION_WS].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [LOCALIZACION_WS] SET ANSI_NULL_DEFAULT OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET ANSI_NULLS OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET ANSI_PADDING OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET ANSI_WARNINGS OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET ARITHABORT OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET AUTO_CLOSE OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET AUTO_CREATE_STATISTICS ON
GO
ALTER DATABASE [LOCALIZACION_WS] SET AUTO_SHRINK OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET AUTO_UPDATE_STATISTICS ON
GO
ALTER DATABASE [LOCALIZACION_WS] SET CURSOR_CLOSE_ON_COMMIT OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET CURSOR_DEFAULT  GLOBAL
GO
ALTER DATABASE [LOCALIZACION_WS] SET CONCAT_NULL_YIELDS_NULL OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET NUMERIC_ROUNDABORT OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET QUOTED_IDENTIFIER OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET RECURSIVE_TRIGGERS OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET  DISABLE_BROKER
GO
ALTER DATABASE [LOCALIZACION_WS] SET AUTO_UPDATE_STATISTICS_ASYNC OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET DATE_CORRELATION_OPTIMIZATION OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET TRUSTWORTHY OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET ALLOW_SNAPSHOT_ISOLATION OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET PARAMETERIZATION SIMPLE
GO
ALTER DATABASE [LOCALIZACION_WS] SET READ_COMMITTED_SNAPSHOT OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET HONOR_BROKER_PRIORITY OFF
GO
ALTER DATABASE [LOCALIZACION_WS] SET  READ_WRITE
GO
ALTER DATABASE [LOCALIZACION_WS] SET RECOVERY FULL
GO
ALTER DATABASE [LOCALIZACION_WS] SET  MULTI_USER
GO
ALTER DATABASE [LOCALIZACION_WS] SET PAGE_VERIFY CHECKSUM
GO
ALTER DATABASE [LOCALIZACION_WS] SET DB_CHAINING OFF
GO
EXEC sys.sp_db_vardecimal_storage_format N'LOCALIZACION_WS', N'ON'
GO
USE [LOCALIZACION_WS]
GO
/****** Object:  UserDefinedFunction [dbo].[Levenshtein]    Script Date: 06/20/2016 17:42:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Computes and returns the Levenshtein edit distance between two strings, i.e. the
-- number of insertion, deletion, and sustitution edits required to transform one
-- string to the other, or NULL if @max is exceeded. Comparisons use the case-
-- sensitivity configured in SQL Server (case-insensitive by default).
-- http://blog.softwx.net/2014/12/optimizing-levenshtein-algorithm-in-tsql.html
-- 
-- Based on Sten Hjelmqvist's "Fast, memory efficient" algorithm, described
-- at http://www.codeproject.com/Articles/13525/Fast-memory-efficient-Levenshtein-algorithm,
-- with some additional optimizations.
-- =============================================
CREATE FUNCTION [dbo].[Levenshtein](
    @s nvarchar(4000)
  , @t nvarchar(4000)
  , @max int
)
RETURNS int
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @distance int = 0 -- return variable
          , @v0 nvarchar(4000)-- running scratchpad for storing computed distances
          , @start int = 1      -- index (1 based) of first non-matching character between the two string
          , @i int, @j int      -- loop counters: i for s string and j for t string
          , @diag int          -- distance in cell diagonally above and left if we were using an m by n matrix
          , @left int          -- distance in cell to the left if we were using an m by n matrix
          , @sChar nchar      -- character at index i from s string
          , @thisJ int          -- temporary storage of @j to allow SELECT combining
          , @jOffset int      -- offset used to calculate starting value for j loop
          , @jEnd int          -- ending value for j loop (stopping point for processing a column)
          -- get input string lengths including any trailing spaces (which SQL Server would otherwise ignore)
          , @sLen int = datalength(@s) / datalength(left(left(@s, 1) + '.', 1))    -- length of smaller string
          , @tLen int = datalength(@t) / datalength(left(left(@t, 1) + '.', 1))    -- length of larger string
          , @lenDiff int      -- difference in length between the two strings
    -- if strings of different lengths, ensure shorter string is in s. This can result in a little
    -- faster speed by spending more time spinning just the inner loop during the main processing.
    IF (@sLen > @tLen) BEGIN
        SELECT @v0 = @s, @i = @sLen -- temporarily use v0 for swap
        SELECT @s = @t, @sLen = @tLen
        SELECT @t = @v0, @tLen = @i
    END
    SELECT @max = ISNULL(@max, @tLen)
         , @lenDiff = @tLen - @sLen
    IF @lenDiff > @max RETURN NULL

    -- suffix common to both strings can be ignored
    WHILE(@sLen > 0 AND SUBSTRING(@s, @sLen, 1) = SUBSTRING(@t, @tLen, 1))
        SELECT @sLen = @sLen - 1, @tLen = @tLen - 1

    IF (@sLen = 0) RETURN @tLen

    -- prefix common to both strings can be ignored
    WHILE (@start < @sLen AND SUBSTRING(@s, @start, 1) = SUBSTRING(@t, @start, 1)) 
        SELECT @start = @start + 1
    IF (@start > 1) BEGIN
        SELECT @sLen = @sLen - (@start - 1)
             , @tLen = @tLen - (@start - 1)

        -- if all of shorter string matches prefix and/or suffix of longer string, then
        -- edit distance is just the delete of additional characters present in longer string
        IF (@sLen <= 0) RETURN @tLen

        SELECT @s = SUBSTRING(@s, @start, @sLen)
             , @t = SUBSTRING(@t, @start, @tLen)
    END

    -- initialize v0 array of distances
    SELECT @v0 = '', @j = 1
    WHILE (@j <= @tLen) BEGIN
        SELECT @v0 = @v0 + NCHAR(CASE WHEN @j > @max THEN @max ELSE @j END)
        SELECT @j = @j + 1
    END

    SELECT @jOffset = @max - @lenDiff
         , @i = 1
    WHILE (@i <= @sLen) BEGIN
        SELECT @distance = @i
             , @diag = @i - 1
             , @sChar = SUBSTRING(@s, @i, 1)
             -- no need to look beyond window of upper left diagonal (@i) + @max cells
             -- and the lower right diagonal (@i - @lenDiff) - @max cells
             , @j = CASE WHEN @i <= @jOffset THEN 1 ELSE @i - @jOffset END
             , @jEnd = CASE WHEN @i + @max >= @tLen THEN @tLen ELSE @i + @max END
        WHILE (@j <= @jEnd) BEGIN
            -- at this point, @distance holds the previous value (the cell above if we were using an m by n matrix)
            SELECT @left = UNICODE(SUBSTRING(@v0, @j, 1))
                 , @thisJ = @j
            SELECT @distance = 
                CASE WHEN (@sChar = SUBSTRING(@t, @j, 1)) THEN @diag                    --match, no change
                     ELSE 1 + CASE WHEN @diag < @left AND @diag < @distance THEN @diag    --substitution
                                   WHEN @left < @distance THEN @left                    -- insertion
                                   ELSE @distance                                        -- deletion
                                END    END
            SELECT @v0 = STUFF(@v0, @thisJ, 1, NCHAR(@distance))
                 , @diag = @left
                 , @j = case when (@distance > @max) AND (@thisJ = @i + @lenDiff) then @jEnd + 2 else @thisJ + 1 end
        END
        SELECT @i = CASE WHEN @j > @jEnd + 1 THEN @sLen + 1 ELSE @i + 1 END
    END
    RETURN CASE WHEN @distance <= @max THEN @distance ELSE NULL END
END
GO
/****** Object:  Table [dbo].[fuentes]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fuentes](
	[id_fuente] [int] IDENTITY(1,1) NOT NULL,
	[fuente] [varchar](50) NOT NULL,
	[valor] [tinyint] NULL,
 CONSTRAINT [PK_fuentes] PRIMARY KEY CLUSTERED 
(
	[id_fuente] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetCommonCharacters]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_GetCommonCharacters](@firstWord VARCHAR(MAX), @secondWord VARCHAR(MAX), @matchWindow INT)
RETURNS VARCHAR(MAX) AS
BEGIN
	DECLARE @CommonChars VARCHAR(MAX)
	DECLARE @copy VARCHAR(MAX)
	DECLARE @char CHAR(1)
	DECLARE @foundIT BIT

	DECLARE @f1_len INT
	DECLARE @f2_len INT
	DECLARE @i INT
	DECLARE @j INT
	DECLARE @j_Max INT

	SET	@CommonChars = ''
    IF @firstWord IS NOT NULL AND @secondWord IS NOT NULL 
    BEGIN
		SET @f1_len = LEN(@firstWord)
		SET @f2_len = LEN(@secondWord)
		SET @copy = @secondWord

		SET @i = 1
		WHILE @i < (@f1_len + 1)
		BEGIN
			SET	@char = SUBSTRING(@firstWord, @i, 1)
			SET @foundIT = 0

			-- Set J starting value
			IF @i - @matchWindow > 1
			BEGIN
				SET @j = @i - @matchWindow
			END
			ELSE
			BEGIN
				SET @j = 1
			END
			-- Set J stopping value
			IF @i + @matchWindow <= @f2_len
			BEGIN
				SET @j_Max = @i + @matchWindow
			END
			ELSE
			IF @f2_len < @i + @matchWindow
			BEGIN
				SET @j_Max = @f2_len
			END

			WHILE @j < (@j_Max + 1) AND @foundIT = 0
			BEGIN
				IF SUBSTRING(@copy, @j, 1) = @char
				BEGIN
					SET	@foundIT = 1
					SET	@CommonChars = @CommonChars + @char
					SET @copy = STUFF(@copy, @j, 1, '#')
				END
				SET @j = @j + 1
			END	
			SET @i = @i + 1
		END
    END

	RETURN @CommonChars
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_calculateTranspositions]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_calculateTranspositions](@s1_len INT, @str1 VARCHAR(MAX), @str2 VARCHAR(MAX)) 
RETURNS INT AS 
BEGIN
	DECLARE @transpositions INT
	DECLARE @i INT

	SET	@transpositions = 0
	SET	@i = 0
	WHILE @i < @s1_len
	BEGIN
		IF SUBSTRING(@str1, @i+1, 1) <> SUBSTRING(@str2, @i+1, 1)
		BEGIN
			SET	@transpositions = @transpositions + 1
		END
		SET @i = @i + 1
	END

	SET	@transpositions = @transpositions / 2
	RETURN @transpositions
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_calculatePrefixLength]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_calculatePrefixLength](@firstWord VARCHAR(MAX), @secondWord VARCHAR(MAX))
RETURNS INT As 
BEGIN
	DECLARE @f1_len INT
	DECLARE @f2_len INT
    DECLARE	@minPrefixTestLength INT
	DECLARE @i INT
	DECLARE @n INT
	DECLARE @foundIT BIT

	SET	@minPrefixTestLength = 4
    IF @firstWord IS NOT NULL AND @secondWord IS NOT NULL 
    BEGIN
		SET @f1_len = LEN(@firstWord)
		SET @f2_len = LEN(@secondWord)
		SET @i = 0
		SET	@foundIT = 0
		SET @n =	CASE	WHEN	@minPrefixTestLength < @f1_len 
									AND @minPrefixTestLength < @f2_len 
							THEN	@minPrefixTestLength
							WHEN	@f1_len < @f2_len 
									AND @f1_len < @minPrefixTestLength 
							THEN	@f1_len
							ELSE	@f2_len
					END
		WHILE @i < @n AND @foundIT = 0
		BEGIN
			IF SUBSTRING(@firstWord, @i+1, 1) <> SUBSTRING(@secondWord, @i+1, 1)
			BEGIN
				SET @minPrefixTestLength = @i
				SET @foundIT = 1
			END
			SET @i = @i + 1
		END
	END
    RETURN @minPrefixTestLength
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_calculateMatchWindow]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_calculateMatchWindow](@s1_len INT, @s2_len INT) 
RETURNS INT AS 
BEGIN
	DECLARE @matchWindow INT
	SET	@matchWindow =	CASE	WHEN @s1_len >= @s2_len
								THEN (@s1_len / 2) - 1
								ELSE (@s2_len / 2) - 1
						END
	RETURN @matchWindow
END
GO
/****** Object:  UserDefinedFunction [dbo].[EliminaDobleBlanco]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[EliminaDobleBlanco]
(
	-- Add the parameters for the function here
	@vnombre varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result varchar (max);
	
	SET @result = @vnombre;
	SET @result = REPLACE(@result, '  ', ' ');

	
	RETURN @result

END
GO
/****** Object:  UserDefinedFunction [dbo].[EliminaAcentos]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[EliminaAcentos] 
(
	-- Add the parameters for the function here
	@vnombre varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result AS VARCHAR(MAX);

	-- Add the T-SQL statements to compute the return value here
	SET @result = @vnombre;
	SET @result = REPLACE(@result,'Í','I');
	SET @result = REPLACE(@result,'Ú','U');
	SET @result = REPLACE(@result,'À','A');
	SET @result = REPLACE(@result,'Á','A');
	SET @result = REPLACE(@result,'á','a');
	SET @result = REPLACE(@result,'à','a');
	SET @result = REPLACE(@result,'É','E');
	SET @result = REPLACE(@result,'È','E');
	SET @result = REPLACE(@result,'é','e');
	SET @result = REPLACE(@result,'è','e');
	SET @result = REPLACE(@result,'í','i');
	SET @result = REPLACE(@result,'Ó','O');
	SET @result = REPLACE(@result,'Ò','O');
	SET @result = REPLACE(@result,'ò','o');
	SET @result = REPLACE(@result,'ó','o');
	SET @result = REPLACE(@result,'ú','u');

	-- Return the result of the function
	RETURN @result

END
GO
/****** Object:  UserDefinedFunction [dbo].[DamLev]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Computes and returns the Damerau-Levenshtein edit distance between two strings, 
-- i.e. the number of insertion, deletion, substitution, and transposition edits
-- required to transform one string to the other.  This value will be >= 0, where
-- 0 indicates identical strings. Comparisons use the case-sensitivity configured
-- in SQL Server (case-insensitive by default). This algorithm is basically the
-- Levenshtein algorithm with a modification that considers transposition of two
-- adjacent characters as a single edit.
-- http://blog.softwx.net/2015/01/optimizing-damerau-levenshtein_19.html
-- See http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
-- Note that this uses Sten Hjelmqvist's "Fast, memory efficient" algorithm, described
-- at http://www.codeproject.com/Articles/13525/Fast-memory-efficient-Levenshtein-algorithm.
-- This version differs by including some optimizations, and extending it to the Damerau-
-- Levenshtein algorithm.
-- Note that this is the simpler and faster optimal string alignment (aka restricted edit) distance
-- that difers slightly from the full Damerau-Levenshtein algorithm by imposing the restriction
-- that no substring is edited more than once. So for example, "CA" to "ABC" has an edit distance
-- of 2 by a complete application of Damerau-Levenshtein, but a distance of 3 by this method that
-- uses the optimal string alignment algorithm. See wikipedia article for more detail on this
-- distinction.
-- 
-- @s - String being compared for distance.
-- @t - String being compared against other string.
-- @max - Maximum distance allowed, or NULL if no maximum is desired. Returns NULL if distance will exceed @max.
-- returns int edit distance, >= 0 representing the number of edits required to transform one string to the other.
-- =============================================
 
CREATE FUNCTION [dbo].[DamLev](
 
    @s nvarchar(4000)
  , @t nvarchar(4000)
  , @max int
)
RETURNS int
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @distance int = 0 -- return variable
          , @v0 nvarchar(4000)-- running scratchpad for storing computed distances
          , @v2 nvarchar(4000)-- running scratchpad for storing previous column's computed distances
          , @start int = 1      -- index (1 based) of first non-matching character between the two string
          , @i int, @j int      -- loop counters: i for s string and j for t string
          , @diag int          -- distance in cell diagonally above and left if we were using an m by n matrix
          , @left int          -- distance in cell to the left if we were using an m by n matrix
          , @nextTransCost int-- transposition base cost for next iteration 
          , @thisTransCost int-- transposition base cost (2 distant along diagonal) for current iteration
          , @sChar nchar      -- character at index i from s string
          , @tChar nchar      -- character at index j from t string
          , @thisJ int          -- temporary storage of @j to allow SELECT combining
          , @jOffset int      -- offset used to calculate starting value for j loop
          , @jEnd int          -- ending value for j loop (stopping point for processing a column)
          -- get input string lengths including any trailing spaces (which SQL Server would otherwise ignore)
          , @sLen int = datalength(@s) / datalength(left(left(@s, 1) + '.', 1))    -- length of smaller string
          , @tLen int = datalength(@t) / datalength(left(left(@t, 1) + '.', 1))    -- length of larger string
          , @lenDiff int      -- difference in length between the two strings
    -- if strings of different lengths, ensure shorter string is in s. This can result in a little
    -- faster speed by spending more time spinning just the inner loop during the main processing.
    IF (@sLen > @tLen) BEGIN
        SELECT @v0 = @s, @i = @sLen -- temporarily use v0 for swap
        SELECT @s = @t, @sLen = @tLen
        SELECT @t = @v0, @tLen = @i
    END
    SELECT @max = ISNULL(@max, @tLen)
         , @lenDiff = @tLen - @sLen
    IF @lenDiff > @max RETURN NULL
 
    -- suffix common to both strings can be ignored
    WHILE(@sLen > 0 AND SUBSTRING(@s, @sLen, 1) = SUBSTRING(@t, @tLen, 1))
        SELECT @sLen = @sLen - 1, @tLen = @tLen - 1
 
    IF (@sLen = 0) RETURN @tLen
 
    -- prefix common to both strings can be ignored
    WHILE (@start < @sLen AND SUBSTRING(@s, @start, 1) = SUBSTRING(@t, @start, 1)) 
        SELECT @start = @start + 1
    IF (@start > 1) BEGIN
        SELECT @sLen = @sLen - (@start - 1)
             , @tLen = @tLen - (@start - 1)
 
        -- if all of shorter string matches prefix and/or suffix of longer string, then
        -- edit distance is just the delete of additional characters present in longer string
        IF (@sLen <= 0) RETURN @tLen
 
        SELECT @s = SUBSTRING(@s, @start, @sLen)
             , @t = SUBSTRING(@t, @start, @tLen)
    END
 
    -- initialize v0 array of distances
    SELECT @v0 = '', @j = 1
    WHILE (@j <= @tLen) BEGIN
        SELECT @v0 = @v0 + NCHAR(CASE WHEN @j > @max THEN @max ELSE @j END)
        SELECT @j = @j + 1
    END
     
    SELECT @v2 = @v0 -- copy...doesn't matter what's in v2, just need to initialize its size
         , @jOffset = @max - @lenDiff
         , @i = 1
    WHILE (@i <= @sLen) BEGIN
        SELECT @distance = @i
             , @diag = @i - 1
             , @sChar = SUBSTRING(@s, @i, 1)
             -- no need to look beyond window of upper left diagonal (@i) + @max cells
             -- and the lower right diagonal (@i - @lenDiff) - @max cells
             , @j = CASE WHEN @i <= @jOffset THEN 1 ELSE @i - @jOffset END
             , @jEnd = CASE WHEN @i + @max >= @tLen THEN @tLen ELSE @i + @max END
             , @thisTransCost = 0
        WHILE (@j <= @jEnd) BEGIN
            -- at this point, @distance holds the previous value (the cell above if we were using an m by n matrix)
            SELECT @nextTransCost = UNICODE(SUBSTRING(@v2, @j, 1))
                 , @v2 = STUFF(@v2, @j, 1, NCHAR(@diag))
                 , @tChar = SUBSTRING(@t, @j, 1)
                 , @left = UNICODE(SUBSTRING(@v0, @j, 1))
                 , @thisJ = @j
            SELECT @distance = CASE WHEN @diag < @left AND @diag < @distance THEN @diag    --substitution
                                    WHEN @left < @distance THEN @left                    -- insertion
                                    ELSE @distance                                        -- deletion
                                END
            SELECT @distance = CASE WHEN (@sChar = @tChar) THEN @diag    -- no change (characters match)
                                    WHEN @i <> 1 AND @j <> 1
                                        AND @tChar = SUBSTRING(@s, @i - 1, 1)
                                        AND @thisTransCost < @distance
                                        AND @sChar = SUBSTRING(@t, @j - 1, 1)
                                        THEN 1 + @thisTransCost        -- transposition
                                    ELSE 1 + @distance END
            SELECT @v0 = STUFF(@v0, @thisJ, 1, NCHAR(@distance))
                 , @diag = @left
                 , @thisTransCost = @nextTransCost
                 , @j = case when (@distance > @max) AND (@thisJ = @i + @lenDiff) then @jEnd + 2 else @thisJ + 1 end
        END
        SELECT @i = CASE WHEN @j > @jEnd + 1 THEN @sLen + 1 ELSE @i + 1 END
    END
    RETURN CASE WHEN @distance <= @max THEN @distance ELSE NULL END
END
GO
/****** Object:  Table [dbo].[cliente]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[cliente](
	[id_cliente] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [varchar](50) NOT NULL,
	[consolidar] [tinyint] NULL,
	[transformar] [tinyint] NULL,
 CONSTRAINT [PK_cliente] PRIMARY KEY CLUSTERED 
(
	[id_cliente] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[metodos]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[metodos](
	[id_metodo] [int] IDENTITY(1,1) NOT NULL,
	[metodo] [varchar](50) NOT NULL,
 CONSTRAINT [PK_metodos] PRIMARY KEY CLUSTERED 
(
	[id_metodo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[parametro]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[parametro](
	[id_parametro] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [varchar](50) NOT NULL,
	[activo] [bit] NOT NULL,
 CONSTRAINT [PK_parametro] PRIMARY KEY CLUSTERED 
(
	[id_parametro] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pre_salida]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pre_salida](
	[id_pre_salida] [int] IDENTITY(1,1) NOT NULL,
	[id_peticion] [int] NOT NULL,
	[request_id] [varchar](30) NOT NULL,
	[error] [smallint] NULL,
	[persona_validada] [smallint] NULL,
	[direccion_validada] [smallint] NULL,
	[telefono_validado] [smallint] NULL,
	[dni_similitud] [smallint] NULL,
	[nomcom_similitud] [smallint] NULL,
	[nombre_similitud] [smallint] NULL,
	[apellido1_similitud] [smallint] NULL,
	[apellido2_similitud] [smallint] NULL,
	[fecnac_similitud] [smallint] NULL,
	[provincia_similitud] [smallint] NULL,
	[poblacion_similitud] [smallint] NULL,
	[cp_similitud] [smallint] NULL,
	[via_similitud] [smallint] NULL,
	[numero_similitud] [smallint] NULL,
	[fuente] [int] NULL,
 CONSTRAINT [PK_pre_salida] PRIMARY KEY CLUSTERED 
(
	[id_pre_salida] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[usuario]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[usuario](
	[id_usuario] [int] IDENTITY(1,1) NOT NULL,
	[id_cliente] [int] NOT NULL,
	[usuario] [varchar](30) NOT NULL,
	[password] [varchar](30) NOT NULL,
 CONSTRAINT [PK_usuario] PRIMARY KEY CLUSTERED 
(
	[id_usuario] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[transforma_formato_fecha]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[transforma_formato_fecha] (
	@fecha1_s nvarchar(4000)
)
RETURNS nvarchar(4000)
AS
BEGIN
	
	declare @fecha nvarchar(4000) = SUBSTRING(@fecha1_s, 7,4) + '-' + --Año
									SUBSTRING(@fecha1_s, 4,2) + '-' + --Mes
									SUBSTRING(@fecha1_s, 1,2);        --Dia
									


	-- Return the result of the function
	RETURN @fecha;
			
END
GO
/****** Object:  Table [dbo].[WS_TELEFONOS]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WS_TELEFONOS](
	[ID_PERSONA] [varchar](50) NULL,
	[TELEFONO] [varchar](50) NULL,
	[F1] [bit] NULL,
	[F2] [bit] NULL,
	[F3] [bit] NULL,
	[F4] [bit] NULL,
	[F5] [bit] NULL,
	[F6] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WS_PERSONAS]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WS_PERSONAS](
	[ID_PERSONA] [varchar](50) NULL,
	[NIF] [varchar](50) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WS_NOMBRES]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WS_NOMBRES](
	[ID_PERSONA] [varchar](50) NULL,
	[NOMBRE] [varchar](50) NULL,
	[APE1] [varchar](50) NULL,
	[APE2] [varchar](50) NULL,
	[DIA] [varchar](50) NULL,
	[MES] [varchar](50) NULL,
	[ANNO] [varchar](50) NULL,
	[F1] [bit] NULL,
	[F2] [bit] NULL,
	[F3] [bit] NULL,
	[F4] [bit] NULL,
	[F5] [bit] NULL,
	[F6] [bit] NULL,
	[NOMCOM_LIMPIO] [varchar](50) NULL,
	[COMNOM_LIMPIO] [varchar](50) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WS_DIRECCIONES]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WS_DIRECCIONES](
	[ID_PERSONA] [varchar](10) NULL,
	[PROVINCIA] [varchar](15) NULL,
	[POBLACION] [varchar](47) NULL,
	[CP] [varchar](5) NULL,
	[VIA] [varchar](56) NULL,
	[NUMERO_VIA] [varchar](10) NULL,
	[F1] [bit] NULL,
	[F2] [bit] NULL,
	[F3] [bit] NULL,
	[F4] [bit] NULL,
	[F5] [bit] NULL,
	[F6] [bit] NULL,
	[PROVINCIA_LIMPIA] [varchar](15) NULL,
	[POPLACION_LIMPIA] [varchar](47) NULL,
	[VIA_LIMPIA] [varchar](56) NULL,
	[NUMERO_LIMPIO] [varchar](10) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[usuario_metodo]    Script Date: 06/20/2016 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[usuario_metodo](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[id_usuario] [int] NOT NULL,
	[id_metodo] [int] NOT NULL,
 CONSTRAINT [PK_usuario_metodo] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[spLogin]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spLogin]
	@username varchar(max),
	@password varchar(max),
	@id_usuario int = null output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @user varchar(max), @pass varchar(max);

	
	SELECT @user = usuario, @pass = password, @id_usuario = id_usuario FROM usuario WHERE usuario = @username;
	
	IF(@user IS NULL)
	BEGIN
		RETURN 0;
	END
	
	IF(@password <> @pass)
	BEGIN
		RETURN 0;
	END
	
	RETURN 1;
	
END
GO
/****** Object:  Table [dbo].[usuario_fuente]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[usuario_fuente](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[id_usuario] [int] NOT NULL,
	[id_fuente] [int] NOT NULL,
 CONSTRAINT [PK_usuario_fuente] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[spConsolidaPresalidas]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spConsolidaPresalidas]
	@id_peticion int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT
		[id_peticion]
		,MAX([request_id]) AS [request_id]
		,0 AS [error]
		,MIN([persona_validada]) AS [persona_validada]
		,MAX([telefono_validado]) AS [telefono_validado]
		,MAX([dni_similitud]) AS [dni_similitud]
		,MAX([nomcom_similitud]) AS [nomcom_similitud]
		,MAX([nombre_similitud]) AS [nombre_similitud]
		,MAX([apellido1_similitud]) AS [apellido1_similitud]
		,MAX([apellido2_similitud]) AS [apellido2_similitud]
		,MAX([fecnac_similitud]) AS [fecnac_similitud]
		,MAX([provincia_similitud]) AS [provincia_similitud]
		,MAX([poblacion_similitud]) AS [poblacion_similitud]
		,MAX([cp_similitud]) AS [cp_similitud]
		,MAX([via_similitud]) AS [via_similitud]
		,MAX([numero_similitud]) AS [numero_similitud]
        ,0 as [fuente] 
    FROM pre_salida 
    WHERE id_peticion = @id_peticion
    GROUP BY id_peticion
    
    
END
GO
/****** Object:  UserDefinedFunction [dbo].[SimilitudNIF]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[SimilitudNIF] (
	@dni1 nvarchar(4000),
	@dni2 nvarchar(4000)
)
RETURNS int
AS
BEGIN

	declare @distancia int = dbo.Levenshtein(@dni1, @dni2, null);
	-- Return the result of the function
	RETURN CASE 
			WHEN @distancia = 0 THEN 100
			WHEN @distancia <= 2 THEN 50
			ELSE 0
			END;

END
GO
/****** Object:  UserDefinedFunction [dbo].[SimilitudFechas]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[SimilitudFechas] (
	@fecha1_s nvarchar(4000),
	@fecha2_s nvarchar(4000)
)
RETURNS int
AS
BEGIN
	
	
	declare @fecha1 date = CONVERT(dateTIME, dbo.transforma_formato_fecha(@fecha1_s));
	declare @fecha2 date = CONVERT(dateTIME, dbo.transforma_formato_fecha(@fecha2_s));

	-- Return the result of the function
	RETURN CASE 
			WHEN @fecha1 = @fecha2 THEN 100
			WHEN (YEAR(@fecha1) = YEAR(@fecha2) AND MONTH(@fecha1) = MONTH(@fecha2)) THEN 90
			WHEN YEAR(@fecha1) = YEAR(@fecha2) THEN 75
			WHEN (DAY(@fecha1) = DAY(@fecha2) AND MONTH(@fecha1) = MONTH(@fecha2)) THEN 40
			ELSE 0
			END;
			
END
GO
/****** Object:  Table [dbo].[peticion]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[peticion](
	[id_peticion] [int] IDENTITY(1,1) NOT NULL,
	[request_id] [varchar](30) NULL,
	[ip] [varchar](50) NULL,
	[fecha] [datetime] NOT NULL,
	[id_usuario] [int] NULL,
	[dni] [varchar](10) NULL,
	[nombre] [varchar](100) NULL,
	[tipo_nombre] [char](1) NULL,
	[apellido1] [varchar](100) NULL,
	[apellido2] [varchar](100) NULL,
	[fecha_nacimiento] [date] NULL,
	[provincia] [varchar](100) NULL,
	[poblacion] [varchar](100) NULL,
	[codigo_postal] [varchar](5) NULL,
	[via] [varchar](100) NULL,
	[numero] [varchar](5) NULL,
	[telefono] [varchar](15) NULL,
	[nomcom_norm] [varchar](300) NULL,
	[comnom_norm] [varchar](300) NULL,
	[via_norm] [varchar](100) NULL,
	[provincia_norm] [varchar](100) NULL,
	[problacion_norm] [varchar](100) NULL,
 CONSTRAINT [PK_peticion] PRIMARY KEY CLUSTERED 
(
	[id_peticion] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[SimilitudCadenas]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SimilitudCadenas]
(
	 @string1 NVARCHAR(100)
    ,@string2 NVARCHAR(100)
)
RETURNS INT
AS
BEGIN

    DECLARE @distancia INT
    
    IF(@string1 IS NULL OR @string2 IS NULL) RETURN 0;

    DECLARE @string1Length INT = COALESCE(LEN(@string1), 0) , @string2Length INT = COALESCE(LEN(@string2), 0)
    
    DECLARE @maxLength INT = CASE WHEN @string1Length > @string2Length THEN @string1Length ELSE @string2Length END
    
    IF(@maxLength = 0)
    begin
		RETURN 0;
    end

    SELECT @distancia = dbo.Levenshtein(@string1  ,@string2, null);

    DECLARE @percentageOfBadCharacters INT = @distancia * 100 / @maxLength

    DECLARE @percentageOfGoodCharacters INT = 100 - @percentageOfBadCharacters

    -- Return the result of the function
    RETURN COALESCE(@percentageOfGoodCharacters, 0)

END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_calculateJaro]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_calculateJaro](@str1 VARCHAR(MAX), @str2 VARCHAR(MAX)) 
RETURNS FLOAT AS 
BEGIN
	DECLARE	@Common1				VARCHAR(MAX)
	DECLARE	@Common2				VARCHAR(MAX)
	DECLARE @Common1_Len			INT
	DECLARE	@Common2_Len			INT
	DECLARE @s1_len					INT  
	DECLARE @s2_len					INT 
	DECLARE	@transpose_cnt			INT
	DECLARE @match_window			INT
	DECLARE @jaro_distance			FLOAT
	SET		@transpose_cnt			= 0
	SET		@match_window			= 0
	SET		@jaro_distance			= 0
	Set @s1_len = LEN(@str1)
	Set @s2_len = LEN(@str2)
	SET	@match_window = dbo.fn_calculateMatchWindow(@s1_len, @s2_len)
	SET	@Common1 = dbo.fn_GetCommonCharacters(@str1, @str2, @match_window)
	SET @Common1_Len = LEN(@Common1)
	IF @Common1_Len = 0 OR @Common1 IS NULL
	BEGIN
		RETURN 0		
	END
	SET @Common2 = dbo.fn_GetCommonCharacters(@str2, @str1, @match_window)
	SET @Common2_Len = LEN(@Common2)
	IF @Common1_Len <> @Common2_Len OR @Common2 IS NULL
	BEGIN
		RETURN 0
	END

	SET	@transpose_cnt = dbo.[fn_calculateTranspositions](@Common1_Len, @Common1, @Common2)
	SET	@jaro_distance =	@Common1_Len / (3.0 * @s1_len) + 
							@Common1_Len / (3.0 * @s2_len) +
							(@Common1_Len - @transpose_cnt) / (3.0 * @Common1_Len);

	RETURN @jaro_distance
END
GO
/****** Object:  UserDefinedFunction [dbo].[LimpiaDireccion]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[LimpiaDireccion] 
(
	-- Add the parameters for the function here
	@vnombre varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	
	DECLARE @result AS VARCHAR(MAX);
	
	SET @result = @vnombre;
	SET @result = replace(@result,'chr(13)',' ');
	SET @result = replace(@result,'chr(10)',' ');
	SET @result = UPPER(@result);

	SET @result = replace(@result,'(A LA)',' ');
	SET @result = replace(@result,'(A LOS)',' ');
	SET @result = replace(@result,'(A LAS)',' ');
	SET @result = replace(@result,'(AS)',' ');

	SET @result = replace(@result,'(EL)',' ');
	SET @result = replace(@result,'( EL )',' ');
	SET @result = replace(@result,'(LA)',' ');
	SET @result = replace(@result,'( LA)',' ');
	SET @result = replace(@result,'( LA)',' ');
	SET @result = replace(@result,'(LOS)',' ');
	SET @result = replace(@result,'(LO)',' ');
	SET @result = replace(@result,'(LAS)',' ');
	SET @result = replace(@result,'(LES)',' ');


	SET @result = replace(@result,'(L'+''''+')',' ');
	SET @result = replace(@result,'(A)',' ');
	SET @result = replace(@result,'(DAS)',' ');
	SET @result = replace(@result,'(O)',' ');

	SET @result = replace(@result,'(DE)',' ');
	SET @result = replace(@result,'(DE L'+''''+')',' ');
	SET @result = replace(@result,'(L'+''''+')',' ');
	SET @result = replace(@result,'(D'+''''+'EN)',' ');
	SET @result = replace(@result,'(D' + '''' + ')',' ');
	SET @result = replace(@result,'(DE LES)',' ');
	SET @result = replace(@result,'(DE LA)',' ');
	SET @result = replace(@result,'(DE LA )',' ');
	SET @result = replace(@result,'(DE)(LA)',' ');
	SET @result = replace(@result,'(DEL)',' ');
	SET @result = replace(@result,'(DELS)',' ');
	SET @result = replace(@result,'(DE LOS)',' ');
	SET @result = replace(@result,'(DE LAS)',' ');

	SET @result = replace(@result,'(ELS)',' ');
	SET @result = replace(@result,'(GRP)',' ');
	SET @result = replace(@result,'KALEA/CALLE ','CALLE ');

	SET @result = replace(@result,'(PASSEIG)',' ');


	SET @result = replace(@result,'(DOS)',' ');
	SET @result = replace(@result,'(DO)',' ');
	SET @result = replace(@result,'(DON)',' ');
	SET @result = replace(@result,'(DA)',' ');
	SET @result = replace(@result,'(DAS)',' ');

	SET @result = replace(@result,'(OS)',' ');


	SET @result = replace(@result,'(DISEMINADO)',' ');
	SET @result = replace(@result,'(DISSEMINAT)',' ');
	SET @result = replace(@result,'(DIS)',' ');
	SET @result = replace(@result,'(DISEM)',' ');
	SET @result = replace(@result,'-(DISEM)',' ');


  SET @result = UPPER(dbo.EliminaAcentos(dbo.EliminaDobleBlanco(RTRIM(LTRIM(@result)))));
 
	RETURN @result;

END
GO
/****** Object:  UserDefinedFunction [dbo].[LimpiaCadena]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[LimpiaCadena]
(
	-- Add the parameters for the function here
	@vnombre varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result varchar(max);
	SET @result = @vnombre;
	
	
	SET @result =  REPLACE(REPLACE(@result, CHAR(13), ' '), CHAR(10), ' ');

	SET @result =  UPPER(dbo.EliminaAcentos(dbo.EliminaDobleBlanco(RTRIM(LTRIM(@result)))));
	
	RETURN RTRIM(LTRIM(@result));


END
GO
/****** Object:  Table [dbo].[cliente_parametro]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cliente_parametro](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[id_cliente] [int] NOT NULL,
	[id_parametro] [int] NOT NULL,
	[valor1_menor] [float] NULL,
	[valor1_mayor] [float] NULL,
	[valor2_menor] [float] NULL,
	[valor2_mayor] [float] NULL,
	[valor0_menor] [float] NULL,
	[valor0_mayor] [float] NULL,
 CONSTRAINT [PK_cliente_parametro] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_calculateJaroWinkler]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_calculateJaroWinkler](@str1 VARCHAR(MAX), @str2 VARCHAR(MAX)) 
RETURNS float As 
BEGIN
	DECLARE @jaro_distance			FLOAT
	DECLARE @jaro_winkler_distance	FLOAT
	DECLARE @prefixLength			INT
	DECLARE @prefixScaleFactor		FLOAT

	SET		@prefixScaleFactor	= 0.1 --Constant = .1

	SET		@jaro_distance	= dbo.fn_calculateJaro(@str1, @str2)	
	SET		@prefixLength	= dbo.fn_calculatePrefixLength(@str1, @str2)

	SET		@jaro_winkler_distance = @jaro_distance + ((@prefixLength * @prefixScaleFactor) * (1.0 - @jaro_distance))
	RETURN	@jaro_winkler_distance
END
GO
/****** Object:  UserDefinedFunction [dbo].[NormalizaNombre]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[NormalizaNombre]
(
	@vnombre varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result varchar(max);

	SET @result = @vnombre;
	SET @result = UPPER(@result);
	
	SET @result =   dbo.EliminaAcentos(
						dbo.EliminaDobleBlanco(
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+ @result+' '
							,' DEL ',' ')+' '
							,'.',' ')+' '
							,' DE ',' ')+' '
							,' Y ',' ')+' '
							,' LA ',' ')+' '
							,'-',' ')+' '
							,' LAS ',' ')+' '
							,' LOS ',' ')+' '
							,'(',' ')+' '
							,')',' ')+' '
							,',',' ')+' '
							,' EL ',' ')+' '
							,' LO ',' ')+' '
						)
					);
	
	SET @result =   dbo.EliminaAcentos(
						dbo.EliminaDobleBlanco(
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+
							REPLACE(' '+ @result +' '
							,' DEL ',' ')+' '
							,' DE ',' ')+' '
							,' Y ',' ')+' '
							,' LA ',' ')+' '
							,' LAS ',' ')+' '
							,' LOS ',' ')+' '
							,'(',' ')+' '
							,')',' ')+' '
							,',',' ')+' '
							,'-',' ')+' '
							,' EL ',' ')+' '
							,' LO ',' ')+' '
						)
					);
					
	SET @result =  REPLACE(@result ,'-',' ');
					


	RETURN dbo.LimpiaCadena(@result);

END
GO
/****** Object:  StoredProcedure [dbo].[spGetUsuario]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spGetUsuario]
	-- Add the parameters for the stored procedure here
	@username varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
	  usuario.id_usuario,
	  id_cliente,
	  usuario,
	  usuario.password,
	  fuente,
	  metodo 
	FROM
	  usuario 
	  LEFT JOIN usuario_fuente 
		ON (
		  usuario_fuente.id_usuario = usuario.id_usuario
		) 
	  LEFT JOIN fuentes 
		ON (
		  usuario_fuente.id_fuente = fuentes.id_fuente
		) 
	  LEFT JOIN usuario_metodo 
		ON (
		  usuario_metodo.id_usuario = usuario.id_usuario
		) 
	  LEFT JOIN metodos 
		ON (
		  usuario_metodo.id_metodo = metodos.id_metodo
		) 
	WHERE usuario = @username 

END
GO
/****** Object:  StoredProcedure [dbo].[spGetFuentesUsuario]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spGetFuentesUsuario] 
	@id_usuario int
AS
BEGIN
	DECLARE @permisos int;
	
	SELECT @permisos = SUM(valor)
	FROM usuario_fuente
	JOIN fuentes ON (fuentes.id_fuente = usuario_fuente.id_fuente)
	where usuario_fuente.id_usuario = @id_usuario
	group by id_usuario
	
	return @permisos;
END
GO
/****** Object:  UserDefinedFunction [dbo].[SimilitudCodigoPostal]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[SimilitudCodigoPostal]
(
	@cp1 varchar(4000),
	@cp2 varchar(4000)
)
RETURNS int
AS
BEGIN
	declare @i int, @len int;
	declare @counter int
	
	IF(@cp1 IS NULL OR @cp2 IS NULL) RETURN 0;
	
	RETURN dbo.SimilitudCadenas(@cp1, @cp2);


	set @i = LEN(@cp1)
	set @len = @i;
	set @counter = 0

	while @i > 0
	begin
	   if SUBSTRING(@cp1, @i, 1) <> SUBSTRING(@cp2, @i, 1)
	   begin 
	   set @counter = @counter + 1
	   end
	   set @i = @i - 1
	end
	
	DECLARE @res INT;
	
	IF(@len > 0)
		SET @res =  (@len - @counter) * 100 / @len;
	ELSE 
		SET @res =  0;
		
	RETURN @res;

END
GO
/****** Object:  StoredProcedure [dbo].[spTransformaPresalidas]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spTransformaPresalidas]
	@id_peticion int, @id_usuario int
AS
BEGIN
	
	SET NOCOUNT ON;
	
	

	SELECT parametro.nombre,  cliente_parametro.*
	INTO #parameters
	FROM usuario
	JOIN cliente ON (usuario.id_cliente = cliente.id_cliente)
	JOIN cliente_parametro ON (cliente_parametro.id_cliente =  cliente.id_cliente)
	JOIN parametro ON (parametro.id_parametro = cliente_parametro.id_parametro)
	WHERE parametro.activo = 1
	AND id_usuario = @id_usuario
	
	
	
	SELECT 
	   [id_pre_salida]
      ,[id_peticion]
      ,[request_id]
      ,[error]
      ,[persona_validada]
      ,[direccion_validada]
      ,CASE 
			WHEN [telefono_validado] <= (SELECT valor1_menor from #parameters WHERE nombre = 'telefono_match') AND [telefono_validado] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'telefono_match')  THEN 1
			WHEN [telefono_validado] <= (SELECT valor2_menor from #parameters WHERE nombre = 'telefono_match') AND [telefono_validado] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'telefono_match')  THEN 2
			WHEN [telefono_validado] <= (SELECT valor0_menor from #parameters WHERE nombre = 'telefono_match') AND [telefono_validado] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'telefono_match')  THEN 0
			ELSE 0
			END
			AS [telefono_validado]
      ,CASE 
			WHEN [dni_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'nif_match') AND [dni_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'nif_match')  THEN 1
			WHEN [dni_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'nif_match') AND [dni_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'nif_match')  THEN 2
			WHEN [dni_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'nif_match') AND [dni_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'nif_match')  THEN 0
			ELSE 0
			END
		AS [dni_similitud]
      , CASE 
			WHEN [nomcom_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'nomcom_match') AND [nomcom_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'nomcom_match')  THEN 1
			WHEN [nomcom_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'nomcom_match') AND [nomcom_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'nomcom_match')  THEN 2
			WHEN [nomcom_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'nomcom_match') AND [nomcom_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'nomcom_match')  THEN 0
			ELSE 0
			END 
		AS [nomcom_similitud]
      ,
      CASE 
			WHEN [nombre_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'nombre_match') AND [nombre_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'nombre_match')  THEN 1
			WHEN [nombre_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'nombre_match') AND [nombre_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'nombre_match')  THEN 2
			WHEN [nombre_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'nombre_match') AND [nombre_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'nombre_match')  THEN 0
			ELSE 0
			END 
		AS [nombre_similitud]
      ,CASE 
			WHEN [apellido1_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'apellido1_match') AND [apellido1_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'apellido1_match')  THEN 1
			WHEN [apellido1_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'apellido1_match') AND [apellido1_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'apellido1_match')  THEN 2
			WHEN [apellido1_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'apellido1_match') AND [apellido1_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'apellido1_match')  THEN 0
			ELSE 0
			END 
		AS [apellido1_similitud]
      ,CASE 
			WHEN [apellido2_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'apellido2_match') AND [apellido2_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'apellido2_match')  THEN 1
			WHEN [apellido2_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'apellido2_match') AND [apellido2_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'apellido2_match')  THEN 2
			WHEN [apellido2_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'apellido2_match') AND [apellido2_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'apellido2_match')  THEN 0
			ELSE 0
			END 
		AS [apellido2_similitud]
      ,CASE 
			WHEN [fecnac_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'fnac_match') AND [fecnac_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'fnac_match')  THEN 1
			WHEN [fecnac_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'fnac_match') AND [fecnac_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'fnac_match')  THEN 2
			WHEN [fecnac_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'fnac_match') AND [fecnac_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'fnac_match')  THEN 0
			ELSE 0
			END 
		AS [fecnac_similitud]
      ,CASE 
			WHEN [provincia_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'provincia_match') AND [provincia_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'provincia_match')  THEN 1
			WHEN [provincia_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'provincia_match') AND [provincia_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'provincia_match')  THEN 2
			WHEN [provincia_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'provincia_match') AND [provincia_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'provincia_match')  THEN 0
			ELSE 0
			END 
		AS [provincia_similitud]
      ,CASE 
			WHEN [poblacion_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'poblacion_match') AND [poblacion_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'poblacion_match')  THEN 1
			WHEN [poblacion_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'poblacion_match') AND [poblacion_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'poblacion_match')  THEN 2
			WHEN [poblacion_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'poblacion_match') AND [poblacion_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'poblacion_match')  THEN 0
			ELSE 0
			END 
		AS [poblacion_similitud]
      ,CASE 
			WHEN [cp_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'cp_match') AND [cp_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'cp_match')  THEN 1
			WHEN [cp_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'cp_match') AND [cp_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'cp_match')  THEN 2
			WHEN [cp_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'cp_match') AND [cp_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'cp_match')  THEN 0
			ELSE 0
			END 
		AS [cp_similitud]
      ,CASE 
			WHEN [via_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'via_match') AND [via_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'via_match')  THEN 1
			WHEN [via_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'via_match') AND [via_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'via_match')  THEN 2
			WHEN [via_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'via_match') AND [via_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'via_match')  THEN 0
			ELSE 0
			END 
		AS [via_similitud]
      ,CASE 
			WHEN [numero_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'numero_match') AND [numero_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'numero_match')  THEN 1
			WHEN [numero_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'numero_match') AND [numero_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'numero_match')  THEN 2
			WHEN [numero_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'numero_match') AND [numero_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'numero_match')  THEN 0
			ELSE 0
			END 
		AS [numero_similitud]
      ,[fuente]
	
	FROM pre_salida where id_peticion = @id_peticion
	
	
	--SELECT * FROM pre_salida where id_peticion = @id_peticion;
END
GO
/****** Object:  StoredProcedure [dbo].[spConsolidaYTransforma]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spConsolidaYTransforma]
	-- Add the parameters for the stored procedure here
	 @id_peticion int, @id_usuario int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
	SELECT parametro.nombre,  cliente_parametro.*
	INTO #parameters
	FROM usuario
	JOIN cliente ON (usuario.id_cliente = cliente.id_cliente)
	JOIN cliente_parametro ON (cliente_parametro.id_cliente =  cliente.id_cliente)
	JOIN parametro ON (parametro.id_parametro = cliente_parametro.id_parametro)
	WHERE parametro.activo = 1
	AND id_usuario = @id_usuario
	
	create table  #salida_consolidada  (
		id_peticion int  ,
		request_id varchar(30) ,
		error int,
		persona_validada int ,
		telefono_validado int ,
		dni_similitud  int,
		nomcom_similitud  int,
		nombre_similitud  int,
		apellido1_similitud  int,
		apellido2_similitud  int,
		fecnac_similitud int ,
		provincia_similitud  int,
		poblacion_similitud  int,
		cp_similitud  int,
		via_similitud int ,
		numero_similitud  int,
		fuente int
	);
	
	INSERT INTO #salida_consolidada EXEC spConsolidaPresalidas @id_peticion;
	 
	
	SELECT 
	   [id_peticion]
      ,[request_id]
      ,[error]
      ,[persona_validada]
      ,CASE 
			WHEN [telefono_validado] <= (SELECT valor1_menor from #parameters WHERE nombre = 'telefono_match') AND [telefono_validado] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'telefono_match')  THEN 1
			WHEN [telefono_validado] <= (SELECT valor2_menor from #parameters WHERE nombre = 'telefono_match') AND [telefono_validado] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'telefono_match')  THEN 2
			WHEN [telefono_validado] <= (SELECT valor0_menor from #parameters WHERE nombre = 'telefono_match') AND [telefono_validado] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'telefono_match')  THEN 0
			ELSE 0
			END
			AS [telefono_validado]
      ,CASE 
			WHEN [dni_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'nif_match') AND [dni_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'nif_match')  THEN 1
			WHEN [dni_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'nif_match') AND [dni_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'nif_match')  THEN 2
			WHEN [dni_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'nif_match') AND [dni_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'nif_match')  THEN 0
			ELSE 0
			END
		AS [dni_similitud]
      , CASE 
			WHEN [nomcom_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'nomcom_match') AND [nomcom_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'nomcom_match')  THEN 1
			WHEN [nomcom_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'nomcom_match') AND [nomcom_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'nomcom_match')  THEN 2
			WHEN [nomcom_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'nomcom_match') AND [nomcom_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'nomcom_match')  THEN 0
			ELSE 0
			END 
		AS [nomcom_similitud]
      ,
      CASE 
			WHEN [nombre_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'nombre_match') AND [nombre_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'nombre_match')  THEN 1
			WHEN [nombre_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'nombre_match') AND [nombre_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'nombre_match')  THEN 2
			WHEN [nombre_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'nombre_match') AND [nombre_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'nombre_match')  THEN 0
			ELSE 0
			END 
		AS [nombre_similitud]
      ,CASE 
			WHEN [apellido1_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'apellido1_match') AND [apellido1_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'apellido1_match')  THEN 1
			WHEN [apellido1_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'apellido1_match') AND [apellido1_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'apellido1_match')  THEN 2
			WHEN [apellido1_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'apellido1_match') AND [apellido1_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'apellido1_match')  THEN 0
			ELSE 0
			END 
		AS [apellido1_similitud]
      ,CASE 
			WHEN [apellido2_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'apellido2_match') AND [apellido2_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'apellido2_match')  THEN 1
			WHEN [apellido2_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'apellido2_match') AND [apellido2_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'apellido2_match')  THEN 2
			WHEN [apellido2_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'apellido2_match') AND [apellido2_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'apellido2_match')  THEN 0
			ELSE 0
			END 
		AS [apellido2_similitud]
      ,CASE 
			WHEN [fecnac_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'fnac_match') AND [fecnac_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'fnac_match')  THEN 1
			WHEN [fecnac_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'fnac_match') AND [fecnac_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'fnac_match')  THEN 2
			WHEN [fecnac_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'fnac_match') AND [fecnac_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'fnac_match')  THEN 0
			ELSE 0
			END 
		AS [fecnac_similitud]
      ,CASE 
			WHEN [provincia_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'provincia_match') AND [provincia_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'provincia_match')  THEN 1
			WHEN [provincia_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'provincia_match') AND [provincia_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'provincia_match')  THEN 2
			WHEN [provincia_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'provincia_match') AND [provincia_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'provincia_match')  THEN 0
			ELSE 0
			END 
		AS [provincia_similitud]
      ,CASE 
			WHEN [poblacion_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'poblacion_match') AND [poblacion_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'poblacion_match')  THEN 1
			WHEN [poblacion_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'poblacion_match') AND [poblacion_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'poblacion_match')  THEN 2
			WHEN [poblacion_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'poblacion_match') AND [poblacion_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'poblacion_match')  THEN 0
			ELSE 0
			END 
		AS [poblacion_similitud]
      ,CASE 
			WHEN [cp_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'cp_match') AND [cp_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'cp_match')  THEN 1
			WHEN [cp_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'cp_match') AND [cp_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'cp_match')  THEN 2
			WHEN [cp_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'cp_match') AND [cp_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'cp_match')  THEN 0
			ELSE 0
			END 
		AS [cp_similitud]
      ,CASE 
			WHEN [via_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'via_match') AND [via_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'via_match')  THEN 1
			WHEN [via_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'via_match') AND [via_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'via_match')  THEN 2
			WHEN [via_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'via_match') AND [via_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'via_match')  THEN 0
			ELSE 0
			END 
		AS [via_similitud]
      ,CASE 
			WHEN [numero_similitud] <= (SELECT valor1_menor from #parameters WHERE nombre = 'numero_match') AND [numero_similitud] >= (SELECT valor1_mayor from #parameters WHERE nombre = 'numero_match')  THEN 1
			WHEN [numero_similitud] <= (SELECT valor2_menor from #parameters WHERE nombre = 'numero_match') AND [numero_similitud] >= (SELECT valor2_mayor from #parameters WHERE nombre = 'numero_match')  THEN 2
			WHEN [numero_similitud] <= (SELECT valor0_menor from #parameters WHERE nombre = 'numero_match') AND [numero_similitud] >= (SELECT valor0_mayor from #parameters WHERE nombre = 'numero_match')  THEN 0
			ELSE 0
			END 
		AS [numero_similitud]
      ,[fuente]
	
	FROM #salida_consolidada

    
END
GO
/****** Object:  StoredProcedure [dbo].[spInsertaPresalida]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spInsertaPresalida]
	@id_peticion int, @id_persona varchar(max),@persona_validada INT,  @fuente INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	DECLARE
		@request_id varchar(max),
		@dni_similitud int,
		@nomcom_similitud int,
		@nombre_similitud int,
		@apellido1_similitud int,
		@apellido2_similitud int,
		@fecnac_similitud int,
		@poblacion_similitud int,
		@provincia_similitud int,
		@cp_similitud int,
		@via_similitud int, 
		@numero_similitud int,
		@telefono_encontrado int
		;
		
	SELECT @request_id = request_id FROM peticion WHERE id_peticion = @id_peticion;
	
	-- =============================================
	-- Busqueda de DNI
	-- =============================================
	PRINT 'Se busca DNI persona';
		
	SELECT 
		@dni_similitud = MAX(dbo.SimilitudNIF(p.dni, ws.NIF))
	FROM peticion p
	JOIN WS_PERSONAS ws ON (WS.ID_PERSONA = @id_persona)
	WHERE id_peticion = @id_peticion
	GROUP BY id_peticion;
	
	
	-- =================================================
	-- Busqueda de nombre completo y fecha de nacimiento
	-- =================================================
	
	PRINT 'Se busca los nombres y las fechas de nacimiento';
	SELECT 
		 @nomcom_similitud    =  MAX(dbo.SimilitudCadenas(p.nomcom_norm, ws.NOMCOM_LIMPIO)) 
		,@nombre_similitud    =  MAX(dbo.SimilitudCadenas(p.nombre, ws.NOMBRE))
		,@apellido1_similitud =  MAX(dbo.SimilitudCadenas(p.apellido1, ws.APE1)) 
		,@apellido2_similitud =  MAX(dbo.SimilitudCadenas(p.apellido2, ws.APE2))
		,@fecnac_similitud    =  MAX(dbo.SimilitudFechas(CONVERT(VARCHAR(10), p.fecha_nacimiento, 105), ws.DIA + '-' + ws.MES + '-' + ws.ANNO))
	FROM peticion p
	JOIN  WS_NOMBRES ws ON (ID_PERSONA = @id_persona)
	WHERE id_peticion = @id_peticion
	AND 
		(
			F1 = NULLIF(CONVERT(BIT,@fuente &  1), 0) OR 
			F2 = NULLIF(CONVERT(BIT,@fuente &  2), 0) OR 
			F3 = NULLIF(CONVERT(BIT,@fuente &  4), 0) OR
			F4 = NULLIF(CONVERT(BIT,@fuente &  8), 0) OR 
			F5 = NULLIF(CONVERT(BIT,@fuente & 16), 0) OR 
			F6 = NULLIF(CONVERT(BIT,@fuente & 32), 0)
		)
	GROUP BY id_peticion;
	
	
	-- =============================================
	-- Busqueda de Direcciones 
	-- =============================================
	
	PRINT 'Se busca las direcciones';
	SELECT 
	
		 @poblacion_similitud = MAX(dbo.SimilitudCadenas(p.problacion_norm, d.POPLACION_LIMPIA))
		,@provincia_similitud = MAX(dbo.SimilitudCadenas(p.provincia_norm, d.PROVINCIA_LIMPIA))
		,@cp_similitud        = MAX(dbo.SimilitudCodigoPostal(p.codigo_postal, d.CP))
		,@via_similitud       = MAX(dbo.SimilitudCadenas(p.via_norm, d.VIA_LIMPIA)) 
		,@numero_similitud    = MAX(dbo.SimilitudCadenas(p.numero, d.NUMERO_LIMPIO))
	FROM peticion p
	JOIN  WS_DIRECCIONES d ON (ID_PERSONA = @id_persona)
	WHERE id_peticion = @id_peticion
	AND 
		(
			F1 = NULLIF(CONVERT(BIT,@fuente &  1), 0) OR 
			F2 = NULLIF(CONVERT(BIT,@fuente &  2), 0) OR 
			F3 = NULLIF(CONVERT(BIT,@fuente &  4), 0) OR
			F4 = NULLIF(CONVERT(BIT,@fuente &  8), 0) OR 
			F5 = NULLIF(CONVERT(BIT,@fuente & 16), 0) OR 
			F6 = NULLIF(CONVERT(BIT,@fuente & 32), 0)
		)
	GROUP BY id_peticion;
	
	
	
	-- =============================================
	-- Busqueda de teléfonos
	-- =============================================
	PRINT 'Se busca telefonos';
	SELECT 
		 @telefono_encontrado = MAX(CASE WHEN p.telefono = t.TELEFONO THEN 1 ELSE 0 END) 
	FROM peticion p
	JOIN  WS_TELEFONOS t ON (ID_PERSONA = @id_persona)
	WHERE id_peticion = @id_peticion
	AND 
		(
			F1 = NULLIF(CONVERT(BIT,@fuente &  1), 0) OR 
			F2 = NULLIF(CONVERT(BIT,@fuente &  2), 0) OR 
			F3 = NULLIF(CONVERT(BIT,@fuente &  4), 0) OR
			F4 = NULLIF(CONVERT(BIT,@fuente &  8), 0) OR 
			F5 = NULLIF(CONVERT(BIT,@fuente & 16), 0) OR 
			F6 = NULLIF(CONVERT(BIT,@fuente & 32), 0)
		)
	GROUP BY id_peticion;
	
	-- =============================================
	-- Se comprueba si la direccion de la peticion es correcta
	-- =============================================
	DECLARE @direccion_validada int;
	
	SET @direccion_validada = 0;
	
	IF(@provincia_similitud = 100 AND @poblacion_similitud = 100 AND @cp_similitud = 100)
	BEGIN
		IF(@via_similitud = 100 AND @numero_similitud = 100)
			BEGIN
			SET @direccion_validada = 1;
			END
		ELSE
		BEGIN
			SET @direccion_validada = 2;
		END
	END
	
	
	-- =============================================
	-- Se obtiene el ID de la fuente que se está utilizando
	-- =============================================
	DECLARE @varfuente varchar(max);
	DECLARE @source_id int;
	
	SELECT @source_id = id_fuente FROM fuentes WHERE valor = @fuente;
	
	
	-- =============================================
	-- Si no se ha encontrado ningun campo no se inserta nada
	-- =============================================
	IF(	@nomcom_similitud IS NULL
		AND @nombre_similitud IS NULL
		AND @apellido1_similitud IS NULL
		AND @apellido2_similitud IS NULL
		AND @fecnac_similitud IS NULL
		AND @provincia_similitud IS NULL
		AND @poblacion_similitud IS NULL
		AND @cp_similitud IS NULL
		AND @via_similitud IS NULL
		AND @numero_similitud IS NULL)
	BEGIN
		RETURN;
	END				
	
	
	-- =============================================
	-- Se crea la presalida de la fuente
	-- =============================================
	
	INSERT INTO pre_salida
           ([id_peticion]
		   ,[request_id]
           ,[error]
           ,[persona_validada]
           ,[direccion_validada]
           ,[telefono_validado]
           ,[dni_similitud]
           ,[nomcom_similitud]
           ,[nombre_similitud]
           ,[apellido1_similitud]
           ,[apellido2_similitud]
           ,[fecnac_similitud]
           ,[provincia_similitud]
           ,[poblacion_similitud]
           ,[cp_similitud]
           ,[via_similitud]
           ,[numero_similitud]
           ,[fuente])
     VALUES
           (@id_peticion
           ,@request_id
           ,0
           ,@persona_validada
           ,@direccion_validada
           ,@telefono_encontrado
           ,@dni_similitud
           ,@nomcom_similitud
           ,@nombre_similitud
           ,@apellido1_similitud
           ,@apellido2_similitud
           ,@fecnac_similitud
           ,@provincia_similitud
           ,@poblacion_similitud
           ,@cp_similitud
           ,@via_similitud
           ,@numero_similitud
           ,@source_id);	

END
GO
/****** Object:  StoredProcedure [dbo].[spBuscaIdPersona]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spBuscaIdPersona]
	-- Add the parameters for the stored procedure here
	@id_persona VARCHAR(MAX) OUTPUT, @persona_validada int OUTPUT, @id_usuario int, @dni varchar(max), @fecha_nacimiento VARCHAR(MAX), @nomcom_norm varchar(max), @comnom_norm varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ANNO VARCHAR(MAX), @MES VARCHAR(MAX), @DIA VARCHAR(MAX);
	
	SELECT @ANNO = SUBSTRING(@fecha_nacimiento, 1, 4), @MES = SUBSTRING(@fecha_nacimiento, 6, 2), @DIA = SUBSTRING(@fecha_nacimiento, 9, 2);
	SET @persona_validada = 0;
	
	DECLARE @permisos int;
	EXEC @permisos = spGetFuentesUsuario @id_usuario;
	
	IF(@dni <> '00000000Z')
	BEGIN
		PRINT 'DNI distinto de vacio';
		
			SELECT @id_persona = ID_PERSONA, @persona_validada = 1 FROM WS_PERSONAS WHERE NIF = @dni;
		
		
		IF(@id_persona IS NULL) 
		BEGIN
			
			PRINT 'No se encuentra por DNI. Se intenta por Nombre+Apellidos y Fecha';
			SELECT TOP 1 @id_persona = ID_PERSONA , @persona_validada = 2
			FROM WS_NOMBRES 
			WHERE NOMCOM_LIMPIO = @nomcom_norm
			AND ANNO = @ANNO AND MES = @MES AND DIA = @DIA
			AND 
			(
				F1 = NULLIF(CONVERT(BIT,@permisos &  1), 0) OR 
				F2 = NULLIF(CONVERT(BIT,@permisos &  2), 0) OR 
				F3 = NULLIF(CONVERT(BIT,@permisos &  4), 0) OR
				F4 = NULLIF(CONVERT(BIT,@permisos &  8), 0) OR 
				F5 = NULLIF(CONVERT(BIT,@permisos & 16), 0) OR 
				F6 = NULLIF(CONVERT(BIT,@permisos & 32), 0)
			)
			;
		END
		
		IF(@id_persona IS NULL) 
		BEGIN
			PRINT 'No se encuentra por DNI. Se intenta por Apellidos+Nombre y Fecha';
			SELECT TOP 1 @id_persona = ID_PERSONA , @persona_validada = 2
			FROM WS_NOMBRES 
			WHERE COMNOM_LIMPIO = @comnom_norm
			AND ANNO = @ANNO AND MES = @MES AND DIA = @DIA
			AND 
			(
				F1 = NULLIF(CONVERT(BIT,@permisos &  1), 0) OR 
				F2 = NULLIF(CONVERT(BIT,@permisos &  2), 0) OR 
				F3 = NULLIF(CONVERT(BIT,@permisos &  4), 0) OR
				F4 = NULLIF(CONVERT(BIT,@permisos &  8), 0) OR 
				F5 = NULLIF(CONVERT(BIT,@permisos & 16), 0) OR 
				F6 = NULLIF(CONVERT(BIT,@permisos & 32), 0)
			)
			;
		END
	END
	ELSE IF(@nomcom_norm IS NOT NULL AND @ANNO IS NOT NULL AND @MES IS NOT NULL AND @DIA IS NOT NULL)
		BEGIN
			SELECT TOP 1 @id_persona = ID_PERSONA , @persona_validada = 2
			FROM WS_NOMBRES 
			WHERE NOMCOM_LIMPIO = @nomcom_norm
			AND ANNO = @ANNO AND MES = @MES AND DIA = @DIA
			AND 
			(
				F1 = NULLIF(CONVERT(BIT,@permisos &  1), 0) OR 
				F2 = NULLIF(CONVERT(BIT,@permisos &  2), 0) OR 
				F3 = NULLIF(CONVERT(BIT,@permisos &  4), 0) OR
				F4 = NULLIF(CONVERT(BIT,@permisos &  8), 0) OR 
				F5 = NULLIF(CONVERT(BIT,@permisos & 16), 0) OR 
				F6 = NULLIF(CONVERT(BIT,@permisos & 32), 0)
			)
			;
			
		END
	ELSE IF(@comnom_norm IS NOT NULL AND @ANNO IS NOT NULL AND @MES IS NOT NULL AND @DIA IS NOT NULL)
		BEGIN
			SELECT TOP 1 @id_persona = ID_PERSONA , @persona_validada = 2
			FROM WS_NOMBRES 
			WHERE COMNOM_LIMPIO = @comnom_norm
			AND ANNO = @ANNO AND MES = @MES AND DIA = @DIA
			AND 
			(
				F1 = NULLIF(CONVERT(BIT,@permisos &  1), 0) OR 
				F2 = NULLIF(CONVERT(BIT,@permisos &  2), 0) OR 
				F3 = NULLIF(CONVERT(BIT,@permisos &  4), 0) OR
				F4 = NULLIF(CONVERT(BIT,@permisos &  8), 0) OR 
				F5 = NULLIF(CONVERT(BIT,@permisos & 16), 0) OR 
				F6 = NULLIF(CONVERT(BIT,@permisos & 32), 0)
			)
			;
		END
		
		IF(@id_persona IS NULL)
		BEGIN
			SET @persona_validada = 0;
		END
		

		--RETURN  @id_persona
	
END
GO
/****** Object:  StoredProcedure [dbo].[spGeneraPeticion]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spGeneraPeticion]
	@request_id varchar(max),
	@dni  varchar(max) = '00000000Z',
	@nombre varchar(max),
	@tipoNombre varchar(max),
	@apellido1 varchar(max),
	@apellido2 varchar(max),
	@fechaNacimiento date,
	@provincia varchar(max),
	@poblacion varchar(max),
	@codigoPostal varchar(max),
	@via varchar(max),
	@numero varchar(max),
	@telefono varchar(max),
	@ip varchar(max),
	@usuario int,
	@id_peticion INT = NULL OUTPUT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @nomcom_norm varchar(max);
	DECLARE @comnom_norm varchar(max);
	
	SELECT @nomcom_norm = 
		CASE @tipoNombre 
			WHEN '1' THEN dbo.NormalizaNombre(@nombre + ' ' + @apellido1 + ' ' + @apellido2)
			WHEN '2' THEN dbo.NormalizaNombre(@nombre)
			ELSE NULL
		END
		
	
	SELECT @comnom_norm = 
		CASE @tipoNombre 
			WHEN '1' THEN dbo.NormalizaNombre(@apellido1 + ' ' + @apellido2 + ' ' + @nombre) 
			WHEN '3' THEN dbo.NormalizaNombre(@nombre)
			ELSE NULL
		END

	INSERT INTO [LOCALIZACION_WS].[dbo].[peticion]
           ([request_id] 
           ,[ip]
           ,[fecha]
           ,[dni]
           ,[nombre]
           ,[tipo_nombre]
           ,[apellido1]
           ,[apellido2]
           ,[fecha_nacimiento]
           ,[provincia]
           ,[poblacion]
           ,[codigo_postal]
           ,[via]
           ,[numero]
           ,[telefono]
           ,[id_usuario]
           ,[nomcom_norm]
           ,[comnom_norm]
           ,[provincia_norm]
           ,[problacion_norm]
           ,[via_norm]
           )
     VALUES
           (@request_id
           ,@ip	
           ,GETDATE()
           ,RTRIM(LTRIM(@dni)) 
           ,RTRIM(LTRIM(@nombre)) 
           ,@tipoNombre 
           ,RTRIM(LTRIM(@apellido1)) 
           ,RTRIM(LTRIM(@apellido2)) 
           ,@fechaNacimiento 
           ,@provincia 
           ,@poblacion 
           ,RTRIM(LTRIM(@codigoPostal)) 
           ,@via 
           ,@numero 
           ,RTRIM(LTRIM(@telefono)) 
           ,@usuario
           ,@nomcom_norm
           ,@comnom_norm
           ,dbo.LimpiaDireccion(@provincia)
           ,dbo.LimpiaDireccion(@poblacion)
           ,dbo.LimpiaDireccion(@via)
           );
           
    SET @id_peticion = SCOPE_IDENTITY();

	
	--SELECT * FROM peticion WHERE id_peticion = @id_peticion;
END
GO
/****** Object:  StoredProcedure [dbo].[spCreaPresalidas]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spCreaPresalidas]
	@id_peticion int
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE 
		@permisos		  int, 
		@id_usuario		  int,
		@id_persona		  VARCHAR(MAX),
		@dni			  VARCHAR(MAX),
		@fecha_nacimiento VARCHAR(MAX) ,
		@nomcom_norm	  VARCHAR(MAX),
		@comnom_norm	  VARCHAR(MAX),
		@id_presalida	  int,
		@persona_validada int,
		@request_id       VARCHAR(MAX)
		
		;
    
    --Se obtiene:
    --		usuario ha hecho la peticion para poder obtener sus permisos
    --		DNI
    --		fecha_nacimiento, 
    --		nombre_completo normalizado (nombre + apellidos),
    --		nombre completo (apellidos + nombre) normalizado
    SELECT 
		@id_usuario = id_usuario, 
		@dni = dni, 
		@fecha_nacimiento = CONVERT(VARCHAR, fecha_nacimiento), 
		@nomcom_norm = nomcom_norm, 
		@comnom_norm = comnom_norm,
		@request_id = request_id
	FROM peticion 
	WHERE id_peticion = @id_peticion;
    
    -- =============================================
	-- Se obttiene los permisos de fuentes del usuario
	-- =============================================
  
	EXEC @permisos = spGetFuentesUsuario @id_usuario;
	
	PRINT 'Permisos: ' + convert(varchar, @permisos);
	
	
	-- =================================================================================
	-- Se busca el ID de la persona	por DNI o por nombre completo y fecha de nacimiento
	-- =================================================================================
	
	EXEC  spBuscaIdPersona @id_persona output,@persona_validada OUTPUT, @id_usuario, @dni, @fecha_nacimiento, @nomcom_norm, @comnom_norm;
	
	print @id_persona;
	
	
	-- ====================================================================================
	-- Si no se encuentra se inserta en presalidad un registro con `persona_validadad` = -1
	-- ====================================================================================
	IF(@id_persona IS NULL)
	BEGIN
		INSERT INTO pre_salida 
		(id_peticion,  request_id,  error, persona_validada, direccion_validada, telefono_validado) VALUES 
		(@id_peticion, @request_id, 0,    0,	            -1,                  -1)
		
		SELECT * FROM pre_salida WHERE id_peticion = @id_peticion;
		RETURN;
	END
	
	
	
	-- =================================================================================
	-- Se obtienen todas las fuentes existentes. Por cada fuente, se comprueba si el 
	-- usuario tiene permisos para dicha fuente y si los tiene inserta un regustro 
	-- en presalida para esa fuente.
	-- =================================================================================
	DECLARE @fuente INT;
	DECLARE FUENTES_CURSOR CURSOR FOR SELECT valor FROM fuentes;
	
	OPEN FUENTES_CURSOR;  
	
	FETCH NEXT FROM FUENTES_CURSOR  
	INTO @fuente;  
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		IF (@permisos & @fuente <> 0)
		BEGIN
			EXEC spInsertaPresalida @id_peticion, @id_persona, @persona_validada, @fuente;
		END
	  
	   FETCH NEXT FROM FUENTES_CURSOR  
		INTO @fuente; 
	END  
	  
	CLOSE FUENTES_CURSOR;  
	DEALLOCATE FUENTES_CURSOR;  
	
	
	-- =================================================================================
	-- Devuelve todas las presalidas para la petición
	-- =================================================================================
	--SELECT * FROM pre_salida WHERE id_peticion = @id_peticion;
	RETURN;
    
END
GO
/****** Object:  StoredProcedure [dbo].[spLocaliza]    Script Date: 06/20/2016 17:42:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spLocaliza]
	@username varchar(max),
	@password varchar(max),
	@request_id varchar(max),
	@dni varchar(max),
	@nombre varchar(max),
	@tipoNombre varchar(max) = '1',
	@apellido1 varchar(max),
	@apellido2 varchar(max),
	@fechaNacimiento date,
	@provincia varchar(max),
	@poblacion varchar(max),
	@codigoPostal varchar(max),
	@via varchar(max),
	@numero varchar(max),
	@telefono varchar(max),
	@ip varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @loginSuccess int, @id_peticion int, @id_usuario int;

	
	EXEC @loginSuccess = spLogin @username, @password, @id_usuario OUTPUT;
	
	EXEC spGeneraPeticion 
		@request_id, @dni, @nombre, @tipoNombre, @apellidO1, @apellido2, @fechaNacimiento, 
		@provincia, @poblacion, @codigoPostal, @via, @numero, @telefono, @ip, @id_usuario, @id_peticion OUTPUT;
		

	--Login CORRECTO
	IF(@loginSuccess = 1 AND @id_usuario IS NOT NULL)
		BEGIN
			EXEC spCreaPresalidas @id_peticion;
		END
	ELSE
		BEGIN
			--LOGIN ERRONEO
			--Error = 1 //Usuario o password incorrecto
			INSERT INTO pre_salida (id_peticion, error, request_id) VALUES (@id_peticion, 1, @request_id);
			
			SELECT * FROM pre_salida WHERE id_peticion = @id_peticion;
			RETURN;
		
		END
	
	DECLARE @consolidar BIT, @transformar BIT;
	
	SELECT @consolidar = consolidar, @transformar = transformar
	FROM usuario
	JOIN cliente ON (cliente.id_cliente = usuario.id_cliente)
	WHERE id_usuario = @id_usuario;
	
	
	
	IF(@consolidar = 1 AND @transformar = 1)
		BEGIN
			--Primero consolida y luego transforma
			--TODO: HAY QUE JUGAR CON TABLAS TEMPORALES
			EXEC spConsolidaYTransforma @id_peticion, @id_usuario;
			RETURN;
			
		END
	ELSE IF (@consolidar = 1)
		BEGIN 
			EXEC spConsolidaPresalidas @id_peticion;
			RETURN;
		END
	ELSE IF (@transformar = 1)
		BEGIN 
			EXEC spTransformaPresalidas @id_peticion, @id_usuario;
			RETURN;
		END
	ELSE
		BEGIN 
			SELECT * FROM pre_salida WHERE id_peticion = @id_peticion;
			RETURN;
		END
	
END
GO
/****** Object:  ForeignKey [FK_usuario_fuente_fuentes]    Script Date: 06/20/2016 17:42:37 ******/
ALTER TABLE [dbo].[usuario_fuente]  WITH CHECK ADD  CONSTRAINT [FK_usuario_fuente_fuentes] FOREIGN KEY([id_fuente])
REFERENCES [dbo].[fuentes] ([id_fuente])
GO
ALTER TABLE [dbo].[usuario_fuente] CHECK CONSTRAINT [FK_usuario_fuente_fuentes]
GO
/****** Object:  ForeignKey [FK_usuario_fuente_usuario]    Script Date: 06/20/2016 17:42:37 ******/
ALTER TABLE [dbo].[usuario_fuente]  WITH CHECK ADD  CONSTRAINT [FK_usuario_fuente_usuario] FOREIGN KEY([id_usuario])
REFERENCES [dbo].[usuario] ([id_usuario])
GO
ALTER TABLE [dbo].[usuario_fuente] CHECK CONSTRAINT [FK_usuario_fuente_usuario]
GO
/****** Object:  ForeignKey [FK_peticion_usuario]    Script Date: 06/20/2016 17:42:37 ******/
ALTER TABLE [dbo].[peticion]  WITH CHECK ADD  CONSTRAINT [FK_peticion_usuario] FOREIGN KEY([id_usuario])
REFERENCES [dbo].[usuario] ([id_usuario])
GO
ALTER TABLE [dbo].[peticion] CHECK CONSTRAINT [FK_peticion_usuario]
GO
/****** Object:  ForeignKey [FK_cliente_parametro_cliente_parametro]    Script Date: 06/20/2016 17:42:37 ******/
ALTER TABLE [dbo].[cliente_parametro]  WITH CHECK ADD  CONSTRAINT [FK_cliente_parametro_cliente_parametro] FOREIGN KEY([id_cliente])
REFERENCES [dbo].[cliente] ([id_cliente])
GO
ALTER TABLE [dbo].[cliente_parametro] CHECK CONSTRAINT [FK_cliente_parametro_cliente_parametro]
GO
/****** Object:  ForeignKey [FK_cliente_parametro_parametro]    Script Date: 06/20/2016 17:42:37 ******/
ALTER TABLE [dbo].[cliente_parametro]  WITH CHECK ADD  CONSTRAINT [FK_cliente_parametro_parametro] FOREIGN KEY([id_parametro])
REFERENCES [dbo].[parametro] ([id_parametro])
GO
ALTER TABLE [dbo].[cliente_parametro] CHECK CONSTRAINT [FK_cliente_parametro_parametro]
GO
