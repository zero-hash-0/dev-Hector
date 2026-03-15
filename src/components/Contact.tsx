export default function Contact() {
  return (
    <section id="contact" className="py-20 px-6 max-w-5xl mx-auto">
      <div className="rounded-2xl border border-border bg-surface p-10 md:p-16 text-center space-y-8">
        <div className="space-y-4">
          <p className="font-mono text-xs text-accent tracking-[0.2em] uppercase">
            Contact
          </p>
          <h2 className="text-4xl md:text-5xl font-semibold tracking-tight">
            Let&apos;s build
            <br />
            something great.
          </h2>
          <p className="text-muted max-w-md mx-auto leading-relaxed">
            Whether you have a project in mind, want to collaborate, or just
            want to say hello — my inbox is open.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <a
            href="mailto:hello@clutched.dev"
            className="inline-flex items-center gap-2 bg-accent text-background text-sm font-medium px-8 py-3 rounded-full hover:bg-accent-dim transition-colors"
          >
            Send a message
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <path d="M1 7h12M7 1l6 6-6 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </a>
          <a
            href="https://x.com/notT0KY0"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center text-sm text-muted hover:text-foreground border border-border px-8 py-3 rounded-full hover:border-zinc-600 transition-all"
          >
            DM on X
          </a>
        </div>
      </div>
    </section>
  );
}
