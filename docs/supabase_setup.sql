-- TravelMate 여행자 제보(커뮤니티) 테이블 + 보안정책 + '가봤어요' 함수
-- Supabase 프로젝트 > SQL Editor 에 붙여넣고 실행하세요.

-- 1) 제보 테이블
create table if not exists contributions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  type text default 'place',                -- place(맛집·명소) | price(시세)
  country_code text not null,
  city text not null,
  name text not null,
  kind text not null default 'food',        -- food | sight
  audience text,                            -- local | tourist | null
  price_hint text default '',
  note text default '',
  lat double precision,
  lng double precision,
  device_id text,
  confirms int default 0,                   -- '가봤어요' 수
  status text default 'pending'             -- pending | verified | hidden
);

-- 2) Row Level Security 켜기
alter table contributions enable row level security;

-- 읽기: 누구나(숨김 필터는 앱에서 status<>hidden)
drop policy if exists "read all" on contributions;
create policy "read all" on contributions for select using (true);

-- 등록: 누구나(익명 제보)
drop policy if exists "insert any" on contributions;
create policy "insert any" on contributions for insert with check (true);

-- 3) 등록 시 status/confirms 조작 방지 — 항상 기본값으로 강제
create or replace function force_pending()
returns trigger language plpgsql as $$
begin
  new.status := 'pending';
  new.confirms := 0;
  return new;
end; $$;

drop trigger if exists trg_force_pending on contributions;
create trigger trg_force_pending before insert on contributions
  for each row execute function force_pending();

-- 4) '가봤어요' 원자적 증가 + 3명 이상이면 자동 '검증됨' 승격
create or replace function confirm_contribution(row_id uuid)
returns void language plpgsql security definer as $$
begin
  update contributions
     set confirms = confirms + 1,
         status = case when confirms + 1 >= 3 and status = 'pending'
                       then 'verified' else status end
   where id = row_id and status <> 'hidden';
end; $$;

grant execute on function confirm_contribution(uuid) to anon;

-- 이미 테이블을 만든 뒤 'type'만 추가할 때(시세 제보 기능용):
alter table contributions add column if not exists type text default 'place';

-- 관리(사장님): 부적절한 제보 숨기기 → Table editor에서 status='hidden'
--             수동 승격 → status='verified'
