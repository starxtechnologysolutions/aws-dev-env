DROP TABLE IF EXISTS
    refresh_tokens,
    user_tokens,
    claim_voucher,
    voucher,
    fine,
    car_finance_information,
    insurance_details,
    maintenance_records,
    car_condition_record,
    orders,
    rental_information,
    car,
    staff,
    driver,
    roles,
    users,
    dict,
    dict_detail,
    permission,
    role_permission

CASCADE;

-- USERS
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(128) PRIMARY KEY,
    email TEXT UNIQUE,
    is_driver BOOLEAN DEFAULT FALSE,
    is_staff BOOLEAN DEFAULT FALSE
);

-- ROLES
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    role TEXT UNIQUE NOT NULL
);

-- DRIVER
CREATE TABLE IF NOT EXISTS driver (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    license_img JSONB,
    verification_img JSONB,
    first_name TEXT,
    last_name TEXT,
    gender SMALLINT CHECK (gender IN (0, 1)),
    license_number TEXT UNIQUE,
    license_card_number TEXT,
    license_expiry_date DATE,
    dob DATE,
    phone TEXT,
    email TEXT,
    address TEXT,
    status TEXT CHECK (status IN ('Verified', 'Unverified', 'Incomplete', 'Blacklisted', 'Rejected')) DEFAULT 'Unverified',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- STAFF
CREATE TABLE IF NOT EXISTS staff (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    role_id INT REFERENCES roles(id) ON DELETE SET NULL,
    first_name TEXT,
    last_name TEXT,
    dob DATE,
    phone TEXT,
    email TEXT,
    address TEXT,
    status TEXT CHECK (status IN ('Active', 'Suspended', 'Deleted')) DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- CAR
CREATE TABLE IF NOT EXISTS car (
    id SERIAL PRIMARY KEY,
    registration VARCHAR(20) UNIQUE NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    vin_number VARCHAR(50) UNIQUE NOT NULL,
    year INT NOT NULL,
    type VARCHAR(50),
    colour VARCHAR(30),
    range_km INT,
    engine VARCHAR(50),
    seats INT,
    state VARCHAR(20),
    current_location VARCHAR(100),
    expire_date DATE,
    status TEXT CHECK (status IN ('Available', 'Pending Pickup', 'Ongoing', 'Returning', 'Maintenance', 'Unavailable')) DEFAULT 'Available',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- RENTAL INFORMATION (must exist before orders)
CREATE TABLE IF NOT EXISTS rental_information (
    id SERIAL PRIMARY KEY,
    car_id INT REFERENCES car(id) ON DELETE CASCADE,
    weekly_rate NUMERIC(10,2),
    monthly_rate NUMERIC(10,2),
    bond_amount NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ORDERS (no circular FK yet)
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    car_id INT REFERENCES car(id) ON DELETE CASCADE,
    driver_id INT REFERENCES driver(id) ON DELETE CASCADE,
    rental_information_id INT REFERENCES rental_information(id),
    start_date DATE,
    end_date DATE,
    rental_amount NUMERIC(10,2),
    bond_amount NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status TEXT CHECK (status IN ('Pending', 'Ongoing', 'Completed', 'Cancelled')) DEFAULT 'Pending'
);

-- CAR CONDITION RECORD (references orders)
CREATE TABLE IF NOT EXISTS car_condition_record (
    id SERIAL PRIMARY KEY,
    car_id INT REFERENCES car(id) ON DELETE CASCADE,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    condition_type TEXT CHECK (condition_type IN ('Good', 'Damaged', 'Needs Repair', 'Maintenance')) DEFAULT 'Good',
    notes TEXT,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- OPTIONAL: if you want orders to have a reverse reference, add after both exist
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS car_condition_record_id INT REFERENCES car_condition_record(id);

-- MAINTENANCE RECORDS
CREATE TABLE IF NOT EXISTS maintenance_records (
    id SERIAL PRIMARY KEY,
    car_id INT REFERENCES car(id) ON DELETE CASCADE,
    description TEXT,
    cost NUMERIC(10,2),
    start_date DATE,
    end_date DATE,
    status TEXT CHECK (status IN ('Scheduled', 'InProgress', 'Completed', 'Cancelled')) DEFAULT 'Scheduled',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- INSURANCE DETAILS
CREATE TABLE IF NOT EXISTS insurance_details (
    id SERIAL PRIMARY KEY,
    car_id INT REFERENCES car(id) ON DELETE CASCADE,
    provider_name TEXT,
    policy_number VARCHAR(50),
    insurance_type TEXT,
    coverage_amount NUMERIC(10,2),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- CAR FINANCE INFORMATION
CREATE TABLE IF NOT EXISTS car_finance_information (
    id SERIAL PRIMARY KEY,
    car_id INT REFERENCES car(id) ON DELETE CASCADE,
    purchase_price NUMERIC(10,2),
    purchase_date DATE,
    loan_provider TEXT,
    interest_rate NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- FINE
CREATE TABLE IF NOT EXISTS fine (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    driver_id INT REFERENCES driver(id) ON DELETE CASCADE,
    description TEXT,
    amount NUMERIC(10,2),
    fine_date DATE,
    issued_by INT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status TEXT CHECK (status IN ('Unpaid', 'Paid', 'Outstanding')) DEFAULT 'Unpaid'
);

-- VOUCHER
CREATE TABLE IF NOT EXISTS voucher (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type TEXT CHECK (discount_type IN ('Amount', 'Percentage')),
    discount_value NUMERIC(10,2),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status TEXT CHECK (status IN ('Active', 'Inactive')) DEFAULT 'Inactive'
);

-- CLAIM VOUCHER
CREATE TABLE IF NOT EXISTS claim_voucher (
    id SERIAL PRIMARY KEY,
    voucher_id INT REFERENCES voucher(id) ON DELETE CASCADE,
    driver_id INT REFERENCES driver(id) ON DELETE CASCADE,
    claimed_date DATE,
    redeemed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

--USER TOKENS
CREATE TABLE IF NOT EXISTS user_tokens (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(128) REFERENCES users(id) ON DELETE CASCADE,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL UNIQUE,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    access_expires_at TIMESTAMPTZ NOT NULL,
    refresh_expires_at TIMESTAMPTZ NOT NULL
);

-- DICT
CREATE TABLE IF NOT EXISTS dict (
    id SERIAL PRIMARY KEY,
    code VARCHAR(100) UNIQUE,
    name VARCHAR(100),
    category VARCHAR(100) CHECK (category IN ('BrandModel', 'Colour', 'Type', 'InsuranceProvider', 'PickUpPoint', 'ReturnPoint')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- DICT_DETAIL
CREATE TABLE IF NOT EXISTS dict_detail (
    id SERIAL PRIMARY KEY,
    dict_id INT REFERENCES dict(id) ON DELETE CASCADE,
    detail_code VARCHAR(100) UNIQUE,
    detail_name VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- PERMISSION
CREATE TABLE IF NOT EXISTS permission (
    id SERIAL PRIMARY KEY,
    url VARCHAR(100),
    name VARCHAR(50),
    type VARCHAR(50) CHECK (type IN ('Directory', 'Menu', 'Button')) DEFAULT 'Menu',
    sort INT,
    parent_id INT
);

-- ROLE_PERMISSION
CREATE TABLE IF NOT EXISTS role_permission (
    role_id INT,
    permission_id INT,
    type VARCHAR(50) CHECK (type IN ('All', 'View')) DEFAULT 'View',
    PRIMARY KEY (role_id, permission_id)
);
