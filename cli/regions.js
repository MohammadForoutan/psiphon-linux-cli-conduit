"use strict";

const REGIONS = [
  { code: "US", name: "United States" },
  { code: "DE", name: "Germany" },
  { code: "NL", name: "Netherlands" },
  { code: "CA", name: "Canada" },
  { code: "GB", name: "United Kingdom" },
  { code: "FR", name: "France" },
  { code: "SG", name: "Singapore" },
  { code: "JP", name: "Japan" },
  { code: "AU", name: "Australia" },
  { code: "IN", name: "India" },
  { code: "BR", name: "Brazil" },
  { code: "PL", name: "Poland" },
  { code: "SE", name: "Sweden" },
  { code: "CH", name: "Switzerland" },
  { code: "ES", name: "Spain" },
  { code: "IT", name: "Italy" },
  { code: "RO", name: "Romania" },
  { code: "CZ", name: "Czech Republic" },
  { code: "AT", name: "Austria" },
  { code: "BE", name: "Belgium" },
  { code: "HK", name: "Hong Kong" },
  { code: "KR", name: "South Korea" },
  { code: "IE", name: "Ireland" },
  { code: "PT", name: "Portugal" },
  { code: "NO", name: "Norway" },
  { code: "FI", name: "Finland" },
  { code: "UA", name: "Ukraine" },
  { code: "TR", name: "Turkey" },
  { code: "MX", name: "Mexico" },
];

function flagForRegionCode(code) {
  if (!code || code.length !== 2) return "";
  const a = code.toUpperCase().charCodeAt(0) - 0x41;
  const b = code.toUpperCase().charCodeAt(1) - 0x41;
  if (a < 0 || a > 25 || b < 0 || b > 25) return "";
  return String.fromCodePoint(0x1f1e6 + a, 0x1f1e6 + b);
}

module.exports = {
  REGIONS,
  flagForRegionCode,
};
