"use client";

import { useState } from "react";
import { z } from "zod";
import { createClient } from "@/lib/supabase/client";
import type { Categoria, Producto } from "@/lib/types";

const productoSchema = z.object({
  nombre: z.string().trim().min(2, "El nombre es muy corto").max(120),
  codigo_barras: z.string().trim().max(64).optional().or(z.literal("")),
  categoria_id: z.string().uuid().optional().or(z.literal("")),
  precio_venta: z.coerce.number().min(0, "El precio no puede ser negativo"),
  costo: z.coerce.number().min(0).default(0),
  stock_actual: z.coerce.number().min(0).default(0),
  stock_minimo: z.coerce.number().min(0).default(0),
  unidad_medida: z.string().trim().min(1).default("unidad"),
});

function formatSoles(n: number) {
  return new Intl.NumberFormat("es-PE", { style: "currency", currency: "PEN" }).format(n);
}

export default function ProductosTable({
  productosIniciales,
  categorias,
  soloLectura,
  tiendaId,
}: {
  productosIniciales: Producto[];
  categorias: Categoria[];
  soloLectura: boolean;
  tiendaId: string;
}) {
  const supabase = createClient();
  const [productos, setProductos] = useState(productosIniciales);
  const [editando, setEditando] = useState<Producto | null>(null);
  const [mostrarForm, setMostrarForm] = useState(false);
  const [errores, setErrores] = useState<string[]>([]);
  const [guardando, setGuardando] = useState(false);
  const [busqueda, setBusqueda] = useState("");

  const filtrados = productos.filter((p) =>
    p.nombre.toLowerCase().includes(busqueda.toLowerCase())
  );

  async function recargar() {
    const { data } = await supabase.from("productos").select("*").order("nombre");
    if (data) setProductos(data as Producto[]);
  }

  async function handleSubmit(formData: FormData) {
    setErrores([]);
    const raw = Object.fromEntries(formData.entries());
    const parsed = productoSchema.safeParse(raw);

    if (!parsed.success) {
      setErrores(parsed.error.issues.map((i) => i.message));
      return;
    }

    setGuardando(true);
    const payload = {
      ...parsed.data,
      codigo_barras: parsed.data.codigo_barras || null,
      categoria_id: parsed.data.categoria_id || null,
      tienda_id: tiendaId,
    };

    const { error } = editando
      ? await supabase.from("productos").update(payload).eq("id", editando.id)
      : await supabase.from("productos").insert(payload);

    setGuardando(false);

    if (error) {
      setErrores([error.message]);
      return;
    }

    setMostrarForm(false);
    setEditando(null);
    await recargar();
  }

  async function eliminar(p: Producto) {
    if (!confirm(`¿Desactivar "${p.nombre}"? Ya no aparecerá en el punto de venta.`)) return;
    await supabase.from("productos").update({ activo: false }).eq("id", p.id);
    await recargar();
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <input
          className="input max-w-xs"
          placeholder="Buscar producto…"
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
        />
        {!soloLectura && (
          <button
            className="btn-primary"
            onClick={() => {
              setEditando(null);
              setMostrarForm(true);
            }}
          >
            + Nuevo producto
          </button>
        )}
      </div>

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-gray-500">
            <tr className="text-left">
              <th className="px-4 py-3">Producto</th>
              <th className="px-4 py-3">Precio</th>
              <th className="px-4 py-3">Stock</th>
              <th className="px-4 py-3">Estado</th>
              {!soloLectura && <th className="px-4 py-3"></th>}
            </tr>
          </thead>
          <tbody>
            {filtrados.filter((p) => p.activo).map((p) => (
              <tr key={p.id} className="border-t">
                <td className="px-4 py-3">
                  <p className="font-medium text-gray-900">{p.nombre}</p>
                  <p className="text-xs text-gray-400">{p.codigo_barras || "sin código"}</p>
                </td>
                <td className="px-4 py-3">{formatSoles(p.precio_venta)}</td>
                <td className="px-4 py-3">
                  <span className={Number(p.stock_actual) <= Number(p.stock_minimo) ? "text-accent-600 font-medium" : ""}>
                    {p.stock_actual} {p.unidad_medida}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <span className="inline-flex items-center rounded-full bg-brand-100 text-brand-700 text-xs px-2 py-0.5">
                    activo
                  </span>
                </td>
                {!soloLectura && (
                  <td className="px-4 py-3 text-right space-x-3 whitespace-nowrap">
                    <button
                      className="text-brand-700 hover:underline text-xs"
                      onClick={() => {
                        setEditando(p);
                        setMostrarForm(true);
                      }}
                    >
                      Editar
                    </button>
                    <button
                      className="text-red-600 hover:underline text-xs"
                      onClick={() => eliminar(p)}
                    >
                      Desactivar
                    </button>
                  </td>
                )}
              </tr>
            ))}
            {filtrados.length === 0 && (
              <tr>
                <td colSpan={5} className="px-4 py-8 text-center text-gray-400">
                  No se encontraron productos.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {mostrarForm && (
        <div className="fixed inset-0 bg-black/30 flex items-center justify-center p-4 z-50">
          <div className="card w-full max-w-lg p-6">
            <h2 className="text-lg font-semibold mb-4">
              {editando ? "Editar producto" : "Nuevo producto"}
            </h2>
            <form
              action={(fd) => handleSubmit(fd)}
              className="grid grid-cols-2 gap-4"
            >
              <div className="col-span-2">
                <label className="label">Nombre</label>
                <input name="nombre" defaultValue={editando?.nombre} className="input" required />
              </div>
              <div className="col-span-2">
                <label className="label">Código de barras (opcional)</label>
                <input name="codigo_barras" defaultValue={editando?.codigo_barras ?? ""} className="input" />
              </div>
              <div className="col-span-2">
                <label className="label">Categoría</label>
                <select name="categoria_id" defaultValue={editando?.categoria_id ?? ""} className="input">
                  <option value="">Sin categoría</option>
                  {categorias.map((c) => (
                    <option key={c.id} value={c.id}>{c.nombre}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="label">Precio de venta (S/)</label>
                <input name="precio_venta" type="number" step="0.01" defaultValue={editando?.precio_venta} className="input" required />
              </div>
              <div>
                <label className="label">Costo (S/)</label>
                <input name="costo" type="number" step="0.01" defaultValue={editando?.costo ?? 0} className="input" />
              </div>
              <div>
                <label className="label">Stock actual</label>
                <input name="stock_actual" type="number" step="0.01" defaultValue={editando?.stock_actual ?? 0} className="input" />
              </div>
              <div>
                <label className="label">Stock mínimo</label>
                <input name="stock_minimo" type="number" step="0.01" defaultValue={editando?.stock_minimo ?? 0} className="input" />
              </div>
              <div className="col-span-2">
                <label className="label">Unidad de medida</label>
                <input name="unidad_medida" defaultValue={editando?.unidad_medida ?? "unidad"} className="input" />
              </div>

              {errores.length > 0 && (
                <div className="col-span-2 text-sm text-red-600 bg-red-50 rounded-lg px-3 py-2">
                  {errores.map((e, i) => <p key={i}>{e}</p>)}
                </div>
              )}

              <div className="col-span-2 flex justify-end gap-3 mt-2">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => {
                    setMostrarForm(false);
                    setEditando(null);
                  }}
                >
                  Cancelar
                </button>
                <button type="submit" disabled={guardando} className="btn-primary">
                  {guardando ? "Guardando…" : "Guardar"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}