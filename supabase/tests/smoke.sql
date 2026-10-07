-- Smoke test of RLS + RPC logic. Runs entirely inside a transaction that is
-- rolled back, so it leaves no data behind:
--   supabase db query --linked -f supabase/tests/smoke.sql
begin;

insert into auth.users (instance_id, id, aud, role, email, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change)
values
 ('00000000-0000-0000-0000-000000000000','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','authenticated','authenticated','smoke.a@fitbud.invalid','{"display_name":"Smoke A"}',now(),now(),'','','',''),
 ('00000000-0000-0000-0000-000000000000','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','authenticated','authenticated','smoke.b@fitbud.invalid','{"display_name":"Smoke B"}',now(),now(),'','','','');

create temp table results (step text, ok boolean, detail text);
grant all on results to authenticated;

-- ---- as user A ----
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}', true);

do $$
declare cid text; n int; ok boolean; r jsonb; rid text;
begin
  -- profile auto-created by trigger
  select count(*) into n from public.profiles where id = auth.uid();
  insert into results values ('profile auto-created', n = 1, n::text);

  -- premium fields are protected
  begin
    update public.profiles set is_premium = true where id = auth.uid();
    insert into results values ('client cannot self-grant premium', false, 'update succeeded');
  exception when others then
    insert into results values ('client cannot self-grant premium', true, sqlerrm);
  end;

  -- direct conversation + message trigger
  cid := public.get_or_create_direct_conversation('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
  insert into results values ('direct conversation id', cid like 'direct_aaaa%_bbbb%', cid);
  insert into public.messages (conversation_id, sender_user_id, text) values (cid, auth.uid(), 'hello smoke');
  select count(*) into n from public.inbox where conversation_id = cid and user_id = auth.uid();
  insert into results values ('sender inbox row', n = 1, n::text);

  -- buddy request
  insert into public.buddy_requests (from_user_id, to_user_id, message)
    values (auth.uid(), 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'hi') returning id into rid;
  create temp table if not exists ctx (k text, v text);
  grant all on ctx to authenticated;
  insert into ctx values ('rid', rid);

  -- gym check-in
  r := public.scan_gym('360_gym_lahore', 'smoke-scan-1', 'dev');
  insert into results values ('scan accepted', r ->> 'result' = 'accepted', r::text);
  r := public.scan_gym('360_gym_lahore', 'smoke-scan-1', 'dev');
  insert into results values ('scan idempotent', r ->> 'result' = 'already_processed', r::text);
  r := public.scan_gym('360_gym_lahore', 'smoke-scan-2', 'dev');
  insert into results values ('scan cooldown', r ->> 'result' = 'cooldown', r::text);

  -- cannot read someone else's data
  select count(*) into n from public.scans where user_id <> auth.uid();
  insert into results values ('cannot see other users scans', n = 0, n::text);
end $$;

-- ---- as user B ----
select set_config('request.jwt.claims', '{"sub":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb","role":"authenticated"}', true);

do $$
declare n int; rid text; ok boolean;
begin
  select v into rid from ctx where k = 'rid';
  select count(*) into n from public.notifications where user_id = auth.uid() and type = 'buddy_request';
  insert into results values ('receiver got buddy_request notification', n = 1, n::text);
  select count(*) into n from public.notifications where user_id = auth.uid() and type = 'message';
  insert into results values ('receiver got message notification', n = 1, n::text);
  select count(*) into n from public.inbox where user_id = auth.uid() and unread_count = 1;
  insert into results values ('receiver unread count = 1', n = 1, n::text);

  -- sender-style accept must be refused for non-receiver paths; receiver accepts via RPC
  perform public.accept_buddy_request(rid);
  select count(*) into n from public.friendships where user_ids @> array['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid, auth.uid()];
  insert into results values ('friendship created on accept', n = 1, n::text);

  perform public.mark_conversation_read((select id from public.conversations limit 1));
  select count(*) into n from public.inbox where user_id = auth.uid() and unread_count = 0;
  insert into results values ('mark read clears unread', n = 1, n::text);

  -- group lifecycle
  perform public.create_group('smoke_group', 'Smoke Group', '', '', array['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa']::uuid[]);
  select count(*) into n from public.group_members where group_id = 'smoke_group';
  insert into results values ('group created with 2 members', n = 2, n::text);
  select count(*) into n from public.inbox where conversation_id = 'group_smoke_group';
  insert into results values ('inbox RLS: member sees only own group inbox row', n = 1, n::text);
end $$;

-- ---- as user A again: cross-user checks ----
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}', true);
do $$
declare n int;
begin
  select count(*) into n from public.inbox where user_id <> auth.uid();
  insert into results values ('cannot read others inbox', n = 0, n::text);
  select count(*) into n from public.groups where id = 'smoke_group';
  insert into results values ('member can read group', n = 1, n::text);
end $$;

reset role;
select step, ok, detail from results order by 1;
rollback;
