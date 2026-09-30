import { google } from 'googleapis';

export async function getGoogleAccessToken() {
  const jwtClient = new google.auth.JWT({
    keyFile: 'keys/meup-bf64f-d292a2730d6b.json',
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const tokens = await jwtClient.authorize();
  return tokens.access_token;
}
