-- =====================================================================
-- Admin panel + Gym panel support (migrated from Firebase)
--
--   * gyms gain an owner (auth user) and the monthly scan-limit fields the
--     admin panel manages.
--   * a gym owner can read ONLY their own gym's check-ins / daily stats.
--   * an admin can also read subscriptions + transactions (dashboard) and
--     update profiles (activate / deactivate users).
--   * storage bucket `catalog-media` for gym / activity / product images
--     (public read, admin-only write).
--   Admin = app_metadata.admin = true (see docs/SUPABASE_SETUP.md).
--   Gym owner accounts are created by the `create-gym-owner` edge function.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Gym ownership + scan-limit fields
-- ---------------------------------------------------------------------
alter table public.gyms
  add column if not exists owner_uid           uuid,
  add column if not exists owner_email         text    not null default '',
  add column if not exists monthly_scan_limit  int     not null default 0,
  add column if not exists scan_month_key      text    not null default '';

create index if not exists gyms_owner_idx on public.gyms (owner_uid);

create or replace function public.is_gym_owner(p_gym_id text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.gyms where id = p_gym_id and owner_uid = auth.uid())
$$;
revoke execute on function public.is_gym_owner(text) from public, anon;
grant  execute on function public.is_gym_owner(text) to authenticated;

-- Owners read their own gym's check-ins and daily aggregates.
create policy scans_gym_owner_select on public.scans for select to authenticated
  using (public.is_gym_owner(gym_id));
create policy gym_stats_owner_select on public.gym_stats_daily for select to authenticated
  using (public.is_gym_owner(gym_id));

-- Daily stats are streamed to the gym panel.
alter publication supabase_realtime add table public.gym_stats_daily;

-- ---------------------------------------------------------------------
-- Admin read access for the dashboard + user management
-- ---------------------------------------------------------------------
drop policy if exists subscriptions_read on public.subscriptions;
create policy subscriptions_read on public.subscriptions for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists transactions_read on public.transactions;
create policy transactions_read on public.transactions for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- profiles_guard() already lets admins change any column.
create policy profiles_admin_update on public.profiles for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- Storage: gym logos / gallery, activity icons / images, product images
--   gyms/{gymId}/logo.png , gyms/{gymId}/gallery/{file}
--   activities/{id}/icon.png , activities/{id}/image.{ext}
--   products/{id}/image.png
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('catalog-media', 'catalog-media', true, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "catalog read" on storage.objects for select using (bucket_id = 'catalog-media');
create policy "catalog admin insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'catalog-media' and public.is_admin());
create policy "catalog admin update" on storage.objects for update to authenticated
  using (bucket_id = 'catalog-media' and public.is_admin());
create policy "catalog admin delete" on storage.objects for delete to authenticated
  using (bucket_id = 'catalog-media' and public.is_admin());
