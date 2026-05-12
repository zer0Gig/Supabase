-- ─────────────────────────────────────────────────────────────────────────────
-- Add Indonesian sub-country location fields to community signups.
--
-- Background: globe currently plots all Indonesian signups at the Jakarta
-- centroid (country lat/lng). With 6+ PT partners onboarding from various
-- Indonesian cities, the cluster looks like a single dot instead of a
-- distributed coalition. New columns let onboarding capture city + kecamatan
-- (sub-district) and the signup API overrides latitude/longitude with the
-- looked-up city coordinates so the globe shows real geography.
-- ─────────────────────────────────────────────────────────────────────────────

alter table community_signups
  add column if not exists city      text,
  add column if not exists kecamatan text;

-- Refresh the country aggregate view so it ignores city-level coords. The
-- existing view already groups by country_code so this is a no-op for
-- correctness — but recreating ensures the schema matches the latest
-- expectations even after column adds.
--
-- (View definition unchanged — country breakdown stays country-centric.)

-- Per-location view for Indonesia: groups signups by (city, latitude,
-- longitude) so the globe can render distinct city dots within Indonesia.
-- Non-ID rows excluded — country-level aggregation still serves them.
create or replace view community_id_cities as
select
  city,
  latitude,
  longitude,
  count(*)                                                       as signup_count,
  count(*) filter (where role = 'client')                        as clients_count,
  count(*) filter (where role = 'agent_owner')                   as agent_owners_count
from community_signups
where country_code = 'ID' and city is not null and city <> ''
group by city, latitude, longitude;

grant select on community_id_cities to anon;
