-- =====================================================================
-- FitBud: server-side logic (replaces Cloud Functions + client-side
-- Firestore transactions), realtime publication, storage, retention.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Notification helper + push fan-out
-- ---------------------------------------------------------------------
create or replace function public.notify_user(
  uid uuid, ntype text, ntitle text, nbody text, ndata jsonb default '{}'::jsonb
) returns void
language sql security definer set search_path = public as $$
  insert into public.notifications (user_id, type, title, body, data)
  values (uid, ntype, ntitle, nbody, ndata);
$$;
revoke all on function public.notify_user(uuid, text, text, text, jsonb) from public, anon, authenticated;

-- Every new notifications row is pushed (FCM) by the `push-notification`
-- edge function. The shared secret lives in Supabase Vault
-- (name: push_webhook_secret); without it the push is simply skipped.
create or replace function public.notifications_push() returns trigger
language plpgsql security definer set search_path = public as $$
declare secret text;
begin
  begin
    select decrypted_secret into secret from vault.decrypted_secrets
     where name = 'push_webhook_secret' limit 1;
    if secret is not null then
      perform net.http_post(
        url     := 'https://tcvldfsydgxxfdyrwspv.supabase.co/functions/v1/push-notification',
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-webhook-secret', secret),
        body    := jsonb_build_object('record', to_jsonb(new))
      );
    end if;
  exception when others then
    null; -- never let a push failure break the originating write
  end;
  return new;
end $$;
create trigger notifications_push_trg after insert on public.notifications
  for each row execute function public.notifications_push();

-- ---------------------------------------------------------------------
-- Buddy requests
-- ---------------------------------------------------------------------
create or replace function public.buddy_requests_guard() returns trigger
language plpgsql as $$
begin
  if auth.uid() is null then return new; end if;
  if new.from_user_id <> old.from_user_id or new.to_user_id <> old.to_user_id then
    raise exception 'cannot change parties of a request' using errcode = '42501';
  end if;
  if new.status is distinct from old.status then
    if new.status in ('accepted', 'rejected') and auth.uid() <> old.to_user_id then
      raise exception 'only the receiver can accept/decline' using errcode = '42501';
    end if;
    if new.status = 'accepted' then
      raise exception 'use accept_buddy_request()' using errcode = '42501';
    end if;
    if new.status in ('cancelled', 'pending') and auth.uid() <> old.from_user_id then
      raise exception 'only the sender can cancel/reopen' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;
create trigger buddy_requests_guard_trg before update on public.buddy_requests
  for each row execute function public.buddy_requests_guard();

create or replace function public.buddy_requests_notify_ins() returns trigger
language plpgsql security definer set search_path = public as $$
declare nm text;
begin
  if new.status <> 'pending' then return new; end if;
  select coalesce(display_name, 'Someone') into nm from public.profiles where id = new.from_user_id;
  perform public.notify_user(new.to_user_id, 'buddy_request', 'New Buddy Request',
    nm || ' sent you a buddy request',
    jsonb_build_object('fromUserId', new.from_user_id, 'requestId', new.id));
  return new;
end $$;
create trigger buddy_requests_notify_ins_trg after insert on public.buddy_requests
  for each row execute function public.buddy_requests_notify_ins();

create or replace function public.accept_buddy_request(request_id text) returns void
language plpgsql security definer set search_path = public as $$
declare
  r   public.buddy_requests%rowtype;
  a   uuid; b uuid; fid text; nm text;
begin
  select * into r from public.buddy_requests where id = request_id for update;
  if not found then raise exception 'Request not found' using errcode = 'P0002'; end if;
  if r.to_user_id <> auth.uid() then raise exception 'Only receiver can accept' using errcode = '42501'; end if;
  if r.status <> 'pending' then return; end if;
  if public.is_blocked_either_way(r.from_user_id) then
    raise exception 'Cannot accept' using errcode = '42501';
  end if;

  update public.buddy_requests set status = 'accepted', responded_at = now() where id = r.id;

  if r.from_user_id::text < r.to_user_id::text then a := r.from_user_id; b := r.to_user_id;
  else a := r.to_user_id; b := r.from_user_id; end if;
  fid := a::text || '_' || b::text;
  insert into public.friendships (id, user_a_id, user_b_id, user_ids)
  values (fid, a, b, array[a, b]) on conflict (id) do nothing;

  select coalesce(display_name, 'Someone') into nm from public.profiles where id = r.to_user_id;
  perform public.notify_user(r.from_user_id, 'buddy_accepted', 'Buddy Request Accepted',
    nm || ' accepted your buddy request',
    jsonb_build_object('toUserId', r.to_user_id, 'requestId', r.id));
end $$;

create or replace function public.remove_friendship(other uuid) returns void
language sql security definer set search_path = public as $$
  delete from public.friendships where user_ids @> array[auth.uid(), other];
$$;

-- ---------------------------------------------------------------------
-- Direct / group conversations
-- ---------------------------------------------------------------------
create or replace function public.get_or_create_direct_conversation(other uuid) returns text
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); cid text;
begin
  if me is null then raise exception 'not signed in' using errcode = '42501'; end if;
  if other is null then raise exception 'Other user id is empty'; end if;
  if other = me then raise exception 'Cannot chat with yourself'; end if;
  if public.is_blocked_either_way(other) then raise exception 'Cannot chat with this user' using errcode = '42501'; end if;

  cid := case when me::text < other::text then 'direct_' || me || '_' || other
              else 'direct_' || other || '_' || me end;
  if exists (select 1 from public.conversations where id = cid) then
    -- make sure *I* still have it in my inbox + participants (after delete-for-me)
    insert into public.conversation_participants (conversation_id, user_id)
      values (cid, me) on conflict do nothing;
    insert into public.inbox (user_id, conversation_id, type) values (me, cid, 'direct') on conflict do nothing;
    return cid;
  end if;

  insert into public.conversations (id, type, created_by_user_id) values (cid, 'direct', me);
  insert into public.conversation_participants (conversation_id, user_id, last_read_at) values (cid, me, now());
  insert into public.conversation_participants (conversation_id, user_id) values (cid, other);
  insert into public.inbox (user_id, conversation_id, type) values (me, cid, 'direct'), (other, cid, 'direct');
  return cid;
end $$;

create or replace function public.create_group(
  p_group_id text, p_title text, p_description text, p_photo_url text, p_members uuid[]
) returns text
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid(); gid text := coalesce(nullif(p_group_id, ''), gen_random_uuid()::text);
  cid text; members uuid[]; m uuid;
begin
  if me is null then raise exception 'not signed in' using errcode = '42501'; end if;
  cid := 'group_' || gid;
  select array(select distinct x from unnest(coalesce(p_members, '{}') || me) x) into members;

  insert into public.groups (id, title, photo_url, description, created_by_user_id, member_count)
  values (gid, p_title, coalesce(p_photo_url, ''), coalesce(p_description, ''), me, cardinality(members));

  insert into public.conversations (id, type, title, group_id, created_by_user_id)
  values (cid, 'group', p_title, gid, me);

  foreach m in array members loop
    insert into public.group_members (group_id, user_id, role)
    values (gid, m, case when m = me then 'owner' else 'member' end);
    insert into public.conversation_participants (conversation_id, user_id, last_read_at)
    values (cid, m, case when m = me then now() end);
    insert into public.inbox (user_id, conversation_id, type, title, photo_url, group_id)
    values (m, cid, 'group', p_title, coalesce(p_photo_url, ''), gid);
  end loop;
  return gid;
end $$;

create or replace function public.accept_group_invite(invite_id text) returns void
language plpgsql security definer set search_path = public as $$
declare i public.group_invites%rowtype; g public.groups%rowtype; cid text;
begin
  select * into i from public.group_invites where id = invite_id for update;
  if not found then raise exception 'Invite not found' using errcode = 'P0002'; end if;
  if i.invited_user_id <> auth.uid() then raise exception 'Not your invite' using errcode = '42501'; end if;
  if i.status <> 'pending' then return; end if;
  select * into g from public.groups where id = i.group_id;
  cid := 'group_' || i.group_id;

  update public.group_invites set status = 'accepted', responded_at = now() where id = i.id;
  insert into public.group_members (group_id, user_id, role) values (i.group_id, auth.uid(), 'member')
    on conflict do nothing;
  update public.groups set member_count = (select count(*) from public.group_members where group_id = i.group_id),
                           updated_at = now() where id = i.group_id;
  insert into public.conversation_participants (conversation_id, user_id) values (cid, auth.uid())
    on conflict do nothing;
  insert into public.inbox (user_id, conversation_id, type, title, photo_url, group_id)
    values (auth.uid(), cid, 'group', g.title, g.photo_url, g.id) on conflict do nothing;
end $$;

create or replace function public.decline_group_invite(invite_id text) returns void
language sql security definer set search_path = public as $$
  update public.group_invites set status = 'declined', responded_at = now()
   where id = invite_id and invited_user_id = auth.uid() and status = 'pending';
$$;

create or replace function public.group_invites_notify() returns trigger
language plpgsql security definer set search_path = public as $$
declare nm text; gt text;
begin
  select coalesce(display_name, 'Someone') into nm from public.profiles where id = new.invited_by_user_id;
  select title into gt from public.groups where id = new.group_id;
  perform public.notify_user(new.invited_user_id, 'group_invite', 'Group Invitation',
    nm || ' invited you to ' || coalesce(gt, 'a group'),
    jsonb_build_object('groupId', new.group_id, 'inviteId', new.id, 'invitedByUserId', new.invited_by_user_id));
  return new;
end $$;
create trigger group_invites_notify_trg after insert on public.group_invites
  for each row execute function public.group_invites_notify();

-- Chat state for "me"
create or replace function public.mark_conversation_read(cid text) returns void
language sql security definer set search_path = public as $$
  update public.conversation_participants set last_read_at = now()
   where conversation_id = cid and user_id = auth.uid();
  update public.inbox set unread_count = 0, updated_at = now()
   where conversation_id = cid and user_id = auth.uid();
$$;

create or replace function public.leave_conversation(cid text) returns void
language sql security definer set search_path = public as $$
  delete from public.conversation_participants where conversation_id = cid and user_id = auth.uid();
  delete from public.inbox where conversation_id = cid and user_id = auth.uid();
$$;

create or replace function public.delete_chat_for_me(cid text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.conversation_participants where conversation_id = cid and user_id = auth.uid()) then
    raise exception 'Not a participant' using errcode = '42501';
  end if;
  update public.conversation_participants set cleared_at = now(), last_read_at = now()
   where conversation_id = cid and user_id = auth.uid();
  delete from public.inbox where conversation_id = cid and user_id = auth.uid();
end $$;

-- ---------------------------------------------------------------------
-- Sessions
-- ---------------------------------------------------------------------
create or replace function public.create_session_invite(
  p_session_id text, p_invited_user uuid
) returns text
language plpgsql security definer set search_path = public as $$
declare s public.sessions%rowtype; me public.profiles%rowtype; iid text;
begin
  select * into s from public.sessions where id = p_session_id;
  if not found then raise exception 'Session not found' using errcode = 'P0002'; end if;
  select * into me from public.profiles where id = auth.uid();
  insert into public.session_invites (
    session_id, invited_user_id, invited_by_user_id, session_category,
    session_location_text, session_date_time, invited_by_name, invited_by_photo_url)
  values (p_session_id, p_invited_user, auth.uid(),
          coalesce(nullif(s.title, ''), s.type), s.location_name, s.start_at,
          coalesce(me.display_name, ''), coalesce(me.photo_url, ''))
  returning id into iid;
  return iid;
end $$;

create or replace function public.accept_session_invite(invite_id text) returns void
language plpgsql security definer set search_path = public as $$
declare i public.session_invites%rowtype;
begin
  select * into i from public.session_invites where id = invite_id for update;
  if not found then raise exception 'Invite not found' using errcode = 'P0002'; end if;
  if i.invited_user_id <> auth.uid() then raise exception 'Not your invite' using errcode = '42501'; end if;
  if i.status <> 'pending' then return; end if;
  update public.session_invites set status = 'accepted', responded_at = now() where id = i.id;
  insert into public.session_participants (session_id, user_id) values (i.session_id, auth.uid())
    on conflict do nothing;
end $$;

create or replace function public.decline_session_invite(invite_id text) returns void
language sql security definer set search_path = public as $$
  update public.session_invites set status = 'declined', responded_at = now()
   where id = invite_id and invited_user_id = auth.uid() and status = 'pending';
$$;

create or replace function public.session_invites_notify_ins() returns trigger
language plpgsql security definer set search_path = public as $$
declare nm text;
begin
  if new.status <> 'pending' then return new; end if;
  nm := coalesce(nullif(new.invited_by_name, ''),
                 (select display_name from public.profiles where id = new.invited_by_user_id), 'Someone');
  perform public.notify_user(new.invited_user_id, 'session_invite', 'Session Invitation',
    nm || ' invited you to ' || coalesce(nullif(new.session_category, ''), 'a session'),
    jsonb_build_object('sessionId', new.session_id, 'inviteId', new.id, 'invitedByUserId', new.invited_by_user_id));
  return new;
end $$;
create trigger session_invites_notify_ins_trg after insert on public.session_invites
  for each row execute function public.session_invites_notify_ins();

create or replace function public.session_invites_notify_upd() returns trigger
language plpgsql security definer set search_path = public as $$
declare nm text;
begin
  if new.status is not distinct from old.status or new.status <> 'accepted' then return new; end if;
  select coalesce(display_name, 'Someone') into nm from public.profiles where id = new.invited_user_id;
  perform public.notify_user(new.invited_by_user_id, 'session_invite', 'Session Invite Accepted',
    nm || ' accepted your invite to ' || coalesce(nullif(new.session_category, ''), 'your session'),
    jsonb_build_object('sessionId', new.session_id, 'inviteId', new.id, 'invitedUserId', new.invited_user_id));
  return new;
end $$;
create trigger session_invites_notify_upd_trg after update on public.session_invites
  for each row execute function public.session_invites_notify_upd();

-- ---------------------------------------------------------------------
-- Addresses (max 2 per user)
-- ---------------------------------------------------------------------
create or replace function public.add_address_enforce_max2(
  p_label text, p_city text, p_lat double precision, p_lng double precision,
  p_is_default boolean default false, p_make_default_if_first boolean default true
) returns text
language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); n int; victim text; new_id text; make_default boolean;
begin
  if me is null then raise exception 'not signed in' using errcode = '42501'; end if;
  select count(*) into n from public.user_addresses where user_id = me;
  make_default := (n = 0 and p_make_default_if_first);
  if n >= 2 then
    select id into victim from public.user_addresses where user_id = me
     order by is_default asc, coalesce(updated_at, created_at) asc limit 1;
    delete from public.user_addresses where id = victim;
  end if;
  if make_default then
    update public.user_addresses set is_default = false, updated_at = now() where user_id = me;
  end if;
  insert into public.user_addresses (user_id, label, city, lat, lng, is_default)
  values (me, p_label, p_city, p_lat, p_lng, make_default or p_is_default)
  returning id into new_id;
  return new_id;
end $$;

create or replace function public.set_default_address(address_id text) returns void
language sql security definer set search_path = public as $$
  update public.user_addresses set is_default = (id = address_id), updated_at = now()
   where user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------
-- Gym check-in (replaces the scanGym callable)
-- ---------------------------------------------------------------------
create or replace function public.scan_gym(
  p_gym_id text, p_client_scan_id text, p_device_id text default ''
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid(); g public.gyms%rowtype; existing text; last_ts timestamptz;
  cooldown int := 120; mins_left int; local_ts timestamp; dk text; hr int; sid text;
begin
  if me is null then raise exception 'User is not signed in.' using errcode = '42501'; end if;
  if coalesce(btrim(p_gym_id), '') = '' then raise exception 'gymId is required.'; end if;
  if coalesce(btrim(p_client_scan_id), '') = '' then raise exception 'clientScanId is required.'; end if;

  select * into g from public.gyms where id = p_gym_id;
  if not found then raise exception 'Gym not found.' using errcode = 'P0002'; end if;
  if g.status in ('inactive', 'suspended') then
    return jsonb_build_object('ok', false, 'result', 'gym_inactive',
      'message', 'This gym isn''t currently accepting check-ins.');
  end if;

  select id into existing from public.scans where user_id = me and client_scan_id = p_client_scan_id;
  if existing is not null then
    return jsonb_build_object('ok', true, 'scanId', existing, 'result', 'already_processed',
      'message', 'This check-in was already recorded.');
  end if;

  select max(scanned_at) into last_ts from public.scans where user_id = me and gym_id = p_gym_id;
  if last_ts is not null and extract(epoch from (now() - last_ts)) / 60 < cooldown then
    mins_left := ceil(cooldown - extract(epoch from (now() - last_ts)) / 60);
    return jsonb_build_object('ok', false, 'result', 'cooldown',
      'message', 'You already checked in recently. Try again in about ' || mins_left || ' minute(s).');
  end if;

  local_ts := now() at time zone 'Asia/Karachi';
  dk := to_char(local_ts, 'YYYY-MM-DD');
  hr := extract(hour from local_ts)::int;

  insert into public.scans (user_id, gym_id, client_scan_id, device_id, day_key, hour)
  values (me, p_gym_id, p_client_scan_id, coalesce(p_device_id, ''), dk, hr)
  returning id into sid;

  insert into public.gym_stats_daily (gym_id, day_key, total, hours)
  values (p_gym_id, dk, 1, jsonb_build_object(hr::text, 1))
  on conflict (gym_id, day_key) do update
    set total = public.gym_stats_daily.total + 1,
        hours = jsonb_set(public.gym_stats_daily.hours, array[hr::text],
                  to_jsonb(coalesce((public.gym_stats_daily.hours ->> hr::text)::int, 0) + 1)),
        updated_at = now();

  return jsonb_build_object('ok', true, 'scanId', sid, 'result', 'accepted', 'message', 'Checked in!');
end $$;

-- ---------------------------------------------------------------------
-- Session recency (used by the sensitive "delete account" flow)
-- ---------------------------------------------------------------------
create or replace function public.session_age_minutes() returns double precision
language sql stable security definer set search_path = public, auth as $$
  select extract(epoch from (now() - created_at)) / 60
    from auth.sessions
   where id = nullif(auth.jwt() ->> 'session_id', '')::uuid
$$;

-- ---------------------------------------------------------------------
-- Function privileges: RPCs are for signed-in users only.
-- ---------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on function
  public.is_admin(), public.is_blocked_either_way(uuid), public.is_participant(text), public.is_group_member(text),
  public.accept_buddy_request(text), public.remove_friendship(uuid),
  public.get_or_create_direct_conversation(uuid),
  public.create_group(text, text, text, text, uuid[]),
  public.accept_group_invite(text), public.decline_group_invite(text),
  public.mark_conversation_read(text), public.leave_conversation(text), public.delete_chat_for_me(text),
  public.create_session_invite(text, uuid), public.accept_session_invite(text), public.decline_session_invite(text),
  public.add_address_enforce_max2(text, text, double precision, double precision, boolean, boolean),
  public.set_default_address(text),
  public.scan_gym(text, text, text),
  public.session_age_minutes()
to authenticated;
-- notify_user() stays server-only.
revoke execute on function public.notify_user(uuid, text, text, text, jsonb) from authenticated;

-- ---------------------------------------------------------------------
-- Realtime (RLS applies to realtime too)
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table
  public.profiles, public.user_settings, public.user_addresses, public.user_blocks, public.notifications,
  public.activities, public.gyms, public.plans, public.products,
  public.subscriptions, public.transactions,
  public.buddy_requests, public.friendships,
  public.conversation_participants, public.messages, public.inbox,
  public.groups, public.group_members, public.group_invites,
  public.sessions, public.session_participants, public.session_invites,
  public.scans, public.reports;

-- ---------------------------------------------------------------------
-- Storage
--   avatars    : users/{uid}/profile.jpg , groups/{gid}/avatar.jpg   (public read)
--   chat-media : {conversationId}/{uid}/{file}                        (public read, participant write)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('avatars',    'avatars',    true, 10485760, array['image/jpeg','image/png','image/webp']),
  ('chat-media', 'chat-media', true, 52428800, null)
on conflict (id) do nothing;

create policy "avatars read" on storage.objects for select using (bucket_id = 'avatars');
create policy "avatars own profile write" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = 'users'
              and (storage.foldername(name))[2] = auth.uid()::text);
create policy "avatars own profile update" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = 'users'
         and (storage.foldername(name))[2] = auth.uid()::text);
create policy "avatars own profile delete" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = 'users'
         and (storage.foldername(name))[2] = auth.uid()::text);
create policy "avatars group write" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = 'groups');
create policy "avatars group update" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = 'groups'
         and public.is_group_member((storage.foldername(name))[2]));

create policy "chat media read" on storage.objects for select using (bucket_id = 'chat-media');
create policy "chat media write" on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-media'
              and (storage.foldername(name))[2] = auth.uid()::text
              and public.is_participant((storage.foldername(name))[1]));

-- ---------------------------------------------------------------------
-- Retention: purge gym check-ins older than 730 days (placeholder period,
-- same as the old purgeExpiredGymScans function).
-- ---------------------------------------------------------------------
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('purge-expired-gym-scans', '17 3 * * *',
  $$delete from public.scans where scanned_at < now() - interval '730 days'$$);
