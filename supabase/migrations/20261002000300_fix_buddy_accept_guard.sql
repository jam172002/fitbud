-- accept_buddy_request() runs as SECURITY DEFINER but auth.uid() is still the
-- caller, so the guard trigger rejected the RPC's own status update. The RPC
-- now sets a transaction-local flag that the guard honours.
create or replace function public.buddy_requests_guard() returns trigger
language plpgsql as $$
begin
  if auth.uid() is null then return new; end if;
  if new.from_user_id <> old.from_user_id or new.to_user_id <> old.to_user_id then
    raise exception 'cannot change parties of a request' using errcode = '42501';
  end if;
  if new.status is distinct from old.status then
    if new.status = 'accepted' then
      if coalesce(current_setting('app.accepting_buddy_request', true), '') <> '1' then
        raise exception 'use accept_buddy_request()' using errcode = '42501';
      end if;
    elsif new.status = 'rejected' and auth.uid() <> old.to_user_id then
      raise exception 'only the receiver can decline' using errcode = '42501';
    elsif new.status in ('cancelled', 'pending') and auth.uid() <> old.from_user_id then
      raise exception 'only the sender can cancel/reopen' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

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

  perform set_config('app.accepting_buddy_request', '1', true);
  update public.buddy_requests set status = 'accepted', responded_at = now() where id = r.id;
  perform set_config('app.accepting_buddy_request', '', true);

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
