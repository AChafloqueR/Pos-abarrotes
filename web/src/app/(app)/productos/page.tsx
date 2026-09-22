import { createServerSupabaseClient } from "@/lib/supabase/server";
import ProductosTable from "./ProductosTable";

export default async function ProductosPage() {
  const supabase = createServerSupabaseClient();

  const [{ data: productos }, { data: categorias }, { data: perfil }] = await Promise.all([
    supabase.from("productos").select("*").order("nombre"),
    supabase.from("categorias").select("*").order("nombre"),
    (async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return { data: null };
      return supabase.from("perfiles").select("rol, tienda_id").eq("id", user.id).single();
    })(),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Productos</h1>
          <p className="text-sm text-gray-500">Catálogo, precios y stock</p>
        </div>
      </div>

      <ProductosTable
  productosIniciales={productos ?? []}
  categorias={categorias ?? []}
  soloLectura={perfil?.rol !== "propietario"}
  tiendaId={perfil?.tienda_id ?? ""}
/>
    </div>
  );
}
