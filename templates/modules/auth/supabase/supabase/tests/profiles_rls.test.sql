-- Row Level Security tests for profiles (pgTAP): a user sees and changes
-- only their own profile; signed-out users see nothing.
-- Run: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

-- Two users; the trigger creates their profiles.
insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

select ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'RLS is enabled on profiles'
);

select results_eq(
  $$ select count(*)::int from public.profiles $$,
  $$ values (2) $$,
  'a profile is created for every new user'
);

-- Signed out.
set local role anon;
select results_eq(
  $$ select count(*)::int from public.profiles $$,
  $$ values (0) $$,
  'anon sees no profiles'
);

-- Signed in as Alice.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

select results_eq(
  $$ select id::text from public.profiles $$,
  $$ values ('11111111-1111-1111-1111-111111111111') $$,
  'a user sees only their own profile'
);

select results_eq(
  $$ with changed as (
       update public.profiles set display_name = 'Alice' returning id
     ) select count(*)::int from changed $$,
  $$ values (1) $$,
  'a user can update their own profile'
);

select results_eq(
  $$ with changed as (
       update public.profiles set display_name = 'hacked'
       where id = '22222222-2222-2222-2222-222222222222' returning id
     ) select count(*)::int from changed $$,
  $$ values (0) $$,
  'a user cannot change another user''s profile'
);

select throws_ok(
  $$ insert into public.profiles (id) values ('33333333-3333-3333-3333-333333333333') $$,
  '42501',
  null,
  'a user cannot insert profiles'
);

-- Deleting the account removes the profile (as the delete-account function does).
reset role;
delete from auth.users where id = '11111111-1111-1111-1111-111111111111';
select results_eq(
  $$ select count(*)::int from public.profiles where id = '11111111-1111-1111-1111-111111111111' $$,
  $$ values (0) $$,
  'deleting the account deletes the profile'
);

select * from finish();
rollback;
