-- =====================================================================
-- FitBud: initial schema (migrated from Firebase/Firestore)
--
-- Conventions
--   * snake_case columns; the Flutter client maps to/from camelCase.
--   * user ids are uuid (= auth.users.id); everything else keeps the
--     Firestore-style text ids (deterministic ids such as
--     'direct_<a>_<b>' / 'group_<gid>' / '<a>_<b>' are preserved).
--   * Security is enforced with RLS. Anything that fans out across several
--     users' rows (inbox, notifications, memberships) is done by
--     SECURITY DEFINER triggers / RPCs, never by the client.
-- =====================================================================

create extension if not exists pgcrypto;
create extension if not exists pg_net;

-- ---------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------
create or replace function public.is_admin() returns boolean
language sql stable as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'admin')::boolean, false)
$$;

create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- Profiles  (Firestore: users/{uid})
-- Not FK'd to auth.users on purpose: account deletion de-identifies the
-- row ("Deleted User") so old messages / groups still resolve a name.
-- ---------------------------------------------------------------------
create table public.profiles (
  id                     uuid primary key,
  display_name           text,
  email                  text,
  phone                  text,
  photo_url              text,
  is_premium             boolean not null default false,
  premium_until          timestamptz,
  active_plan_id         text,
  active_subscription_id text,
  activities             text[] not null default '{}',
  favourite_activity     text,
  has_gym                boolean,
  gym_name               text,
  about                  text,
  is_profile_complete    boolean,
  city                   text,
  gender                 text,
  dob                    timestamptz,
  is_active              boolean,
  fcm_tokens             text[] not null default '{}',
  deleted_at             timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);
create index profiles_discover_idx on public.profiles (is_active, is_premium, city);
create index profiles_activities_gin on public.profiles using gin (activities);

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Clients may never change premium state / FCM bookkeeping of a profile
-- except fcm_tokens; premium fields are written by trusted backend only.
create or replace function public.profiles_guard() returns trigger
language plpgsql as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.is_premium is distinct from old.is_premium
       or new.premium_until is distinct from old.premium_until
       or new.active_plan_id is distinct from old.active_plan_id
       or new.active_subscription_id is distinct from old.active_subscription_id
       or new.deleted_at is distinct from old.deleted_at then
      raise exception 'premium/subscription fields are server-managed'
        using errcode = '42501';
    end if;
  end if;
  return new;
end $$;
create trigger profiles_guard_trg before update on public.profiles
  for each row execute function public.profiles_guard();

create or replace function public.profiles_guard_insert() returns trigger
language plpgsql as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.is_premium := false;
    new.premium_until := null;
    new.active_plan_id := null;
    new.active_subscription_id := null;
    new.deleted_at := null;
  end if;
  return new;
end $$;
create trigger profiles_guard_insert_trg before insert on public.profiles
  for each row execute function public.profiles_guard_insert();

alter table public.profiles enable row level security;
create policy profiles_select on public.profiles for select to authenticated using (true);
create policy profiles_insert on public.profiles for insert to authenticated with check (id = auth.uid());
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
-- no delete policy: deletion goes through the delete-account edge function.

-- Auto-create a profile + settings row whenever an auth user appears.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, display_name, photo_url, is_active, is_profile_complete)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'display_name',
             new.raw_user_meta_data ->> 'full_name',
             new.raw_user_meta_data ->> 'name'),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture'),
    true,
    false
  ) on conflict (id) do nothing;
  insert into public.user_settings (user_id) values (new.id) on conflict do nothing;
  return new;
end $$;

-- ---------------------------------------------------------------------
-- Per-user tables
-- ---------------------------------------------------------------------
create table public.user_settings (
  user_id              uuid primary key,
  push_enabled         boolean not null default true,
  show_online_status   boolean not null default true,
  show_last_seen       boolean not null default true,
  allow_buddy_requests boolean not null default true,
  allow_group_invites  boolean not null default true,
  language             text not null default 'en',
  theme_mode           text not null default 'system',
  selected_address_id  text,
  updated_at           timestamptz not null default now()
);
alter table public.user_settings enable row level security;
create policy user_settings_all on public.user_settings for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create table public.user_addresses (
  id         text primary key default gen_random_uuid()::text,
  user_id    uuid not null,
  label      text not null default '',
  city       text not null default '',
  lat        double precision,
  lng        double precision,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index user_addresses_user_idx on public.user_addresses (user_id, is_default desc, updated_at desc);
alter table public.user_addresses enable row level security;
create policy user_addresses_all on public.user_addresses for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create table public.user_blocks (
  user_id         uuid not null,
  blocked_user_id uuid not null,
  created_at      timestamptz not null default now(),
  primary key (user_id, blocked_user_id)
);
alter table public.user_blocks enable row level security;
create policy user_blocks_all on public.user_blocks for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
-- A user must be able to learn that someone blocked them (two-way block check)
create or replace function public.is_blocked_either_way(other uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_blocks
    where (user_id = auth.uid() and blocked_user_id = other)
       or (user_id = other and blocked_user_id = auth.uid())
  )
$$;

create table public.notifications (
  id         text primary key default gen_random_uuid()::text,
  user_id    uuid not null,
  type       text not null default 'message',
  title      text not null default '',
  body       text not null default '',
  data       jsonb not null default '{}'::jsonb,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
alter table public.notifications enable row level security;
create policy notifications_select on public.notifications for select to authenticated using (user_id = auth.uid());
create policy notifications_update on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
-- inserts are server-side only (triggers below / service role)

-- ---------------------------------------------------------------------
-- Reference data
-- ---------------------------------------------------------------------
create table public.activities (
  id         text primary key,
  name       text not null,
  "order"    int  not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.gyms (
  id               text primary key,
  name             text not null default '',
  address          text not null default '',
  location         jsonb,                       -- {lat,lng}
  city             text not null default '',
  phone            text not null default '',
  logo_url         text not null default '',
  status           text not null default 'active',
  qr_public_id     text not null default '',
  years_of_service int not null default 0,
  members          int not null default 0,
  rating           double precision not null default 0,
  day_hours        text not null default '',
  night_hours      text not null default '',
  equipments       text[] not null default '{}',
  images           text[] not null default '{}',
  monthly_scans    int not null default 0,
  total_scans      int not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create table public.gym_stats_daily (
  gym_id     text not null references public.gyms(id) on delete cascade,
  day_key    text not null,
  total      int not null default 0,
  hours      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (gym_id, day_key)
);
create table public.plans (
  id            text primary key,
  name          text not null default '',
  description   text not null default '',
  price         double precision not null default 0,
  currency      text not null default 'PKR',
  duration_days int not null default 30,
  features      text[] not null default '{}',
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create table public.products (
  id          text primary key,
  title       text not null default '',
  description text not null default '',
  price       double precision not null default 0,
  image_url   text not null default '',
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

alter table public.activities     enable row level security;
alter table public.gyms           enable row level security;
alter table public.gym_stats_daily enable row level security;
alter table public.plans          enable row level security;
alter table public.products       enable row level security;

create policy activities_read on public.activities for select to authenticated using (true);
create policy activities_write on public.activities for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy gyms_read on public.gyms for select to authenticated using (true);
create policy gyms_write on public.gyms for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy gym_stats_read on public.gym_stats_daily for select to authenticated using (public.is_admin());
create policy plans_read on public.plans for select to authenticated using (true);
create policy plans_write on public.plans for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy products_read on public.products for select to authenticated using (true);
create policy products_write on public.products for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Subscriptions / payments (server-write-only)
-- ---------------------------------------------------------------------
create table public.subscriptions (
  id                 text primary key,           -- orderId
  user_id            uuid not null,
  plan_id            text not null default '',
  status             text not null default 'pending',
  provider           text not null default '',
  provider_sub_id    text not null default '',
  start_at           timestamptz,
  current_period_end timestamptz,
  cancelled_at       timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index subscriptions_user_idx on public.subscriptions (user_id, created_at desc);
create table public.transactions (
  id              text primary key default gen_random_uuid()::text,
  user_id         uuid not null,
  subscription_id text not null default '',
  amount          double precision not null default 0,
  currency        text not null default 'PKR',
  provider        text not null default '',
  provider_txn_id text not null default '',
  status          text not null default '',
  created_at      timestamptz not null default now()
);
create index transactions_user_idx on public.transactions (user_id, created_at desc);
alter table public.subscriptions enable row level security;
alter table public.transactions  enable row level security;
create policy subscriptions_read on public.subscriptions for select to authenticated using (user_id = auth.uid());
create policy transactions_read  on public.transactions  for select to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- Buddies
-- ---------------------------------------------------------------------
create table public.buddy_requests (
  id           text primary key default gen_random_uuid()::text,
  from_user_id uuid not null,
  to_user_id   uuid not null,
  status       text not null default 'pending',
  message      text not null default '',
  created_at   timestamptz not null default now(),
  responded_at timestamptz
);
create index buddy_requests_to_idx   on public.buddy_requests (to_user_id, created_at desc);
create index buddy_requests_from_idx on public.buddy_requests (from_user_id, created_at desc);
alter table public.buddy_requests enable row level security;
create policy buddy_requests_select on public.buddy_requests for select to authenticated
  using (from_user_id = auth.uid() or to_user_id = auth.uid());
create policy buddy_requests_insert on public.buddy_requests for insert to authenticated
  with check (from_user_id = auth.uid() and to_user_id <> auth.uid());
create policy buddy_requests_update on public.buddy_requests for update to authenticated
  using (from_user_id = auth.uid() or to_user_id = auth.uid());
create policy buddy_requests_delete on public.buddy_requests for delete to authenticated
  using (to_user_id = auth.uid());

create table public.friendships (
  id                 text primary key,            -- '<minUid>_<maxUid>'
  user_a_id          uuid not null,
  user_b_id          uuid not null,
  user_ids           uuid[] not null,
  is_blocked         boolean not null default false,
  blocked_by_user_id uuid,
  created_at         timestamptz not null default now()
);
create index friendships_user_ids_gin on public.friendships using gin (user_ids);
alter table public.friendships enable row level security;
create policy friendships_select on public.friendships for select to authenticated using (auth.uid() = any (user_ids));
create policy friendships_delete on public.friendships for delete to authenticated using (auth.uid() = any (user_ids));
-- creation only through accept_buddy_request()

-- ---------------------------------------------------------------------
-- Chat
-- ---------------------------------------------------------------------
create table public.conversations (
  id                   text primary key,
  type                 text not null default 'direct',
  title                text not null default '',
  group_id             text not null default '',
  created_by_user_id   uuid,
  last_message_id      text not null default '',
  last_message_preview text not null default '',
  last_message_at      timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
create table public.conversation_participants (
  conversation_id   text not null references public.conversations(id) on delete cascade,
  user_id           uuid not null,
  joined_at         timestamptz not null default now(),
  last_read_at      timestamptz,
  last_delivered_at timestamptz,
  cleared_at        timestamptz,
  is_muted          boolean not null default false,
  muted_until       timestamptz,
  primary key (conversation_id, user_id)
);
create index conv_participants_user_idx on public.conversation_participants (user_id);

create or replace function public.is_participant(cid text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.conversation_participants
                 where conversation_id = cid and user_id = auth.uid())
$$;

create table public.messages (
  id                text primary key default gen_random_uuid()::text,
  conversation_id   text not null references public.conversations(id) on delete cascade,
  sender_user_id    uuid not null,
  type              text not null default 'text',
  text              text not null default '',
  media_url         text not null default '',
  thumbnail_url     text not null default '',
  lat               double precision,
  lng               double precision,
  reply_to_message_id text not null default '',
  client_message_id text not null default '',
  client_created_at timestamptz,
  is_deleted        boolean not null default false,
  delivery_state    text not null default 'sent',
  created_at        timestamptz not null default now()
);
create index messages_conv_idx on public.messages (conversation_id, created_at desc);
create index messages_sender_idx on public.messages (sender_user_id);

create table public.inbox (
  user_id              uuid not null,
  conversation_id      text not null,
  type                 text not null default 'direct',
  title                text not null default '',
  photo_url            text not null default '',
  group_id             text not null default '',
  last_message_at      timestamptz,
  last_message_preview text not null default '',
  unread_count         int not null default 0,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  primary key (user_id, conversation_id)
);
create index inbox_user_idx on public.inbox (user_id, updated_at desc);

alter table public.conversations             enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages                  enable row level security;
alter table public.inbox                     enable row level security;

create policy conversations_select on public.conversations for select to authenticated using (public.is_participant(id));
create policy conversations_update on public.conversations for update to authenticated using (public.is_participant(id));
-- conversations are created via RPCs only.

create policy conv_participants_select on public.conversation_participants for select to authenticated
  using (user_id = auth.uid() or public.is_participant(conversation_id));
create policy conv_participants_update_self on public.conversation_participants for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy conv_participants_delete_self on public.conversation_participants for delete to authenticated
  using (user_id = auth.uid());

create policy messages_select on public.messages for select to authenticated using (public.is_participant(conversation_id));
create policy messages_insert on public.messages for insert to authenticated
  with check (public.is_participant(conversation_id) and sender_user_id = auth.uid());
create policy messages_update on public.messages for update to authenticated
  using (sender_user_id = auth.uid()) with check (sender_user_id = auth.uid());

create policy inbox_select on public.inbox for select to authenticated using (user_id = auth.uid());
create policy inbox_update on public.inbox for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy inbox_delete on public.inbox for delete to authenticated using (user_id = auth.uid());

-- New message => update conversation, every participant's inbox row,
-- and write notification rows for the other participants.
create or replace function public.on_message_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  conv   public.conversations%rowtype;
  prev   text;
  sender text;
  p      record;
begin
  select * into conv from public.conversations where id = new.conversation_id;

  prev := case new.type
    when 'text'     then case when length(btrim(new.text)) > 60 then left(btrim(new.text), 60) || '…' else btrim(new.text) end
    when 'image'    then 'Photo'
    when 'video'    then 'Video'
    when 'audio'    then 'Audio'
    when 'file'     then 'File'
    when 'location' then 'Location'
    else 'System' end;

  update public.conversations
     set last_message_id = new.id, last_message_preview = prev,
         last_message_at = new.created_at, updated_at = new.created_at
   where id = new.conversation_id;

  select coalesce(display_name, 'Someone') into sender from public.profiles where id = new.sender_user_id;

  for p in select user_id from public.conversation_participants where conversation_id = new.conversation_id loop
    insert into public.inbox (user_id, conversation_id, type, title, group_id,
                              last_message_at, last_message_preview, unread_count, updated_at)
    values (p.user_id, new.conversation_id, conv.type, conv.title, conv.group_id,
            new.created_at, prev, case when p.user_id = new.sender_user_id then 0 else 1 end, new.created_at)
    on conflict (user_id, conversation_id) do update
      set last_message_at = excluded.last_message_at,
          last_message_preview = excluded.last_message_preview,
          unread_count = case when excluded.user_id = new.sender_user_id then 0
                              else public.inbox.unread_count + 1 end,
          updated_at = excluded.updated_at;

    if p.user_id <> new.sender_user_id and not new.is_deleted then
      insert into public.notifications (user_id, type, title, body, data)
      values (p.user_id, 'message', sender,
              case when new.type = 'text' and btrim(new.text) <> ''
                   then left(btrim(new.text), 80) else coalesce(nullif(prev,''), 'Sent you a message') end,
              jsonb_build_object('conversationId', new.conversation_id, 'messageId', new.id,
                                 'senderUserId', new.sender_user_id));
    end if;
  end loop;
  return new;
end $$;
create trigger messages_after_insert after insert on public.messages
  for each row execute function public.on_message_insert();

-- ---------------------------------------------------------------------
-- Groups
-- ---------------------------------------------------------------------
create table public.groups (
  id                 text primary key default gen_random_uuid()::text,
  title              text not null default '',
  photo_url          text not null default '',
  description        text not null default '',
  created_by_user_id uuid not null,
  member_count       int not null default 0,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create table public.group_members (
  group_id    text not null references public.groups(id) on delete cascade,
  user_id     uuid not null,
  role        text not null default 'member',
  joined_at   timestamptz not null default now(),
  is_muted    boolean not null default false,
  muted_until timestamptz,
  primary key (group_id, user_id)
);
create index group_members_user_idx on public.group_members (user_id);
create table public.group_invites (
  id                 text primary key default gen_random_uuid()::text,
  group_id           text not null references public.groups(id) on delete cascade,
  invited_user_id    uuid not null,
  invited_by_user_id uuid not null,
  status             text not null default 'pending',
  created_at         timestamptz not null default now(),
  responded_at       timestamptz
);
create index group_invites_user_idx on public.group_invites (invited_user_id, status, created_at desc);

create or replace function public.is_group_member(gid text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.group_members where group_id = gid and user_id = auth.uid())
$$;

alter table public.groups        enable row level security;
alter table public.group_members enable row level security;
alter table public.group_invites enable row level security;
create policy groups_select on public.groups for select to authenticated using (public.is_group_member(id));
create policy groups_update on public.groups for update to authenticated using (public.is_group_member(id));
create policy group_members_select on public.group_members for select to authenticated
  using (user_id = auth.uid() or public.is_group_member(group_id));
create policy group_members_delete_self on public.group_members for delete to authenticated using (user_id = auth.uid());
create policy group_invites_select on public.group_invites for select to authenticated
  using (invited_user_id = auth.uid() or invited_by_user_id = auth.uid());
create policy group_invites_insert on public.group_invites for insert to authenticated
  with check (invited_by_user_id = auth.uid() and public.is_group_member(group_id));
-- accept/decline through RPCs.

-- ---------------------------------------------------------------------
-- Sessions
-- ---------------------------------------------------------------------
create table public.sessions (
  id                 text primary key default gen_random_uuid()::text,
  type               text not null default 'gym',
  title              text not null default '',
  description        text not null default '',
  created_by_user_id uuid not null,
  start_at           timestamptz,
  end_at             timestamptz,
  location           jsonb,
  location_name      text not null default '',
  gym_id             text not null default '',
  status             text not null default 'scheduled',
  is_group_session   boolean not null default false,
  group_id           text not null default '',
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index sessions_owner_idx on public.sessions (created_by_user_id, created_at desc);
create table public.session_participants (
  session_id text not null references public.sessions(id) on delete cascade,
  user_id    uuid not null,
  attended   boolean not null default false,
  joined_at  timestamptz not null default now(),
  primary key (session_id, user_id)
);
create table public.session_invites (
  id                     text primary key default gen_random_uuid()::text,
  session_id             text not null references public.sessions(id) on delete cascade,
  invited_user_id        uuid not null,
  invited_by_user_id     uuid not null,
  status                 text not null default 'pending',
  session_category       text not null default '',
  session_image_url      text not null default '',
  session_location_text  text not null default '',
  session_date_time      timestamptz,
  invited_by_name        text not null default '',
  invited_by_photo_url   text not null default '',
  created_at             timestamptz not null default now(),
  responded_at           timestamptz
);
create index session_invites_user_idx on public.session_invites (invited_user_id, status, created_at desc);

alter table public.sessions             enable row level security;
alter table public.session_participants enable row level security;
alter table public.session_invites      enable row level security;
create policy sessions_select on public.sessions for select to authenticated using (true);
create policy sessions_insert on public.sessions for insert to authenticated with check (created_by_user_id = auth.uid());
create policy sessions_update on public.sessions for update to authenticated using (created_by_user_id = auth.uid());
create policy sess_part_select on public.session_participants for select to authenticated using (true);
create policy sess_part_insert on public.session_participants for insert to authenticated
  with check (user_id = auth.uid());
create policy sess_part_update on public.session_participants for update to authenticated using (user_id = auth.uid());
create policy sess_part_delete on public.session_participants for delete to authenticated using (user_id = auth.uid());
create policy sess_inv_select on public.session_invites for select to authenticated
  using (invited_user_id = auth.uid() or invited_by_user_id = auth.uid());
create policy sess_inv_insert on public.session_invites for insert to authenticated
  with check (invited_by_user_id = auth.uid());
-- accept/decline through RPCs.

-- ---------------------------------------------------------------------
-- Gym check-ins (server validated; see scan_gym())
-- ---------------------------------------------------------------------
create table public.scans (
  id             text primary key default gen_random_uuid()::text,
  user_id        uuid not null,
  gym_id         text not null,
  client_scan_id text not null,
  device_id      text not null default '',
  scanned_at     timestamptz not null default now(),
  day_key        text not null,
  hour           int  not null,
  status         text not null default 'accepted',
  unique (user_id, client_scan_id)
);
create index scans_user_idx on public.scans (user_id, scanned_at desc);
create index scans_gym_user_idx on public.scans (user_id, gym_id, scanned_at desc);
alter table public.scans enable row level security;
create policy scans_select on public.scans for select to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- Moderation
-- ---------------------------------------------------------------------
create table public.reports (
  id                     text primary key,        -- deterministic: '<reporter>_<type>_<key>'
  reporter_user_id       uuid not null,
  target_type            text not null,
  target_user_id         uuid not null,
  target_conversation_id text not null default '',
  target_message_id      text not null default '',
  reason                 text not null,
  details                text not null default '',
  status                 text not null default 'open',
  reviewed_by            text,
  review_notes           text,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);
alter table public.reports enable row level security;
create policy reports_select on public.reports for select to authenticated
  using (reporter_user_id = auth.uid() or public.is_admin());
create policy reports_insert on public.reports for insert to authenticated
  with check (reporter_user_id = auth.uid() and target_user_id <> auth.uid()
              and id like (auth.uid()::text || '\_%'));
create policy reports_update on public.reports for update to authenticated
  using (reporter_user_id = auth.uid()) with check (reporter_user_id = auth.uid());
create or replace function public.reports_guard() returns trigger language plpgsql as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.status is distinct from old.status or new.reviewed_by is distinct from old.reviewed_by
       or new.review_notes is distinct from old.review_notes
       or new.reporter_user_id is distinct from old.reporter_user_id
       or new.target_user_id is distinct from old.target_user_id then
      raise exception 'moderation fields are admin-only' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;
create trigger reports_guard_trg before update on public.reports
  for each row execute function public.reports_guard();

create table public.account_deletions (
  user_id      uuid primary key,
  status       text not null default 'pending',
  requested_via text not null default 'app',
  error        text,
  steps        jsonb not null default '{}'::jsonb,
  requested_at timestamptz not null default now(),
  started_at   timestamptz,
  completed_at timestamptz,
  failed_at    timestamptz
);
alter table public.account_deletions enable row level security;
create policy account_deletions_select on public.account_deletions for select to authenticated using (user_id = auth.uid());
