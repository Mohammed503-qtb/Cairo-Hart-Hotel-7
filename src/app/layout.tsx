import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "فندق قلب القاهرة | Cairo Heart Hotel",
  description: "منصة تشغيل رقمية متكاملة لفندق قلب القاهرة في عدن",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <body className="antialiased" style={{ margin: 0, padding: 0, background: "#FAF7F2" }}>
        {children}
      </body>
    </html>
  );
}
