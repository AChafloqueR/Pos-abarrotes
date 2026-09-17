import { createServerSupabaseClient } from "@/lib/supabase/server";

function formatSoles(n: number) {
  return new Intl.NumberFormat("es-PE", { style: "currency", currency: "PEN" }).format(n);
}

export default async function DashboardPage() {
  const supabase = createServerSupabaseClient();

  const hoyInicio = new Date();
  hoyInicio.setHours(0, 0, 0, 0);

  const [{ data: ventasHoy }, { data: productosBajoStock }, { data: cajaAbierta }] =
    await Promise.all([
      supabase
        .from("ventas")
        .select("total, metodo_pago")
        .eq("estado", "completada")
        .gte("created_at", hoyInicio.toISOString()),
      supabase
        .from("productos")
        .select("id, nombre, stock_actual, stock_minimo")
        .eq("activo", true)
        .order("stock_actual", { ascending: true })
        .limit(50),
      supabase.from("cajas").select("id, usuario_id, monto_apertura, abierta_at").eq("estado", "abierta"),
    ]);

  const totalHoy = (ventasHoy ?? []).reduce((acc, v) => acc + Number(v.total), 0);
  const numVentasHoy = (ventasHoy ?? []).length;
  const bajoStock = (productosBajoStock ?? []).filter((p) => Number(p.stock_actual) <= Number(p.stock_minimo));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Resumen de hoy</h1>
        <p className="text-sm text-gray-500">
          {new Date().toLocaleDateString("es-PE", { weekday: "long", day: "numeric", month: "long" })}
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="card p-5">
          <p className="text-sm text-gray-500">Ventas de hoy</p>
          <p className="text-2xl font-semibold text-brand-700 mt-1">{formatSoles(totalHoy)}</p>
          <p className="text-xs text-gray-400 mt-1">{numVentasHoy} ticket(s) emitidos</p>
        </div>
        <div className="card p-5">
          <p className="text-sm text-gray-500">Cajas abiertas ahora</p>
          <p className="text-2xl font-semibold text-gray-900 mt-1">{cajaAbierta?.length ?? 0}</p>
          <p className="text-xs text-gray-400 mt-1">en el mostrador</p>
        </div>
        <div className="card p-5">
          <p className="text-sm text-gray-500">Productos con stock bajo</p>
          <p className="text-2xl font-semibold text-accent-600 mt-1">{bajoStock.length}</p>
          <p className="text-xs text-gray-400 mt-1">necesitan reposición</p>
        </div>
      </div>

      <div className="card p-5">
        <h2 className="text-base font-semibold text-gray-900 mb-3">Alerta de stock bajo</h2>
        {bajoStock.length === 0 ? (
          <p className="text-sm text-gray-500">Todo el inventario está por encima del mínimo. 🎉</p>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b">
                <th className="py-2">Producto</th>
                <th className="py-2">Stock actual</th>
                <th className="py-2">Stock mínimo</th>
              </tr>
            </thead>
            <tbody>
              {bajoStock.map((p) => (
                <tr key={p.id} className="border-b last:border-0">
                  <td className="py-2">{p.nombre}</td>
                  <td className="py-2 font-medium text-accent-600">{p.stock_actual}</td>
                  <td className="py-2 text-gray-400">{p.stock_minimo}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
