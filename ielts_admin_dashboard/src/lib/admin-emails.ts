const DEFAULT_ADMIN_EMAILS = ['murshedkoli@gmail.com'];

function parseEmails(value: string | undefined): string[] {
  return (value ?? '')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

export const ADMIN_EMAILS = [
  ...new Set([
    ...DEFAULT_ADMIN_EMAILS,
    ...parseEmails(process.env.ADMIN_EMAILS),
    ...parseEmails(process.env.NEXT_PUBLIC_ADMIN_EMAILS),
  ]),
];

export function isAllowedAdminEmail(email: string | null | undefined): boolean {
  return Boolean(email && ADMIN_EMAILS.includes(email.toLowerCase()));
}
