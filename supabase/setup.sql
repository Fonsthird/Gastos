-- Gastos: tablas y funciones en Supabase.
-- Pégalo completo en Supabase → SQL Editor → New query → Run. Se puede correr más de una vez.

-- Movimientos y configuración: cada fila guarda el mismo objeto que usa la app (columna data).
create table if not exists public.movimientos (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);
create table if not exists public.config (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
-- Clave personal para el widget y el atajo de Wallet (no usan tu sesión).
create table if not exists public.claves (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  token text not null unique check (length(token) >= 24),
  created_at timestamptz not null default now()
);

-- Cada quien solo ve y cambia sus propias filas.
alter table public.movimientos enable row level security;
alter table public.config enable row level security;
alter table public.claves enable row level security;

drop policy if exists "propios" on public.movimientos;
create policy "propios" on public.movimientos for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists "propios" on public.config;
create policy "propios" on public.config for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists "propios" on public.claves;
create policy "propios" on public.claves for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

revoke all on public.movimientos, public.config, public.claves from anon;
grant select, insert, update, delete on public.movimientos, public.config, public.claves to authenticated;

-- Widget: devuelve tu configuración y los movimientos de los últimos 70 días.
create or replace function public.widget_datos(p_token text)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare uid uuid;
begin
  select c.user_id into uid from public.claves c where c.token = p_token;
  if uid is null then raise exception 'clave inválida' using errcode = '28000'; end if;
  return jsonb_build_object(
    'config', (select c.data from public.config c where c.user_id = uid),
    'movs', coalesce((select jsonb_agg(m.data) from public.movimientos m
                      where m.user_id = uid
                        and coalesce((m.data->>'ts')::bigint, 0) >= (extract(epoch from now()) * 1000)::bigint - 70::bigint * 86400000), '[]'::jsonb)
  );
end $$;

-- Wallet: registra un gasto "por clasificar". Acepta el monto como texto ("MX$1,234.50", "85,00").
create or replace function public.wallet_gasto(p_token text, p_monto text, p_comercio text default '')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare uid uuid; t text; n numeric; ts bigint; nid text;
begin
  select c.user_id into uid from public.claves c where c.token = p_token;
  if uid is null then raise exception 'clave inválida' using errcode = '28000'; end if;
  t := regexp_replace(coalesce(p_monto, ''), '[^0-9.,]', '', 'g');
  if t like '%,%' and t like '%.%' then t := replace(t, ',', '');
  elsif t ~ ',[0-9]{1,2}$' then t := replace(t, ',', '.');
  else t := replace(t, ',', ''); end if;
  if t !~ '^[0-9]*\.?[0-9]+$' then raise exception 'monto inválido'; end if;
  n := round(t::numeric, 2);
  if n <= 0 then raise exception 'monto inválido'; end if;
  ts := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  nid := 'w' || ts || substr(md5(random()::text), 1, 4);
  insert into public.movimientos (user_id, id, data) values (uid, nid, jsonb_build_object(
    'id', nid, 'tipo', 'gasto', 'monto', n, 'cat', 'otros', 'nota', left(trim(coalesce(p_comercio, '')), 80),
    'ts', ts, 'pagador', 'yo', 'metodo', 'tarjeta', 'porClasificar', true));
  return jsonb_build_object('ok', true, 'monto', n);
end $$;

revoke all on function public.widget_datos(text) from public;
revoke all on function public.wallet_gasto(text, text, text) from public;
grant execute on function public.widget_datos(text) to anon, authenticated;
grant execute on function public.wallet_gasto(text, text, text) to anon, authenticated;
