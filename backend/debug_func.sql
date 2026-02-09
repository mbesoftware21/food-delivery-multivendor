-- Debug script
DROP FUNCTION IF EXISTS test_func(text);
CREATE FUNCTION test_func(p_email text) 
RETURNS TABLE (
    email text
) AS $$
BEGIN
    email := p_email;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
