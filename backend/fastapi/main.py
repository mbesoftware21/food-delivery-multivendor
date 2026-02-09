from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

class Restaurant(BaseModel):
    _id: str
    orderId: str
    name: str
    image: Optional[str] = None
    address: Optional[str] = None

class LoginResponse(BaseModel):
    userId: str
    token: str
    email: str
    userType: str
    restaurants: List[Restaurant]
    permissions: List[str]
    userTypeId: str
    image: Optional[str] = None
    name: str

class LoginRequest(BaseModel):
    input: dict  # Hasura actions wrap args in an 'input' object or similar structure depending on configuration.
                 # Actually for an action with args email and password, the body is {"action": {"name": "ownerLogin"}, "input": {"email": "...", "password": "..."}}

@app.post("/ownerLogin")
def owner_login(req: dict):
    # Extract credentials
    params = req.get("input", {})
    email = params.get("email")
    password = params.get("password")

    # TODO: Validate against DB. For now, mock response.
    if email == "admin@enatega.com" and password == "123456":
        return {
            "userId": "1", # Mock ID
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

@app.get("/")
def read_root():
    return {"Hello": "World", "Service": "Enatega Backend"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
