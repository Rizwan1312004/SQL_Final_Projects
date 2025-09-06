-- Inventory & Warehouse Management System (MySQL)
-- Author: Rizwan M
-- ------------------------------------------------------------
-- Purpose: End-to-end SQL backend for basic warehouse inventory tracking
-- Components: schema, sample data, queries, triggers, procedure
-- Tested dialect: MySQL
-- ------------------------------------------------------------

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS low_stock_alerts;
DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS stock;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS suppliers;
SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE suppliers (
  supplier_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  supplier_name   VARCHAR(120) NOT NULL,
  contact_email   VARCHAR(150),
  contact_phone   VARCHAR(40),
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_suppliers_name (supplier_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE warehouses (
  warehouse_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  warehouse_code  VARCHAR(20) NOT NULL,
  warehouse_name  VARCHAR(120) NOT NULL,
  city            VARCHAR(100),
  capacity_units  BIGINT UNSIGNED NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_warehouses_code (warehouse_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE products (
  product_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  sku             VARCHAR(40) NOT NULL,
  product_name    VARCHAR(160) NOT NULL,
  unit            VARCHAR(20) NOT NULL DEFAULT 'pcs',  -- e.g., pcs, box, kg
  supplier_id     BIGINT UNSIGNED,
  reorder_level   INT UNSIGNED NOT NULL DEFAULT 10,    -- default threshold
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_products_sku (sku),
  KEY idx_products_supplier_id (supplier_id),
  CONSTRAINT fk_products_supplier
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stock (
  warehouse_id    BIGINT UNSIGNED NOT NULL,
  product_id      BIGINT UNSIGNED NOT NULL,
  quantity        BIGINT NOT NULL DEFAULT 0,           
  reorder_level   INT UNSIGNED NULL,                    
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (warehouse_id, product_id),
  CONSTRAINT fk_stock_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_stock_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stock_movements (
  movement_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  product_id        BIGINT UNSIGNED NOT NULL,
  from_warehouse_id BIGINT UNSIGNED NULL,   
  to_warehouse_id   BIGINT UNSIGNED NULL,   
  quantity          BIGINT NOT NULL,       
  movement_type     ENUM('RECEIPT','TRANSFER','ADJUSTMENT','SALE','RETURN') NOT NULL,
  note              VARCHAR(255),
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_movements_product (product_id),
  KEY idx_movements_from (from_warehouse_id),
  KEY idx_movements_to (to_warehouse_id),
  CONSTRAINT fk_movements_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_movements_from
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_movements_to
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE low_stock_alerts (
  alert_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  warehouse_id   BIGINT UNSIGNED NOT NULL,
  product_id     BIGINT UNSIGNED NOT NULL,
  quantity       BIGINT NOT NULL,
  threshold      INT UNSIGNED NOT NULL,
  stock_active         TINYINT(1) NOT NULL DEFAULT 1,  -- 1=open, 0=cleared
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_active_alert (warehouse_id, product_id, stock_active),
  CONSTRAINT fk_alert_wh FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_alert_prod FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* From kaggle*/
INSERT INTO suppliers (supplier_name, contact_email, contact_phone) VALUES
('Zenith Components', 'sales@zenith.example', '+91-90000-00001'),
('Acme Plastics', 'orders@acmeplast.example', '+91-90000-00002'),
('BrightSteel Industries', 'support@brightsteel.example', '+91-90000-00003'),
('Global Agro Foods', 'sales@globalagro.example', '+91-90000-00004'),
('Nimbus Electronics', 'contact@nimbusele.example', '+91-90000-00005'),
('Evergreen Textiles', 'info@evergreentex.example', '+91-90000-00006'),
('Summit Chemicals', 'orders@summitchem.example', '+91-90000-00007'),
('Starline Logistics', 'support@starlinelog.example', '+91-90000-00008'),
('Apex Hardware', 'sales@apexhard.example', '+91-90000-00009'),
('Crystal Beverages', 'contact@crystalbev.example', '+91-90000-00010'),
('Metro Packaging', 'info@metropack.example', '+91-90000-00011'),
('Trinity Pharma', 'orders@trinitypharma.example', '+91-90000-00012'),
('Fusion Ceramics', 'support@fusionceramics.example', '+91-90000-00013'),
('Sunrise Furniture', 'sales@sunrisefurn.example', '+91-90000-00014'),
('BlueWave Paints', 'info@bluewavepaints.example', '+91-90000-00015'),
('NextGen Energy', 'contact@nextgenenergy.example', '+91-90000-00016'),
('Vision Optics', 'orders@visionoptics.example', '+91-90000-00017'),
('Rapid Motors', 'support@rapidmotors.example', '+91-90000-00018'),
('Prime Stationery', 'sales@primestat.example', '+91-90000-00019'),
('EcoLife Organics', 'info@ecolifeorg.example', '+91-90000-00020'),
('Titan Engineering', 'contact@titaneng.example', '+91-90000-00021'),
('Skyline Apparel', 'orders@skylineapparel.example', '+91-90000-00022'),
('GreenLeaf Agro', 'support@greenleafagro.example', '+91-90000-00023'),
('Urban Plastics', 'sales@urbanplast.example', '+91-90000-00024'),
('Alpha Cables', 'contact@alphacables.example', '+91-90000-00025'),
('Royal Footwear', 'orders@royalfootwear.example', '+91-90000-00026'),
('IronClad Metals', 'support@ironcladmetals.example', '+91-90000-00027'),
('Harmony Cosmetics', 'info@harmonycos.example', '+91-90000-00028'),
('Silverline Paper', 'sales@silverlinepaper.example', '+91-90000-00029'),
('ProTech Gadgets', 'orders@protechgadgets.example', '+91-90000-00030'),
('Velocity Tools', 'support@velocitytools.example', '+91-90000-00031'),
('Diamond Glassware', 'info@diamondglass.example', '+91-90000-00032'),
('PureFresh Dairy', 'sales@purefreshdairy.example', '+91-90000-00033'),
('Neptune Tyres', 'contact@neptunetyres.example', '+91-90000-00034'),
('Aurora Lighting', 'orders@auroralights.example', '+91-90000-00035'),
('SteelMax Industries', 'support@steelmax.example', '+91-90000-00036'),
('Omega Electronics', 'sales@omegaelectro.example', '+91-90000-00037'),
('Victory Sportswear', 'info@victorysports.example', '+91-90000-00038'),
('Harvest Seeds', 'orders@harvestseeds.example', '+91-90000-00039'),
('Galaxy Constructions', 'support@galaxycon.example', '+91-90000-00040'),
('SmartPack Solutions', 'contact@smartpack.example', '+91-90000-00041'),
('Coral Mining', 'sales@coralmining.example', '+91-90000-00042'),
('Vista Pharmaceuticals', 'orders@vistapharma.example', '+91-90000-00043'),
('Oceanic Fisheries', 'info@oceanicfish.example', '+91-90000-00044'),
('Rapid Courier', 'support@rapidcourier.example', '+91-90000-00045'),
('Future Plastics', 'sales@futureplastics.example', '+91-90000-00046'),
('EcoBuild Cement', 'orders@ecobuild.example', '+91-90000-00047'),
('Auric Stationery', 'contact@auricstat.example', '+91-90000-00048'),
('Maxwell Fabrics', 'info@maxwellfab.example', '+91-90000-00049'),
('Zen Organics', 'sales@zenorg.example', '+91-90000-00050');


INSERT INTO warehouses (warehouse_code, warehouse_name, city, capacity_units) VALUES
('CBE-1', 'Coimbatore Central DC', 'Coimbatore', 500000),
('BLR-1', 'Bengaluru Regional DC', 'Bengaluru', 300000),
('CHN-1', 'Chennai Mega DC', 'Chennai', 450000),
('HYD-1', 'Hyderabad Logistics Hub', 'Hyderabad', 400000),
('DEL-1', 'Delhi North DC', 'Delhi', 600000),
('MUM-1', 'Mumbai Western DC', 'Mumbai', 550000),
('PUN-1', 'Pune Regional DC', 'Pune', 280000),
('KOL-1', 'Kolkata Eastern DC', 'Kolkata', 350000),
('AHM-1', 'Ahmedabad Supply Hub', 'Ahmedabad', 300000),
('SUR-1', 'Surat Distribution Center', 'Surat', 250000),
('CBE-2', 'Coimbatore South DC', 'Coimbatore', 200000),
('BLR-2', 'Bengaluru East Hub', 'Bengaluru', 320000),
('CHN-2', 'Chennai North Hub', 'Chennai', 270000),
('HYD-2', 'Hyderabad South DC', 'Hyderabad', 310000),
('DEL-2', 'Delhi West Logistics', 'Delhi', 290000),
('MUM-2', 'Mumbai Central Hub', 'Mumbai', 420000),
('PUN-2', 'Pune South Warehouse', 'Pune', 180000),
('KOL-2', 'Kolkata Port DC', 'Kolkata', 370000),
('AHM-2', 'Ahmedabad West Hub', 'Ahmedabad', 260000),
('SUR-2', 'Surat Industrial DC', 'Surat', 230000),
('LKO-1', 'Lucknow Distribution Center', 'Lucknow', 210000),
('PAT-1', 'Patna Supply Hub', 'Patna', 190000),
('BPL-1', 'Bhopal Logistics Hub', 'Bhopal', 240000),
('NAG-1', 'Nagpur Central DC', 'Nagpur', 280000),
('IND-1', 'Indore Regional Hub', 'Indore', 260000),
('VIZ-1', 'Vizag Port Warehouse', 'Visakhapatnam', 300000),
('TRV-1', 'Trivandrum Distribution', 'Trivandrum', 170000),
('KOZ-1', 'Kozhikode South Hub', 'Kozhikode', 150000),
('MAD-1', 'Madurai DC', 'Madurai', 160000),
('TIR-1', 'Tiruppur Apparel Hub', 'Tiruppur', 140000),
('CBE-3', 'Coimbatore West Logistics', 'Coimbatore', 200000),
('BLR-3', 'Bengaluru South DC', 'Bengaluru', 310000),
('CHN-3', 'Chennai Port Warehouse', 'Chennai', 330000),
('HYD-3', 'Hyderabad West DC', 'Hyderabad', 340000),
('DEL-3', 'Delhi East Hub', 'Delhi', 310000),
('MUM-3', 'Mumbai East Logistics', 'Mumbai', 360000),
('PUN-3', 'Pune Industrial DC', 'Pune', 250000),
('KOL-3', 'Kolkata South Hub', 'Kolkata', 270000),
('AHM-3', 'Ahmedabad Industrial Hub', 'Ahmedabad', 220000),
('SUR-3', 'Surat Textile DC', 'Surat', 210000),
('GOA-1', 'Goa Port Warehouse', 'Goa', 120000),
('RAN-1', 'Ranchi DC', 'Ranchi', 150000),
('JAI-1', 'Jaipur Mega Hub', 'Jaipur', 300000),
('KAN-1', 'Kanpur Central DC', 'Kanpur', 200000),
('CHD-1', 'Chandigarh Logistics', 'Chandigarh', 180000),
('GUW-1', 'Guwahati Supply Hub', 'Guwahati', 160000),
('SHI-1', 'Shillong Distribution', 'Shillong', 100000),
('JAM-1', 'Jammu DC', 'Jammu', 130000),
('SRN-1', 'Srinagar Warehouse', 'Srinagar', 120000),
('AMR-1', 'Amritsar Hub', 'Amritsar', 140000),
('UDA-1', 'Udaipur Logistics', 'Udaipur', 110000);


INSERT INTO products (sku, product_name, unit, supplier_id, reorder_level) VALUES
('SKU-1001', '8mm Steel Bolt', 'pcs', 1, 200),
('SKU-1002', 'Plastic Housing A', 'pcs', 2, 150),
('SKU-2001', 'Lubricant Oil 1L', 'bottle', 1, 60),
('SKU-3005', 'Sensor Module X', 'pcs', 1, 40),
('SKU-1003', '10mm Steel Nut', 'pcs', 1, 180),
('SKU-1004', 'Aluminium Bracket', 'pcs', 3, 120),
('SKU-1005', 'Copper Washer 5mm', 'pcs', 4, 250),
('SKU-2002', 'Grease Tube 250g', 'tube', 5, 90),
('SKU-2003', 'Engine Coolant 500ml', 'bottle', 2, 70),
('SKU-2004', 'Hydraulic Fluid 1L', 'bottle', 6, 100),
('SKU-3006', 'Temperature Sensor T100', 'pcs', 7, 30),
('SKU-3007', 'Pressure Sensor P50', 'pcs', 8, 25),
('SKU-3008', 'Proximity Switch M12', 'pcs', 9, 60),
('SKU-3009', 'Relay Module 5V', 'pcs', 2, 45),
('SKU-3010', 'Arduino-Compatible Board', 'pcs', 10, 50),
('SKU-4001', 'Cardboard Box Small', 'pcs', 11, 400),
('SKU-4002', 'Cardboard Box Medium', 'pcs', 11, 350),
('SKU-4003', 'Bubble Wrap Roll', 'roll', 12, 150),
('SKU-4004', 'Packing Tape 50m', 'roll', 12, 200),
('SKU-4005', 'Plastic Pallet', 'pcs', 13, 80),
('SKU-5001', 'Safety Helmet', 'pcs', 14, 100),
('SKU-5002', 'Safety Gloves', 'pair', 14, 150),
('SKU-5003', 'Ear Protection', 'pcs', 15, 90),
('SKU-5004', 'Safety Goggles', 'pcs', 15, 120),
('SKU-5005', 'Reflective Jacket', 'pcs', 16, 70),
('SKU-6001', 'PVC Pipe 1m', 'pcs', 17, 250),
('SKU-6002', 'PVC Elbow Joint', 'pcs', 17, 220),
('SKU-6003', 'Copper Pipe 1m', 'pcs', 18, 150),
('SKU-6004', 'Brass Fitting 1/2"', 'pcs', 19, 180),
('SKU-6005', 'Steel Rod 1m', 'pcs', 20, 200),
('SKU-7001', 'Lithium Battery 3.7V', 'pcs', 21, 100),
('SKU-7002', 'Lead Acid Battery 12V', 'pcs', 22, 50),
('SKU-7003', 'Solar Panel 50W', 'pcs', 23, 40),
('SKU-7004', 'DC Motor 12V', 'pcs', 24, 75),
('SKU-7005', 'Stepper Motor 5V', 'pcs', 24, 60),
('SKU-8001', 'Paint Can White 1L', 'can', 25, 90),
('SKU-8002', 'Paint Can Blue 1L', 'can', 25, 90),
('SKU-8003', 'Industrial Adhesive 500ml', 'bottle', 26, 70),
('SKU-8004', 'Epoxy Resin 1kg', 'pack', 26, 60),
('SKU-8005', 'Solvent Cleaner 1L', 'bottle', 27, 80),
('SKU-9001', 'LED Bulb 9W', 'pcs', 28, 200),
('SKU-9002', 'LED Tube 18W', 'pcs', 28, 150),
('SKU-9003', 'Halogen Lamp 50W', 'pcs', 29, 100),
('SKU-9004', 'Floodlight 100W', 'pcs', 29, 70),
('SKU-9005', 'Street Light 150W', 'pcs', 30, 60),
('SKU-9101', 'Networking Cable 10m', 'pcs', 31, 120),
('SKU-9102', 'Ethernet Switch 8-port', 'pcs', 31, 45),
('SKU-9103', 'WiFi Router Dual Band', 'pcs', 32, 60),
('SKU-9104', 'RJ45 Connector Pack', 'pack', 33, 200),
('SKU-9105', 'Server Rack 42U', 'pcs', 34, 20);


-- Initial stock positions
INSERT INTO stock (warehouse_id, product_id, quantity, reorder_level) VALUES
(1, 1, 350, NULL),      -- uses product default (200) → ok
(1, 2, 120, NULL),      -- below default (150) → alert
(1, 3, 70, 50),         -- override threshold 50 → ok
(2, 1, 90, 180),        -- low vs override → alert
(2, 4, 42, NULL),       -- edge vs default (40) → ok
(1, 5, 260, NULL),      
(1, 6, 80, NULL),       
(1, 7, 220, 200),       
(2, 8, 95, NULL),       
(2, 9, 65, 60),         
(2, 10, 120, NULL),     
(3, 11, 28, NULL),      -- low stock
(3, 12, 18, 20),        -- below override
(3, 13, 75, NULL),      
(3, 14, 35, 40),        -- alert
(3, 15, 45, NULL),      
(4, 16, 390, NULL),     
(4, 17, 320, NULL),     
(4, 18, 110, NULL),     
(4, 19, 150, NULL),     
(4, 20, 70, 100),       -- below override
(5, 21, 85, NULL),      
(5, 22, 130, NULL),     
(5, 23, 75, NULL),      
(5, 24, 100, 120),      -- below override
(5, 25, 65, NULL),      
(6, 26, 230, NULL),     
(6, 27, 210, NULL),     
(6, 28, 135, NULL),     
(6, 29, 170, NULL),     
(6, 30, 140, 180),      -- below override
(7, 31, 90, NULL),      
(7, 32, 48, NULL),      -- below default
(7, 33, 35, NULL),      -- below default
(7, 34, 65, 70),        -- below override
(7, 35, 58, NULL),      
(8, 36, 78, NULL),      
(8, 37, 80, NULL),      
(8, 38, 55, NULL),      
(8, 39, 62, NULL),      
(8, 40, 45, 50),        -- alert
(9, 41, 175, NULL),     
(9, 42, 120, NULL),     
(9, 43, 85, NULL),      
(9, 44, 55, NULL),      
(9, 45, 48, NULL),      -- low stock
(10, 46, 105, NULL),    
(10, 47, 35, 40),       -- alert
(10, 48, 70, NULL),     
(10, 49, 110, NULL),    
(10, 50, 15, NULL);     -- critical


DELIMITER $$

CREATE TRIGGER trg_stock_before_ins
BEFORE INSERT ON stock
FOR EACH ROW
BEGIN
  IF NEW.quantity < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity cannot be negative';
  END IF;
END$$

CREATE TRIGGER trg_stock_before_upd
BEFORE UPDATE ON stock
FOR EACH ROW
BEGIN
  IF NEW.quantity < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity cannot be negative';
  END IF;
END$$

-- Helper to compute threshold = COALESCE(stock.reorder_level, products.reorder_level)
CREATE TRIGGER trg_stock_after_ins
AFTER INSERT ON stock
FOR EACH ROW
BEGIN
  DECLARE v_threshold INT UNSIGNED;
  SELECT COALESCE(NEW.reorder_level, p.reorder_level) INTO v_threshold
  FROM products p WHERE p.product_id = NEW.product_id;

  -- If at/below threshold -> open/refresh alert; else ensure any open alert is closed
  IF NEW.quantity <= v_threshold THEN
    INSERT INTO low_stock_alerts (warehouse_id, product_id, quantity, threshold, stock_active)
    VALUES (NEW.warehouse_id, NEW.product_id, NEW.quantity, v_threshold, 1)
    ON DUPLICATE KEY UPDATE quantity=VALUES(quantity), threshold=VALUES(threshold), updated_at=NOW(), stock_active=1;
  ELSE
    UPDATE low_stock_alerts
      SET stock_active=0, updated_at=NOW()
      WHERE warehouse_id=NEW.warehouse_id AND product_id=NEW.product_id AND stock_active=1;
  END IF;
END$$

CREATE TRIGGER trg_stock_after_upd
AFTER UPDATE ON stock
FOR EACH ROW
BEGIN
  DECLARE v_threshold INT UNSIGNED;
  SELECT COALESCE(NEW.reorder_level, p.reorder_level) INTO v_threshold
  FROM products p WHERE p.product_id = NEW.product_id;

  IF NEW.quantity <= v_threshold THEN
    INSERT INTO low_stock_alerts (warehouse_id, product_id, quantity, threshold, stock_active)
    VALUES (NEW.warehouse_id, NEW.product_id, NEW.quantity, v_threshold, 1)
    ON DUPLICATE KEY UPDATE quantity=VALUES(quantity), threshold=VALUES(threshold), updated_at=NOW(), stock_active=1;
  ELSE
    UPDATE low_stock_alerts
      SET stock_active=0, updated_at=NOW()
      WHERE warehouse_id=NEW.warehouse_id AND product_id=NEW.product_id AND stock_active=1;
  END IF;
END$$

DELIMITER ;

DELIMITER $$
CREATE PROCEDURE transfer_stock (
  IN p_product_id BIGINT UNSIGNED,
  IN p_from_wh    BIGINT UNSIGNED,
  IN p_to_wh      BIGINT UNSIGNED,
  IN p_qty        BIGINT,
  IN p_note       VARCHAR(255)
)
BEGIN
  DECLARE v_available BIGINT;

  IF p_qty IS NULL OR p_qty <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transfer quantity must be > 0';
  END IF;
  IF p_from_wh = p_to_wh THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'from_warehouse and to_warehouse must differ';
  END IF;

  START TRANSACTION;

  -- Lock the source row to prevent race conditions
  SELECT quantity INTO v_available
  FROM stock
  WHERE warehouse_id = p_from_wh AND product_id = p_product_id
  FOR UPDATE;

  IF v_available IS NULL THEN
    -- no stock row yet
    SET v_available = 0;
  END IF;

  IF v_available < p_qty THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock in source warehouse';
  END IF;

  -- Deduct from source
  INSERT INTO stock (warehouse_id, product_id, quantity)
  VALUES (p_from_wh, p_product_id, 0)
  ON DUPLICATE KEY UPDATE quantity = quantity - p_qty;

  -- Add to destination
  INSERT INTO stock (warehouse_id, product_id, quantity)
  VALUES (p_to_wh, p_product_id, p_qty)
  ON DUPLICATE KEY UPDATE quantity = quantity + p_qty;

  -- Log movement (single row capturing both ends)
  INSERT INTO stock_movements (
    product_id, from_warehouse_id, to_warehouse_id, quantity, movement_type, note
  ) VALUES (
    p_product_id, p_from_wh, p_to_wh, p_qty, 'TRANSFER', p_note
  );

  COMMIT;
END$$
DELIMITER ;

-- View: current stock with thresholds and low flag
CREATE OR REPLACE VIEW v_stock_levels AS
SELECT
  w.warehouse_id,
  w.warehouse_code,
  w.warehouse_name,
  p.product_id,
  p.sku,
  p.product_name,
  s.quantity,
  COALESCE(s.reorder_level, p.reorder_level) AS threshold,
  (s.quantity <= COALESCE(s.reorder_level, p.reorder_level)) AS is_low
FROM stock s
JOIN warehouses w ON w.warehouse_id = s.warehouse_id
JOIN products   p ON p.product_id   = s.product_id;

-- 6A) Query: stock by warehouse & product
SELECT * FROM v_stock_levels ORDER BY warehouse_code, sku;

-- 6B) Query: low-stock items (reorder alerts)
SELECT * FROM v_stock_levels WHERE is_low = 1 ORDER BY warehouse_code, sku;

-- 6C) Query: total on-hand per product across warehouses
SELECT p.product_id, p.sku, p.product_name, SUM(s.quantity) AS total_qty
FROM stock s JOIN products p ON p.product_id = s.product_id
GROUP BY p.product_id, p.sku, p.product_name
ORDER BY total_qty desc;

-- 6D) Query: stock for a supplier
SELECT p.sku, p.product_name, w.warehouse_code, s.quantity
 FROM stock s
 JOIN products p   ON p.product_id = s.product_id
 JOIN warehouses w ON w.warehouse_id = s.warehouse_id
 WHERE p.supplier_id = 1
 ORDER BY p.sku, w.warehouse_code;

-- 6E) Query: open low-stock alerts
SELECT a.alert_id, w.warehouse_code, p.sku, p.product_name, a.quantity, a.threshold, a.created_at
 FROM low_stock_alerts a
 JOIN warehouses w ON w.warehouse_id = a.warehouse_id
 JOIN products p   ON p.product_id   = a.product_id
 WHERE a.stock_active = 1
 ORDER BY a.created_at DESC;

CALL transfer_stock(1, 1, 2, 50, 'Rebalance to BLR');
SELECT * FROM v_stock_levels WHERE sku='SKU-1001';
-- Check alerts after transfer
SELECT * FROM low_stock_alerts WHERE active=1 ORDER BY created_at DESC;

-- Acknowledge/close an alert manually
UPDATE low_stock_alerts SET active=0, updated_at=NOW() WHERE alert_id = 1;

-- Receive goods into a warehouse (simple pattern)
INSERT INTO stock (warehouse_id, product_id, quantity)
 VALUES (1, 3, 20) ON DUPLICATE KEY UPDATE quantity = quantity + 20;
INSERT INTO stock_movements (product_id, to_warehouse_id, quantity, movement_type, note)
 VALUES (3, 1, 20, 'RECEIPT', 'PO#12345');
