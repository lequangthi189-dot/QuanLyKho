CREATE DATABASE QuanLyKho_A7;
GO

USE QuanLyKho_A7;
GO

-- 1. Bảng dữ liệu

CREATE TABLE Category
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(255) NULL
);

CREATE TABLE Supplier
(
    SupplierID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName NVARCHAR(150) NOT NULL UNIQUE,
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NULL,
    Address NVARCHAR(200) NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Warehouse
(
    WarehouseID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseName NVARCHAR(100) NOT NULL UNIQUE,
    Address NVARCHAR(200) NOT NULL,
    Capacity INT NOT NULL CHECK (Capacity > 0)
);

CREATE TABLE Employee
(
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Position NVARCHAR(50) NOT NULL,
    Phone VARCHAR(15) NOT NULL UNIQUE,
    WarehouseID INT NOT NULL,
    CONSTRAINT FK_Employee_Warehouse
        FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

CREATE TABLE Product
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(150) NOT NULL UNIQUE,
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    Unit NVARCHAR(20) NOT NULL,
    MinStockThreshold INT NOT NULL DEFAULT 10
        CHECK (MinStockThreshold >= 0),
    CONSTRAINT FK_Product_Category
        FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
    CONSTRAINT FK_Product_Supplier
        FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

CREATE TABLE Batch
(
    BatchID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    ManufactureDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    ImportPrice DECIMAL(18,2) NOT NULL CHECK (ImportPrice > 0),
    CONSTRAINT CK_Batch_Date
        CHECK (ExpiryDate > ManufactureDate),
    CONSTRAINT FK_Batch_Product
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

CREATE TABLE Inventory
(
    BatchID INT NOT NULL,
    WarehouseID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 0 CHECK (Quantity >= 0),
    CONSTRAINT PK_Inventory
        PRIMARY KEY (BatchID, WarehouseID),
    CONSTRAINT FK_Inventory_Batch
        FOREIGN KEY (BatchID) REFERENCES Batch(BatchID),
    CONSTRAINT FK_Inventory_Warehouse
        FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

CREATE TABLE ImportReceipt
(
    ImportReceiptID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID INT NOT NULL,
    EmployeeID INT NOT NULL,
    WarehouseID INT NOT NULL,
    ImportDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ImportReceipt_Supplier
        FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID),
    CONSTRAINT FK_ImportReceipt_Employee
        FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
    CONSTRAINT FK_ImportReceipt_Warehouse
        FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

CREATE TABLE ImportDetail
(
    ImportReceiptID INT NOT NULL,
    BatchID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    CONSTRAINT PK_ImportDetail
        PRIMARY KEY (ImportReceiptID, BatchID),
    CONSTRAINT FK_ImportDetail_Receipt
        FOREIGN KEY (ImportReceiptID)
        REFERENCES ImportReceipt(ImportReceiptID),
    CONSTRAINT FK_ImportDetail_Batch
        FOREIGN KEY (BatchID) REFERENCES Batch(BatchID)
);

CREATE TABLE ExportReceipt
(
    ExportReceiptID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseID INT NOT NULL,
    EmployeeID INT NOT NULL,
    ExportDate DATETIME NOT NULL DEFAULT GETDATE(),
    Purpose NVARCHAR(200) NULL,
    CONSTRAINT FK_ExportReceipt_Warehouse
        FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID),
    CONSTRAINT FK_ExportReceipt_Employee
        FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

CREATE TABLE ExportDetail
(
    ExportReceiptID INT NOT NULL,
    BatchID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    CONSTRAINT PK_ExportDetail
        PRIMARY KEY (ExportReceiptID, BatchID),
    CONSTRAINT FK_ExportDetail_Receipt
        FOREIGN KEY (ExportReceiptID)
        REFERENCES ExportReceipt(ExportReceiptID),
    CONSTRAINT FK_ExportDetail_Batch
        FOREIGN KEY (BatchID) REFERENCES Batch(BatchID)
);

CREATE TABLE StockAlert
(
    AlertID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    WarehouseID INT NOT NULL,
    AlertDate DATETIME NOT NULL DEFAULT GETDATE(),
    CurrentQty INT NOT NULL,
    Threshold INT NOT NULL,
    Message NVARCHAR(255) NOT NULL,
    CONSTRAINT FK_StockAlert_Product
        FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    CONSTRAINT FK_StockAlert_Warehouse
        FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

-- 2. Dữ liệu mẫu

INSERT INTO Category(CategoryName, Description) VALUES
(N'Thực phẩm khô', N'Gạo, mì và thực phẩm đóng gói'),
(N'Đồ uống', N'Nước suối, nước ngọt và bia'),
(N'Hóa mỹ phẩm', N'Dầu gội, sữa tắm và xà phòng'),
(N'Văn phòng phẩm', N'Giấy, bút và tập'),
(N'Điện gia dụng', N'Quạt, nồi cơm và bàn ủi'),
(N'Bánh kẹo', N'Bánh, kẹo và đồ ăn nhẹ'),
(N'Gia vị', N'Nước mắm, dầu ăn và đường'),
(N'Đồ đông lạnh', N'Xúc xích và thực phẩm đông lạnh'),
(N'Sữa và sản phẩm sữa', N'Sữa hộp và sữa chua'),
(N'Đồ dùng gia đình', N'Sản phẩm vệ sinh gia đình');

INSERT INTO Supplier(SupplierName, Phone, Email, Address) VALUES
(N'Công ty TNHH Minh Phát', '0901111222', 'minhphat@gmail.com', N'Quận 1, TP.HCM'),
(N'Công ty CP Đại Nam', '0902222333', 'dainam@gmail.com', N'Quận 7, TP.HCM'),
(N'Công ty TNHH Hòa Bình', '0903333444', 'hoabinh@gmail.com', N'Bình Dương'),
(N'Công ty CP Việt Thái', '0904444555', 'vietthai@gmail.com', N'Đồng Nai'),
(N'DNTN Tân Tiến', '0905555666', 'tantien@gmail.com', N'Quận 5, TP.HCM'),
(N'Công ty TNHH Phú Cường', '0906666777', 'phucuong@gmail.com', N'Tân Bình, TP.HCM'),
(N'Công ty CP Sài Gòn Food', '0907777888', 'sgfood@gmail.com', N'Quận 12, TP.HCM'),
(N'Công ty TNHH An Khang', '0908888999', 'ankhang@gmail.com', N'Dĩ An, Bình Dương'),
(N'Công ty CP Thành Đạt', '0909999000', 'thanhdat@gmail.com', N'Bình Thạnh, TP.HCM'),
(N'DNTN Hồng Phúc', '0910000111', 'hongphuc@gmail.com', N'Long An'),
(N'Công ty TNHH An Việt', '0911111000', 'anviet@gmail.com', N'Thủ Đức, TP.HCM'),
(N'Công ty CP Thành Công', '0912222000', 'thanhcong@gmail.com', N'Quận 10, TP.HCM');

INSERT INTO Warehouse(WarehouseName, Address, Capacity) VALUES
(N'Kho Trung Tâm', N'Quận 10, TP.HCM', 5000),
(N'Kho Bình Chánh', N'Huyện Bình Chánh, TP.HCM', 4000),
(N'Kho Thủ Đức', N'TP. Thủ Đức, TP.HCM', 4500),
(N'Kho Tân Bình', N'Quận Tân Bình, TP.HCM', 3500),
(N'Kho Bình Dương', N'Dĩ An, Bình Dương', 5000);

INSERT INTO Employee(FullName, Position, Phone, WarehouseID) VALUES
(N'Lê Quang Thi', N'Thủ kho', '0911111111', 1),
(N'Nguyễn Văn An', N'Nhân viên nhập hàng', '0922222222', 1),
(N'Trần Thị Bích', N'Thủ kho', '0933333333', 2),
(N'Phạm Văn Cường', N'Nhân viên xuất hàng', '0944444444', 2),
(N'Võ Thị Diễm', N'Thủ kho', '0955555555', 3),
(N'Đặng Văn Em', N'Nhân viên nhập hàng', '0966666666', 3),
(N'Bùi Thị Phượng', N'Thủ kho', '0977777777', 4),
(N'Hoàng Văn Giang', N'Nhân viên xuất hàng', '0988888888', 4),
(N'Ngô Thị Hoa', N'Thủ kho', '0999999999', 5),
(N'Lý Văn Inh', N'Nhân viên nhập hàng', '0912121212', 5),
(N'Dương Thị Kim', N'Nhân viên xuất hàng', '0913131313', 1),
(N'Trịnh Văn Long', N'Nhân viên kiểm kê', '0914141414', 3),
(N'Nguyễn Thị Mai', N'Nhân viên nhập hàng', '0915151515', 2),
(N'Phan Văn Nam', N'Nhân viên xuất hàng', '0916161616', 5),
(N'Tạ Thị Oanh', N'Nhân viên kiểm kê', '0917171717', 4);

INSERT INTO Product
(ProductName, CategoryID, SupplierID, Unit, MinStockThreshold) VALUES
(N'Gạo ST25 5kg', 1, 1, N'Bao', 50),
(N'Mì Hảo Hảo thùng 30 gói', 1, 2, N'Thùng', 30),
(N'Cá ngừ đóng hộp 3 lon', 1, 5, N'Lốc', 40),
(N'Nước suối Aquafina 500ml', 2, 3, N'Thùng', 40),
(N'Coca-Cola lon thùng 24', 2, 2, N'Thùng', 40),
(N'Bia Tiger thùng 24', 2, 7, N'Thùng', 35),
(N'Dầu gội Clear 650ml', 3, 4, N'Chai', 20),
(N'Sữa tắm Lifebuoy 850ml', 3, 4, N'Chai', 20),
(N'Xà phòng Lifebuoy lốc 3', 3, 6, N'Lốc', 30),
(N'Giấy A4 Double A', 4, 1, N'Ram', 60),
(N'Bút bi Thiên Long hộp 20', 4, 9, N'Hộp', 25),
(N'Tập 200 trang lốc 10', 4, 9, N'Lốc', 30),
(N'Quạt điện Senko 16 inch', 5, 3, N'Cái', 15),
(N'Nồi cơm điện Sharp 1.8L', 5, 8, N'Cái', 10),
(N'Bàn ủi Panasonic', 5, 8, N'Cái', 12),
(N'Bánh Oreo thùng', 6, 6, N'Thùng', 25),
(N'Snack Oishi thùng', 6, 7, N'Thùng', 30),
(N'Kẹo Alpenliebe bịch', 6, 6, N'Bịch', 40),
(N'Nước mắm Nam Ngư 750ml', 7, 5, N'Chai', 35),
(N'Dầu ăn Tường An 1L', 7, 5, N'Chai', 35),
(N'Đường Biên Hòa 1kg', 7, 10, N'Bao', 40),
(N'Xúc xích Đức Việt', 8, 7, N'Gói', 30),
(N'Chả giò hải sản', 8, 7, N'Gói', 25),
(N'Sữa tươi Vinamilk thùng 48', 9, 11, N'Thùng', 30),
(N'Sữa chua Vinamilk lốc 4', 9, 11, N'Lốc', 30),
(N'Nước rửa chén Sunlight 750ml', 10, 12, N'Chai', 25),
(N'Nước lau sàn Sunlight 1L', 10, 12, N'Chai', 20),
(N'Khăn giấy Pulppy', 10, 9, N'Bịch', 30),
(N'Bột giặt OMO 3kg', 10, 4, N'Túi', 20),
(N'Nước xả Comfort 3L', 10, 4, N'Túi', 20);

DECLARE @i INT = 1;

WHILE @i <= 40
BEGIN
    INSERT INTO Batch(ProductID, ManufactureDate, ExpiryDate, ImportPrice)
    VALUES
    (
        ((@i - 1) % 30) + 1,
        DATEADD(DAY, -(@i * 10 + 60), CAST(GETDATE() AS DATE)),
        CASE
            WHEN @i <= 3 THEN DATEADD(DAY, -@i, CAST(GETDATE() AS DATE))
            WHEN @i <= 8 THEN DATEADD(DAY, @i * 3, CAST(GETDATE() AS DATE))
            ELSE DATEADD(DAY, 365 + @i, CAST(GETDATE() AS DATE))
        END,
        20000 + @i * 5000
    );

    SET @i = @i + 1;
END;

SET @i = 1;

WHILE @i <= 30
BEGIN
    INSERT INTO ImportReceipt
    (SupplierID, EmployeeID, WarehouseID, ImportDate)
    VALUES
    (
        ((@i - 1) % 12) + 1,
        ((@i - 1) % 15) + 1,
        ((@i - 1) % 5) + 1,
        DATEADD(DAY, -(@i * 5), GETDATE())
    );

    SET @i = @i + 1;
END;

SET @i = 1;

WHILE @i <= 40
BEGIN
    INSERT INTO ImportDetail(ImportReceiptID, BatchID, Quantity)
    VALUES
    (
        ((@i - 1) % 30) + 1,
        @i,
        50 + (@i % 30)
    );

    SET @i = @i + 1;
END;

INSERT INTO ImportDetail(ImportReceiptID, BatchID, Quantity)
VALUES (13, 1, 20);

SET @i = 1;

WHILE @i <= 30
BEGIN
    INSERT INTO ExportReceipt
    (WarehouseID, EmployeeID, ExportDate, Purpose)
    VALUES
    (
        ((@i - 1) % 5) + 1,
        ((@i + 4) % 15) + 1,
        DATEADD(DAY, -(@i * 2), GETDATE()),
        N'Xuất hàng theo yêu cầu số ' + CAST(@i AS NVARCHAR(10))
    );

    SET @i = @i + 1;
END;

SET @i = 1;

WHILE @i <= 40
BEGIN
    INSERT INTO ExportDetail(ExportReceiptID, BatchID, Quantity)
    VALUES
    (
        ((@i - 1) % 30) + 1,
        @i,
        5 + (@i % 10)
    );

    SET @i = @i + 1;
END;

WITH TongNhap AS
(
    SELECT
        id.BatchID,
        ir.WarehouseID,
        SUM(id.Quantity) AS SoLuongNhap
    FROM ImportDetail id
    JOIN ImportReceipt ir
        ON id.ImportReceiptID = ir.ImportReceiptID
    GROUP BY id.BatchID, ir.WarehouseID
),
TongXuat AS
(
    SELECT
        ed.BatchID,
        er.WarehouseID,
        SUM(ed.Quantity) AS SoLuongXuat
    FROM ExportDetail ed
    JOIN ExportReceipt er
        ON ed.ExportReceiptID = er.ExportReceiptID
    GROUP BY ed.BatchID, er.WarehouseID
)
INSERT INTO Inventory(BatchID, WarehouseID, Quantity)
SELECT
    tn.BatchID,
    tn.WarehouseID,
    tn.SoLuongNhap - ISNULL(tx.SoLuongXuat, 0)
FROM TongNhap tn
LEFT JOIN TongXuat tx
    ON tn.BatchID = tx.BatchID
   AND tn.WarehouseID = tx.WarehouseID;

-- 3. Chỉ mục

CREATE INDEX IX_Product_CategoryID
ON Product(CategoryID);

CREATE INDEX IX_Product_SupplierID
ON Product(SupplierID);

CREATE INDEX IX_Batch_ProductID
ON Batch(ProductID);

CREATE INDEX IX_Batch_ExpiryDate
ON Batch(ExpiryDate);

CREATE INDEX IX_Inventory_WarehouseID
ON Inventory(WarehouseID);

CREATE INDEX IX_ImportReceipt_ImportDate
ON ImportReceipt(ImportDate);

CREATE INDEX IX_ExportReceipt_ExportDate
ON ExportReceipt(ExportDate);

CREATE INDEX IX_ImportDetail_BatchID
ON ImportDetail(BatchID);

CREATE INDEX IX_ExportDetail_BatchID
ON ExportDetail(BatchID);
GO

-- 4. View

CREATE VIEW V_TonKhoHienTai
AS
SELECT
    w.WarehouseID,
    w.WarehouseName,
    p.ProductID,
    p.ProductName,
    b.BatchID,
    b.ExpiryDate,
    i.Quantity,
    p.MinStockThreshold,
    b.ImportPrice
FROM Inventory i
JOIN Batch b ON i.BatchID = b.BatchID
JOIN Product p ON b.ProductID = p.ProductID
JOIN Warehouse w ON i.WarehouseID = w.WarehouseID;
GO

CREATE VIEW V_LoHangSapHetHan
AS
SELECT
    p.ProductID,
    p.ProductName,
    b.BatchID,
    b.ExpiryDate,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), b.ExpiryDate) AS SoNgayConLai
FROM Batch b
JOIN Product p ON b.ProductID = p.ProductID
WHERE DATEDIFF(DAY, CAST(GETDATE() AS DATE), b.ExpiryDate)
      BETWEEN 0 AND 30;
GO

CREATE VIEW V_BaoCaoNhapXuatTon
AS
SELECT
    p.ProductID,
    p.ProductName,
    ISNULL
    (
        (
            SELECT SUM(id.Quantity)
            FROM ImportDetail id
            JOIN Batch b1 ON id.BatchID = b1.BatchID
            WHERE b1.ProductID = p.ProductID
        ),
        0
    ) AS TongNhap,
    ISNULL
    (
        (
            SELECT SUM(ed.Quantity)
            FROM ExportDetail ed
            JOIN Batch b2 ON ed.BatchID = b2.BatchID
            WHERE b2.ProductID = p.ProductID
        ),
        0
    ) AS TongXuat,
    ISNULL
    (
        (
            SELECT SUM(i.Quantity)
            FROM Inventory i
            JOIN Batch b3 ON i.BatchID = b3.BatchID
            WHERE b3.ProductID = p.ProductID
        ),
        0
    ) AS TonHienTai
FROM Product p;
GO

CREATE VIEW V_GiaTriTonTheoKho
AS
SELECT
    w.WarehouseID,
    w.WarehouseName,
    SUM(i.Quantity * b.ImportPrice) AS GiaTriTonKho
FROM Inventory i
JOIN Batch b ON i.BatchID = b.BatchID
JOIN Warehouse w ON i.WarehouseID = w.WarehouseID
GROUP BY w.WarehouseID, w.WarehouseName;
GO

CREATE VIEW V_LichSuNhapXuat
AS
SELECT
    id.BatchID,
    N'Nhập' AS LoaiGiaoDich,
    ir.ImportDate AS NgayGiaoDich,
    ir.WarehouseID,
    id.Quantity
FROM ImportDetail id
JOIN ImportReceipt ir
    ON id.ImportReceiptID = ir.ImportReceiptID

UNION ALL

SELECT
    ed.BatchID,
    N'Xuất',
    er.ExportDate,
    er.WarehouseID,
    ed.Quantity
FROM ExportDetail ed
JOIN ExportReceipt er
    ON ed.ExportReceiptID = er.ExportReceiptID;
GO

-- 5. Stored Procedure

CREATE PROCEDURE SP_ThemNhaCungCap
    @SupplierName NVARCHAR(150),
    @Phone VARCHAR(15),
    @Email VARCHAR(100),
    @Address NVARCHAR(200)
AS
BEGIN
    BEGIN TRY
        IF EXISTS
        (
            SELECT 1
            FROM Supplier
            WHERE SupplierName = @SupplierName
        )
            THROW 50001, N'Nhà cung cấp đã tồn tại.', 1;

        INSERT INTO Supplier(SupplierName, Phone, Email, Address)
        VALUES (@SupplierName, @Phone, @Email, @Address);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_ThemSanPham
    @ProductName NVARCHAR(150),
    @CategoryID INT,
    @SupplierID INT,
    @Unit NVARCHAR(20),
    @MinStockThreshold INT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM Category
            WHERE CategoryID = @CategoryID
        )
            THROW 50002, N'Loại hàng không tồn tại.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Supplier
            WHERE SupplierID = @SupplierID
              AND IsActive = 1
        )
            THROW 50003, N'Nhà cung cấp không tồn tại.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Product
            WHERE ProductName = @ProductName
        )
            THROW 50004, N'Sản phẩm đã tồn tại.', 1;

        INSERT INTO Product
        (ProductName, CategoryID, SupplierID, Unit, MinStockThreshold)
        VALUES
        (@ProductName, @CategoryID, @SupplierID, @Unit, @MinStockThreshold);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_TimSanPham
    @TuKhoa NVARCHAR(150)
AS
BEGIN
    BEGIN TRY
        IF EXISTS
        (
            SELECT 1
            FROM Product
            WHERE ProductName LIKE N'%' + @TuKhoa + N'%'
        )
        BEGIN
            SELECT
                p.ProductID,
                p.ProductName,
                c.CategoryName,
                s.SupplierName,
                p.Unit,
                p.MinStockThreshold
            FROM Product p
            JOIN Category c ON p.CategoryID = c.CategoryID
            JOIN Supplier s ON p.SupplierID = s.SupplierID
            WHERE p.ProductName LIKE N'%' + @TuKhoa + N'%';
        END
        ELSE
            RAISERROR(N'Không tìm thấy sản phẩm.', 16, 1);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_CapNhatNguongTon
    @ProductID INT,
    @MinStockThreshold INT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM Product
            WHERE ProductID = @ProductID
        )
            THROW 50005, N'Sản phẩm không tồn tại.', 1;

        IF @MinStockThreshold < 0
            THROW 50006, N'Ngưỡng tồn không được âm.', 1;

        UPDATE Product
        SET MinStockThreshold = @MinStockThreshold
        WHERE ProductID = @ProductID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_LayTongTonKho
    @ProductID INT,
    @WarehouseID INT,
    @TongTon INT OUTPUT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM Product
            WHERE ProductID = @ProductID
        )
        BEGIN
            SET @TongTon = 0;
            RETURN 1;
        END

        IF NOT EXISTS
        (
            SELECT 1
            FROM Warehouse
            WHERE WarehouseID = @WarehouseID
        )
        BEGIN
            SET @TongTon = 0;
            RETURN 2;
        END

        SELECT @TongTon = ISNULL(SUM(i.Quantity), 0)
        FROM Inventory i
        JOIN Batch b ON i.BatchID = b.BatchID
        WHERE b.ProductID = @ProductID
          AND i.WarehouseID = @WarehouseID;

        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @TongTon = 0;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_TinhGiaTriTonKho
    @WarehouseID INT,
    @TongGiaTri DECIMAL(18,2) OUTPUT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS
        (
            SELECT 1
            FROM Warehouse
            WHERE WarehouseID = @WarehouseID
        )
        BEGIN
            SET @TongGiaTri = 0;
            RETURN 1;
        END

        SELECT @TongGiaTri =
            ISNULL(SUM(i.Quantity * b.ImportPrice), 0)
        FROM Inventory i
        JOIN Batch b ON i.BatchID = b.BatchID
        WHERE i.WarehouseID = @WarehouseID;

        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @TongGiaTri = 0;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_BaoCaoNhapXuatTon_Temp
    @TuKhoa NVARCHAR(150) = NULL
AS
BEGIN
    BEGIN TRY
        SELECT
            ProductID,
            ProductName,
            TongNhap,
            TongXuat,
            TonHienTai
        INTO #BaoCao
        FROM V_BaoCaoNhapXuatTon
        WHERE @TuKhoa IS NULL
           OR ProductName LIKE N'%' + @TuKhoa + N'%';

        SELECT *
        FROM #BaoCao
        ORDER BY ProductName;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_ThongKeLoSapHetHan_Temp
    @SoNgay INT = 30
AS
BEGIN
    BEGIN TRY
        SELECT
            p.ProductName,
            b.BatchID,
            b.ExpiryDate,
            DATEDIFF(DAY, GETDATE(), b.ExpiryDate) AS SoNgayConLai
        INTO #LoSapHetHan
        FROM Batch b
        JOIN Product p ON b.ProductID = p.ProductID
        WHERE DATEDIFF(DAY, GETDATE(), b.ExpiryDate)
              BETWEEN 0 AND @SoNgay;

        SELECT *
        FROM #LoSapHetHan
        ORDER BY SoNgayConLai;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_KiemTraLoHetHan_Cursor
AS
BEGIN
    BEGIN TRY
        DECLARE @BatchID INT;
        DECLARE @ProductName NVARCHAR(150);
        DECLARE @ExpiryDate DATE;

        DECLARE cur_LoHetHan CURSOR LOCAL FAST_FORWARD FOR
            SELECT b.BatchID, p.ProductName, b.ExpiryDate
            FROM Batch b
            JOIN Product p ON b.ProductID = p.ProductID
            WHERE b.ExpiryDate < CAST(GETDATE() AS DATE);

        CREATE TABLE #KetQua
        (
            BatchID INT,
            ProductName NVARCHAR(150),
            ExpiryDate DATE
        );

        OPEN cur_LoHetHan;

        FETCH NEXT FROM cur_LoHetHan
        INTO @BatchID, @ProductName, @ExpiryDate;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO #KetQua
            VALUES (@BatchID, @ProductName, @ExpiryDate);

            FETCH NEXT FROM cur_LoHetHan
            INTO @BatchID, @ProductName, @ExpiryDate;
        END

        CLOSE cur_LoHetHan;
        DEALLOCATE cur_LoHetHan;

        SELECT *
        FROM #KetQua
        ORDER BY ExpiryDate;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur_LoHetHan') >= 0
            CLOSE cur_LoHetHan;

        IF CURSOR_STATUS('local', 'cur_LoHetHan') >= -1
            DEALLOCATE cur_LoHetHan;

        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_NhapKho
    @SupplierID INT,
    @EmployeeID INT,
    @WarehouseID INT,
    @ProductID INT,
    @ManufactureDate DATE,
    @ExpiryDate DATE,
    @Quantity INT,
    @ImportPrice DECIMAL(18,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Quantity <= 0
            THROW 50007, N'Số lượng nhập phải lớn hơn 0.', 1;

        IF @ExpiryDate <= @ManufactureDate
            THROW 50008, N'Hạn sử dụng phải sau ngày sản xuất.', 1;

        IF @ImportPrice <= 0
            THROW 50009, N'Giá nhập phải lớn hơn 0.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Product
            WHERE ProductID = @ProductID
              AND SupplierID = @SupplierID
        )
            THROW 50010, N'Sản phẩm hoặc nhà cung cấp không hợp lệ.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employee
            WHERE EmployeeID = @EmployeeID
        )
            THROW 50011, N'Nhân viên không tồn tại.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Warehouse
            WHERE WarehouseID = @WarehouseID
        )
            THROW 50012, N'Kho không tồn tại.', 1;

        INSERT INTO Batch
        (ProductID, ManufactureDate, ExpiryDate, ImportPrice)
        VALUES
        (@ProductID, @ManufactureDate, @ExpiryDate, @ImportPrice);

        DECLARE @BatchID INT;
        SET @BatchID = SCOPE_IDENTITY();

        INSERT INTO ImportReceipt
        (SupplierID, EmployeeID, WarehouseID, ImportDate)
        VALUES
        (@SupplierID, @EmployeeID, @WarehouseID, GETDATE());

        DECLARE @ImportReceiptID INT;
        SET @ImportReceiptID = SCOPE_IDENTITY();

        INSERT INTO ImportDetail
        (ImportReceiptID, BatchID, Quantity)
        VALUES
        (@ImportReceiptID, @BatchID, @Quantity);

        COMMIT TRANSACTION;

        SELECT
            @ImportReceiptID AS ImportReceiptID,
            @BatchID AS BatchID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_XuatKho
    @WarehouseID INT,
    @EmployeeID INT,
    @BatchID INT,
    @Quantity INT,
    @Purpose NVARCHAR(200)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Quantity <= 0
            THROW 50013, N'Số lượng xuất phải lớn hơn 0.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employee
            WHERE EmployeeID = @EmployeeID
        )
            THROW 50014, N'Nhân viên không tồn tại.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Batch
            WHERE BatchID = @BatchID
        )
            THROW 50015, N'Lô hàng không tồn tại.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM Batch
            WHERE BatchID = @BatchID
              AND ExpiryDate < CAST(GETDATE() AS DATE)
        )
            THROW 50016, N'Không được xuất lô đã hết hạn.', 1;

        DECLARE @TonHienTai INT;

        SELECT @TonHienTai = Quantity
        FROM Inventory
        WHERE BatchID = @BatchID
          AND WarehouseID = @WarehouseID;

        IF @TonHienTai IS NULL OR @TonHienTai < @Quantity
            THROW 50017, N'Số lượng tồn không đủ.', 1;

        INSERT INTO ExportReceipt
        (WarehouseID, EmployeeID, ExportDate, Purpose)
        VALUES
        (@WarehouseID, @EmployeeID, GETDATE(), @Purpose);

        DECLARE @ExportReceiptID INT;
        SET @ExportReceiptID = SCOPE_IDENTITY();

        INSERT INTO ExportDetail
        (ExportReceiptID, BatchID, Quantity)
        VALUES
        (@ExportReceiptID, @BatchID, @Quantity);

        COMMIT TRANSACTION;

        SELECT @ExportReceiptID AS ExportReceiptID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE SP_KiemTraNguongTon
AS
BEGIN
    BEGIN TRY
        INSERT INTO StockAlert
        (ProductID, WarehouseID, CurrentQty, Threshold, Message)
        SELECT
            p.ProductID,
            i.WarehouseID,
            SUM(i.Quantity),
            p.MinStockThreshold,
            N'Tồn kho thấp hơn ngưỡng tối thiểu'
        FROM Inventory i
        JOIN Batch b ON i.BatchID = b.BatchID
        JOIN Product p ON b.ProductID = p.ProductID
        GROUP BY
            p.ProductID,
            i.WarehouseID,
            p.MinStockThreshold
        HAVING SUM(i.Quantity) < p.MinStockThreshold
           AND NOT EXISTS
           (
               SELECT 1
               FROM StockAlert sa
               WHERE sa.ProductID = p.ProductID
                 AND sa.WarehouseID = i.WarehouseID
                 AND CAST(sa.AlertDate AS DATE) =
                     CAST(GETDATE() AS DATE)
           );

        SELECT *
        FROM StockAlert
        WHERE CAST(AlertDate AS DATE) =
              CAST(GETDATE() AS DATE);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- 6. Trigger

CREATE TRIGGER TR_ImportDetail_AfterInsert
ON ImportDetail
AFTER INSERT
AS
BEGIN
    DECLARE @Nhap TABLE
    (
        BatchID INT,
        WarehouseID INT,
        Quantity INT
    );

    INSERT INTO @Nhap
    SELECT
        i.BatchID,
        r.WarehouseID,
        SUM(i.Quantity)
    FROM inserted i
    JOIN ImportReceipt r
        ON i.ImportReceiptID = r.ImportReceiptID
    GROUP BY i.BatchID, r.WarehouseID;

    UPDATE inv
    SET inv.Quantity = inv.Quantity + n.Quantity
    FROM Inventory inv
    JOIN @Nhap n
        ON inv.BatchID = n.BatchID
       AND inv.WarehouseID = n.WarehouseID;

    INSERT INTO Inventory(BatchID, WarehouseID, Quantity)
    SELECT n.BatchID, n.WarehouseID, n.Quantity
    FROM @Nhap n
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Inventory inv
        WHERE inv.BatchID = n.BatchID
          AND inv.WarehouseID = n.WarehouseID
    );
END;
GO

CREATE TRIGGER TR_ImportDetail_AfterUpdate
ON ImportDetail
AFTER UPDATE
AS
BEGIN
    DECLARE @ThayDoi TABLE
    (
        BatchID INT,
        WarehouseID INT,
        ChenhLech INT
    );

    INSERT INTO @ThayDoi
    SELECT
        x.BatchID,
        x.WarehouseID,
        SUM(x.ChenhLech)
    FROM
    (
        SELECT
            i.BatchID,
            r.WarehouseID,
            i.Quantity AS ChenhLech
        FROM inserted i
        JOIN ImportReceipt r
            ON i.ImportReceiptID = r.ImportReceiptID

        UNION ALL

        SELECT
            d.BatchID,
            r.WarehouseID,
            -d.Quantity
        FROM deleted d
        JOIN ImportReceipt r
            ON d.ImportReceiptID = r.ImportReceiptID
    ) x
    GROUP BY x.BatchID, x.WarehouseID;

    IF EXISTS
    (
        SELECT 1
        FROM @ThayDoi t
        LEFT JOIN Inventory inv
            ON t.BatchID = inv.BatchID
           AND t.WarehouseID = inv.WarehouseID
        WHERE ISNULL(inv.Quantity, 0) + t.ChenhLech < 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'Cập nhật làm tồn kho bị âm.', 16, 1);
        RETURN;
    END

    UPDATE inv
    SET inv.Quantity = inv.Quantity + t.ChenhLech
    FROM Inventory inv
    JOIN @ThayDoi t
        ON inv.BatchID = t.BatchID
       AND inv.WarehouseID = t.WarehouseID;

    INSERT INTO Inventory(BatchID, WarehouseID, Quantity)
    SELECT t.BatchID, t.WarehouseID, t.ChenhLech
    FROM @ThayDoi t
    WHERE t.ChenhLech > 0
      AND NOT EXISTS
      (
          SELECT 1
          FROM Inventory inv
          WHERE inv.BatchID = t.BatchID
            AND inv.WarehouseID = t.WarehouseID
      );
END;
GO

CREATE TRIGGER TR_ImportDetail_AfterDelete
ON ImportDetail
AFTER DELETE
AS
BEGIN
    DECLARE @XoaNhap TABLE
    (
        BatchID INT,
        WarehouseID INT,
        Quantity INT
    );

    INSERT INTO @XoaNhap
    SELECT
        d.BatchID,
        r.WarehouseID,
        SUM(d.Quantity)
    FROM deleted d
    JOIN ImportReceipt r
        ON d.ImportReceiptID = r.ImportReceiptID
    GROUP BY d.BatchID, r.WarehouseID;

    IF EXISTS
    (
        SELECT 1
        FROM @XoaNhap x
        LEFT JOIN Inventory inv
            ON x.BatchID = inv.BatchID
           AND x.WarehouseID = inv.WarehouseID
        WHERE inv.BatchID IS NULL
           OR inv.Quantity < x.Quantity
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'Không thể xóa vì tồn kho không đủ để hoàn tác.', 16, 1);
        RETURN;
    END

    UPDATE inv
    SET inv.Quantity = inv.Quantity - x.Quantity
    FROM Inventory inv
    JOIN @XoaNhap x
        ON inv.BatchID = x.BatchID
       AND inv.WarehouseID = x.WarehouseID;
END;
GO

CREATE TRIGGER TR_ExportDetail_AfterInsert
ON ExportDetail
AFTER INSERT
AS
BEGIN
    DECLARE @Xuat TABLE
    (
        BatchID INT,
        WarehouseID INT,
        Quantity INT
    );

    INSERT INTO @Xuat
    SELECT
        i.BatchID,
        r.WarehouseID,
        SUM(i.Quantity)
    FROM inserted i
    JOIN ExportReceipt r
        ON i.ExportReceiptID = r.ExportReceiptID
    GROUP BY i.BatchID, r.WarehouseID;

    IF EXISTS
    (
        SELECT 1
        FROM @Xuat x
        LEFT JOIN Inventory inv
            ON x.BatchID = inv.BatchID
           AND x.WarehouseID = inv.WarehouseID
        WHERE inv.BatchID IS NULL
           OR inv.Quantity < x.Quantity
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'Số lượng tồn không đủ để xuất.', 16, 1);
        RETURN;
    END

    UPDATE inv
    SET inv.Quantity = inv.Quantity - x.Quantity
    FROM Inventory inv
    JOIN @Xuat x
        ON inv.BatchID = x.BatchID
       AND inv.WarehouseID = x.WarehouseID;
END;
GO

CREATE TRIGGER TR_ExportDetail_AfterUpdate
ON ExportDetail
AFTER UPDATE
AS
BEGIN
    DECLARE @ThayDoi TABLE
    (
        BatchID INT,
        WarehouseID INT,
        ChenhLech INT
    );

    INSERT INTO @ThayDoi
    SELECT
        x.BatchID,
        x.WarehouseID,
        SUM(x.ChenhLech)
    FROM
    (
        SELECT
            d.BatchID,
            r.WarehouseID,
            d.Quantity AS ChenhLech
        FROM deleted d
        JOIN ExportReceipt r
            ON d.ExportReceiptID = r.ExportReceiptID

        UNION ALL

        SELECT
            i.BatchID,
            r.WarehouseID,
            -i.Quantity
        FROM inserted i
        JOIN ExportReceipt r
            ON i.ExportReceiptID = r.ExportReceiptID
    ) x
    GROUP BY x.BatchID, x.WarehouseID;

    IF EXISTS
    (
        SELECT 1
        FROM @ThayDoi t
        LEFT JOIN Inventory inv
            ON t.BatchID = inv.BatchID
           AND t.WarehouseID = inv.WarehouseID
        WHERE ISNULL(inv.Quantity, 0) + t.ChenhLech < 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR(N'Cập nhật làm tồn kho bị âm.', 16, 1);
        RETURN;
    END

    UPDATE inv
    SET inv.Quantity = inv.Quantity + t.ChenhLech
    FROM Inventory inv
    JOIN @ThayDoi t
        ON inv.BatchID = t.BatchID
       AND inv.WarehouseID = t.WarehouseID;

    INSERT INTO Inventory(BatchID, WarehouseID, Quantity)
    SELECT t.BatchID, t.WarehouseID, t.ChenhLech
    FROM @ThayDoi t
    WHERE t.ChenhLech > 0
      AND NOT EXISTS
      (
          SELECT 1
          FROM Inventory inv
          WHERE inv.BatchID = t.BatchID
            AND inv.WarehouseID = t.WarehouseID
      );
END;
GO

CREATE TRIGGER TR_ExportDetail_AfterDelete
ON ExportDetail
AFTER DELETE
AS
BEGIN
    DECLARE @XoaXuat TABLE
    (
        BatchID INT,
        WarehouseID INT,
        Quantity INT
    );

    INSERT INTO @XoaXuat
    SELECT
        d.BatchID,
        r.WarehouseID,
        SUM(d.Quantity)
    FROM deleted d
    JOIN ExportReceipt r
        ON d.ExportReceiptID = r.ExportReceiptID
    GROUP BY d.BatchID, r.WarehouseID;

    UPDATE inv
    SET inv.Quantity = inv.Quantity + x.Quantity
    FROM Inventory inv
    JOIN @XoaXuat x
        ON inv.BatchID = x.BatchID
       AND inv.WarehouseID = x.WarehouseID;

    INSERT INTO Inventory(BatchID, WarehouseID, Quantity)
    SELECT x.BatchID, x.WarehouseID, x.Quantity
    FROM @XoaXuat x
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Inventory inv
        WHERE inv.BatchID = x.BatchID
          AND inv.WarehouseID = x.WarehouseID
    );
END;
GO

CREATE TRIGGER TR_Inventory_AfterInsertUpdate
ON Inventory
AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO StockAlert
    (ProductID, WarehouseID, CurrentQty, Threshold, Message)
    SELECT
        p.ProductID,
        k.WarehouseID,
        k.TongTon,
        p.MinStockThreshold,
        N'Tồn kho thấp hơn ngưỡng tối thiểu'
    FROM
    (
        SELECT
            b.ProductID,
            x.WarehouseID,
            SUM(inv.Quantity) AS TongTon
        FROM
        (
            SELECT DISTINCT
                b1.ProductID,
                i.WarehouseID
            FROM inserted i
            JOIN Batch b1 ON i.BatchID = b1.BatchID
        ) x
        JOIN Batch b ON x.ProductID = b.ProductID
        JOIN Inventory inv
            ON b.BatchID = inv.BatchID
           AND x.WarehouseID = inv.WarehouseID
        GROUP BY b.ProductID, x.WarehouseID
    ) k
    JOIN Product p ON k.ProductID = p.ProductID
    WHERE k.TongTon < p.MinStockThreshold
      AND NOT EXISTS
      (
          SELECT 1
          FROM StockAlert sa
          WHERE sa.ProductID = p.ProductID
            AND sa.WarehouseID = k.WarehouseID
            AND CAST(sa.AlertDate AS DATE) =
                CAST(GETDATE() AS DATE)
      );
END;
GO

CREATE TRIGGER TR_Product_InsteadOfDelete
ON Product
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM deleted d
        JOIN Batch b ON d.ProductID = b.ProductID
    )
    BEGIN
        RAISERROR(N'Không thể xóa sản phẩm đã phát sinh lô hàng.', 16, 1);
        RETURN;
    END

    DELETE p
    FROM Product p
    JOIN deleted d ON p.ProductID = d.ProductID;
END;
GO

CREATE TRIGGER TR_Warehouse_InsteadOfDelete
ON Warehouse
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM deleted d
        LEFT JOIN Employee e
            ON d.WarehouseID = e.WarehouseID
        LEFT JOIN Inventory i
            ON d.WarehouseID = i.WarehouseID
        LEFT JOIN ImportReceipt ir
            ON d.WarehouseID = ir.WarehouseID
        LEFT JOIN ExportReceipt er
            ON d.WarehouseID = er.WarehouseID
        WHERE e.EmployeeID IS NOT NULL
           OR i.BatchID IS NOT NULL
           OR ir.ImportReceiptID IS NOT NULL
           OR er.ExportReceiptID IS NOT NULL
    )
    BEGIN
        RAISERROR(N'Không thể xóa kho đã phát sinh dữ liệu.', 16, 1);
        RETURN;
    END

    DELETE w
    FROM Warehouse w
    JOIN deleted d ON w.WarehouseID = d.WarehouseID;
END;
GO

-- 7. Truy vấn nghiệp vụ, Cursor và Demo

-- 1. Truy vấn nghiệp vụ

SELECT
    w.WarehouseName,
    p.ProductName,
    SUM(i.Quantity) AS TonTheoKho,
    p.MinStockThreshold
FROM Inventory i
JOIN Batch b ON i.BatchID = b.BatchID
JOIN Product p ON b.ProductID = p.ProductID
JOIN Warehouse w ON i.WarehouseID = w.WarehouseID
GROUP BY
    w.WarehouseName,
    p.ProductName,
    p.MinStockThreshold
HAVING SUM(i.Quantity) < p.MinStockThreshold;

SELECT *
FROM V_LoHangSapHetHan
ORDER BY SoNgayConLai;

SELECT *
FROM V_GiaTriTonTheoKho
ORDER BY GiaTriTonKho DESC;

SELECT TOP 5
    p.ProductName,
    SUM(id.Quantity) AS TongSoLuongNhap
FROM ImportDetail id
JOIN Batch b ON id.BatchID = b.BatchID
JOIN Product p ON b.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TongSoLuongNhap DESC;

SELECT *
FROM V_LichSuNhapXuat
WHERE BatchID = 1
ORDER BY NgayGiaoDich;

SELECT TOP 1
    s.SupplierName,
    ISNULL(SUM(i.Quantity), 0) AS TongTon
FROM Supplier s
LEFT JOIN Product p ON s.SupplierID = p.SupplierID
LEFT JOIN Batch b ON p.ProductID = b.ProductID
LEFT JOIN Inventory i ON b.BatchID = i.BatchID
GROUP BY s.SupplierName
ORDER BY TongTon;

-- 2. Cursor độc lập

DECLARE @BatchID INT;
DECLARE @ProductName NVARCHAR(150);
DECLARE @ExpiryDate DATE;

DECLARE @KetQuaHetHan TABLE
(
    BatchID INT,
    ProductName NVARCHAR(150),
    ExpiryDate DATE
);

DECLARE cur_ExpiredBatch CURSOR FAST_FORWARD FOR
    SELECT b.BatchID, p.ProductName, b.ExpiryDate
    FROM Batch b
    JOIN Product p ON b.ProductID = p.ProductID
    WHERE b.ExpiryDate < CAST(GETDATE() AS DATE);

OPEN cur_ExpiredBatch;

FETCH NEXT FROM cur_ExpiredBatch
INTO @BatchID, @ProductName, @ExpiryDate;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO @KetQuaHetHan
    VALUES (@BatchID, @ProductName, @ExpiryDate);

    FETCH NEXT FROM cur_ExpiredBatch
    INTO @BatchID, @ProductName, @ExpiryDate;
END

CLOSE cur_ExpiredBatch;
DEALLOCATE cur_ExpiredBatch;

SELECT *
FROM @KetQuaHetHan;

DECLARE @WarehouseID INT;
DECLARE @WarehouseName NVARCHAR(100);
DECLARE @GiaTri DECIMAL(18,2);

DECLARE @KetQuaKho TABLE
(
    WarehouseID INT,
    WarehouseName NVARCHAR(100),
    GiaTriTon DECIMAL(18,2)
);

DECLARE cur_WarehouseValue CURSOR FAST_FORWARD FOR
    SELECT WarehouseID, WarehouseName
    FROM Warehouse;

OPEN cur_WarehouseValue;

FETCH NEXT FROM cur_WarehouseValue
INTO @WarehouseID, @WarehouseName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @GiaTri = ISNULL(SUM(i.Quantity * b.ImportPrice), 0)
    FROM Inventory i
    JOIN Batch b ON i.BatchID = b.BatchID
    WHERE i.WarehouseID = @WarehouseID;

    INSERT INTO @KetQuaKho
    VALUES (@WarehouseID, @WarehouseName, @GiaTri);

    FETCH NEXT FROM cur_WarehouseValue
    INTO @WarehouseID, @WarehouseName;
END

CLOSE cur_WarehouseValue;
DEALLOCATE cur_WarehouseValue;

SELECT *
FROM @KetQuaKho;

DECLARE @ProductID INT;
DECLARE @TenSanPham NVARCHAR(150);
DECLARE @Nguong INT;
DECLARE @TongTon INT;

DECLARE @KetQuaCanhBao TABLE
(
    ProductID INT,
    ProductName NVARCHAR(150),
    TongTon INT,
    Nguong INT
);

DECLARE cur_LowStock CURSOR FAST_FORWARD FOR
    SELECT ProductID, ProductName, MinStockThreshold
    FROM Product;

OPEN cur_LowStock;

FETCH NEXT FROM cur_LowStock
INTO @ProductID, @TenSanPham, @Nguong;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @TongTon = ISNULL(SUM(i.Quantity), 0)
    FROM Inventory i
    JOIN Batch b ON i.BatchID = b.BatchID
    WHERE b.ProductID = @ProductID;

    IF @TongTon < @Nguong
        INSERT INTO @KetQuaCanhBao
        VALUES (@ProductID, @TenSanPham, @TongTon, @Nguong);

    FETCH NEXT FROM cur_LowStock
    INTO @ProductID, @TenSanPham, @Nguong;
END

CLOSE cur_LowStock;
DEALLOCATE cur_LowStock;

SELECT *
FROM @KetQuaCanhBao;

GO
