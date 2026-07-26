const env = require('../config/env');
const logger = require('../config/logger');

// Provider-agnostic OTP sender. Swapping providers is a config change
// (SMS_PROVIDER=twilio|msg91), not a code change in authService/authController.
//
// 'console' (the default) logs the code instead of sending an SMS — this is
// what local dev and the test suite run against, so OTP login works out of
// the box with zero external credentials.
async function sendViaConsole(phone, otp) {
  logger.info(`[dev SMS] OTP for ${phone}: ${otp}`);
}

// Uses Twilio's REST API directly via fetch (Node 18+) rather than pulling
// in the twilio SDK as a dependency just for one call.
async function sendViaTwilio(phone, otp) {
  const { accountSid, authToken, fromNumber } = env.sms.twilio;
  if (!accountSid || !authToken || !fromNumber) {
    throw new Error('Twilio is not configured (TWILIO_ACCOUNT_SID/AUTH_TOKEN/FROM_NUMBER)');
  }

  const body = new URLSearchParams({
    To: phone,
    From: fromNumber,
    Body: `Your GK Quiz verification code is ${otp}. It expires in 5 minutes.`,
  });

  const res = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw new Error(`Twilio send failed (${res.status}): ${detail}`);
  }
}

// MSG91 (common for India-based SMS delivery) via their v5 flow API.
async function sendViaMsg91(phone, otp) {
  const { authKey, templateId, senderId } = env.sms.msg91;
  if (!authKey || !templateId) {
    throw new Error('MSG91 is not configured (MSG91_AUTH_KEY/MSG91_TEMPLATE_ID)');
  }

  const res = await fetch('https://control.msg91.com/api/v5/flow/', {
    method: 'POST',
    headers: {
      authkey: authKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      template_id: templateId,
      sender: senderId,
      short_url: '0',
      mobiles: phone.replace('+', ''),
      OTP: otp,
    }),
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw new Error(`MSG91 send failed (${res.status}): ${detail}`);
  }
}

async function sendOtpSms(phone, otp) {
  switch (env.sms.provider) {
    case 'twilio':
      return sendViaTwilio(phone, otp);
    case 'msg91':
      return sendViaMsg91(phone, otp);
    case 'console':
    default:
      return sendViaConsole(phone, otp);
  }
}

module.exports = { sendOtpSms };
