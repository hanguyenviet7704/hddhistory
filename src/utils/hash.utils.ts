import { createHash } from 'crypto';

export function hashPassword(password: string): string {
    const hash = createHash('sha256');
    hash.update(password);
    return hash.digest('hex');
}

export function comparePassword(password: string, hashedPassword: string): boolean {
    const hash = hashPassword(password);
    return hash === hashedPassword;
}