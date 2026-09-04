# PHASE 4 — Design System
## سیستم مدیریت مالی، دارایی و ثروت شخصی
**وضعیت:** ✅ تکمیل‌شده — در انتظار تأیید شما
**تاریخ:** ۲۰۲۶-۰۹-۰۳
**شاخه:** `docs/phase-04-design-system.md`

---

## ۰. فلسفهٔ بصری (مطابق بند ۹-۱۰، ۸۸، ۸۹، ۱۰۸-۱۰۹)

هدف: **«همان کیفیت بصری بلوبانک، اما هویت مستقل.»** — ساده، آرام، پریمیوم، منظم، فضای خالی؛ نه شلوغ، نه کودکانه، نه Excel. پیچیدگی مالی پشت‌صحنه پنهان است؛ UI فوق‌ساده.

**شخصیت طراحی:** `Calm · Elegant · Premium · Friendly · Intelligent`
**مفهوم مرکزی:** «استوای مالی چندگانه» — کارت‌های سطحی نرم، فونت فارسی رنج‌نشده و آرام، تأکید بر ارزش با تصحیح/روائی؛ اعداد را ارجمند نگه می‌داریم.

---

## ۱. Typography (بند ۸۷، ۹۰)

### فونت
- **اصل:** **Vazirmatn** (افزوده به Assets) — فارسی مدرن، خوانا، اعداد شفاف.
- **West** (عدد لاتین/علائم): Vazirmatn (دارای لاتین هم خوب). در صورت نیاز ارز (USD/EUR)، `tabular figures` فعال شود.
- **Fallback:** Roboto (برای Latin/فروشگاه).

### مقیاس (Scale)
| توکن | اندازه | قلم | کاربرد |
|---|---|---|---|
| `display` | 34 | Bold | NetWorth big number |
| `headline` | 26 | SemiBold | عنوان صفحه/کارت اصلی |
| `title` | 20 | SemiBold | عنوان کارت/بخش |
| `titleSmall` | 17 | SemiBold | |
| `body` | 15 | Regular | متن اصلی |
| `bodySmall` | 13 | Regular | ثانویه |
| `label` | 14 | Medium | برچسب/دکمه |
| `labelSmall` | 12 | Medium | caption/برچسب کوچک |
| `caption` | 11 | Regular | Hint/Timestamp |

- **اعداد:** از `FontFeature.tabularFigures()` برای اعداد داخل کارت برای تراز ستونی.
- **Dynamic Text Scale** (بند ۹۰): از سیستم textScaler پشتیبانی می‌شود.

---

## ۲. Color System (بند ۸۸، ۸۹) — Light & Dark

> در کار می‌شود: `Tokens` (خام) → `Semantic` (ارزش کاربردی) → `LightTheme`/`DarkTheme`.

### ۲.۱ رنگ‌های معنی (Semantic) — Light
| Token | Hex | کاربرد |
|---|---|---|
| `bg` (Background) | `#F6F7F9` | صفحه |
| `surface` | `#FFFFFF` | کارت/شیت |
| `surfaceAlt` | `#F1F2F5` | کارت‌های فرعی |
| `textPrimary` | `#1A1C1E` | متن اصلی |
| `textSecondary` | `#6B7178` | متن ثانویه |
| `textTertiary` | `#9AA0A6` | hint |
| `primary` | `#135F56` | **رنگ هویت** (سبز زمردیِ آرامِ ممتاز) |
| `onPrimary` | `#FFFFFF` | |
| `primarySoft` | `#E2F0ED` | پس‌زمینهٔ ملایم accent |
| `success` | `#1F9D61` | سود/ورود |
| `warning` | `#E0A03C` | هشدار |
| `error` | `#D14D4D` | منفی/خطا |
| `successSoft` | `#E3F5EB` | |
| `warningSoft` | `#FBEFD8` | |
| `errorSoft` | `#FBE6E6` | |
| `border` | `#E8EAED` | خطوط |
| `chartGrid` | `#ECEEF1` | خط شبکه نمودار |

### ۲.۲ رنگ‌های معنی — Dark
| Token | Hex |
|---|---|
| `bg` | `#0E1213` |
| `surface` | `#15191B` |
| `surfaceAlt` | `#1D2225` |
| `textPrimary` | `#F0F2F3` |
| `textSecondary` | `#A6ADB3` |
| `textTertiary` | `#6C737A` |
| `primary` | `#5BC2AE` (روشن‌تر برای Contrast) |
| `onPrimary` | `#0E1614` |
| `primarySoft` | `#16302B` |
| `success` | `#43C98D` |
| `warning` | `#E8B458` |
| `error` | `#E67474` |
| `border` | `#262B2E` |
| `chartGrid` | `#22282B` |

### ۲.۳ Accent کاربر (بند ۸)
- یک `accent` قابل تغییر از لیست محدود (سبز زمردی / فیروزهٔ دریایی / بنفش یشمی / نارنجی لطیف / آبی محوشده). Default = زمردی.
- استفادهٔ محتاطانه؛ در حالت خنثی نسخهٔ Soft.

### ۲.۴ قواعد رنگ
- **محدود بودن:** ۱ رنگ Primary، ۳ کاربری (success/warning/error) + آکستن. بدون سوارکاری.
- **Contrast AA**: حداقل 4.5:1 برای متن؛ حالت تیره با دقت.
- **فضای خالی:** رنگ‌های muted برای پس‌زمینه; accent برای تأکید نقطـه‌ای.

---

## ۳. Spacing & Radius (بند ۸۸)

### ۳.۱ پله‌های فاصله (4dp base)
| توکن | ارزش | |
|---|---|---|
| `xs` | 4 | |
| `sm` | 8 | |
| `md` | 12 | |
| `lg` | 16 | |
| `xl` | 24 | |
| `xxl` | 32 | |
| `screenPad` | 20 | فاصلهٔ لبه‌ای صفحات |

### ۳.۲ شعاع (Radius)
| توکن | | |
|---|---|---|
| `rSm` | 8 | |
| `rMd` | 12 | دکمه |
| `rLg` | 16 | کارت‌ها |
| `rXl` | 24 | کارت بزرگ/برگه |
| `rFull` | 999 | دکمهٔ گرد / آواتار |

### ۳.۳ سایه
عمدتاً سایهٔ ملایم (ورو‌برد) `primarySoft` تا حس پیشرفته؛ `elevation = 1–2` با رنگ سطح. Dark شیه کمتر.

### ۳.۴ تقویم و اعداد (شمسی — بند ۸ 'Date Format')
- **زبان UI:** فارسی (fa_IR)، RTL، ارقام فارسی.
- **تاریخ ها:** نمایش/ورودی **شمسی (جلالی)** — `۱۴۰۵/۰۶/۱۲`، تاریخ شمشیری بومی؛ ذخیره در UI در UTC برای صحت (رجوع به `decisions-i18n-calendar.md`).
- **قابل‌شخصی‌سازی:** فرمت تاریخ (اسمی/عدد ی) در تنظیمات (بند ۸).

---

## ۴. Components & Cards (بند ۸۸، ۱۰-۱۱، ۸۵)

### کارت‌ها (`WealthCard`)
- Layout: `surface`, radius `rLg`, padding `lg`, border `border`(1) اختیاری، سایهٔ ملایم.
- `WealthCard` دارای: عنوان، مقدار (big number با tabular), دلتا (▲/▼ رنگ), کاشی کوچک نمودار/آیکون.
- **کارت NetWorth** (Hero): بزرگ، نمایش `display` عدد + trend + Drill-down (`🔍`)
- **کارت Metric** (نقدینگی/سرمایه‌گذاری/بدهی): ۳ کاشی کوچک.
- **Drill-down پذیری:** کارت‌ها قابل کلیک به جزئیات.

### دکمه‌ها (`WealthButton`)
| variant | توضیح |
|---|---|
| `primary` | پر، هویت |
| `secondary` | خالی با border |
| `ghost` | بدون پس‌زمینه |
| `danger` | خطا/حذف |
| `softPrimary` | نرم (primarySoft) |
- Radius `rMd`, height 48 (touch ≥48، بند ۹۰), Ripple سبک, `minWidth`.

### ورودی‌ها (`WealthField`)
- TextField با label, helper, error. Border `border`, focus primary, radius `rMd`, padding.
- **بزرگ برای مبلغ:** جداکنندهٔ هزارگان + واحد (تومان). برای اعداد `tabular`.
- Select/Dropdown، Segmented (برای نوع), Chip (برای تگ).
- Dialog/Sheet انتخاب.

### Navigation (بند ۱۲، H)
- **BottomNavigationBar**: پنج تب (خانه/تراکنش/+/دارایی/آینده) + دکمهٔ مرکزی گرد `+` (FAB center).
- **TopAppBar**: سرصفحهٔ نیمه‌شفاف، عنوان + آیکون پروفایل/اعلان.
- **AnimatedSwitcher** برای جابه‌جایی تب (کوتاه).
- **IndexedStack** برای حفظ state تب‌ها.

### State/Empty/Error (بند ۸۳)
- `LoadingSkeleton` (فروش ستون‌ها)، `EmptyState` با CTA («اولین دارایی‌ات را اضافه کن» — بند ۸۵)، `ErrorState`, `OfflineBanner` (آخرین قیمت موجود — بند ۸۲), `FirstUseHint`.

### Micro-interactions (بند ۸۶)
- **AnimatedNumber** (شمارش موجودی)، Fade/Scale ورودی, Success check animation, Tab transition, Chart reveal.
- همهٔ CSS/Flutter با `reducedMotion` (بند ۹۰).

---

## ۵. Charts (بند ۸۸ بخش نمودار)

### انواع
- **Line/Area** → رشد ثروت (NetWorth)، قیمت، جریان نقدی.
- **Donut/Pie** → تخصیص دارایی، مخارج.
- **Bar** → مخارج دسته، ریزش.
- **Sparkline** → کاشی‌های کوچک.

### استایل
- خطوط: primary، رنگ‌های Soft، بدون ضخامت زیاد.
- Grid: `chartGrid`, بدون labelهای شلوغ.
- Tooltip: surface با shadow.
- X-axis: تاریخ فشرده، Y-axis: ۳-۴ تیک.
- **محور RTL**: نمودارها به‌صورت راست‌چین (فلدر جهت رعایت Persian).

---

## ۶. Dark Mode (بند ۸۹)

- از Semantic tokens بالا؛ **نه** فقط مشکی‌کردن.
- خودکار از `theme_mode` (system/light/dark) + انتخاب کاربر.
- Contrast و خوانایی در Dark رعایت.

---

## ۷. Accessibility (بند ۹۰)

- **RTL** کامل (Direction), Dynamic Font, Screen Sizes.
- Touch targets ≥48dp، Contrast AA، Reduced Motion.
- فونت با متن مرجع در حالت‌های Small/Large.
- نمودارها قابل درک با رنگ+برچسب (نه فقط رنگ).

---

## ۸. توکن‌های پیاده‌سازی (Flutter)

```dart
// design/colors
class WColors {
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  ...
  static const primary = Color(0xFF135F56);
  ...
}
// design/theme
ThemeData buildAppTheme({required ThemeMode mode, required Color accent}) {...}
// design/typography
const kFontFamily = 'Vazirmatn';
```

---

## ۹. معیار Done فاز ۴
- [x] تایپوگرافی (Vazirmatn + scale + tabular)
- [x] رنگ (Light+Dark+Accent)
- [x] فاصله و شعاع
- [x] کامپوننت‌ها (Card/Button/Input/Nav)
- [x] حالت‌های Empty/Error/Loading
- [x] نمودارها (انواع + استایل + RTL)
- [x] Dark Mode واقعی
- [x] Accessibility (RTL/Font/Contrast/ReducedMotion)
- [x] توکن‌های Flutter
- [x] نمونهٔ مرجع HTML (`artifacts/design-system-preview.html`)

---

## ۱۰. گزارش پایان فاز ۴
1. **ساخته شد:** نظام طراحی کامل (Type/Color/Space/Components/Cards/Buttons/Inputs/Nav/Charts/Dark/Accessibility) + نمونهٔ مرجع HTML قابل‌مشاهده.
2. **فایل‌ها:** `docs/phase-04-design-system.md` + `artifacts/design-system-preview.html`.
3. **Schema:** هیچ (فاز طراحی).
4. **تصمیمات:** هویت رنگی سبز زمردی، Vazirmatn، Semantic+Light/Dark tokens، Card/Button/Field استاندارد، Donut/Bar/Line chart راست‌چین، ReducedMotion.
5. **تست:** فاز ۴، تست انیمیشن/Charts در فاز ۱۶/پیاده‌سازی (UI).
6. **مشکلات:** عدم دسترسی به فونت Vazirmatn در HTML پیش‌نمایش (token ها در کد Flutter از Assets می‌آیند).
7. **باقی‌مانده:** فاز ۵ — UX/Wireframes.
8. **پیشنهادها:** فاز ۵ ترکیب این رنگ‌ها/کارت‌ها و فریم‌های صفحه.
9. **ناسازگاری:** ندارد؛ هم‌راستا با بند ۹-۱۰، ۸۸-۹۰، ۱۰۸-۱۰۹.

---

✅ **فاز ۴ کامل شد. نیازمند تأیید برای فاز ۵ (UX / Wireframes) هستم.**
