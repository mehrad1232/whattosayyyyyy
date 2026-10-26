# NOVA Calculator — پروژه بومی Swift/UIKit برای iPhone

این پروژه برنامه وب نیست؛ یک پروژه بومی iOS با Swift و UIKit است و `IPHONEOS_DEPLOYMENT_TARGET` روی `12.0` تنظیم شده. رابط کاربری با Auto Layout ساخته شده تا چرخش عمودی و افقی را پشتیبانی کند. محاسبات با اعداد صحیح ده‌دهی انجام می‌شود، پس جمع و تفریق به محدودیت معمول `Int64` وابسته نیستند. عملیات‌های جمع، تفریق، ضرب و تقسیم صحیح پیاده‌سازی شده‌اند. در تقسیم، بخش اعشاری حذف می‌شود.

## فایل‌ها
- `NOVACalculator.xcodeproj`: پروژه Xcode با scheme اشتراکی
- `NOVACalculator/AppDelegate.swift`: ورودی برنامه
- `NOVACalculator/CalculatorViewController.swift`: رابط گرافیکی، دکمه‌ها، انیمیشن و چرخش صفحه
- `NOVACalculator/BigInteger.swift`: موتور محاسبات صحیح با دقت دلخواه
- `NOVACalculator/Info.plist`: تنظیمات اپ و جهت‌های صفحه
- `NOVACalculator/Assets.xcassets`: آیکون برنامه
- `.github/workflows/build-ipa.yml`: تلاش برای ساخت IPA بدون امضا روی runner ابری macOS

## راه مستقیم در Mac
1. ZIP را از حالت فشرده خارج کنید.
2. `NOVACalculator.xcodeproj` را در Xcode باز کنید.
3. در Target > Signing & Capabilities، گزینه Automatically manage signing را روشن و Team خود را انتخاب کنید.
4. برای تست، iPhone را وصل و Run کنید.
5. برای خروجی IPA، از Product > Archive و سپس Distribute App استفاده کنید.

## ساخت IPA بدون نیاز به داشتن Mac شخصی (با GitHub Actions)
این مخزن یک workflow ابری هم دارد؛ خودم از این محیط به Xcode/iOS SDK دسترسی ندارم، بنابراین ساخت نهایی این workflow از اینجا اجرا یا تأیید نشده است.

1. یک مخزن GitHub بساز و محتویات پوشه پروژه را در آن بارگذاری کن.
2. در تب Actions، workflow با نام `Build NOVA iOS IPA` را باز کن.
3. `Run workflow` را بزن و صبر کن تا job کامل شود.
4. فایل `NOVA-unsigned.ipa` را از بخش Artifacts دانلود کن.

اگر runner ابری نتوانست Xcode 15.4 را نصب کند یا build را به خاطر target نسخه قدیمی متوقف کرد، به یک محیط macOS/Xcode سازگار نیاز است. این پروژه را در ویندوز می‌توان ویرایش کرد، اما کامپایل iOS باید در macOS انجام شود.

## نصب روی iPhone از ویندوز
AltServer قابلیت Direct IPA Sideloading برای دستگاه‌های iOS 9.3 یا جدیدتر را مستند کرده است. بعد از دریافت IPA، AltServer را از https://altstore.io/ نصب کن؛ در ویندوز هنگام کلیک روی AltServer کلید Shift را نگه دار و `Sideload .ipa…` را انتخاب کن. در صورت درخواست، Apple ID را برای امضای مجدد وارد کن. برنامه‌های امضاشده با حساب رایگان معمولاً هر ۷ روز نیاز به نصب/امضای دوباره دارند.
راهنمای رسمی: https://faq.altstore.io/release-notes/altserver

## تست‌های پیشنهادی
- `999999999999999999 + 1` → `1,000,000,000,000,000,000`
- `1000 - 250` → `750`
- `-45 - 55` → `−100`
- `7 × 8` → `56`
- `17 ÷ 5` → `3` (تقسیم صحیح)
- تقسیم بر صفر → پیام خطا
