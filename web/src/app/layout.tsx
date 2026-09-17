import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "POS Abarrotes — Panel Admin",
  description: "Panel de administración para la tienda de abarrotes",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
