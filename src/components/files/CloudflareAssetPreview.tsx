import React, { useEffect, useMemo, useRef, useState } from "react";
import lottie, { AnimationItem } from "lottie-web";
import { cloudflareService } from "../../services/cloudflareR2Service";

const ANIMATION_EXT_REGEX = /\.(json|lottie)(\?|#|$)/i;
const IMAGE_EXT_REGEX = /\.(png|jpe?g|gif|webp|svg)(\?|#|$)/i;

const normalizeAnimationData = (raw: any) => {
  if (!raw) return null;
  if (typeof raw === "string") {
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  }
  if (raw.data) return raw.data;
  return raw;
};

const extractKeyFromUrl = (value: string) => {
  const clean = value.split("?")[0].split("#")[0];
  if (!clean) return "";
  try {
    const parsed = new URL(clean);
    const path = decodeURIComponent(parsed.pathname);
    const marker = "/cloudflares/download/";
    const idx = path.indexOf(marker);
    if (idx >= 0) {
      return path.slice(idx + marker.length).replace(/^\/+/, "");
    }
    const parts = path.split("/").filter(Boolean);
    if (parts.length === 0) return "";
    return parts.slice(-2).join("/");
  } catch {
    const path = decodeURIComponent(clean);
    const marker = "/cloudflares/download/";
    const idx = path.indexOf(marker);
    if (idx >= 0) {
      return path.slice(idx + marker.length).replace(/^\/+/, "");
    }
    const parts = path.split("/").filter(Boolean);
    if (parts.length === 0) return "";
    return parts.slice(-2).join("/");
  }
};

const buildCloudflareDownloadUrl = (value: string): string => {
  if (!value) return "";
  if (
    value.startsWith("data:") ||
    value.startsWith("blob:") ||
    value.startsWith("/")
  ) {
    return value;
  }

  if (value.startsWith("http")) {
    try {
      const parsed = new URL(value);
      const marker = "/cloudflares/download/";
      const idx = parsed.pathname.indexOf(marker);
      if (idx === -1) return value;
      const rawKey = decodeURIComponent(
        parsed.pathname.slice(idx + marker.length)
      );
      const encodedKey = encodeURIComponent(rawKey);
      parsed.pathname = `${parsed.pathname.slice(
        0,
        idx + marker.length
      )}${encodedKey}`;
      return parsed.toString();
    } catch {
      return value;
    }
  }

  if (!IMAGE_EXT_REGEX.test(value) && !ANIMATION_EXT_REGEX.test(value)) {
    return value;
  }

  const apiBase = (process.env.REACT_APP_BACKEND_AI_TUTOR || "").replace(
    /\/+$/,
    ""
  );
  const downloadBase = apiBase
    ? `${apiBase}/api/v1/cloudflares/download/`
    : "/api/v1/cloudflares/download/";

  return `${downloadBase}${encodeURIComponent(value)}`;
};

interface CloudflareAssetPreviewProps {
  src?: string;
  alt?: string;
  className?: string;
  style?: React.CSSProperties;
  fallbackSrc?: string;
  errorText?: string;
}

const CloudflareAssetPreview: React.FC<CloudflareAssetPreviewProps> = ({
  src,
  alt = "",
  className,
  style,
  fallbackSrc,
  errorText = "Cannot preview this animation",
}) => {
  const rawSrc = useMemo(() => src || fallbackSrc || "", [src, fallbackSrc]);
  const displaySrc = useMemo(
    () => buildCloudflareDownloadUrl(rawSrc),
    [rawSrc]
  );
  const isAnimation = ANIMATION_EXT_REGEX.test(rawSrc);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const animationRef = useRef<AnimationItem | null>(null);
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    if (!isAnimation || !rawSrc || !containerRef.current) {
      animationRef.current?.destroy();
      animationRef.current = null;
      setHasError(false);
      return;
    }

    let cancelled = false;

    const loadAnimation = async () => {
      setHasError(false);
      animationRef.current?.destroy();
      animationRef.current = null;

      const attachAnimation = (animationData: any) => {
        if (cancelled || !containerRef.current) return;
        animationRef.current = lottie.loadAnimation({
          container: containerRef.current,
          renderer: "svg",
          loop: true,
          autoplay: true,
          animationData,
        });
        const onDataFailed = () => setHasError(true);
        animationRef.current?.addEventListener("data_failed", onDataFailed);
        animationRef.current?.addEventListener("error", onDataFailed);
      };

      try {
        let data: any = null;
        const key = extractKeyFromUrl(rawSrc);

        if (rawSrc.startsWith("http")) {
          try {
            const res = await fetch(displaySrc, { mode: "cors" });
            if (res.ok) {
              data = await res.json();
            }
          } catch {
            // Ignore fetch errors; fallback to proxy.
          }
        }

        if (!data && key) {
          try {
            console.log(12343123223);
            const proxied = await cloudflareService.download(key);
            data = normalizeAnimationData(proxied);
          } catch (proxyErr) {
            console.error("Animation proxy error:", proxyErr);
          }
        }

        if (!data) {
          throw new Error("Cannot load animation data");
        }

        attachAnimation(data);
      } catch (err) {
        console.error("Animation preview error:", err);
        if (!cancelled) setHasError(true);
      }
    };

    loadAnimation();

    return () => {
      cancelled = true;
      animationRef.current?.destroy();
      animationRef.current = null;
    };
  }, [displaySrc, isAnimation, rawSrc]);

  if (!rawSrc) return null;

  if (!isAnimation) {
    return (
      <img src={displaySrc} alt={alt} className={className} style={style} />
    );
  }

  return (
    <div
      className={className}
      style={{ position: "relative", ...(style || {}) }}
    >
      <div ref={containerRef} className="w-full h-full" />
      {hasError && (
        <div
          className="absolute inset-0 flex items-center justify-center text-xs text-red-600 bg-white/80 px-2 text-center"
          aria-label={errorText}
        >
          {errorText}
        </div>
      )}
    </div>
  );
};

export default CloudflareAssetPreview;
