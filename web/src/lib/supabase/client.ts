"use client";

// Cliente de Supabase para Client Components (navegador). Usa la anon key
// pública — la seguridad real la da RLS en la base de datos, no esta key.
import { createBrowserClient } from "@supabase/ssr";

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
