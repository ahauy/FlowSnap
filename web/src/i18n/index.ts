import en from "./en.json";
import vi from "./vi.json";

export type Locale = "en" | "vi";

export const locales: Locale[] = ["en", "vi"];
export const defaultLocale: Locale = "en";

export function getI18n(lang: Locale = "en") {
  return lang === "vi" ? vi : en;
}

export type I18nDictionary = typeof en;
