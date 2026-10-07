-- =====================================================================
-- Optional: connect YOUR account to the demo people from seed.sql so the
-- Buddies / Chat / Notifications / Home screens have content to show.
--
-- 1. Sign up in the app with your own email first.
-- 2. Put that email below, then run this in the Supabase SQL editor
--    (it runs as the postgres role, so it bypasses RLS on purpose).
-- Safe to re-run.
-- =====================================================================
do $$
declare
  target_email text := 'you@example.com';   -- <<< CHANGE ME
  me uuid;
  demo uuid;
  a uuid; b uuid; cid text; fid text;
  demo_ids uuid[] := array[
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000002',
    '00000000-0000-4000-8000-000000000003']::uuid[];
begin
  select id into me from auth.users where lower(email) = lower(target_email);
  if me is null then raise exception 'No auth user with email %', target_email; end if;

  -- make the demo profiles + me premium so everything is visible
  foreach demo in array demo_ids loop
    if me::text < demo::text then a := me; b := demo; else a := demo; b := me; end if;
    fid := a::text || '_' || b::text;
    insert into public.friendships (id, user_a_id, user_b_id, user_ids)
    values (fid, a, b, array[a, b]) on conflict (id) do nothing;

    cid := 'direct_' || a::text || '_' || b::text;
    insert into public.conversations (id, type, created_by_user_id) values (cid, 'direct', me)
      on conflict (id) do nothing;
    insert into public.conversation_participants (conversation_id, user_id) values (cid, me), (cid, demo)
      on conflict do nothing;
    insert into public.inbox (user_id, conversation_id, type) values (me, cid, 'direct'), (demo, cid, 'direct')
      on conflict do nothing;

    -- one greeting from the demo buddy (the trigger fills inbox + notification)
    if not exists (select 1 from public.messages where conversation_id = cid) then
      insert into public.messages (conversation_id, sender_user_id, text)
      values (cid, demo, 'Hey! Up for a workout this week?');
    end if;
  end loop;

  -- a pending buddy request from the 4th & 5th demo users
  insert into public.buddy_requests (from_user_id, to_user_id, message)
  select d, me, 'Saw we like the same sports - want to train together?'
    from unnest(array[
      '00000000-0000-4000-8000-000000000004',
      '00000000-0000-4000-8000-000000000005']::uuid[]) d
   where not exists (select 1 from public.buddy_requests r where r.from_user_id = d and r.to_user_id = me);

  -- a session invite
  insert into public.sessions (id, type, title, description, created_by_user_id, start_at, location_name, status)
  values ('demo_session_1', 'gym', 'Chest & Back Day', 'Push/pull split, all levels welcome.',
          demo_ids[1], now() + interval '2 days', '360 GYM Commercial Area', 'scheduled')
  on conflict (id) do nothing;
  insert into public.session_participants (session_id, user_id) values ('demo_session_1', demo_ids[1])
    on conflict do nothing;
  if not exists (select 1 from public.session_invites where session_id = 'demo_session_1' and invited_user_id = me) then
    insert into public.session_invites (
      session_id, invited_user_id, invited_by_user_id, session_category,
      session_location_text, session_date_time, invited_by_name)
    values ('demo_session_1', me, demo_ids[1], 'Chest & Back Day',
            '360 GYM Commercial Area', now() + interval '2 days', 'Ayesha Khan');
  end if;
end $$;
