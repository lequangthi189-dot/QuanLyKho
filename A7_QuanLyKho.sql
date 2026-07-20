CREATE DATABASE QuanLyKho_A7;
USE QuanLyKho_A7;
GO

-- 1. TẠO BẢNG

-- Nhà cung cấp
CREATE TABLE Supplier (
    SupplierID    INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName  NVARCHAR(150) NOT NULL,
    Phone         VARCHAR(15)   NOT NULL,
    Email         VARCHAR(100)  NULL,
    Address       NVARCHAR(200) NULL,
    IsActive      BIT NOT NULL DEFAULT 1
);

-- Loại hàng. CategoryName UNIQUE nên cũng là một khóa dự tuyển.
CREATE TABLE Category (
    CategoryID    INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName  NVARCHAR(100) NOT NULL UNIQUE,
    Description   NVARCHAR(255) NULL
);

-- Kho hàng
CREATE TABLE Warehouse (
    WarehouseID   INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseName NVARCHAR(100) NOT NULL,
    Address       NVARCHAR(200) NOT NULL,
    Capacity      INT NOT NULL CHECK (Capacity > 0)
);

-- Nhân viên. Chỉ lưu WarehouseID, KHÔNG lưu tên kho (lưu sẽ sinh bắc cầu, hỏng 3NF).
CREATE TABLE Employee (
    EmployeeID    INT IDENTITY(1,1) PRIMARY KEY,
    FullName      NVARCHAR(100) NOT NULL,
    Position      NVARCHAR(50)  NOT NULL,
    Phone         VARCHAR(15)   NOT NULL,
    WarehouseID   INT NOT NULL,       -- kho biên chế (QĐ4)
    CONSTRAINT FK_Employee_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

-- Sản phẩm. Không lưu tên loại / tên NCC vì sẽ sinh bắc cầu, hỏng 3NF.
CREATE TABLE Product (
    ProductID         INT IDENTITY(1,1) PRIMARY KEY,
    ProductName       NVARCHAR(150) NOT NULL,
    CategoryID        INT NOT NULL,
    SupplierID        INT NOT NULL,
    Unit              NVARCHAR(20) NOT NULL,
    MinStockThreshold INT NOT NULL DEFAULT 10 CHECK (MinStockThreshold >= 0),
    CONSTRAINT FK_Product_Category FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
    CONSTRAINT FK_Product_Supplier FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

-- Lô hàng. Hạn dùng + giá ở cấp lô (QĐ2); để ở Product sẽ hỏng 1NF.
CREATE TABLE Batch (
    BatchID         INT IDENTITY(1,1) PRIMARY KEY,
    ProductID       INT NOT NULL,
    ManufactureDate DATE NOT NULL,
    ExpiryDate      DATE NOT NULL,
    ImportPrice     DECIMAL(18,2) NOT NULL CHECK (ImportPrice >= 0),
    CONSTRAINT FK_Batch_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    CONSTRAINT CK_Batch_Date CHECK (ExpiryDate > ManufactureDate)
);

-- Tồn kho. Khóa GHÉP cho 1 lô ở nhiều kho (QĐ3). Không lưu tên kho (sẽ hỏng BCNF).
CREATE TABLE Inventory (
    BatchID     INT NOT NULL,
    WarehouseID INT NOT NULL,
    Quantity    INT NOT NULL CHECK (Quantity >= 0),
    CONSTRAINT PK_Inventory PRIMARY KEY (BatchID, WarehouseID),
    CONSTRAINT FK_Inventory_Batch     FOREIGN KEY (BatchID)     REFERENCES Batch(BatchID),
    CONSTRAINT FK_Inventory_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

-- Phiếu nhập. WarehouseID = kho NHẬN hàng, khác nghĩa Employee.WarehouseID (QĐ4).
CREATE TABLE ImportReceipt (
    ImportReceiptID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID      INT NOT NULL,
    EmployeeID      INT NOT NULL,
    WarehouseID     INT NOT NULL,
    ImportDate      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Import_Supplier  FOREIGN KEY (SupplierID)  REFERENCES Supplier(SupplierID),
    CONSTRAINT FK_Import_Employee  FOREIGN KEY (EmployeeID)  REFERENCES Employee(EmployeeID),
    CONSTRAINT FK_Import_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

-- Chi tiết nhập. KHÔNG có đơn giá (giá ở Batch); để ở đây sẽ hỏng 2NF (phụ thuộc bộ phận).
CREATE TABLE ImportDetail (
    ImportReceiptID INT NOT NULL,
    BatchID         INT NOT NULL,
    Quantity        INT NOT NULL CHECK (Quantity > 0),
    CONSTRAINT PK_ImportDetail PRIMARY KEY (ImportReceiptID, BatchID),
    CONSTRAINT FK_ImpDetail_Receipt FOREIGN KEY (ImportReceiptID) REFERENCES ImportReceipt(ImportReceiptID),
    CONSTRAINT FK_ImpDetail_Batch   FOREIGN KEY (BatchID)         REFERENCES Batch(BatchID)
);

-- Phiếu xuất
CREATE TABLE ExportReceipt (
    ExportReceiptID INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseID     INT NOT NULL,
    EmployeeID      INT NOT NULL,
    ExportDate      DATETIME NOT NULL DEFAULT GETDATE(),
    Purpose         NVARCHAR(200) NULL,
    CONSTRAINT FK_Export_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID),
    CONSTRAINT FK_Export_Employee  FOREIGN KEY (EmployeeID)  REFERENCES Employee(EmployeeID)
);

-- Chi tiết xuất
CREATE TABLE ExportDetail (
    ExportReceiptID INT NOT NULL,
    BatchID         INT NOT NULL,
    Quantity        INT NOT NULL CHECK (Quantity > 0),
    CONSTRAINT PK_ExportDetail PRIMARY KEY (ExportReceiptID, BatchID),
    CONSTRAINT FK_ExpDetail_Receipt FOREIGN KEY (ExportReceiptID) REFERENCES ExportReceipt(ExportReceiptID),
    CONSTRAINT FK_ExpDetail_Batch   FOREIGN KEY (BatchID)         REFERENCES Batch(BatchID)
);

-- Log cảnh báo. CurrentQty/Threshold là snapshot lúc ghi (QĐ6), không phải dư thừa.
CREATE TABLE StockAlert (
    AlertID     INT IDENTITY(1,1) PRIMARY KEY,
    ProductID   INT NOT NULL,
    WarehouseID INT NOT NULL,
    AlertDate   DATETIME NOT NULL DEFAULT GETDATE(),
    CurrentQty  INT NOT NULL,
    Threshold   INT NOT NULL,
    Message     NVARCHAR(255) NOT NULL,
    CONSTRAINT FK_Alert_Product   FOREIGN KEY (ProductID)   REFERENCES Product(ProductID),
    CONSTRAINT FK_Alert_Warehouse FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

-- 1B. CHỈ MỤC (INDEX) - THIẾT KẾ MỨC LOGIC
-- Index trên cột JOIN hay dùng, chỉ tập tối thiểu (chi tiết: báo cáo Word).
-- PK và UNIQUE đã tự tạo index.

CREATE INDEX IX_Batch_ProductID       ON Batch(ProductID);        -- câu 1,4,6 + view báo cáo
CREATE INDEX IX_Product_SupplierID    ON Product(SupplierID);     -- câu 6 (drive từ Supplier)

CREATE INDEX IX_Inventory_WarehouseID ON Inventory(WarehouseID);  -- câu 1,3 + SP tra cứu/thống kê

CREATE INDEX IX_ImportDetail_BatchID  ON ImportDetail(BatchID);   -- câu 4,5 + view báo cáo
CREATE INDEX IX_ExportDetail_BatchID  ON ExportDetail(BatchID);   -- câu 5 + view báo cáo
-- Không đánh index cho Product.CategoryID: không truy vấn nào join theo loại hàng.

-- 2. DỮ LIỆU MẪU
-- Dòng đánh dấu <== là dữ liệu đặt chủ đích để kiểm chứng ở Phần 9.

INSERT INTO Category (CategoryName, Description) VALUES
(N'Thực phẩm khô', N'Gạo, mì, đồ hộp'),
(N'Đồ uống',       N'Nước ngọt, nước suối, bia'),
(N'Hóa mỹ phẩm',   N'Xà phòng, dầu gội, sữa tắm'),
(N'Văn phòng phẩm',N'Giấy, bút, tập'),
(N'Điện gia dụng', N'Quạt, nồi cơm, bàn ủi'),
(N'Bánh kẹo',      N'Bánh, kẹo, snack'),
(N'Gia vị',        N'Nước mắm, dầu ăn, đường'),
(N'Đồ đông lạnh',  N'Xúc xích, chả giò');

INSERT INTO Supplier (SupplierName, Phone, Email, Address) VALUES
(N'Công ty TNHH Minh Phát',  '0901111222', 'minhphat@gmail.com',  N'Quận 1, TP.HCM'),
(N'Công ty CP Đại Nam',      '0902222333', 'dainam@gmail.com',    N'Quận 7, TP.HCM'),
(N'Công ty TNHH Hòa Bình',   '0903333444', 'hoabinh@gmail.com',   N'TP. Thủ Dầu Một, Bình Dương'),
(N'Công ty CP Việt Thái',    '0904444555', 'vietthai@gmail.com',  N'Biên Hòa, Đồng Nai'),
(N'DNTN Tân Tiến',           '0905555666', 'tantien@gmail.com',   N'Quận 5, TP.HCM'),
(N'Công ty TNHH Phú Cường',  '0906666777', 'phucuong@gmail.com',  N'Quận Tân Bình, TP.HCM'),
(N'Công ty CP Sài Gòn Food', '0907777888', 'sgfood@gmail.com',    N'Quận 12, TP.HCM'),
(N'Công ty TNHH An Khang',   '0908888999', 'ankhang@gmail.com',   N'TP. Dĩ An, Bình Dương'),
(N'Công ty CP Thành Đạt',    '0909999000', 'thanhdat@gmail.com',  N'Quận Bình Thạnh, TP.HCM'),
(N'DNTN Hồng Phúc',          '0910000111', 'hongphuc@gmail.com',  N'Long An');

INSERT INTO Warehouse (WarehouseName, Address, Capacity) VALUES
(N'Kho Trung Tâm Q.10', N'Quận 10, TP.HCM',         5000),
(N'Kho Bình Chánh',     N'Huyện Bình Chánh, TP.HCM',3000),
(N'Kho Thủ Đức',        N'TP. Thủ Đức, TP.HCM',     4000),
(N'Kho Tân Bình',       N'Quận Tân Bình, TP.HCM',   3500),
(N'Kho Bình Dương',     N'TP. Dĩ An, Bình Dương',   4500);

INSERT INTO Employee (FullName, Position, Phone, WarehouseID) VALUES
(N'Lê Quang Thi',      N'Thủ kho',              '0911111111', 1),
(N'Nguyễn Văn An',     N'Nhân viên nhập hàng',  '0922222222', 1),
(N'Trần Thị Bích',     N'Thủ kho',              '0933333333', 2),
(N'Phạm Văn Cường',    N'Nhân viên xuất hàng',  '0944444444', 2),
(N'Võ Thị Diễm',       N'Thủ kho',              '0955555555', 3),
(N'Đặng Văn Em',       N'Nhân viên nhập hàng',  '0966666666', 3),
(N'Bùi Thị Phượng',    N'Thủ kho',              '0977777777', 4),
(N'Hoàng Văn Giang',   N'Nhân viên xuất hàng',  '0988888888', 4),
(N'Ngô Thị Hoa',       N'Thủ kho',              '0999999999', 5),
(N'Lý Văn Inh',        N'Nhân viên nhập hàng',  '0912121212', 5),
(N'Dương Thị Kim',     N'Nhân viên xuất hàng',  '0913131313', 1),
(N'Trịnh Văn Long',    N'Nhân viên kiểm kê',    '0914141414', 3);

INSERT INTO Product (ProductName, CategoryID, SupplierID, Unit, MinStockThreshold) VALUES
(N'Gạo ST25 5kg',                    1, 1, N'Bao',   50),
(N'Mì Hảo Hảo (thùng 30 gói)',       1, 2, N'Thùng', 30),
(N'Đồ hộp cá ngừ 3 lon',             1, 5, N'Lốc',   40),
(N'Nước suối Aquafina 500ml (thùng)',2, 3, N'Thùng', 40),
(N'Coca-Cola lon (thùng 24)',        2, 2, N'Thùng', 40),
(N'Bia Tiger (thùng 24)',            2, 7, N'Thùng', 35),
(N'Dầu gội Clear 650ml',             3, 4, N'Chai',  20),
(N'Sữa tắm Lifebuoy 850ml',          3, 4, N'Chai',  20),
(N'Xà phòng Lifebuoy (lốc 3)',       3, 6, N'Lốc',   30),
(N'Giấy A4 Double A',                4, 1, N'Ram',   60),
(N'Bút bi Thiên Long (hộp 20)',      4, 9, N'Hộp',   25),
(N'Tập 200 trang (lốc 10)',          4, 9, N'Lốc',   30),
(N'Quạt điện Senko 16"',             5, 3, N'Cái',   15),
(N'Nồi cơm điện Sharp 1.8L',         5, 8, N'Cái',   10),
(N'Bàn ủi Panasonic',                5, 8, N'Cái',   12),
(N'Bánh Oreo (thùng)',               6, 6, N'Thùng', 25),
(N'Snack Oishi (thùng)',             6, 7, N'Thùng', 30),
(N'Kẹo Alpenliebe (bịch)',           6, 6, N'Bịch',  40),
(N'Nước mắm Nam Ngư 750ml',          7, 5, N'Chai',  35),
(N'Dầu ăn Tường An 1L',              7, 5, N'Chai',  35),
(N'Đường Biên Hòa 1kg',              7, 10,N'Bao',   40),
(N'Xúc xích Đức Việt (gói)',         8, 7, N'Gói',   30);

-- Lô hàng. Cùng 1 SP nhưng số ngày hạn dùng khác nhau (QĐ2) <== dữ liệu cho KC4.
INSERT INTO Batch (ProductID, ManufactureDate, ExpiryDate, ImportPrice) VALUES
( 1,'2026-01-10','2027-01-10',185000),
( 1,'2026-04-01','2027-04-01',190000),
( 2,'2026-02-15','2026-08-15', 95000),
( 2,'2026-05-01','2026-11-01', 97000),
( 3,'2026-03-01','2026-12-01', 82000),
( 4,'2026-03-01','2027-03-01', 65000),
( 4,'2026-06-01','2027-06-01', 66000),
( 5,'2026-03-10','2026-12-10',210000),
( 5,'2026-05-20','2027-05-20',212000),
( 6,'2026-04-05','2026-12-05',285000),
( 7,'2026-01-20','2027-01-20', 48000),
( 8,'2026-02-01','2027-02-01', 52000),
( 9,'2026-03-15','2027-03-15', 33000),
(10,'2025-12-01','2028-12-01', 72000),
(11,'2026-01-05','2028-01-05', 68000),
(12,'2026-02-10','2028-02-10', 45000),
(13,'2026-02-01','2029-02-01',650000),
(14,'2026-03-01','2029-03-01',1450000),
(15,'2026-03-01','2029-03-01',420000),
(16,'2026-04-10','2026-07-25',115000),  -- lô 20  SP16 hạn 106 ngày  <== KC4
(16,'2026-05-15','2026-11-15',118000),  -- lô 21  SP16 hạn 184 ngày  <== KC4
(17,'2026-04-01','2026-10-01', 98000),
(18,'2026-02-20','2026-06-20', 60000),
(19,'2026-01-15','2027-01-15', 42000),
(19,'2026-05-01','2027-05-01', 43000),
(20,'2026-02-10','2027-02-10', 48000),
(21,'2026-03-05','2027-09-05', 22000),
(21,'2026-06-01','2027-12-01', 23000),
(22,'2026-04-20','2026-07-30', 55000),  -- lô 29  SP22 hạn 101 ngày  <== KC4
(22,'2026-06-10','2026-09-10', 56000),  -- lô 30  SP22 hạn  92 ngày  <== KC4
( 3,'2026-05-01','2027-05-01', 84000),
( 6,'2026-06-15','2027-02-15',288000);

INSERT INTO Inventory (BatchID, WarehouseID, Quantity) VALUES
( 1,1,120),( 1,2, 30),   -- <== lô 1 ở 2 kho, số lượng khác nhau (KC1)
( 2,1, 80),( 3,1, 25),
( 4,3, 60),( 5,1, 55),
( 6,1, 90),( 7,3, 70),
( 8,1, 60),( 9,2, 45),
(10,1, 25),(11,3, 15),   -- lô 11 tồn 15 < ngưỡng 20 -> demo cảnh báo
(12,1, 40),(13,2, 20),
(14,1, 90),(15,4, 12),
(16,1,200),(17,4, 45),
(18,3,  8),(19,1, 30),
(20,2, 70),(21,1, 25),
(22,2, 45),(23,1, 60),
(24,1, 28),(25,3, 55),
(26,2, 40),(27,1, 22),
(28,4, 50),(29,1, 18),
(30,2, 65),(31,5, 30);

-- Phiếu nhập: (NCC, NV lập phiếu, kho NHẬN, ngày)
INSERT INTO ImportReceipt (SupplierID, EmployeeID, WarehouseID, ImportDate) VALUES
( 1, 2, 1,'2026-01-12'),
( 2, 2, 1,'2026-02-16'),
( 2, 6, 3,'2026-03-02'),
( 3, 6, 3,'2026-03-02'),
( 3, 2, 1,'2026-03-12'),
( 7, 2, 1,'2026-04-06'),
( 6, 2, 2,'2026-03-16'),   -- phiếu 7  <== NV 2 (kho 1) lập cho KHO 2, điều động (KC2)
( 5, 3, 3,'2026-05-02'),   -- phiếu 8  <== NV 3 (kho 2) lập cho KHO 3, điều động (KC2)
( 4, 2, 1,'2026-01-22'),
( 8, 6, 3,'2026-04-11'),
( 9, 1, 1,'2026-02-11'),
( 1, 2, 1,'2026-04-02'),
( 5, 1, 1,'2026-01-25'),
(10, 2, 1,'2026-03-08'),
( 2, 2, 1,'2026-04-20');

INSERT INTO ImportDetail (ImportReceiptID, BatchID, Quantity) VALUES
( 1, 1,150),( 1,14, 95),
( 2, 3,100),( 2, 8, 70),
( 3, 4,100),
( 4, 7, 80),
( 5, 6, 80),
( 6,10,100),( 6,29, 45),
( 7,13, 50),( 7,20, 60),
( 8,25, 70),
( 9,12, 70),
(10,18, 30),
(11,16, 55),
(12, 2, 90),(12, 1, 30),   -- <== lô 1 giao đợt 2 (đợt 1 ở phiếu 1) - QĐ3, KC3
(13, 5, 90),(13,24, 28),
(14,27, 22),
(15, 3, 40);               -- <== lô 3 giao đợt 2 (đợt 1 ở phiếu 2) - QĐ3, KC3

INSERT INTO ExportReceipt (WarehouseID, EmployeeID, ExportDate, Purpose) VALUES
(1,11,'2026-02-01',N'Bán cho đại lý A'),
(1,11,'2026-03-05',N'Bán cho đại lý B'),
(3, 5,'2026-03-20',N'Chuyển kho Bình Chánh'),
(2, 4,'2026-04-02',N'Bán lẻ'),
(1,11,'2026-04-15',N'Bán cho siêu thị'),
(4,11,'2026-05-01',N'Bán cho đại lý C'),        -- phiếu 6  <== NV 11 (kho 1) lập cho KHO 4
(3, 5,'2026-05-10',N'Xuất hủy hàng hết hạn'),
(1,11,'2026-05-20',N'Bán cho đại lý A'),
(2, 4,'2026-06-01',N'Bán lẻ'),
(5, 5,'2026-06-10',N'Bán cho đại lý D'),        -- phiếu 10 <== NV 5 (kho 3) lập cho KHO 5
(1,11,'2026-06-15',N'Bán cho siêu thị'),
(4, 8,'2026-06-20',N'Bán lẻ');

INSERT INTO ExportDetail (ExportReceiptID, BatchID, Quantity) VALUES
( 1, 1, 30),( 1, 6, 10),
( 2, 2, 10),( 2, 8, 15),
( 3, 4, 20),( 3, 7, 10),
( 4, 9, 15),( 4,20, 10),
( 5,14, 10),( 5,16, 40),
( 6,15,  5),( 6,17, 10),
( 7,18, 12),
( 8, 1, 20),( 8,23, 10),
( 9,26, 15),
(10,31, 10),
(11,16, 30),(11,24, 12),
(12,28, 10);

-- 3. VIEW

-- Tồn kho hiện tại kèm hạn dùng
GO

CREATE VIEW V_TonKhoHienTai AS
SELECT  w.WarehouseName, p.ProductName, b.BatchID, b.ExpiryDate,
        i.Quantity, p.MinStockThreshold
FROM Inventory i
    JOIN Batch     b ON i.BatchID     = b.BatchID
    JOIN Product   p ON b.ProductID   = p.ProductID
    JOIN Warehouse w ON i.WarehouseID = w.WarehouseID;
GO

-- Lô còn 0-30 ngày là hết hạn
CREATE VIEW V_LoHangSapHetHan AS
SELECT  p.ProductName, b.BatchID, b.ExpiryDate,
        DATEDIFF(DAY, GETDATE(), b.ExpiryDate) AS SoNgayConLai
FROM Batch b
    JOIN Product p ON b.ProductID = p.ProductID
WHERE DATEDIFF(DAY, GETDATE(), b.ExpiryDate) BETWEEN 0 AND 30;
GO

-- Báo cáo tổng nhập - tổng xuất - tồn theo sản phẩm
CREATE VIEW V_BaoCaoNhapXuatTon AS
SELECT  p.ProductID, p.ProductName,
        ISNULL(SUM(idet.Quantity), 0) AS TongNhap,
        ISNULL((SELECT SUM(edet.Quantity)
                FROM ExportDetail edet JOIN Batch b2 ON edet.BatchID = b2.BatchID
                WHERE b2.ProductID = p.ProductID), 0) AS TongXuat,
        ISNULL((SELECT SUM(inv.Quantity)
                FROM Inventory inv JOIN Batch b3 ON inv.BatchID = b3.BatchID
                WHERE b3.ProductID = p.ProductID), 0) AS TonHienTai
FROM Product p
    LEFT JOIN Batch b           ON b.ProductID  = p.ProductID
    LEFT JOIN ImportDetail idet ON idet.BatchID = b.BatchID
GROUP BY p.ProductID, p.ProductName;
GO

-- 4. TRUY VẤN NGHIỆP VỤ

-- Câu 1: Sản phẩm tồn ở từng kho thấp hơn ngưỡng cảnh báo
SELECT  w.WarehouseName, p.ProductName,
        SUM(i.Quantity) AS TonTheoKho, p.MinStockThreshold AS Nguong
FROM Inventory i
    JOIN Batch     b ON i.BatchID     = b.BatchID
    JOIN Product   p ON b.ProductID   = p.ProductID
    JOIN Warehouse w ON i.WarehouseID = w.WarehouseID
GROUP BY w.WarehouseName, p.ProductName, p.MinStockThreshold
HAVING SUM(i.Quantity) < p.MinStockThreshold
ORDER BY w.WarehouseName;

-- Câu 2: Lô sắp hết hạn trong 30 ngày tới
SELECT * FROM V_LoHangSapHetHan ORDER BY SoNgayConLai;

-- Câu 3: Tổng giá trị tồn kho theo từng kho (giá lấy từ Batch)
SELECT  w.WarehouseName, SUM(i.Quantity * b.ImportPrice) AS GiaTriTonKho
FROM Inventory i
    JOIN Batch     b ON i.BatchID     = b.BatchID
    JOIN Warehouse w ON i.WarehouseID = w.WarehouseID
GROUP BY w.WarehouseName
ORDER BY GiaTriTonKho DESC;

-- Câu 4: Top 5 sản phẩm nhập nhiều nhất
SELECT TOP 5 p.ProductName, SUM(idet.Quantity) AS TongSoLuongNhap
FROM ImportDetail idet
    JOIN Batch   b ON idet.BatchID = b.BatchID
    JOIN Product p ON b.ProductID  = p.ProductID
GROUP BY p.ProductName
ORDER BY TongSoLuongNhap DESC;

-- Câu 5: Lịch sử nhập/xuất của lô 1 (đơn giá lấy từ Batch bằng JOIN)
SELECT  N'Nhập' AS LoaiGiaoDich, ir.ImportDate AS NgayGD, id.Quantity, b.ImportPrice AS DonGia
FROM ImportDetail id
    JOIN ImportReceipt ir ON id.ImportReceiptID = ir.ImportReceiptID
    JOIN Batch          b ON id.BatchID         = b.BatchID
WHERE id.BatchID = 1
UNION ALL
SELECT  N'Xuất', er.ExportDate, ed.Quantity, b.ImportPrice
FROM ExportDetail ed
    JOIN ExportReceipt er ON ed.ExportReceiptID = er.ExportReceiptID
    JOIN Batch          b ON ed.BatchID         = b.BatchID
WHERE ed.BatchID = 1
ORDER BY NgayGD;

-- Câu 6: Nhà cung cấp có tổng hàng tồn ít nhất
SELECT TOP 1 s.SupplierName, SUM(i.Quantity) AS TongTon
FROM Supplier s
    JOIN Product   p ON p.SupplierID = s.SupplierID
    JOIN Batch     b ON b.ProductID  = p.ProductID
    JOIN Inventory i ON i.BatchID    = b.BatchID
GROUP BY s.SupplierName
ORDER BY TongTon ASC;

-- 5. STORED PROCEDURE
-- 12 SP (5 dạng), đều bọc TRY...CATCH -> lỗi thì ROLLBACK rồi THROW.

---------- Dạng THÊM ----------
GO

CREATE PROCEDURE SP_ThemNhaCungCap
    @SupplierName NVARCHAR(150), @Phone VARCHAR(15),
    @Email VARCHAR(100), @Address NVARCHAR(200)
AS
BEGIN
    BEGIN TRY
        INSERT INTO Supplier(SupplierName, Phone, Email, Address)
        VALUES (@SupplierName, @Phone, @Email, @Address);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE SP_ThemSanPham
    @ProductName NVARCHAR(150), @CategoryID INT, @SupplierID INT,
    @Unit NVARCHAR(20), @MinStockThreshold INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO Product(ProductName, CategoryID, SupplierID, Unit, MinStockThreshold)
        VALUES (@ProductName, @CategoryID, @SupplierID, @Unit, @MinStockThreshold);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE SP_ThemNhanVien
    @FullName NVARCHAR(100), @Position NVARCHAR(50),
    @Phone VARCHAR(15), @WarehouseID INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO Employee(FullName, Position, Phone, WarehouseID)
        VALUES (@FullName, @Position, @Phone, @WarehouseID);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

---------- Dạng SỬA ----------
CREATE PROCEDURE SP_CapNhatSanPham
    @ProductID INT, @ProductName NVARCHAR(150), @MinStockThreshold INT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = @ProductID)
            THROW 52001, N'Không tìm thấy sản phẩm cần cập nhật.', 1;

        UPDATE Product
        SET ProductName = @ProductName, MinStockThreshold = @MinStockThreshold
        WHERE ProductID = @ProductID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE SP_CapNhatKho
    @WarehouseID INT, @Capacity INT
AS
BEGIN
    BEGIN TRY
        UPDATE Warehouse SET Capacity = @Capacity WHERE WarehouseID = @WarehouseID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

---------- Dạng XÓA ----------
CREATE PROCEDURE SP_XoaSanPham
    @ProductID INT
AS
BEGIN
    BEGIN TRY
        -- Còn tồn thì trigger TR_PreventDeleteProductWithStock chặn lại
        DELETE FROM Product WHERE ProductID = @ProductID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE SP_XoaLoHang
    @BatchID INT
AS
BEGIN
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Inventory WHERE BatchID = @BatchID AND Quantity > 0)
            THROW 52002, N'Không thể xóa lô hàng vì vẫn còn tồn.', 1;

        DELETE FROM Batch WHERE BatchID = @BatchID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

---------- Dạng TRA CỨU ----------
CREATE PROCEDURE SP_TraCuuTonKho
    @ProductID INT, @WarehouseID INT
AS
BEGIN
    BEGIN TRY
        SELECT  p.ProductName, w.WarehouseName, SUM(i.Quantity) AS TonHienTai
        FROM Inventory i
            JOIN Batch     b ON i.BatchID     = b.BatchID
            JOIN Product   p ON b.ProductID   = p.ProductID
            JOIN Warehouse w ON i.WarehouseID = w.WarehouseID
        WHERE p.ProductID = @ProductID AND w.WarehouseID = @WarehouseID
        GROUP BY p.ProductName, w.WarehouseName;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE SP_ThongKeTonKhoTheoKho
    @WarehouseID INT
AS
BEGIN
    BEGIN TRY
        SELECT  p.ProductName,
                SUM(i.Quantity)                 AS SoLuongTon,
                SUM(i.Quantity * b.ImportPrice) AS GiaTri
        FROM Inventory i
            JOIN Batch   b ON i.BatchID   = b.BatchID
            JOIN Product p ON b.ProductID = p.ProductID
        WHERE i.WarehouseID = @WarehouseID
        GROUP BY p.ProductName
        ORDER BY GiaTri DESC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

---------- Dạng NGHIỆP VỤ ----------
-- Nhập kho: 3 INSERT trong 1 giao dịch, lỗi thì rollback hết.
CREATE PROCEDURE SP_ImportGoods
    @SupplierID INT, @EmployeeID INT, @WarehouseID INT,
    @ProductID  INT, @ManufactureDate DATE, @ExpiryDate DATE,
    @Quantity   INT, @ImportPrice DECIMAL(18,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @BatchID INT, @ReceiptID INT;

        INSERT INTO Batch(ProductID, ManufactureDate, ExpiryDate, ImportPrice)
        VALUES (@ProductID, @ManufactureDate, @ExpiryDate, @ImportPrice);
        SET @BatchID = SCOPE_IDENTITY();

        INSERT INTO ImportReceipt(SupplierID, EmployeeID, WarehouseID)
        VALUES (@SupplierID, @EmployeeID, @WarehouseID);
        SET @ReceiptID = SCOPE_IDENTITY();

        INSERT INTO ImportDetail(ImportReceiptID, BatchID, Quantity)
        VALUES (@ReceiptID, @BatchID, @Quantity);   -- trigger tự cộng tồn

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Xuất kho: kiểm tra tồn đủ mới cho xuất
CREATE PROCEDURE SP_ExportGoods
    @WarehouseID INT, @EmployeeID INT, @BatchID INT,
    @Quantity INT, @Purpose NVARCHAR(200)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Ton INT;
        SELECT @Ton = Quantity FROM Inventory
        WHERE BatchID = @BatchID AND WarehouseID = @WarehouseID;

        IF @Ton IS NULL OR @Ton < @Quantity
            THROW 51000, N'Số lượng tồn không đủ để xuất kho.', 1;

        DECLARE @ReceiptID INT;
        INSERT INTO ExportReceipt(WarehouseID, EmployeeID, Purpose)
        VALUES (@WarehouseID, @EmployeeID, @Purpose);
        SET @ReceiptID = SCOPE_IDENTITY();

        INSERT INTO ExportDetail(ExportReceiptID, BatchID, Quantity)
        VALUES (@ReceiptID, @BatchID, @Quantity);   -- trigger tự trừ tồn

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Quét tồn kho, ghi cảnh báo cho (sản phẩm, kho) nào dưới ngưỡng
CREATE PROCEDURE SP_UpdateStockAlerts
AS
BEGIN
    BEGIN TRY
        INSERT INTO StockAlert(ProductID, WarehouseID, CurrentQty, Threshold, Message)
        SELECT  p.ProductID, i.WarehouseID, SUM(i.Quantity), p.MinStockThreshold,
                N'Tồn kho dưới ngưỡng cho phép'
        FROM Inventory i
            JOIN Batch   b ON i.BatchID   = b.BatchID
            JOIN Product p ON b.ProductID = p.ProductID
        GROUP BY p.ProductID, i.WarehouseID, p.MinStockThreshold
        HAVING SUM(i.Quantity) < p.MinStockThreshold;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- 6. TRIGGER
-- Viết set-based (JOIN inserted) vì inserted có thể nhiều dòng.

-- Có chi tiết nhập -> tự cộng tồn
CREATE TRIGGER TR_ImportDetail_UpdateStock
ON ImportDetail
AFTER INSERT
AS
BEGIN
    -- Lô đã có trong kho: cộng dồn
    UPDATE inv
    SET inv.Quantity = inv.Quantity + i.Quantity
    FROM Inventory inv
        JOIN inserted i      ON inv.BatchID = i.BatchID
        JOIN ImportReceipt r ON i.ImportReceiptID = r.ImportReceiptID
                            AND inv.WarehouseID   = r.WarehouseID;

    -- Lô chưa có trong kho: thêm dòng mới
    INSERT INTO Inventory(BatchID, WarehouseID, Quantity)
    SELECT i.BatchID, r.WarehouseID, i.Quantity
    FROM inserted i
        JOIN ImportReceipt r ON i.ImportReceiptID = r.ImportReceiptID
    WHERE NOT EXISTS (
        SELECT 1 FROM Inventory inv
        WHERE inv.BatchID = i.BatchID AND inv.WarehouseID = r.WarehouseID);
END
GO

-- Có chi tiết xuất -> tự trừ tồn
CREATE TRIGGER TR_ExportDetail_UpdateStock
ON ExportDetail
AFTER INSERT
AS
BEGIN
    UPDATE inv
    SET inv.Quantity = inv.Quantity - i.Quantity
    FROM Inventory inv
        JOIN inserted i      ON inv.BatchID = i.BatchID
        JOIN ExportReceipt r ON i.ExportReceiptID = r.ExportReceiptID
                            AND inv.WarehouseID   = r.WarehouseID;
END
GO

-- Tồn tụt dưới ngưỡng -> ghi log cảnh báo
CREATE TRIGGER TR_Inventory_StockAlert
ON Inventory
AFTER UPDATE
AS
BEGIN
    INSERT INTO StockAlert(ProductID, WarehouseID, CurrentQty, Threshold, Message)
    SELECT  b.ProductID, i.WarehouseID, i.Quantity, p.MinStockThreshold,
            N'Tồn kho vừa giảm dưới ngưỡng cảnh báo'
    FROM inserted i
        JOIN Batch   b ON i.BatchID   = b.BatchID
        JOIN Product p ON b.ProductID = p.ProductID
    WHERE i.Quantity < p.MinStockThreshold;
END
GO

-- Chặn xóa sản phẩm còn tồn. Dùng INSTEAD OF để chặn trước khi xóa.
CREATE TRIGGER TR_PreventDeleteProductWithStock
ON Product
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM deleted d
            JOIN Batch     b ON b.ProductID = d.ProductID
            JOIN Inventory i ON i.BatchID   = b.BatchID
        WHERE i.Quantity > 0)
    BEGIN
        RAISERROR(N'Không thể xóa sản phẩm vì vẫn còn hàng tồn kho.', 16, 1);
        RETURN;
    END

    DELETE p FROM Product p JOIN deleted d ON p.ProductID = d.ProductID;
END
GO

-- 7. CURSOR

-- Cursor 1: duyệt lô đã hết hạn, ghi cảnh báo cho từng dòng tồn của lô
DECLARE @BatchID INT, @ProductID INT, @ExpiryDate DATE;

DECLARE cur_ExpiredBatch CURSOR FOR
    SELECT BatchID, ProductID, ExpiryDate FROM Batch WHERE ExpiryDate <= GETDATE();

OPEN cur_ExpiredBatch;
FETCH NEXT FROM cur_ExpiredBatch INTO @BatchID, @ProductID, @ExpiryDate;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO StockAlert(ProductID, WarehouseID, CurrentQty, Threshold, Message)
    SELECT @ProductID, WarehouseID, Quantity, 0, N'Lô hàng đã hết hạn sử dụng'
    FROM Inventory WHERE BatchID = @BatchID;

    FETCH NEXT FROM cur_ExpiredBatch INTO @BatchID, @ProductID, @ExpiryDate;
END

CLOSE cur_ExpiredBatch;
DEALLOCATE cur_ExpiredBatch;
GO

-- Cursor 2: duyệt từng kho, tính tổng giá trị tồn
DECLARE @WID INT, @WName NVARCHAR(100), @Value DECIMAL(18,2);

DECLARE cur_WarehouseValue CURSOR FOR
    SELECT WarehouseID, WarehouseName FROM Warehouse;

OPEN cur_WarehouseValue;
FETCH NEXT FROM cur_WarehouseValue INTO @WID, @WName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @Value = ISNULL(SUM(i.Quantity * b.ImportPrice), 0)
    FROM Inventory i JOIN Batch b ON i.BatchID = b.BatchID
    WHERE i.WarehouseID = @WID;

    PRINT N'Kho ' + @WName + N': ' + CAST(@Value AS NVARCHAR(30)) + N' VND';

    FETCH NEXT FROM cur_WarehouseValue INTO @WID, @WName;
END

CLOSE cur_WarehouseValue;
DEALLOCATE cur_WarehouseValue;
GO

-- Cursor 3: duyệt từng sản phẩm, cảnh báo nếu tổng tồn thấp hơn ngưỡng
DECLARE @PID INT, @PName NVARCHAR(150), @Min INT, @Total INT;

DECLARE cur_LowStock CURSOR FOR
    SELECT ProductID, ProductName, MinStockThreshold FROM Product;

OPEN cur_LowStock;
FETCH NEXT FROM cur_LowStock INTO @PID, @PName, @Min;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @Total = ISNULL(SUM(i.Quantity), 0)
    FROM Inventory i JOIN Batch b ON i.BatchID = b.BatchID
    WHERE b.ProductID = @PID;

    IF @Total < @Min
        PRINT N'Canh bao: ' + @PName + N' chi con ' + CAST(@Total AS NVARCHAR(10))
              + N' (nguong ' + CAST(@Min AS NVARCHAR(10)) + N')';

    FETCH NEXT FROM cur_LowStock INTO @PID, @PName, @Min;
END

CLOSE cur_LowStock;
DEALLOCATE cur_LowStock;
GO

-- 8. DEMO

-- Demo 1: nhập kho. SP 1 tại kho 1 đang có 200 (lô 1 = 120, lô 2 = 80).
EXEC SP_ImportGoods
    @SupplierID = 1, @EmployeeID = 2, @WarehouseID = 1,
    @ProductID = 1, @ManufactureDate = '2026-07-01', @ExpiryDate = '2027-07-01',
    @Quantity = 100, @ImportPrice = 195000;

EXEC SP_TraCuuTonKho @ProductID = 1, @WarehouseID = 1;   -- kỳ vọng 300

-- Demo 2: xuất kho hợp lệ, xuất 20 từ lô 1
EXEC SP_ExportGoods
    @WarehouseID = 1, @EmployeeID = 11, @BatchID = 1,
    @Quantity = 20, @Purpose = N'Ban cho dai ly A';

EXEC SP_TraCuuTonKho @ProductID = 1, @WarehouseID = 1;   -- kỳ vọng 280

-- Demo 3: xuất quá tồn -> báo lỗi 51000
BEGIN TRY
    EXEC SP_ExportGoods
        @WarehouseID = 1, @EmployeeID = 11, @BatchID = 1,
        @Quantity = 999999, @Purpose = N'Test loi thieu ton';
END TRY
BEGIN CATCH
    PRINT N'Da bat loi: ' + ERROR_MESSAGE();
END CATCH

-- Demo 4: xóa sản phẩm còn tồn -> trigger chặn
BEGIN TRY
    EXEC SP_XoaSanPham @ProductID = 1;
END TRY
BEGIN CATCH
    PRINT N'Da bat loi: ' + ERROR_MESSAGE();
END CATCH

-- Demo 5: quét cảnh báo tồn thấp
EXEC SP_UpdateStockAlerts;
SELECT TOP 20 * FROM StockAlert ORDER BY AlertID DESC;

-- Demo 6: xem view
SELECT * FROM V_LoHangSapHetHan ORDER BY SoNgayConLai;
SELECT * FROM V_BaoCaoNhapXuatTon ORDER BY ProductID;

-- 9. KIỂM CHỨNG CHUẨN HÓA
-- Cùng vế trái mà khác vế phải -> phụ thuộc hàm không tồn tại (chi tiết: Word ch3).

-- KC1: bác bỏ BatchID -> Quantity (Inventory)  => đạt 2NF
--      Kỳ vọng: lô 1 có 2 số lượng khác nhau ở 2 kho.
SELECT BatchID, COUNT(DISTINCT Quantity) AS SoGiaTriQuantity
FROM Inventory
GROUP BY BatchID
HAVING COUNT(DISTINCT Quantity) > 1;

-- KC2: bác bỏ EmployeeID -> WarehouseID (ImportReceipt)  => đạt 3NF
--      Kỳ vọng: NV 2 lập phiếu cho 2 kho khác nhau.
SELECT  r.EmployeeID, e.FullName, e.WarehouseID AS KhoBienChe,
        COUNT(DISTINCT r.WarehouseID) AS SoKhoDaLapPhieu
FROM ImportReceipt r JOIN Employee e ON r.EmployeeID = e.EmployeeID
GROUP BY r.EmployeeID, e.FullName, e.WarehouseID
HAVING COUNT(DISTINCT r.WarehouseID) > 1;

-- KC3: bác bỏ BatchID -> Quantity (ImportDetail)  => đạt 2NF, khóa ghép tối thiểu
--      Kỳ vọng: lô 1 và lô 3 nhập 2 đợt, số lượng khác nhau.
SELECT BatchID, COUNT(*) AS SoPhieuNhap, COUNT(DISTINCT Quantity) AS SoGiaTriSL
FROM ImportDetail
GROUP BY BatchID
HAVING COUNT(*) > 1;

-- KC4: bác bỏ (ProductID, ManufactureDate) -> ExpiryDate (Batch)  => đạt 3NF
--      Kỳ vọng: 7 sản phẩm có nhiều mức hạn dùng khác nhau.
SELECT  p.ProductID, p.ProductName, COUNT(*) AS SoLo,
        COUNT(DISTINCT DATEDIFF(DAY, b.ManufactureDate, b.ExpiryDate)) AS SoHanDungKhacNhau
FROM Batch b JOIN Product p ON b.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(DISTINCT DATEDIFF(DAY, b.ManufactureDate, b.ExpiryDate)) > 1;

-- KC5: tên kho chỉ tồn tại ở bảng Warehouse (nếu có ở Inventory nữa -> hỏng BCNF)
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%Name%'
ORDER BY TABLE_NAME;

-- 10. KIỂM TRA HIỆU NĂNG CHỈ MỤC (MỨC VẬT LÝ)
-- SET STATISTICS IO đếm số trang đọc: so câu DÙNG index vs ÉP quét bảng.

SET STATISTICS IO ON;

-- Câu 5 lọc theo lô. Có IX_ImportDetail_BatchID -> Index Seek (đọc ít trang).
PRINT N'--- Dùng index (Index Seek) ---';
SELECT * FROM ImportDetail WHERE BatchID = 1;

-- Ép bỏ index bằng gợi ý FORCESCAN -> Table Scan, đọc nhiều trang hơn.
PRINT N'--- Ép quét toàn bảng (Table Scan) ---';
SELECT * FROM ImportDetail WITH (FORCESCAN) WHERE BatchID = 1;

 
-- Trong SSMS bấm Ctrl+M (Include Actual Execution Plan) rồi chạy 2 câu trên:
--   câu đầu hiện "Index Seek", câu sau hiện "Table Scan" với chi phí cao hơn.
-- Ghi chú: dữ liệu mẫu nhỏ nên chênh lệch số trang chưa lớn; điểm cần thấy là
-- KIỂU toán tử (Seek vs Scan) đổi khi có/không index.

-- Liệt kê toàn bộ chỉ mục đang có (dùng làm bằng chứng cho báo cáo)
SELECT  t.name AS Bang,
        i.name AS TenChiMuc,
        i.type_desc AS Loai,
        STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS CacCot
FROM sys.indexes i
    JOIN sys.tables t         ON i.object_id = t.object_id
    JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    JOIN sys.columns c        ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.type > 0        -- bỏ heap
GROUP BY t.name, i.name, i.type_desc
ORDER BY t.name, i.name;

-- HẾT FILE