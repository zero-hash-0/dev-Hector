import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Hector — Developer & Product Builder",
  description:
    "Developer and product builder based in Florida. Specializing in security-first architecture, iOS development, and premium digital experiences.",
  keywords: [
    "developer",
    "portfolio",
    "React",
    "Next.js",
    "iOS",
    "Swift",
    "TypeScript",
    "cybersecurity",
  ],
  authors: [{ name: "Hector" }],
  openGraph: {
    title: "Hector — Developer & Product Builder",
    description:
      "Developer and product builder based in Florida. Security-first architecture, iOS development, and premium digital experiences.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-background text-foreground`}
      >
        {children}
      </body>
    </html>
  );
}
