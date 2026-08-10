-- scripts/reset.sql
--
-- Wipes and reseeds all three practice schemas. Run manually — this file is
-- NEVER executed automatically on container init (only database/01_schema.sql
-- and database/02_seed.sql are mounted into /docker-entrypoint-initdb.d).
--
-- Usage (from repo root, container already running via `docker compose up -d`):
--   docker compose exec -T postgres psql -U postgres -d practice < scripts/reset.sql
--
-- The \i paths below are container paths: docker-compose.yml bind-mounts
-- ./database into /docker-entrypoint-initdb.d for the life of the container,
-- so these files stay readable there even outside of first-boot init.

DROP SCHEMA IF EXISTS employees CASCADE;
DROP SCHEMA IF EXISTS ecommerce CASCADE;
DROP SCHEMA IF EXISTS sakila CASCADE;

\i /docker-entrypoint-initdb.d/01_schema.sql
\i /docker-entrypoint-initdb.d/02_seed.sql
