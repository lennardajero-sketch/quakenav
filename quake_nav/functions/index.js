const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const cheerio = require("cheerio");
const https = require("https");

admin.initializeApp();

function parseLevel(rawIntensity) {
  const text = String(rawIntensity || "").toLowerCase().trim();
  if (!text) return null;

  const numberMatch = text.match(/(^|\D)(10|[0-9])(\D|$)/);
  if (numberMatch && numberMatch[2] !== undefined) {
    const level = Number(numberMatch[2]);
    if (!Number.isNaN(level) && level >= 0 && level <= 10) return level;
  }

  if (text.includes("system ready")) return 0;
  if (text.includes("barely felt")) return 1;
  if (text.includes("slightly felt")) return 2;
  if (text.includes("weak")) return 3;
  if (text.includes("moderate")) return 4;
  if (text.includes("fairly strong")) return 5;
  if (text === "strong" || text.includes(" strong")) return 6;
  if (text.includes("very strong")) return 7;
  if (text.includes("destructive")) return 8;
  if (text.includes("devastating")) return 9;
  if (text.includes("catastrophic")) return 10;

  return null;
}

function levelLabel(level) {
  switch (level) {
    case 0:
      return "System Ready";
    case 1:
      return "Barely felt";
    case 2:
      return "Slightly felt";
    case 3:
      return "Weak";
    case 4:
      return "Moderate";
    case 5:
      return "Fairly strong";
    case 6:
      return "Strong";
    case 7:
      return "Very strong";
    case 8:
      return "Destructive";
    case 9:
      return "Devastating";
    case 10:
      return "Catastrophic";
    default:
      return "Unknown";
  }
}

async function collectUserTokens() {
  const usersSnapshot = await admin.database().ref("/users").once("value");
  const value = usersSnapshot.val() || {};
  const tokens = [];
  Object.values(value).forEach((user) => {
    const token = user && user.fcmToken ? String(user.fcmToken).trim() : "";
    if (token) tokens.push(token);
  });
  return [...new Set(tokens)];
}

exports.onQuakeHistoryWrite = functions.database
  .ref("/quake_history/{pushId}")
  .onCreate(async (snapshot) => {
    const data = snapshot.val() || {};
    const level = parseLevel(data.intensity);
    if (level === null || level === 0) {
      return null;
    }

    const tokens = await collectUserTokens();
    if (!tokens.length) {
      console.log("No FCM tokens found.");
      return null;
    }

    const multicastMessage = {
      tokens,
      data: {
        type: level >= 5 ? "evacuation" : "advisory",
        level: String(level),
        intensity: levelLabel(level),
        eventId: snapshot.key || "",
        sourceTs: data.esp_epoch_ms ? String(data.esp_epoch_ms) : "",
      },
      android: {
        priority: "high",
      },
    };

    const response = await admin.messaging().sendEachForMulticast(multicastMessage);
    console.log(`FCM sent: success=${response.successCount}, failure=${response.failureCount}`);

    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((res, index) => {
        if (!res.success) {
          const errorCode = res.error && res.error.code ? res.error.code : "";
          const token = tokens[index];
          console.error(`Failed token ${token}: ${errorCode}`);
          if (
            errorCode === "messaging/registration-token-not-registered" ||
            errorCode === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(token);
          }
        }
      });

      if (invalidTokens.length) {
        const usersRef = admin.database().ref("/users");
        const usersSnapshot = await usersRef.once("value");
        const usersValue = usersSnapshot.val() || {};
        const updates = {};

        Object.entries(usersValue).forEach(([uid, user]) => {
          const token = user && user.fcmToken ? String(user.fcmToken).trim() : "";
          if (invalidTokens.includes(token)) {
            updates[`${uid}/fcmToken`] = null;
            updates[`${uid}/fcmTokenUpdatedAt`] = admin.database.ServerValue.TIMESTAMP;
          }
        });

        if (Object.keys(updates).length) {
          await usersRef.update(updates);
        }
      }
    }

    return null;
  });

function toNum(text) {
  const n = Number(String(text || "").replace(/[^\d.-]/g, ""));
  return Number.isFinite(n) ? n : null;
}

exports.syncPhivolcsLatest = functions.pubsub
  .schedule("every 5 minutes")
  .timeZone("Asia/Manila")
  .onRun(async () => {
    const url = "https://earthquake.phivolcs.dost.gov.ph/";
    let resp = null;
    let lastError = null;

    for (let attempt = 1; attempt <= 3; attempt += 1) {
      try {
        resp = await axios.get(url, {
          timeout: 30000,
          maxRedirects: 5,
          headers: {
            "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            Accept:
              "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "no-cache",
          },
        });
        break;
      } catch (err) {
        lastError = err;
        const code = err && err.code ? err.code : "unknown";
        const status =
          err && err.response && err.response.status
            ? err.response.status
            : "n/a";
        console.error(
          `PHIVOLCS fetch failed attempt ${attempt}/3 (code=${code}, status=${status})`
        );

        // PHIVOLCS endpoint intermittently serves an incomplete cert chain.
        // As a fallback, retry once with relaxed TLS verification.
        if (
          !resp &&
          (code === "UNABLE_TO_VERIFY_LEAF_SIGNATURE" ||
            code === "UNABLE_TO_GET_ISSUER_CERT_LOCALLY")
        ) {
          try {
            resp = await axios.get(url, {
              timeout: 30000,
              maxRedirects: 5,
              httpsAgent: new https.Agent({ rejectUnauthorized: false }),
              headers: {
                "User-Agent":
                  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
                Accept:
                  "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Cache-Control": "no-cache",
              },
            });
            console.warn(
              "PHIVOLCS fetch succeeded using TLS-relaxed fallback."
            );
            break;
          } catch (fallbackErr) {
            lastError = fallbackErr;
            console.error(
              `PHIVOLCS TLS-relaxed fallback failed: ${
                fallbackErr && fallbackErr.code ? fallbackErr.code : "unknown"
              }`
            );
          }
        }
        if (attempt < 3) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 2000));
        }
      }
    }

    if (!resp) {
      const code = lastError && lastError.code ? lastError.code : "unknown";
      const message =
        lastError && lastError.message
          ? lastError.message
          : "Unknown PHIVOLCS fetch failure";
      console.error(`PHIVOLCS fetch failed after retries: ${code} ${message}`);
      await admin.database().ref("phivolcs/lastError").set({
        code,
        message,
        at: admin.database.ServerValue.TIMESTAMP,
      });
      return null;
    }

    const $ = cheerio.load(resp.data);

    const firstRow = $("table tr")
      .filter((_, el) => $(el).find("td").length >= 6)
      .first();

    if (!firstRow.length) {
      console.log("No PHIVOLCS row found");
      await admin.database().ref("phivolcs/lastError").set({
        code: "parse/no-row",
        message: "No PHIVOLCS table row found",
        at: admin.database.ServerValue.TIMESTAMP,
      });
      return null;
    }

    const tds = firstRow.find("td");
    const dateTimePH = $(tds[0]).text().trim();
    const latitude = toNum($(tds[1]).text());
    const longitude = toNum($(tds[2]).text());
    const depthKm = toNum($(tds[3]).text());
    const magnitude = toNum($(tds[4]).text());
    const locationText = $(tds[5]).text().trim();

    const payload = {
      dateTimePH,
      latitude,
      longitude,
      depthKm,
      magnitude,
      locationText,
      source: "PHIVOLCS",
      updatedAt: admin.database.ServerValue.TIMESTAMP,
    };

    await admin.database().ref("phivolcs/latest").set(payload);

    const eventId = `${dateTimePH}_${latitude}_${longitude}`.replace(
      /[^\w.-]/g,
      "_"
    );
    await admin.database().ref(`phivolcs/events/${eventId}`).set(payload);
    await admin.database().ref("phivolcs/lastError").remove();

    console.log("Synced PHIVOLCS latest:", payload);
    return null;
  });
