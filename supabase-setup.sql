-- Kör i Supabase SQL Editor. Publikt event: alla med appens länk kan räkna.
create table if not exists public.beer_counts (
  device_id uuid primary key,
  count integer not null default 0 check (count >= 0),
  updated_at timestamptz not null default now()
);
alter table public.beer_counts enable row level security;
revoke all on public.beer_counts from anon, authenticated;
create or replace function public.beer_change(p_device uuid, p_delta integer)
returns table(my_count integer, all_count bigint)
language plpgsql security definer set search_path = public
as $$
begin
  if p_delta not in (-1, 0, 1) then raise exception 'Invalid delta'; end if;
  insert into public.beer_counts(device_id,count) values(p_device, greatest(0,p_delta))
  on conflict(device_id) do update
    set count = greatest(0, beer_counts.count + p_delta), updated_at = now();
  return query select
    (select b.count from public.beer_counts b where b.device_id=p_device),
    (select coalesce(sum(b.count),0) from public.beer_counts b);
end $$;
revoke all on function public.beer_change(uuid,integer) from public;
grant execute on function public.beer_change(uuid,integer) to anon, authenticated;
