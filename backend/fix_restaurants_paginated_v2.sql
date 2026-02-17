CREATE OR REPLACE FUNCTION public.restaurants_paginated(page integer DEFAULT 1, "limit" integer DEFAULT 10, search text DEFAULT ''::text)
 RETURNS SETOF restaurants_paginated_response
 LANGUAGE plpgsql
 STABLE
AS $function$
 DECLARE
     v_offset INT;
     v_total_count INT;
     v_total_pages INT;
     v_result restaurants_paginated_response%ROWTYPE;
 BEGIN
     -- Calculate offset
     v_offset := (page - 1) * "limit";

     -- Get total count
     IF search IS NOT NULL AND search != '' THEN
         SELECT COUNT(*) INTO v_total_count
         FROM restaurants r
         WHERE r.name ILIKE '%' || search || '%' OR r.address ILIKE '%' || search || '%';
     ELSE
         SELECT COUNT(*) INTO v_total_count FROM restaurants;
     END IF;

     v_total_pages := CEIL(v_total_count::FLOAT / "limit");

     -- Build JSON array of restaurants via subquery
     SELECT
         COALESCE(json_agg(row_to_json(t)), '[]'::json)
     INTO v_result."data"
     FROM (
         SELECT
             r.id::text as "unique_restaurant_id",
             r._id as "_id",
             r.name as "name",
             r.image as "image",
             'ORD' as "orderPrefix",
             r.slug as "slug",
             r.address as "address",
             r.delivery_time as "deliveryTime",
             r.minimum_order as "minimumOrder",
             r.is_active as "isActive",
             COALESCE(rs.commission_rate, 0) as "commissionRate",
             '' as "username",
             COALESCE(rs.tax, 0) as "tax",
             json_build_object(
                 '_id', u._id,
                 'email', u.email,
                 'isActive', u.is_active
             ) as "owner",
             'restaurant' as "shopType"
         FROM restaurants r
         LEFT JOIN users u ON r.owner_id = u.id
         LEFT JOIN restaurant_settings rs ON r.id = rs.restaurant_id
         WHERE (search IS NULL OR search = '' OR r.name ILIKE '%' || search || '%' OR r.address ILIKE '%' || search || '%')
         ORDER BY r.created_at DESC
         LIMIT "limit" OFFSET v_offset
     ) t;

     v_result."totalCount" := v_total_count;
     v_result."currentPage" := page;
     v_result."totalPages" := v_total_pages;

     RETURN NEXT v_result;
 END;
 $function$
