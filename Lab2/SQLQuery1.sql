USE CSW431_PhamTranGiaHung_2331200153_lab2;
GO

-- Drop database
ALTER DATABASE LibraryManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE LibraryManagementDB;
GO
CREATE DATABASE LibraryManagementDB;
GO
USE LibraryManagementDB;
GO

-- Question1


-- TPH
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    UserType NVARCHAR(50) NOT NULL,
    FullName NVARCHAR(255) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    
    -- Student 
    StudentCode NVARCHAR(50) NULL,
    Major NVARCHAR(255) NULL,
    
    -- Lecturer 
    LecturerCode NVARCHAR(50) NULL,
    Department NVARCHAR(255) NULL,
    
    CONSTRAINT CK_UserType CHECK (UserType IN ('Student', 'Lecturer'))
);

-- Books
CREATE TABLE Books (
    BookId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(500) NOT NULL,
    Author NVARCHAR(255) NOT NULL,
    ISBN NVARCHAR(50),
    TotalCopies INT NOT NULL DEFAULT 1,
    AvailableCopies INT NOT NULL DEFAULT 1,
    CONSTRAINT CK_Copies CHECK (AvailableCopies >= 0 AND AvailableCopies <= TotalCopies)
);

-- BorrowingTransactions
CREATE TABLE BorrowingTransactions (
    TransactionId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    BookId INT NOT NULL,
    BorrowDate DATETIME NOT NULL DEFAULT GETDATE(),
    DueDate DATETIME NOT NULL,
    ReturnDate DATETIME NULL,
    Status NVARCHAR(50) NOT NULL DEFAULT 'Borrowed',
    CONSTRAINT FK_Borrow_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_Borrow_Book FOREIGN KEY (BookId) REFERENCES Books(BookId)
);

-- Sample data
INSERT INTO Users (UserType, FullName, Email, StudentCode, Major)
VALUES 
    ('Student', N'Miyabi', 'a@student.com', 'SC001', N'CSE'),
    ('Student', N'Fangyi', 'b@student.com', 'SC002', N'ECE');

INSERT INTO Users (UserType, FullName, Email, LecturerCode, Department)
VALUES 
    ('Lecturer', N'Dr.Typhon', 'abc@lecturer.com', 'LC001', N'Software Engineering');

INSERT INTO Books (Title, Author, ISBN, TotalCopies, AvailableCopies)
VALUES 
    (N'Backend', N'Hypergryph', '111-001', 5, 5),
    (N'Database', N'Arknight', '111-002', 3, 3);

GO

-- question2
CREATE PROCEDURE BorrowBook
    @UserId INT,
    @BookId INT,
    @DueDate DATETIME
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @AvailableCopies INT;
        
        -- Lock availability
        SELECT @AvailableCopies = AvailableCopies
        FROM Books WITH (UPDLOCK, HOLDLOCK)
        WHERE BookId = @BookId;
        
        -- Check available
        IF @AvailableCopies IS NULL OR @AvailableCopies <= 0
        BEGIN
            ROLLBACK;
            PRINT 'Book not available';
            RETURN;
        END
        
        -- Create borrowing 
        INSERT INTO BorrowingTransactions (UserId, BookId, BorrowDate, DueDate, Status)
        VALUES (@UserId, @BookId, GETDATE(), @DueDate, 'Borrowed');
        
        -- Decrease copies
        UPDATE Books
        SET AvailableCopies = AvailableCopies - 1
        WHERE BookId = @BookId;
        
        COMMIT;
        PRINT 'Borrow successful';
    END TRY
    BEGIN CATCH
        ROLLBACK;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


-- QUESTION 3: QUERY OPTIMIZATION
-- book selection
SELECT BookId, Title, Author, AvailableCopies 
FROM Books 
WHERE Title LIKE 'Database%';

-- index for optimization
CREATE INDEX IX_Books_Title ON Books(Title);
CREATE INDEX IX_Books_Author ON Books(Author);
CREATE INDEX IX_Borrowing_UserId ON BorrowingTransactions(UserId);
CREATE INDEX IX_Borrowing_BookId ON BorrowingTransactions(BookId);



-- Test

SELECT * FROM Users;
SELECT * FROM Books;

-- Test borrow
EXEC BorrowBook @UserId = 1, @BookId = 1, @DueDate = '2026-02-01';

-- View borrow
SELECT TOP 5 * FROM vw_BorrowingStats ORDER BY BorrowCount DESC;

-- View transactions
SELECT 
    u.FullName,
    b.Title,
    bt.BorrowDate,
    bt.Status
FROM BorrowingTransactions bt
JOIN Users u ON bt.UserId = u.UserId
JOIN Books b ON bt.BookId = b.BookId;
GO