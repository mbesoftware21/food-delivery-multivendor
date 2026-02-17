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

     SELECT
         json_agg(
             json_build_object(
                 'unique_restaurant_id', r.id::text,
                 '_id', r._id,
                 'name', r.name,
                 'image', r.image,
                 'orderPrefix', 'ORD',
                 'slug', r.slug,
                 'address', r.address,
                 'deliveryTime', r.delivery_time,
                 'minimumOrder', r.minimum_order,
                 'isActive', r.is_active,
                 'commissionRate', COALESCE(rs.commission_rate, 0),
                 'username', '',
                 'tax', COALESCE(rs.tax, 0),
                 'owner', json_build_object(
                     '_id', u._id,
                     'email', u.email,
                     'isActive', u.is_active
                 ),
                 'shopType', 'restaurant'
             )
         ),
         v_total_count,
         page,
         v_total_pages
     INTO v_result."data", v_result."totalCount", v_result."currentPage", v_result."totalPages"
     FROM restaurants r
     LEFT JOIN users u ON r.owner_id = u.id
     LEFT JOIN restaurant_settings rs ON r.id = rs.restaurant_id
     WHERE (search IS NULL OR search = '' OR r.name ILIKE '%' || search || '%' OR r.address ILIKE '%' || search || '%')
     ORDER BY r.created_at DESC
     LIMIT "limit" OFFSET v_offset;

     RETURN NEXT v_result;
 END;
 $function$
