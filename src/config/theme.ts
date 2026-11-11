import { createTheme } from "@mui/material/styles";

// MUI half of the HDDhistory theme; the Tailwind half (brand / bronze scales)
// lives in tailwind.config.js and uses the same hex values.
export const theme = createTheme({
  palette: {
    primary: {
      main: "#946a08",
      light: "#dcb84a",
      dark: "#7a5807",
      contrastText: "#ffffff",
    },
    secondary: {
      main: "#7a5231",
      light: "#c69f76",
      dark: "#604027",
      contrastText: "#ffffff",
    },
    background: { default: "#f5f5f4" },
  },
  typography: {
    // Same system stack as Tailwind's `font-sans`, so MUI and Tailwind text
    // match; headings take the brand face like the h1–h3 rule in index.css.
    fontFamily:
      'ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
    h1: { fontFamily: '"Poppins", ui-sans-serif, system-ui, sans-serif' },
    h2: { fontFamily: '"Poppins", ui-sans-serif, system-ui, sans-serif' },
    h3: { fontFamily: '"Poppins", ui-sans-serif, system-ui, sans-serif' },
    h4: { fontFamily: '"Poppins", ui-sans-serif, system-ui, sans-serif' },
    h5: { fontFamily: '"Poppins", ui-sans-serif, system-ui, sans-serif' },
    h6: { fontFamily: '"Poppins", ui-sans-serif, system-ui, sans-serif' },
    button: { textTransform: "none", fontWeight: 600 },
  },
  shape: { borderRadius: 8 },
});
