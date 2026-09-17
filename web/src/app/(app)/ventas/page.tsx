import { createServerSupabaseClient } from "@/lib/supabase/server";

function formatSoles(n: number) {
  return new Intl.NumberFormat("es-PE", { style: "currency", currency: "PEN" }).format(n);
}

const metodoLabel: Record<string, string> = {
  efectivo: "Efectivo",
  yape: "Yape",
  plin: "Plin",
  tarjeta: "Tarjeta",
};

export default async function VentasPage() {
  const supabase = createServerSupabaseClient();

  const { data: ventas } = await supabase
    .from("ventas")
    .select("id, numero_ticket, total, metodo_pago, estado, created_at, perfiles(nombre_completo)")
    .order("created_at", { ascending: false })
    .limit(100);

  const totalPeriodo = (ventas ?? [])
    .filter((v) => v.estado === "completada")
    .reduce((acc, v) => acc + Number(v.total), 0);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Ventas</h1>
          <p className="text-sm text-gray-500">Últimos 100 tickets emitidos</p>
        </div>
        <div className="card px-5 py-3 text-right">
          <p className="text-xs text-gray-500">Total del período</p>
          <p className="text-lg font-semibold text-brand-700">{formatSoles(totalPeriodo)}</p>
        </div>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-gray-500">
            <tr className="text-left">
              <th className="px-4 py-3">Ticket</th>
              <th className="px-4 py-3">Fecha</th>
              <th className="px-4 py-3">Cajero</th>
              <th className="px-4 py-3">Método de pago</th>
              <th className="px-4 py-3">Total</th>
              <th className="px-4 py-3">Estado</th>
            </tr>
          </thead>
          <tbody>
            {(ventas ?? []).map((v: any) => (
              <tr key={v.id} className="border-t">
                <td className="px-4 py-3 font-medium text-gray-900">#{v.numero_ticket}</td>
                <td className="px-4 py-3 text-gray-500">{new Date(v.created_at).toLocaleString("es-PE")}</td>
                <td className="px-4 py-3 text-gray-500">{v.perfiles?.nombre_completo ?? "—"}</td>
                <td className="px-4 py-3">{metodoLabel[v.metodo_pago] ?? v.metodo_pago}</td>
                <td className="px-4 py-3">{formatSoles(v.total)}</td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs ${
                      v.estado === "completada"
                        ? "bg-brand-100 text-brand-700"
                        : "bg-red-50 text-red-600"
                    }`}
                  >
                    {v.estado}
                  </span>
                </td>
              </tr>
            ))}
            {(ventas ?? []).length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-400">
                  Todavía no se ha registrado ninguna venta.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
