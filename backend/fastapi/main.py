import os
import base64
import uuid
import psycopg2
from psycopg2 import pool
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# Configuration for local storage
UPLOAD_DIR = "static"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# Mount static files to serve images
app.mount("/static", StaticFiles(directory=UPLOAD_DIR), name="static")

# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgres://postgres:postgrespassword@localhost:5432/enatega")
db_pool = pool.SimpleConnectionPool(1, 10, DATABASE_URL)

# Base URL for images
BASE_URL = os.getenv("IMAGE_BASE_URL", "http://localhost:8000")

class VendorInput(BaseModel):
    _id: Optional[str] = None
    name: str
    email: str
    password: str
    image: Optional[str] = None
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    phoneNumber: Optional[str] = None

class StaffInput(BaseModel):
    _id: Optional[str] = None
    name: str
    email: str
    password: str
    phone: Optional[str] = None
    isActive: Optional[bool] = True
    permissions: Optional[List[str]] = []

class RiderInput(BaseModel):
    _id: Optional[str] = None
    name: str
    username: str
    password: str
    phone: Optional[str] = None
    available: Optional[bool] = True
    vehicleType: Optional[str] = None
    zone: Optional[dict] = None # Expects {"_id": "uuid"}

class UserInput(BaseModel):
    _id: Optional[str] = None
    name: str
    email: str
    password: str
    phone: Optional[str] = None

class OpeningTimeInput(BaseModel):
    day: str
    startTime: str
    endTime: str
    isClosed: Optional[bool] = False

class RestaurantInput(BaseModel):
    _id: Optional[str] = None
    name: str
    address: str
    image: Optional[str] = None
    logo: Optional[str] = None
    phone: Optional[str] = None
    deliveryTime: Optional[int] = 30
    minimumOrder: Optional[float] = 0
    tax: Optional[float] = 0
    slug: Optional[str] = None
    owner: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None
    shopType: Optional[str] = None
    cuisines: Optional[List[str]] = []
    openingTimes: Optional[List[OpeningTimeInput]] = []

@app.post("/createVendor")
def create_vendor(req: dict):
    """
    Hasura Action for createVendor.
    Expects { "input": { "vendorInput": { ... } } }
    """
    params = req.get("input", {})
    vi = params.get("vendorInput", {})
    print(f"Creating vendor: {vi.get('email')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Match vendor_input_type: (_id, name, email, password, image, firstname, lastname, phonenumber)
            cur.execute("""
                SELECT * FROM create_vendor((%s, %s, %s, %s, %s, %s, %s, %s)::vendor_input_type)
            """, (
                vi.get("_id"), vi.get("name"), vi.get("email"), vi.get("password"),
                vi.get("image"), vi.get("firstName"), vi.get("lastName"), vi.get("phoneNumber")
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                name = row[3]
                names = name.split(' ', 1)
                first = names[0]
                last = names[1] if len(names) > 1 else ""
                # Return standardized vendor object
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "password": row[2],
                    "name": name,
                    "phoneNumber": row[4],
                    "userType": row[5],
                    "image": row[6],
                    "firstName": first,
                    "lastName": last
                }
    except Exception as e:
        conn.rollback()
        print(f"Error creating vendor: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/editVendor")
def edit_vendor(req: dict):
    params = req.get("input", {})
    vi = params.get("vendorInput", {})
    print(f"Editing vendor: {vi.get('_id')} - {vi.get('email')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT * FROM edit_vendor((%s, %s, %s, %s, %s, %s, %s, %s)::vendor_input_type)
            """, (
                vi.get("_id"), vi.get("name"), vi.get("email"), vi.get("password"),
                vi.get("image"), vi.get("firstName"), vi.get("lastName"), vi.get("phoneNumber")
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                name = row[3]
                names = name.split(' ', 1)
                first = names[0]
                last = names[1] if len(names) > 1 else ""
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "password": row[2],
                    "name": name,
                    "phoneNumber": row[4],
                    "userType": row[5],
                    "image": row[6],
                    "firstName": first,
                    "lastName": last
                }
    except Exception as e:
        conn.rollback()
        print(f"Error editing vendor: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/createStore")
def create_store(req: dict):
    params = req.get("input", {})
    ri = params.get("restaurant", {})
    owner_id = params.get("owner")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO restaurants (name, address, image, logo, phone, delivery_time, owner_id, slug)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                ri.get("name"), ri.get("address"), ri.get("image"), ri.get("logo"),
                ri.get("phone"), ri.get("deliveryTime", 30), owner_id, ri.get("slug")
            ))
            res_id = cur.fetchone()[0]
            
            cur.execute("""
                INSERT INTO restaurant_settings (restaurant_id, minimum_order, tax)
                VALUES (%s, %s, %s)
            """, (res_id, ri.get("minimumOrder", 0), ri.get("tax", 0)))
            
            opening_times = ri.get("openingTimes", [])
            for ot in opening_times:
                cur.execute("""
                    INSERT INTO opening_times (restaurant_id, day, start_time, end_time, is_closed)
                    VALUES (%s, %s, %s, %s, %s)
                """, (res_id, ot.get("day"), ot.get("startTime"), ot.get("endTime"), ot.get("isClosed", False)))
            
            conn.commit()
            return {
                "_id": str(res_id),
                "name": ri.get("name"),
                "slug": ri.get("slug")
            }
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/editStore")
def edit_store(req: dict):
    params = req.get("input", {})
    ri = params.get("restaurant", {})
    res_id = ri.get("_id")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE restaurants SET 
                    name = COALESCE(%s, name),
                    address = COALESCE(%s, address),
                    image = COALESCE(%s, image),
                    logo = COALESCE(%s, logo),
                    phone = COALESCE(%s, phone),
                    delivery_time = COALESCE(%s, delivery_time),
                    slug = COALESCE(%s, slug),
                    updated_at = NOW()
                WHERE id = %s
            """, (
                ri.get("name"), ri.get("address"), ri.get("image"), ri.get("logo"),
                ri.get("phone"), ri.get("deliveryTime"), ri.get("slug"), res_id
            ))
            
            cur.execute("""
                UPDATE restaurant_settings SET
                    minimum_order = COALESCE(%s, minimum_order),
                    tax = COALESCE(%s, tax),
                    updated_at = NOW()
                WHERE restaurant_id = %s
            """, (ri.get("minimumOrder"), ri.get("tax"), res_id))
            
            if "openingTimes" in ri:
                cur.execute("DELETE FROM opening_times WHERE restaurant_id = %s", (res_id,))
                for ot in ri["openingTimes"]:
                    cur.execute("""
                        INSERT INTO opening_times (restaurant_id, day, start_time, end_time, is_closed)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (res_id, ot.get("day"), ot.get("startTime"), ot.get("endTime"), ot.get("isClosed", False)))
            
            conn.commit()
            return {"success": True}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/deleteStore")
def delete_store(req: dict):
    params = req.get("input", {})
    res_id = params.get("id")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE restaurants SET is_active = false WHERE id = %s", (res_id,))
            conn.commit()
            return {"success": True}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/createStaff")
def create_staff(req: dict):
    params = req.get("input", {})
    si = params.get("staffInput", {})
    print(f"Creating staff: {si.get('email')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Match staff_input_type: (_id, name, email, password, phone, is_active, permissions)
            cur.execute("""
                SELECT * FROM create_staff((%s, %s, %s, %s, %s, %s, %s)::staff_input_type)
            """, (
                si.get("_id"), si.get("name"), si.get("email"), si.get("password"),
                si.get("phone"), si.get("isActive"), si.get("permissions")
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "password": row[2],
                    "name": row[3],
                    "phone": row[4],
                    "userType": row[5],
                    "isActive": row[7],
                    "permissions": row[13] if len(row) > 13 else []
                }
    except Exception as e:
        conn.rollback()
        print(f"Error creating staff: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/editStaff")
def edit_staff(req: dict):
    params = req.get("input", {})
    si = params.get("staffInput", {})
    print(f"Editing staff: {si.get('_id')} - {si.get('email')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT * FROM edit_staff((%s, %s, %s, %s, %s, %s, %s)::staff_input_type)
            """, (
                si.get("_id"), si.get("name"), si.get("email"), si.get("password"),
                si.get("phone"), si.get("isActive"), si.get("permissions")
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "password": row[2],
                    "name": row[3],
                    "phone": row[4],
                    "userType": row[5],
                    "isActive": row[7],
                    "permissions": row[13] if len(row) > 13 else []
                }
    except Exception as e:
        conn.rollback()
        print(f"Error editing staff: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/deleteVendor")
def delete_vendor(req: dict):
    params = req.get("input", {})
    vendor_id = params.get("id")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM users WHERE id = %s AND user_type = 'VENDOR' RETURNING id", (vendor_id,))
            row = cur.fetchone()
            conn.commit()
            return row is not None
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/createRider")
def create_rider(req: dict):
    params = req.get("input", {})
    ri = params.get("riderInput", {})
    print(f"Creating rider: {ri.get('username')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Match rider_input_type: (_id, name, username, password, phone, available, vehicle_type, zone_id)
            zone = ri.get("zone", {})
            zone_id = zone.get("_id") if isinstance(zone, dict) else zone
            
            cur.execute("""
                SELECT * FROM create_rider((%s, %s, %s, %s, %s, %s, %s, %s)::rider_input_type)
            """, (
                ri.get("_id"), ri.get("name"), ri.get("username"), ri.get("password"),
                ri.get("phone"), ri.get("available"), ri.get("vehicleType"), zone_id
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "name": row[3],
                    "phone": row[4],
                    "userType": row[5]
                }
    except Exception as e:
        conn.rollback()
        print(f"Error creating rider: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/editRider")
def edit_rider(req: dict):
    params = req.get("input", {})
    ri = params.get("riderInput", {})
    print(f"Editing rider: {ri.get('_id')} - {ri.get('username')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            zone = ri.get("zone", {})
            zone_id = zone.get("_id") if isinstance(zone, dict) else zone
            
            cur.execute("""
                SELECT * FROM edit_rider((%s, %s, %s, %s, %s, %s, %s, %s)::rider_input_type)
            """, (
                ri.get("_id"), ri.get("name"), ri.get("username"), ri.get("password"),
                ri.get("phone"), ri.get("available"), ri.get("vehicleType"), zone_id
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "name": row[3],
                    "phone": row[4],
                    "userType": row[5]
                }
    except Exception as e:
        conn.rollback()
        print(f"Error editing rider: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/createUser")
def create_customer(req: dict):
    params = req.get("input", {})
    ui = params.get("userInput", {})
    print(f"Creating customer: {ui.get('email')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Match user_input_type: (_id, name, email, password, phone)
            cur.execute("""
                SELECT * FROM create_user((%s, %s, %s, %s, %s)::user_input_type)
            """, (
                ui.get("_id"), ui.get("name"), ui.get("email"), ui.get("password"),
                ui.get("phone")
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "name": row[3],
                    "phone": row[4],
                    "userType": row[5]
                }
    except Exception as e:
        conn.rollback()
        print(f"Error creating customer: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/editUser")
def edit_customer(req: dict):
    params = req.get("input", {})
    ui = params.get("userInput", {})
    print(f"Editing customer: {ui.get('_id')} - {ui.get('email')}")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT * FROM edit_user((%s, %s, %s, %s, %s)::user_input_type)
            """, (
                ui.get("_id"), ui.get("name"), ui.get("email"), ui.get("password"),
                ui.get("phone")
            ))
            row = cur.fetchone()
            conn.commit()
            
            if row:
                return {
                    "_id": str(row[0]),
                    "email": row[1],
                    "name": row[3],
                    "phone": row[4],
                    "userType": row[5]
                }
    except Exception as e:
        conn.rollback()
        print(f"Error editing customer: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/ownerLogin")
def owner_login(req: dict):
    # Hasura Actions wrap args in an 'input' object
    params = req.get("input", {})
    email = params.get("email")
    password = params.get("password")

    if email == "admin@enatega.com" and password == "123456":
        return {
            "userId": "1",
            "token": "mock-token-123",
            "email": email,
            "userType": "ADMIN",
            "restaurants": [],
            "permissions": ["Admin", "Vendors", "Stores", "Riders", "Users", "Staff", "Configuration", "Orders", "Coupons", "Cuisine", "Banners", "Tipping", "Commission Rate", "Withdraw Request", "Notification", "Zone", "Dispatch", "Shop Type"],
            "userTypeId": "ADMIN",
            "image": None,
            "name": "Super Admin"
        }
    
    raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/uploadImageToS3")
async def upload_image_local(req: dict):
    """
    Simulates S3 upload by saving to local disk.
    Expects base64 in req['input']['image']
    """
    params = req.get("input", {})
    image_data = params.get("image")
    
    if not image_data:
        raise HTTPException(status_code=400, detail="No image data provided")
    
    try:
        # Handle data:image/png;base64,... format
        if "," in image_data:
            header, encoded = image_data.split(",", 1)
            # Try to guess extension from header
            ext = "png"
            if "jpeg" in header or "jpg" in header:
                ext = "jpg"
            elif "webp" in header:
                ext = "webp"
        else:
            encoded = image_data
            ext = "png"
            
        file_name = f"{uuid.uuid4()}.{ext}"
        file_path = os.path.join(UPLOAD_DIR, file_name)
        
        with open(file_path, "wb") as f:
            f.write(base64.b64decode(encoded))
            
        return {
            "imageUrl": f"{BASE_URL}/static/{file_name}"
        }
    except Exception as e:
        print(f"Error saving image: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
def read_root():
    return {"Hello": "World", "Service": "Enatega Backend"}

@app.post("/restaurantByOwner")
def restaurant_by_owner(req: dict):
    """
    Hasura Query for restaurantByOwner.
    Expects { "input": { "id": "owner-uuid" } }
    """
    params = req.get("input", {})
    owner_id = params.get("id")
    
    if not owner_id:
        raise HTTPException(status_code=400, detail="Owner ID is required")
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Get user info
            cur.execute("""
                SELECT id, email, user_type
                FROM users
                WHERE id = %s
            """, (owner_id,))
            
            user_row = cur.fetchone()
            if not user_row:
                return {
                    "_id": owner_id,
                    "email": "",
                    "userType": "",
                    "restaurants": []
                }
            
            # Get restaurants with settings
            cur.execute("""
                SELECT 
                    r.id, r.name, r.slug, r.image,
                    r.address, r.is_active, r.delivery_time, r.minimum_order,
                    r.location, rs.tax, r.delivery_charges
                FROM restaurants r
                LEFT JOIN restaurant_settings rs ON r.id = rs.restaurant_id
                WHERE r.owner_id = %s
                ORDER BY r.created_at DESC
            """, (owner_id,))
            
            restaurant_rows = cur.fetchall()
            restaurants = []
            
            for row in restaurant_rows:
                rest_id = row[0]
                
                delivery_row = None
                
                # Get opening times
                cur.execute("""
                    SELECT day, start_time, end_time
                    FROM opening_times
                    WHERE restaurant_id = %s
                    ORDER BY 
                        CASE day
                            WHEN 'MONDAY' THEN 1
                            WHEN 'TUESDAY' THEN 2
                            WHEN 'WEDNESDAY' THEN 3
                            WHEN 'THURSDAY' THEN 4
                            WHEN 'FRIDAY' THEN 5
                            WHEN 'SATURDAY' THEN 6
                            WHEN 'SUNDAY' THEN 7
                        END
                """, (rest_id,))
                timing_rows = cur.fetchall()
                
                opening_times = []
                for t_row in timing_rows:
                    start_hour = str(t_row[1].hour)
                    start_min = str(t_row[1].minute).zfill(2)
                    end_hour = str(t_row[2].hour)
                    end_min = str(t_row[2].minute).zfill(2)
                    
                    opening_times.append({
                        "day": t_row[0],
                        "times": [{
                            "startTime": [start_hour, start_min],
                            "endTime": [end_hour, end_min]
                        }]
                    })
                
                # Build location
                location = None
                if row[8]:  # location column
                    try:
                        # Extract coordinates from geography
                        cur.execute("""
                            SELECT ST_X(%s::geometry), ST_Y(%s::geometry)
                        """, (row[8], row[8]))
                        coords = cur.fetchone()
                        if coords:
                            location = {
                                "coordinates": [coords[0], coords[1]]
                            }
                    except:
                        location = None
                
                restaurants.append({
                    "_id": str(rest_id),
                    "unique_restaurant_id": str(rest_id),
                    "orderId": None,
                    "orderPrefix": None,
                    "name": row[1],
                    "slug": row[2],
                    "image": row[3],
                    "address": row[4],
                    "isActive": row[5],
                    "deliveryTime": row[6],
                    "minimumOrder": float(row[7]) if row[7] else 0,
                    "username": "",
                    "password": "",
                    "location": location,
                    "deliveryInfo": {
                        "minDeliveryFee": 0,
                        "deliveryDistance": 0,
                        "deliveryFee": float(row[10]) if row[10] else 0
                    },
                    "openingTimes": opening_times,
                    "shopType": "RESTAURANT" # Default value
                })
            
            return {
                "_id": str(user_row[0]),
                "email": user_row[1],
                "userType": user_row[2],
                "restaurants": restaurants
            }
            
    except Exception as e:
        print(f"Error fetching restaurants by owner: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.post("/restaurantsPaginated")
def restaurants_paginated(req: dict):
    """
    Hasura Action for restaurantsPaginated.
    Expects { "input": { "page": 1, "limit": 10, "search": "" } }
    """
    params = req.get("input", {})
    page = params.get("page", 1)
    limit = params.get("limit", 10)
    search = params.get("search", "")
    
    offset = (page - 1) * limit
    
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Get total count
            count_query = "SELECT COUNT(*) FROM restaurants r"
            count_params = []
            if search:
                count_query += " WHERE r.name ILIKE %s OR r.address ILIKE %s"
                count_params = [f"%{search}%", f"%{search}%"]
            
            cur.execute(count_query, count_params)
            total_count = cur.fetchone()[0]
            
            total_pages = (total_count + limit - 1) // limit if limit > 0 else 1
            
            # Get restaurants
            fetch_query = """
                SELECT 
                    r.id, r._id, r.name, r.image, r.slug, r.address, 
                    r.delivery_time, r.minimum_order, r.is_active,
                    rs.commission_rate, rs.tax,
                    u._id as owner_uuid, u.email as owner_email, u.is_active as owner_active
                FROM restaurants r
                LEFT JOIN restaurant_settings rs ON r.id = rs.restaurant_id
                LEFT JOIN users u ON r.owner_id = u.id
            """
            fetch_params = []
            if search:
                fetch_query += " WHERE r.name ILIKE %s OR r.address ILIKE %s"
                fetch_params = [f"%{search}%", f"%{search}%", limit, offset]
            else:
                fetch_params = [limit, offset]
                
            fetch_query += " ORDER BY r.created_at DESC LIMIT %s OFFSET %s"
            
            cur.execute(fetch_query, fetch_params)
            rows = cur.fetchall()
            
            restaurants = []
            for row in rows:
                restaurants.append({
                    "unique_restaurant_id": str(row[0]),
                    "_id": row[1],
                    "name": row[2],
                    "image": row[3],
                    "orderPrefix": "ORD", # Default value
                    "slug": row[4],
                    "address": row[5],
                    "deliveryTime": row[6],
                    "minimumOrder": float(row[7]) if row[7] else 0.0,
                    "isActive": row[8],
                    "commissionRate": float(row[9]) if row[9] else 0.0,
                    "username": "", # Default value
                    "tax": float(row[10]) if row[10] else 0.0,
                    "owner": {
                        "_id": row[11],
                        "email": row[12],
                        "isActive": row[13]
                    },
                    "shopType": "RESTAURANT" # Default value
                })
            
            return {
                "data": restaurants,
                "totalCount": total_count,
                "currentPage": page,
                "totalPages": total_pages
            }
            
    except Exception as e:
        print(f"Error in restaurantsPaginated: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db_pool.putconn(conn)

@app.get("/health")
def health_check():
    return {"status": "ok"}
