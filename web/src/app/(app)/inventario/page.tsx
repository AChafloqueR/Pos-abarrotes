import { createServerSupabaseClient } from "@/lib/supabase/server";

export default async function InventarioPage() {
  const supabase = createServerSupabaseClient();

  const { data: movimientos } = await supabase
    .from("movimientos_inventario")
    .select("id, tipo, cantidad, motivo, created_at, productos(nombre), perfiles(nombre_completo)")
    .order("created_at", { ascending: false })
    .limit(100);

  const tipoColor: Record<string, string> = {
    entrada: "bg-brand-100 text-brand-700",
    salida: "bg-accent-500/10 text-accent-600",
    ajuste: "bg-gray-100 text-gray-600",
    venta: "bg-blue-50 text-blue-700",
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Movimientos de inventario</h1>
        <p className="text-sm text-gray-500">
          Últimos 100 movimientos — entradas, salidas, ajustes y descuentos por venta
        </p>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-gray-500">
            <tr className="text-left">
              <th className="px-4 py-3">Fecha</th>
              <th className="px-4 py-3">Producto</th>
              <th className="px-4 py-3">Tipo</th>
              <th className="px-4 py-3">Cantidad</th>
              <th className="px-4 py-3">Motivo</th>
              <th className="px-4 py-3">Usuario</th>
            </tr>
          </thead>
          <tbody>
            {(movimientos ?? []).map((m: any) => (
              <tr key={m.id} className="border-t">
                <td className="px-4 py-3 text-gray-500">
                  {new Date(m.created_at).toLocaleString("es-PE")}
                </td>
                <td className="px-4 py-3 font-medium text-gray-900">{m.productos?.nombre}</td>
                <td className="px-4 py-3">
                  <span className={`rounded-full px-2 py-0.5 text-xs ${tipoColor[m.tipo] ?? ""}`}>
                    {m.tipo}
                  </span>
                </td>
                <td className="px-4 py-3">{m.cantidad}</td>
                <td className="px-4 py-3 text-gray-500">{m.motivo ?? "—"}</td>
                <td className="px-4 py-3 text-gray-500">{m.perfiles?.nombre_completo ?? "sistema"}</td>
              </tr>
            ))}
            {(movimientos ?? []).length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-400">
                  Aún no hay movimientos registrados.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
