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
DATABASE_URL = os.getenv("DATABASE_URL", "postgres://postgres:postgrespassword@postgres:5432/enatega")
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

@app.get("/health")
def health_check():
    return {"status": "ok"}
