-- =============================================================================
-- Single-Device Licensing System — Supabase SQL Schema & RPC
-- =============================================================================
-- الجدول مسؤول عن ربط مفتاح الترخيص بجهاز واحد فقط.
-- الوصول المباشر من العميل (anon / authenticated) ممنوع تماماً،
-- وكل عمليات التحقق والربط تتم عبر دالة RPC آمنة (SECURITY DEFINER).
--
-- ملاحظة: لإنشاء تراخيص من لوحة Supabase استخدم SQL Editor (دور service_role
-- يتجاوز RLS)، أو أضف التراخيص من خلال أداة Table Editor مع حساب المالك.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) الجدول
-- -----------------------------------------------------------------------------
create table if not exists public.licenses (
  license_key   text primary key,
  device_id     text,
  is_active     boolean not null default true,
  activated_at  timestamptz,
  expires_at    timestamptz,
  notes         text
);

-- فهرس لتسريع البحث عن الأجهزة (يُستخدم عند ربط/التحقق).
create index if not exists licenses_device_id_idx on public.licenses (device_id);

-- -----------------------------------------------------------------------------
-- 2) Row Level Security — حظر كل وصول مباشر من العميل
-- -----------------------------------------------------------------------------
alter table public.licenses enable row level security;

-- إبطال كل الامتيازات المباشرة على الجدول لمستخدمي العميل (حزام وأمان):
-- حتى لو عُطّلت RLS لسبب ما، لا يستطيع anon/authenticated قراءة أو تعديل.
revoke all on public.licenses from anon, authenticated;

-- لا توجد أي سياسة إدراج/تحديث/حذف/قراءة للعميل، لذلك:
--   SELECT  -> مرفوض  (RLS بلا سياسات = رفض كلي)
--   INSERT  -> مرفوض
--   UPDATE  -> مرفوض
--   DELETE  -> مرفوض
-- كل شيء يتم حصرياً عبر دالة activate_or_verify_license أدناه.

-- -----------------------------------------------------------------------------
-- 3) دالة RPC الآمنة — SECURITY DEFINER
-- -----------------------------------------------------------------------------
-- تعمل بصلاحيات مالك الجدول (postgres) فتتجاوز RLS، لكن الوصول إليها مقيد
-- بمنح EXECUTE فقط. أُضيف set search_path لمنع هجمات search_path.
--
-- منطق الدالة:
--   - مفتاح غير موجود            -> license_not_found
--   - ترخيص معطّل (is_active=false) -> license_inactive   (kill-switch)
--   - انتهت الصلاحية              -> license_expired
--   - device_id فارغ              -> ربط الجهاز + تسجيل التفعيل -> activated
--   - device_id مطابق            -> تحقق ناجح               -> verified
--   - device_id مختلف            -> مرفوض                   -> license_other_device
-- تُرجع النتيجة كـ JSONB لتُستهلك مباشرة من تطبيق Flutter.
-- =============================================================================
create or replace function public.activate_or_verify_license(
  p_license_key text,
  p_device_id   text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lic public.licenses%rowtype;
begin
  -- لو كان المفتاح فارغاً أو البصمة فارغة نرفض فوراً.
  if btrim(coalesce(p_license_key, '')) = '' then
    return jsonb_build_object(
      'success', false,
      'code', 'license_not_found',
      'message', 'مفتاح الترخيص غير موجود',
      'server_time', now()
    );
  end if;

  if btrim(coalesce(p_device_id, '')) = '' then
    return jsonb_build_object(
      'success', false,
      'code', 'license_other_device',
      'message', 'تعذر التعرف على الجهاز',
      'server_time', now()
    );
  end if;

  select *
    into v_lic
  from public.licenses
  where license_key = p_license_key
  limit 1;

  if not found then
    return jsonb_build_object(
      'success', false,
      'code', 'license_not_found',
      'message', 'مفتاح الترخيص غير موجود',
      'server_time', now()
    );
  end if;

  -- الترخيص معطّل (إيقاف عن بُعد من لوحة Supabase).
  if not coalesce(v_lic.is_active, false) then
    return jsonb_build_object(
      'success', false,
      'code', 'license_inactive',
      'message', 'تم تعطيل هذا الترخيص',
      'server_time', now()
    );
  end if;

  -- انتهت صلاحية الترخيص. (expires_at = null تعني ترخيصاً دائماً)
  if v_lic.expires_at is not null and v_lic.expires_at < now() then
    return jsonb_build_object(
      'success', false,
      'code', 'license_expired',
      'message', 'انتهت صلاحية هذا الترخيص',
      'server_time', now()
    );
  end if;

  -- أول تفعيل: لا يوجد جهاز مرتبط -> نربط الجهاز الحالي ونسجل تاريخ التفعيل.
  if v_lic.device_id is null or btrim(v_lic.device_id) = '' then
    update public.licenses
       set device_id    = p_device_id,
           activated_at = coalesce(v_lic.activated_at, now())
     where license_key  = p_license_key;

    return jsonb_build_object(
      'success', true,
      'code', 'activated',
      'message', 'تم تفعيل الترخيص بنجاح',
      'device_id', p_device_id,
      'activated_at', coalesce(v_lic.activated_at, now()),
      'expires_at', v_lic.expires_at,
      'server_time', now()
    );
  end if;

  -- نفس الجهاز: تحقق ناجح.
  if v_lic.device_id = p_device_id then
    return jsonb_build_object(
      'success', true,
      'code', 'verified',
      'message', 'تم التحقق من الترخيص بنجاح',
      'device_id', v_lic.device_id,
      'activated_at', v_lic.activated_at,
      'expires_at', v_lic.expires_at,
      'server_time', now()
    );
  end if;

  -- جهاز مختلف: الترخيص مستخدم على جهاز آخر.
  return jsonb_build_object(
    'success', false,
    'code', 'license_other_device',
    'message', 'هذا الترخيص مستخدم على جهاز آخر',
    'device_id', v_lic.device_id,
    'server_time', now()
  );
end;
$$;

-- منح صلاحية التنفيذ لمستخدمي العميل فقط (بدون أي صلاحية على الجدول).
grant execute on function public.activate_or_verify_license(text, text)
  to anon, authenticated;

-- =============================================================================
-- (اختياري) أدوات إدارة الترخيص من لوحة Supabase
--   - تعطيل/إعادة تفعيل ترخيص:
--       update public.licenses set is_active = false where license_key = 'X';
--   - إعادة ربط ترخيص بجهاز آخر (تحرير الجهاز المرتبط):
--       update public.licenses
--          set device_id = null, activated_at = null
--        where license_key = 'X';
--   - تمديد الصلاحية:
--       update public.licenses
--          set expires_at = now() + interval '1 year'
--        where license_key = 'X';
-- =============================================================================
