/** @type {import('tailwindcss').Config} */
const plugin = require("tailwindcss/plugin");
const daisyuiColorObj = require("daisyui/src/theming/index");

module.exports = {
  daisyui: {
    themes: [
      {
        light: {
          primary: "#c25a0a",
          "primary-content": "#ffffff",
          secondary: "#52525b",
          accent: "#f68712",
          neutral: "#71717a",
          "neutral-content": "#d4d4d8",
          "base-100": "#ffffff",
          "base-200": "#f4f4f5",
          "base-content": "#0a0a0a",
          info: "#fdba74",
          success: "#22c55e",
          warning: "#facc15",
          error: "#dc2626",
        },
      },
      {
        dark: {
          primary: "#f68712",
          "primary-content": "#0a0a0a",
          secondary: "#a1a1aa",
          accent: "#fb9a3c",
          neutral: "#a1a1aa",
          "neutral-content": "#3f3f46",
          "base-100": "#0a0a0a",
          "base-200": "#18181b",
          "base-content": "#fafafa",
          info: "#fdba74",
          success: "#00b17d",
          warning: "#eac700",
          error: "#f1293c",
        },
      },
    ],
  },
  darkMode: ["class", '[data-theme="dark"]'],
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",

    // For the "layouts" directory
    "./layouts/**/*.{js,ts,jsx,tsx}",
  ],
  plugins: [
    require("daisyui"),
    plugin(({ addVariant }) => {
      addVariant("dark", '&[data-theme="dark"]');
    }),
    require("tailwindcss-animate"),
  ],
  theme: {
    extend: {
      colors: {
        border: daisyuiColorObj["neutral-content"],
        input: daisyuiColorObj["base-content"],
        ring: daisyuiColorObj["base-content"],
        background: daisyuiColorObj["base-100"],
        foreground: daisyuiColorObj["base-content"],
        primary: {
          DEFAULT: daisyuiColorObj["primary"],
          foreground: daisyuiColorObj["primary-content"],
        },
        secondary: {
          DEFAULT: daisyuiColorObj["secondary"],
          foreground: daisyuiColorObj["secondary-content"],
        },
        destructive: {
          DEFAULT: daisyuiColorObj["error"],
          foreground: daisyuiColorObj["error-content"],
        },
        muted: {
          DEFAULT: daisyuiColorObj["base-300"],
          foreground: daisyuiColorObj["base-content"],
        },
        accent: {
          DEFAULT: daisyuiColorObj["accent"],
          foreground: daisyuiColorObj["accent-content"],
        },
        popover: {
          DEFAULT: daisyuiColorObj["base-200"],
          foreground: daisyuiColorObj["base-content"],
        },
        card: {
          DEFAULT: daisyuiColorObj["base-100"],
          foreground: daisyuiColorObj["base-content"],
        },
      },
      borderRadius: {
        lg: "var(--rounded-btn)",
        md: "calc(var(--rounded-btn) - 2px)",
        sm: "calc(var(--rounded-btn) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
};
