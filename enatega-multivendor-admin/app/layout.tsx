import { NextIntlClientProvider } from 'next-intl';
import { getLocale, getMessages } from 'next-intl/server';
import Script from 'next/script';
import { ThemeProvider } from 'next-themes';

// ✅ Add metadata export for favicon
export const metadata = {
  title: 'Enatega Admin Dashboard',
  icons: {
    icon: '/favsicons.png',
    // You can add more like:
    // shortcut: "/favicon.png",
    // apple: "/apple-touch-icon.png"
  },
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const locale = await getLocale();
  const rawMessages = await getMessages({ locale });

  // Transform flat messages to nested structure to avoid INVALID_KEY error with dots
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const messages = Object.entries(rawMessages).reduce((acc: any, [key, value]) => {
    const keys = key.split('.');
    if (keys.length > 1) {
      let current = acc;
      let collision = false;
      for (let i = 0; i < keys.length - 1; i++) {
        const k = keys[i];
        if (current[k] !== undefined && typeof current[k] !== 'object') {
          collision = true;
          break;
        }
        current[k] = current[k] || {};
        current = current[k];
      }
      if (!collision && typeof current === 'object' && (current[keys[keys.length - 1]] === undefined || typeof current[keys[keys.length - 1]] !== 'object')) {
        current[keys[keys.length - 1]] = value;
      } else {
        // On collision or invalid path, keep it flat in the root
        acc[key] = value;
      }
    } else {
      if (acc[key] === undefined || typeof acc[key] !== 'object') {
        acc[key] = value;
      }
    }
    return acc;
  }, {});

  return (
    <html lang={locale}>
      <head>
        {/* Microsoft Clarity */}
        <Script id="microsoft-clarity" strategy="afterInteractive">
          {`
            (function(c,l,a,r,i,t,y){
        c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
        t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
        y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
    })(window, document, "clarity", "script", "tjqxrz689j");
          `}
        </Script>
      </head>
      <body>
        <ThemeProvider attribute={'class'}>
          <NextIntlClientProvider messages={messages}>
            {children}
          </NextIntlClientProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
