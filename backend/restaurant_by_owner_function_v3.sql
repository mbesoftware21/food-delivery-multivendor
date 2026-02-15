-- Drop existing function and type
DROP FUNCTION IF EXISTS public.restaurant_by_owner(text);
DROP TYPE IF EXISTS public.restaurant_by_owner_result;

-- Create function with RETURNS TABLE
CREATE OR REPLACE FUNCTION public.restaurant_by_owner(owner_id_input text)
RETURNS TABLE (
    "_id" text,
    email text,
    "userType" text,
    restaurants jsonb
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id::text AS "_id",
        u.email,
        u.user_type AS "userType",
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    '_id', r.id::text,
                    'unique_restaurant_id', r.id::text,
                    'orderId', r.order_id,
                    'orderPrefix', r.order_prefix,
                    'name', r.name,
                    'slug', r.slug,
                    'image', r.image,
                    'address', r.address,
                    'isActive', r.is_active,
                    'deliveryTime', r.delivery_time,
                    'minimumOrder', r.minimum_order,
                    'username', '',
                    'password', '',
                    'location', CASE 
                        WHEN r.location IS NOT NULL 
                        THEN jsonb_build_object('coordinates', jsonb_build_array(
                            ST_X(r.location::geometry),
                            ST_Y(r.location::geometry)
                        ))
                        ELSE NULL 
                    END,
                    'deliveryInfo', (
                        SELECT jsonb_build_object(
                            'minDeliveryFee', COALESCE(rz.min_delivery_fee, 0),
                            'deliveryDistance', COALESCE(rz.delivery_distance, 0),
                            'deliveryFee', COALESCE(rz.delivery_fee, 0)
                        )
                        FROM restaurant_zones rz
                        WHERE rz.restaurant_id = r.id
                        LIMIT 1
                    ),
                    'openingTimes', (
                        SELECT COALESCE(jsonb_agg(
                            jsonb_build_object(
                                'day', ot.day,
                                'times', jsonb_build_array(
                                    jsonb_build_object(
                                        'startTime', ARRAY[
                                            EXTRACT(HOUR FROM ot.start_time)::text,
                                            LPAD(EXTRACT(MINUTE FROM ot.start_time)::text, 2, '0')
                                        ],
                                        'endTime', ARRAY[
                                            EXTRACT(HOUR FROM ot.end_time)::text,
                                            LPAD(EXTRACT(MINUTE FROM ot.end_time)::text, 2, '0')
                                        ]
                                    )
                                )
                            )
                        ), '[]'::jsonb)
                        FROM opening_times ot
                        WHERE ot.restaurant_id = r.id
                    ),
                    'shopType', r.shop_type
                )
            ) FILTER (WHERE r.id IS NOT NULL),
            '[]'::jsonb
        ) AS restaurants
    FROM users u
    LEFT JOIN restaurants r ON r.owner_id = u.id
    WHERE u.id = owner_id_input::uuid
    GROUP BY u.id, u.email, u.user_type;
END;
$$;
