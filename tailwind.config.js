/** @type {import('tailwindcss').Config} */
const defaultTheme = require("tailwindcss/defaultTheme");

// HDDhistory brand gold — the same values as hddhistory-web's globals.css
// (50/100/200/300/500/700/900). 400/600/800/950 are filled in between so every
// Tailwind step exists. 600 is the darkest shade that still reads as gold and
// the first one white text passes WCAG AA on (≈4.8:1) — use it for solid fills
// that carry text, not 500.
const brand = {
  50: "#fbf3e0",
  100: "#f5e4b8",
  200: "#ebd08a",
  300: "#dcb84a",
  400: "#c99d22",
  500: "#b8860b",
  600: "#946a08",
  700: "#7a5807",
  800: "#5c4205",
  900: "#3d2c04",
  950: "#241a02",
  DEFAULT: "#b8860b",
};

// Secondary accent: a darker bronze. The UI used blue and indigo as two
// different accents; they map to brand and bronze so the pairs stay apart.
const bronze = {
  50: "#f7f1ea",
  100: "#ede0d0",
  200: "#dcc2a3",
  300: "#c69f76",
  400: "#ae7f52",
  500: "#95673d",
  600: "#7a5231",
  700: "#604027",
  800: "#47301e",
  900: "#2f2014",
  950: "#1c130c",
};

module.exports = {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: { brand, bronze },
      // Poppins (the web app's face) for brand + headings only. Body text
      // stays on the system stack: Poppins runs ~10% wider, and the dense
      // tables and toolbars here were laid out for the narrower face.
      fontFamily: {
        display: ["Poppins", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [],
};
