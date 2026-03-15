export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="border-t border-border px-6 py-8">
      <div className="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
        <span className="font-mono text-xs text-muted tracking-widest uppercase">
          hector.dev
        </span>
        <div className="flex items-center gap-6">
          <a
            href="https://github.com/zero-hash-0"
            target="_blank"
            rel="noopener noreferrer"
            className="font-mono text-xs text-muted hover:text-foreground transition-colors"
          >
            GitHub
          </a>
          <a
            href="https://x.com/notT0KY0"
            target="_blank"
            rel="noopener noreferrer"
            className="font-mono text-xs text-muted hover:text-foreground transition-colors"
          >
            X / Twitter
          </a>
        </div>
        <span className="font-mono text-xs text-muted">&copy; {year} Hector</span>
      </div>
    </footer>
  );
}
