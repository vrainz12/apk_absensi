// Edge Function: buat-akun
// Deploy:  supabase functions deploy buat-akun
//
// Aksi:
//   - (default)      membuat akun peserta baru (Auth user + baris profiles)
//   - "reset_sandi"  mengganti kata sandi peserta
//
// Hanya bisa dipanggil oleh pengguna yang login dengan role 'admin'.
// SUPABASE_URL, SUPABASE_ANON_KEY, dan SUPABASE_SERVICE_ROLE_KEY
// otomatis tersedia di lingkungan Edge Function.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DOMAIN_INTERNAL = "simagang.internal"; // harus sama dengan kDomainInternal

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // 1. Pastikan pemanggil adalah admin aktif.
  const authHeader = req.headers.get("Authorization") ?? "";
  const pemanggil = createClient(url, anon, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: u } = await pemanggil.auth.getUser();
  if (!u?.user) return json({ error: "Sesi tidak valid." }, 401);

  const admin = createClient(url, service);
  const { data: prof } = await admin
    .from("profiles")
    .select("role, status")
    .eq("id", u.user.id)
    .maybeSingle();
  if (prof?.role !== "admin" || prof?.status !== "aktif") {
    return json({ error: "Hanya admin yang boleh melakukan ini." }, 403);
  }

  let body: Record<string, string | null | undefined>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Body tidak valid." }, 400);
  }

  // 2a. Reset kata sandi
  if (body.aksi === "reset_sandi") {
    if (!body.user_id || (body.password ?? "").length < 8) {
      return json({ error: "Data reset tidak lengkap." }, 400);
    }
    const { error } = await admin.auth.admin.updateUserById(body.user_id, {
      password: body.password!,
    });
    if (error) return json({ error: error.message }, 400);
    return json({ ok: true });
  }

  // 2b. Buat akun peserta baru
  const username = (body.username ?? "").trim().toLowerCase();
  const password = body.password ?? "";
  const nama = (body.nama ?? "").trim();

  if (!/^[a-z0-9._]{3,30}$/.test(username)) {
    return json({ error: "Format username tidak valid." }, 400);
  }
  if (password.length < 8) {
    return json({ error: "Kata sandi minimal 8 karakter." }, 400);
  }
  if (!nama) return json({ error: "Nama wajib diisi." }, 400);

  const { data: dipakai } = await admin
    .from("profiles")
    .select("id")
    .eq("username", username)
    .maybeSingle();
  if (dipakai) return json({ error: "Username sudah dipakai." }, 409);

  const { data: dibuat, error: errAuth } = await admin.auth.admin.createUser({
    email: `${username}@${DOMAIN_INTERNAL}`,
    password,
    email_confirm: true,
  });
  if (errAuth || !dibuat.user) {
    return json({ error: errAuth?.message ?? "Gagal membuat akun." }, 400);
  }

  const kosong = (s?: string | null) => (s && s.trim() ? s.trim() : null);
  // upsert: aman jika ada trigger yang sudah membuat baris profiles otomatis.
  const { error: errProf } = await admin.from("profiles").upsert({
    id: dibuat.user.id,
    username,
    nama,
    role: "peserta",
    status: "aktif",
    telepon: kosong(body.telepon),
    divisi: kosong(body.divisi),
    batch: kosong(body.batch),
    kampus: kosong(body.kampus),
  });
  if (errProf) {
    // Batalkan agar tidak ada user Auth tanpa profil.
    await admin.auth.admin.deleteUser(dibuat.user.id);
    return json({ error: `Gagal menyimpan profil: ${errProf.message}` }, 400);
  }

  return json({ ok: true, id: dibuat.user.id });
});

