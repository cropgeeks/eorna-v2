-- Revoke all default privileges
REVOKE ALL PRIVILEGES, GRANT OPTION
  FROM 'eorna2'@'%';

-- Grant read-only access
GRANT SELECT
  ON eorna2.*
  TO 'eorna2'@'%';

FLUSH PRIVILEGES;

