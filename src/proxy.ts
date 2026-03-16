import { NextRequest, NextResponse } from 'next/server';

const VALID_CODES = (process.env.NEXT_PUBLIC_BETA_INVITE_CODES || 'OPUS-BETA-001,OPUS-BETA-002,OPUS-BETA-003,OPUS-BETA-004,OPUS-BETA-005,OPUS-BETA-IOS')
  .split(',')
  .map(c => c.trim().toUpperCase())
  .filter(Boolean);

export function proxy(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // Only gate /opus/app and all sub-paths
  if (!pathname.startsWith('/opus/app')) return NextResponse.next();

  // Check for invite cookie
  const inviteCookie = req.cookies.get('opus_invite')?.value?.toUpperCase();
  const isValid = inviteCookie && VALID_CODES.includes(inviteCookie);

  if (!isValid) {
    const redirectUrl = req.nextUrl.clone();
    redirectUrl.pathname = '/opus';
    redirectUrl.searchParams.set('gate', 'true');
    return NextResponse.redirect(redirectUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/opus/app/:path*'],
};
