import { useState } from "react";
import { authService } from "../../services/authService";
import { useNavigate } from "react-router-dom";
import { AccountCircle, Lock } from "@mui/icons-material";
import { getClientInfo } from "../../utils/device";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    const device = getClientInfo();

    try {
      const res = await authService.login({
        email,
        password,
        device: {
          deviceId: device.userAgent,
          deviceName: device.platform,
        },
      });

      const result: {
        token: { accessToken: string; refreshToken: string };
        user: { _id: string };
      } = res.data?.data;

      // const FcmToken = await getFcmToken();

      // if (FcmToken) {
      //   await authService.subscribeTopic({
      //     token: FcmToken,
      //     topic: result.user.id,
      //   });
      // }

      localStorage.setItem("accessToken", result.token.accessToken);
      localStorage.setItem("refreshToken", result.token.refreshToken);
      localStorage.setItem("userId", result.user._id);

      navigate("/");
    } catch (err) {
      console.error("Login failed:", err);
      setError("Email hoặc mật khẩu không đúng!");
    }
  };

  return (
    <div className="flex h-screen font-display">
      {/* Left: brand panel — the Đông Sơn drum on bronze */}
      <div className="relative hidden md:flex w-1/2 flex-col justify-center items-center overflow-hidden bg-gradient-to-br from-brand-950 via-brand-900 to-brand-800 px-10 text-white">
        <div
          aria-hidden
          className="pointer-events-none absolute -right-40 -bottom-40 h-[34rem] w-[34rem] rounded-full border border-brand-500/20"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute -left-24 -top-24 h-80 w-80 rounded-full bg-brand-500/10 blur-3xl"
        />
        <img
          src="/logo-trong-dong.svg"
          alt=""
          className="relative w-40 h-40 mb-8 drop-shadow-[0_8px_24px_rgba(0,0,0,0.35)]"
        />
        <h1 className="relative text-4xl font-bold tracking-tight">HDDhistory</h1>
        <p className="relative mt-3 max-w-sm text-center text-brand-100/90">
          Học lịch sử Việt Nam qua đồ thị tri thức
        </p>
        <p className="relative mt-8 text-xs font-semibold uppercase tracking-[0.2em] text-brand-300/80">
          Trang quản trị nội dung
        </p>
      </div>

      {/* Right: Login form */}
      <div className="w-full md:w-1/2 flex justify-center items-center bg-stone-50 px-6">
        <form
          onSubmit={handleSubmit}
          className="w-full max-w-sm rounded-2xl border border-stone-200 bg-white p-8 shadow-sm"
        >
          <img
            src="/logo-trong-dong.svg"
            alt="HDDhistory"
            className="mx-auto mb-4 h-14 w-14 md:hidden"
          />
          <h2 className="text-2xl font-bold text-stone-900 text-center">
            Đăng nhập
          </h2>
          <p className="mt-1 mb-6 text-sm text-stone-500 text-center">
            Dùng tài khoản quản trị để tiếp tục
          </p>

          {error && (
            <p
              role="alert"
              className="mb-4 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 text-center"
            >
              {error}
            </p>
          )}

          {/* Email */}
          <label className="mb-1 block text-sm font-medium text-stone-700" htmlFor="login-email">
            Email
          </label>
          <div className="relative mb-4">
            <AccountCircle className="absolute top-2.5 left-3 text-stone-400" />
            <input
              id="login-email"
              type="email"
              autoComplete="username"
              placeholder="ban@vi-du.com"
              className="w-full rounded-lg border border-stone-300 pl-10 pr-3 py-2.5 focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-200"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          {/* Password */}
          <label className="mb-1 block text-sm font-medium text-stone-700" htmlFor="login-password">
            Mật khẩu
          </label>
          <div className="relative mb-3">
            <Lock className="absolute top-2.5 left-3 text-stone-400" />
            <input
              id="login-password"
              type="password"
              autoComplete="current-password"
              placeholder="Nhập mật khẩu"
              className="w-full rounded-lg border border-stone-300 pl-10 pr-3 py-2.5 focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-200"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          {/* Forgot password */}
          <div className="flex justify-end mb-6">
            <a href="#" className="text-sm font-medium text-brand-700 hover:underline">
              Quên mật khẩu
            </a>
          </div>

          {/* Button */}
          <button
            type="submit"
            className="w-full rounded-lg bg-brand-600 py-2.5 font-semibold text-white shadow-sm transition hover:bg-brand-700 focus:outline-none focus:ring-2 focus:ring-brand-300 focus:ring-offset-2"
          >
            Đăng nhập
          </button>
        </form>
      </div>
    </div>
  );
}
