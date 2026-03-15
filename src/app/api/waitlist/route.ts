import { NextRequest, NextResponse } from 'next/server';
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function POST(req: NextRequest) {
  try {
    const { email } = await req.json();

    if (!email || typeof email !== 'string' || !email.includes('@')) {
      return NextResponse.json({ error: 'Invalid email' }, { status: 400 });
    }

    const fromEmail = process.env.RESEND_FROM_EMAIL || 'beta@opus.app';
    const founderEmail = process.env.RESEND_FOUNDER_EMAIL;

    // Send confirmation to the user
    await resend.emails.send({
      from: `Opus <${fromEmail}>`,
      to: email,
      bcc: founderEmail ? [founderEmail] : [],
      subject: "You're on the Opus waitlist.",
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0F0E11; color: #F2F0FF; padding: 40px; max-width: 480px; margin: 0 auto; border-radius: 16px;">
          <p style="font-size: 28px; font-weight: 600; margin: 0 0 8px;">You're on the list.</p>
          <p style="color: rgba(242,240,255,0.5); font-size: 15px; line-height: 1.6; margin: 0 0 32px;">
            We'll send your invite code as soon as your spot opens up.<br />
            We're keeping the beta small — so it actually works.
          </p>
          <div style="background: rgba(245,166,35,0.1); border: 1px solid rgba(245,166,35,0.2); border-radius: 12px; padding: 20px; margin-bottom: 32px;">
            <p style="color: #F5A623; font-size: 13px; font-weight: 600; margin: 0 0 4px;">WHAT TO EXPECT</p>
            <p style="color: rgba(242,240,255,0.6); font-size: 13px; line-height: 1.5; margin: 0;">
              An invite code arriving in your inbox shortly.<br />
              No spam. No newsletters. Just the app.
            </p>
          </div>
          <p style="color: rgba(242,240,255,0.25); font-size: 12px; margin: 0;">
            © 2026 Opus. Work that means something.
          </p>
        </div>
      `,
    });

    return NextResponse.json({ success: true });
  } catch (err) {
    console.error('[waitlist] error:', err);
    // Return success even on email failure — don't surface infra errors to users
    return NextResponse.json({ success: true });
  }
}
