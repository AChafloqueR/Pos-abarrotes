import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export default async function UsuariosPage() {
  const supabase = createServerSupabaseClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: miPerfil } = await supabase
    .from("perfiles")
    .select("rol")
    .eq("id", user.id)
    .single();

  // Solo el propietario administra usuarios — refuerza en UI lo que RLS ya
  // exige en la base de datos (defensa en profundidad).
  if (miPerfil?.rol !== "propietario") redirect("/dashboard");

  const { data: perfiles } = await supabase
    .from("perfiles")
    .select("id, nombre_completo, rol, activo, created_at")
    .order("created_at");

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Usuarios</h1>
        <p className="text-sm text-gray-500">Personas con acceso a este panel y a la app de venta</p>
      </div>

      <div className="card p-5 bg-brand-50 border-brand-100 text-sm text-brand-800">
        <p className="font-medium mb-1">Cómo agregar un cajero nuevo</p>
        <p>
          Por seguridad, las altas de usuario se hacen desde el panel de Supabase
          (Authentication → Users → Invite user), agregando en &quot;User Metadata&quot;:
        </p>
        <pre className="bg-white rounded-lg p-3 mt-2 text-xs overflow-x-auto">
{`{ "tienda_id": "<id-de-tu-tienda>", "nombre_completo": "Nombre", "rol": "cajero" }`}
        </pre>
        <p className="mt-2">El perfil se crea automáticamente al aceptar la invitación. Detalle completo en <code>docs/DESPLIEGUE.md</code>.</p>
      </div>

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-gray-500">
            <tr className="text-left">
              <th className="px-4 py-3">Nombre</th>
              <th className="px-4 py-3">Rol</th>
              <th className="px-4 py-3">Estado</th>
              <th className="px-4 py-3">Desde</th>
            </tr>
          </thead>
          <tbody>
            {(perfiles ?? []).map((p) => (
              <tr key={p.id} className="border-t">
                <td className="px-4 py-3 font-medium text-gray-900">{p.nombre_completo}</td>
                <td className="px-4 py-3 capitalize">{p.rol}</td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs ${
                      p.activo ? "bg-brand-100 text-brand-700" : "bg-gray-100 text-gray-500"
                    }`}
                  >
                    {p.activo ? "activo" : "inactivo"}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {new Date(p.created_at).toLocaleDateString("es-PE")}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
