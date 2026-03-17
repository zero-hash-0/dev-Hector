import { NextRequest, NextResponse } from 'next/server';
import { Resend } from 'resend';

const BETA_LIMIT = 25;
const EARLY_TESTER_LIMIT = 25; // all 25 get the gold badge

// Uses Resend Audiences as the persistent store — no external DB needed.
// Env vars required:
//   RESEND_API_KEY          — Resend secret key
//   RESEND_AUDIENCE_ID      — audience ID from Resend dashboard (create once)
//   RESEND_FROM_EMAIL       — e.g. "beta@opus.app"
//   RESEND_FOUNDER_EMAIL    — BCC for every signup notification

function getResend() {
  return new Resend(process.env.RESEND_API_KEY || 'placeholder');
}

// ── GET /api/beta — return current signup count & slots remaining ─────────────
export async function GET() {
  try {
    const resend = getResend();
    const audienceId = process.env.RESEND_AUDIENCE_ID;

    if (!audienceId) {
      return NextResponse.json({ count: 0, remaining: BETA_LIMIT, full: false });
    }

    const result = await resend.contacts.list({ audienceId });
    const count = result.data?.data?.length ?? 0;
    const remaining = Math.max(0, BETA_LIMIT - count);

    return NextResponse.json({ count, remaining, full: remaining === 0 });
  } catch {
    return NextResponse.json({ count: 0, remaining: BETA_LIMIT, full: false });
  }
}

// ── POST /api/beta — register a beta tester ───────────────────────────────────
export async function POST(req: NextRequest) {
  try {
    const { name, email } = await req.json();

    if (!email || typeof email !== 'string' || !email.includes('@')) {
      return NextResponse.json({ error: 'Invalid email' }, { status: 400 });
    }
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return NextResponse.json({ error: 'Name required' }, { status: 400 });
    }

    const firstName = name.trim().split(' ')[0];
    const resend    = getResend();
    const audienceId = process.env.RESEND_AUDIENCE_ID;
    const fromEmail  = process.env.RESEND_FROM_EMAIL  || 'beta@opus.app';
    const founderEmail = process.env.RESEND_FOUNDER_EMAIL;

    // ── Check current count ──
    let currentCount = 0;
    if (audienceId) {
      const listResult = await resend.contacts.list({ audienceId });
      currentCount = listResult.data?.data?.length ?? 0;
    }

    if (currentCount >= BETA_LIMIT) {
      return NextResponse.json({ error: 'Beta is full', full: true }, { status: 409 });
    }

    // ── Check for duplicate ──
    if (audienceId) {
      const existing = await resend.contacts.list({ audienceId });
      const alreadyIn = existing.data?.data?.some(
        (c: { email: string }) => c.email.toLowerCase() === email.toLowerCase()
      );
      if (alreadyIn) {
        return NextResponse.json({ error: 'Already registered', duplicate: true }, { status: 409 });
      }
    }

    const slotNumber  = currentCount + 1;
    const isEarlyTester = slotNumber <= EARLY_TESTER_LIMIT;

    // ── Add to Resend audience ──
    if (audienceId) {
      await resend.contacts.create({
        audienceId,
        email,
        firstName: firstName,
        lastName:  name.trim().split(' ').slice(1).join(' ') || undefined,
        unsubscribed: false,
      });
    }

    // ── Send welcome email to tester ──
    await resend.emails.send({
      from: `Opus <${fromEmail}>`,
      to: email,
      bcc: founderEmail ? [founderEmail] : [],
      subject: isEarlyTester
        ? `🥇 You're Beta Tester #${slotNumber} — Gold Badge unlocked`
        : `You're in the Opus Beta`,
      html: buildWelcomeEmail(firstName, slotNumber, isEarlyTester),
    });

    return NextResponse.json({
      success: true,
      slot: slotNumber,
      isEarlyTester,
      remaining: Math.max(0, BETA_LIMIT - slotNumber),
    });
  } catch (err) {
    console.error('[beta] error:', err);
    return NextResponse.json({ error: 'Server error' }, { status: 500 });
  }
}

// ── Email template ────────────────────────────────────────────────────────────
function buildWelcomeEmail(firstName: string, slot: number, isEarlyTester: boolean) {
  const badgeSection = isEarlyTester ? `
    <div style="
      background: linear-gradient(135deg, rgba(234,179,8,0.15) 0%, rgba(161,122,0,0.1) 100%);
      border: 1px solid rgba(234,179,8,0.35);
      border-radius: 14px;
      padding: 20px 24px;
      margin-bottom: 28px;
      display: flex;
      align-items: center;
      gap: 16px;
    ">
      <span style="font-size: 32px;">🥇</span>
      <div>
        <p style="
          color: #EAB308;
          font-size: 12px;
          font-weight: 700;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          margin: 0 0 4px;
        ">FOUNDING MEMBER · #${slot} OF ${EARLY_TESTER_LIMIT}</p>
        <p style="
          color: rgba(234,179,8,0.75);
          font-size: 13px;
          line-height: 1.5;
          margin: 0;
        ">
          You're one of the first ${EARLY_TESTER_LIMIT} testers. Your profile carries a permanent
          <strong style="color: #EAB308;">Gold Badge</strong> — a thank-you that never goes away.
        </p>
      </div>
    </div>
  ` : '';

  return `
    <div style="
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0F0E11;
      color: #F2F0FF;
      padding: 40px 36px;
      max-width: 500px;
      margin: 0 auto;
      border-radius: 20px;
    ">

      <!-- Header -->
      <div style="margin-bottom: 32px;">
        <div style="
          width: 52px; height: 52px;
          background: linear-gradient(135deg, #6E6BF5, #8A4AF3);
          border-radius: 14px;
          display: flex; align-items: center; justify-content: center;
          margin-bottom: 20px;
          font-size: 24px;
          line-height: 52px;
          text-align: center;
        ">✓</div>
        <p style="font-size: 26px; font-weight: 700; margin: 0 0 8px; color: #F2F0FF;">
          You're in, ${firstName}.
        </p>
        <p style="color: rgba(242,240,255,0.45); font-size: 15px; line-height: 1.6; margin: 0;">
          Welcome to the Opus beta. You're tester #${slot}.
        </p>
      </div>

      ${badgeSection}

      <!-- What's next -->
      <div style="margin-bottom: 28px;">
        <p style="
          color: rgba(242,240,255,0.3);
          font-size: 11px;
          font-weight: 700;
          letter-spacing: 0.14em;
          text-transform: uppercase;
          margin: 0 0 14px;
        ">WHAT'S NEXT</p>

        <div style="display: flex; flex-direction: column; gap: 10px;">
          ${stepRow('1', 'Download via TestFlight', 'Link arriving within 24 hours — check this inbox.')}
          ${stepRow('2', 'Complete onboarding', 'Set your name, pick your focus area, and add your first task.')}
          ${stepRow('3', 'Build your streak', 'Complete tasks daily to grow your momentum score.')}
        </div>
      </div>

      <!-- Feedback note -->
      <div style="
        background: rgba(138,74,243,0.1);
        border: 1px solid rgba(138,74,243,0.2);
        border-radius: 12px;
        padding: 16px 20px;
        margin-bottom: 32px;
      ">
        <p style="color: rgba(167,139,250,0.9); font-size: 13px; line-height: 1.6; margin: 0;">
          🛠 Your feedback shapes the roadmap. Reply to this email anytime
          — every message goes straight to the builder.
        </p>
      </div>

      <!-- Footer -->
      <p style="color: rgba(242,240,255,0.18); font-size: 12px; margin: 0;">
        © 2026 Opus · Slot ${slot}/${EARLY_TESTER_LIMIT} secured
      </p>
    </div>
  `;
}

function stepRow(num: string, title: string, desc: string) {
  return `
    <div style="
      display: flex;
      gap: 14px;
      background: rgba(242,240,255,0.04);
      border: 1px solid rgba(242,240,255,0.07);
      border-radius: 11px;
      padding: 14px 16px;
    ">
      <div style="
        width: 24px; height: 24px; min-width: 24px;
        background: rgba(138,74,243,0.2);
        border-radius: 50%;
        color: #A78BFA;
        font-size: 12px;
        font-weight: 700;
        display: flex; align-items: center; justify-content: center;
        text-align: center;
        line-height: 24px;
      ">${num}</div>
      <div>
        <p style="color: #F2F0FF; font-size: 14px; font-weight: 600; margin: 0 0 3px;">${title}</p>
        <p style="color: rgba(242,240,255,0.4); font-size: 12px; margin: 0; line-height: 1.5;">${desc}</p>
      </div>
    </div>
  `;
}
