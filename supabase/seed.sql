-- =====================================================================
-- FitBud sample data. Safe to run more than once (idempotent).
--   supabase db push --include-seed        (remote)
--   or paste into the SQL editor
--
-- The five demo people are created WITHOUT a password, so nobody can log
-- in as them - they exist so Discover / Buddies / Chat have content.
-- To connect your own account to them see supabase/demo_connect.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Activities
-- ---------------------------------------------------------------------
insert into public.activities (id, name, "order") values
  ('badminton', 'Badminton', 1),
  ('gym',       'Gym',       2),
  ('running',   'Running',   3),
  ('football',  'Football',  4),
  ('cricket',   'Cricket',   5),
  ('yoga',      'Yoga',      6),
  ('cycling',   'Cycling',   7)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Gyms
-- ---------------------------------------------------------------------
insert into public.gyms
  (id, name, address, city, phone, status, qr_public_id, years_of_service, members, rating,
   day_hours, night_hours, equipments, location)
values
  ('360_gym_lahore', '360 GYM Commercial Area', 'Commercial Area, Phase 4, DHA', 'Lahore', '03001110001',
   'active', '360_gym_lahore', 6, 850, 4.6, '6:00 AM - 12:00 PM', '4:00 PM - 11:00 PM',
   array['Treadmills','Free Weights','Cable Machines','Cardio Zone','Sauna'], '{"lat":31.4697,"lng":74.4056}'),
  ('iron_house_fitness', 'Iron House Fitness', 'Main Boulevard, Gulberg III', 'Lahore', '03001110002',
   'active', 'iron_house_fitness', 4, 520, 4.4, '6:00 AM - 1:00 PM', '5:00 PM - 11:00 PM',
   array['Power Racks','Dumbbells','Leg Press','Cardio Zone'], '{"lat":31.5204,"lng":74.3587}'),
  ('gold_gym_dha', 'Gold Gym DHA', 'Phase 5 Commercial, DHA', 'Lahore', '03001110003',
   'active', 'gold_gym_dha', 9, 1200, 4.8, '5:00 AM - 12:00 PM', '3:00 PM - 12:00 AM',
   array['Olympic Lifting Platform','Treadmills','Spin Bikes','Steam Room','Juice Bar'], '{"lat":31.4820,"lng":74.4100}'),
  ('fitness_hub_model_town', 'Fitness Hub Model Town', 'Block C, Model Town', 'Lahore', '03001110004',
   'active', 'fitness_hub_model_town', 3, 340, 4.2, '6:00 AM - 12:00 PM', '4:00 PM - 10:00 PM',
   array['Free Weights','Cardio Zone','Yoga Studio'], '{"lat":31.4829,"lng":74.3297}'),
  ('powerhouse_gym', 'PowerHouse Gym', 'F-7 Markaz', 'Islamabad', '03001110005',
   'active', 'powerhouse_gym', 7, 640, 4.5, '6:00 AM - 1:00 PM', '4:00 PM - 11:00 PM',
   array['Power Racks','Cable Machines','Treadmills','CrossFit Area'], '{"lat":33.7215,"lng":73.0551}')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Plans
-- ---------------------------------------------------------------------
insert into public.plans (id, name, description, price, currency, duration_days, features) values
  ('monthly',   'Monthly',   'Full access, billed every month.',          1500,  'PKR', 30,
   array['Unlimited gym check-ins','Buddy matching','Group chats']),
  ('quarterly', 'Quarterly', 'Save 11% - three months of full access.',   4000,  'PKR', 90,
   array['Unlimited gym check-ins','Buddy matching','Group chats','Priority support']),
  ('yearly',    'Yearly',    'Best value - twelve months of full access.', 14000, 'PKR', 365,
   array['Unlimited gym check-ins','Buddy matching','Group chats','Priority support','Early access to features'])
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Products (home banner)
-- ---------------------------------------------------------------------
insert into public.products (id, title, description, price, image_url) values
  ('whey_protein_2lb',  'Whey Protein 2 lb',  'Chocolate whey isolate, 25 g protein per scoop.', 6500, ''),
  ('shaker_bottle',     'FitBud Shaker',      '700 ml leak-proof shaker with mixing ball.',       900, ''),
  ('resistance_bands',  'Resistance Bands Set','Set of 5 bands for home and travel workouts.',   1800, ''),
  ('gym_gloves',        'Training Gloves',    'Breathable, padded grip gloves.',                 1200, '')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Demo people (no password => cannot be logged into)
-- ---------------------------------------------------------------------
do $$
declare
  demo record;
begin
  for demo in
    select * from (values
      ('00000000-0000-4000-8000-000000000001'::uuid, 'Ayesha Khan',  'demo.ayesha@fitbud.invalid',  'Lahore',    'Female', date '1999-04-12', array['Badminton','Gym','Running'],        'Badminton', true,  '360 GYM Commercial Area', 'Consistency over intensity. Looking for badminton and gym partners.'),
      ('00000000-0000-4000-8000-000000000002'::uuid, 'Hamza Ali',    'demo.hamza@fitbud.invalid',   'Lahore',    'Male',   date '2001-09-03', array['Yoga','Cycling','Running'],         'Cycling',   false, null,                      'Early-morning rides and yoga. Prefer long-term accountability partners.'),
      ('00000000-0000-4000-8000-000000000003'::uuid, 'Bilal Ahmed',   'demo.bilal@fitbud.invalid',   'Islamabad', 'Male',   date '1997-01-22', array['Football','Cricket','Gym','Running'],'Football',  true,  'PowerHouse Gym',          'Team sports plus strength training. Always up for football.'),
      ('00000000-0000-4000-8000-000000000004'::uuid, 'Sara Malik',    'demo.sara@fitbud.invalid',    'Lahore',    'Female', date '2000-06-30', array['Yoga','Running'],                  'Yoga',      false, null,                      'Yoga teacher in training. Weekend trail runs.'),
      ('00000000-0000-4000-8000-000000000005'::uuid, 'Usman Tariq',   'demo.usman@fitbud.invalid',   'Lahore',    'Male',   date '1995-11-15', array['Gym','Cricket','Badminton'],        'Gym',       true,  'Gold Gym DHA',            'Powerlifting 4x a week. Cricket on Sundays.')
    ) as t(id, name, email, city, gender, dob, activities, fav, has_gym, gym_name, about)
  loop
    insert into auth.users (
      instance_id, id, aud, role, email, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', demo.id, 'authenticated', 'authenticated', demo.email, now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('display_name', demo.name), now(), now(),
      '', '', '', ''
    ) on conflict (id) do nothing;

    -- handle_new_user() created the profile row; fill it in.
    update public.profiles set
      display_name = demo.name,
      city = demo.city,
      gender = demo.gender,
      dob = demo.dob::timestamptz,
      activities = demo.activities,
      favourite_activity = demo.fav,
      has_gym = demo.has_gym,
      gym_name = demo.gym_name,
      about = demo.about,
      is_active = true,
      is_profile_complete = true,
      is_premium = true,           -- visible in Discover (premium-only listing)
      premium_until = now() + interval '365 days'
    where id = demo.id;
  end loop;
end $$;
