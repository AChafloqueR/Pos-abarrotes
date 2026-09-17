import Link from "next/link";
import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import SignOutButton from "@/components/SignOutButton";

const NAV = [
  { href: "/dashboard", label: "Resumen", icon: "📊" },
  { href: "/productos", label: "Productos", icon: "📦" },
  { href: "/inventario", label: "Inventario", icon: "📋" },
  { href: "/ventas", label: "Ventas", icon: "🧾" },
  { href: "/usuarios", label: "Usuarios", icon: "👤" },
];

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const supabase = createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: perfil } = await supabase
    .from("perfiles")
    .select("nombre_completo, rol")
    .eq("id", user.id)
    .single();

  return (
    <div className="min-h-screen flex">
      <aside className="w-60 shrink-0 bg-brand-800 text-white flex flex-col">
        <div className="px-5 py-5 text-lg font-semibold border-b border-brand-700">
          🛒 POS Abarrotes
        </div>
        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.filter((item) => item.href !== "/usuarios" || perfil?.rol === "propietario").map(
            (item) => (
              <Link
                key={item.href}
                href={item.href}
                className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm text-brand-50 hover:bg-brand-700 transition-colors"
              >
                <span>{item.icon}</span>
                {item.label}
              </Link>
            )
          )}
        </nav>
        <div className="px-4 py-4 border-t border-brand-700 text-sm">
          <p className="font-medium">{perfil?.nombre_completo ?? user.email}</p>
          <p className="text-brand-200 text-xs capitalize mb-3">{perfil?.rol ?? "usuario"}</p>
          <SignOutButton />
        </div>
      </aside>
      <main className="flex-1 bg-brand-50 min-h-screen p-6 md:p-8">{children}</main>
    </div>
  );
}
