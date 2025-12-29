export function buildAQIRecommendation({ aqi, profile, city }) {
  let title = "⚠️ Air Quality Alert";
  let body = `AQI in ${city} is ${aqi}. Take precautions.`;

  if (!profile) {
    return { title, body };
  }

  const { ageGroup, skinType, conditions, airSensitivity } = profile;

  // Gen-Z but not cringe
  if (aqi >= 300) {
    title = "🚨 Air outside is straight-up toxic";
    body = "Please stay indoors. This is not a drill.";
  } 
  else if (aqi >= 200) {
    title = "😷 Air quality is bad";
    body = "Mask up if you step outside. Your lungs will thank you.";
  } 
  else if (aqi >= 150) {
    title = "⚠️ Air quality dropping";
    body = "Outdoor plans? Maybe reconsider.";
  }

  // Health tweaks
  if (conditions?.includes("Asthma")) {
    body += " Asthma alert — avoid exertion.";
  }

  if (skinType === "Sensitive") {
    body += " Sensitive skin? Cleanse after exposure.";
  }

  if (airSensitivity === "High") {
    body += " You’re more sensitive — play it safe.";
  }

  return { title, body };
}
