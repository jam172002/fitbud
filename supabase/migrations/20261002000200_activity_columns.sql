alter table public.activities
  add column if not exists icon_url  text not null default '',
  add column if not exists image_url text not null default '';
