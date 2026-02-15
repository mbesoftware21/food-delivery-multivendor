@app.post("/restaurantByOwner")
def restaurant_by_owner(req: dict):
    """
    Hasura Action for restaurantByOwner.
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
                raise HTTPException(status_code=404, detail="Owner not found")
            
            # Get restaurants
            cur.execute("""
                SELECT 
                    r.id, r.name, r.slug, r.image,
                    r.address, r.is_active, r.delivery_time, r.minimum_order,
                    r.location
                FROM restaurants r
                WHERE r.owner_id = %s
                ORDER BY r.created_at DESC
            """, (owner_id,))
            
            restaurant_rows = cur.fetchall()
            restaurants = []
            
            for row in restaurant_rows:
                rest_id = row[0]
                
                # Get delivery info
                cur.execute("""
                    SELECT min_delivery_fee, delivery_distance, delivery_fee
                    FROM restaurant_zones
                    WHERE restaurant_id = %s
                    LIMIT 1
                """, (rest_id,))
                delivery_row = cur.fetchone()
                
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
                    # Extract coordinates from geography
                    cur.execute("""
                        SELECT ST_X(%s::geometry), ST_Y(%s::geometry)
                    """, (row[8], row[8]))
                    coords = cur.fetchone()
                    if coords:
                        location = {
                            "coordinates": [coords[0], coords[1]]
                        }
                
                restaurants.append({
                    "_id": str(rest_id),
                    "unique_restaurant_id": str(rest_id),
                    "orderId": "",
                    "orderPrefix": "",
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
                        "minDeliveryFee": float(delivery_row[0]) if delivery_row and delivery_row[0] else 0,
                        "deliveryDistance": float(delivery_row[1]) if delivery_row and delivery_row[1] else 0,
                        "deliveryFee": float(delivery_row[2]) if delivery_row and delivery_row[2] else 0
                    } if delivery_row else {
                        "minDeliveryFee": 0,
                        "deliveryDistance": 0,
                        "deliveryFee": 0
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
