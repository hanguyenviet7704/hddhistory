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
        user: { id: string };
      } = res.data?.data;

      localStorage.setItem("accessToken", result.token.accessToken);
      localStorage.setItem("refreshToken", result.token.refreshToken);
      localStorage.setItem("userId", result.user.id);

      navigate("/");
    } catch (err) {
      console.error("Login failed:", err);
      setError("Email hoặc mật khẩu không đúng!");
    }
  };

  return (
    <div className="flex h-screen">
      {/* Left: Blue background with logo + AI-TUTOR */}
      <div className="w-1/2 bg-blue-500 flex flex-col justify-center items-center text-white">
        <img
          src="https://cdn-icons-png.flaticon.com/512/4712/4712109.png"
          alt="AI Tutor Logo"
          className="w-28 h-28 mb-6 drop-shadow-lg"
        />
        <h1 className="text-4xl font-bold">AI-TUTOR</h1>
      </div>

      {/* Right: Login form */}
      <div className="w-1/2 flex justify-center items-center bg-white">
        <form onSubmit={handleSubmit} className="w-96">
          <h2 className="text-2xl font-bold mb-6 text-gray-800 text-center">
            Đăng nhập
          </h2>

          {error && (
            <p className="text-red-500 text-sm mb-4 text-center">{error}</p>
          )}

          {/* Email */}
          <div className="relative mb-4">
            <AccountCircle className="absolute top-3 left-3 text-gray-400" />
            <input
              type="email"
              placeholder="Nhập email..."
              className="w-full pl-10 pr-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-400"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          {/* Password */}
          <div className="relative mb-4">
            <Lock className="absolute top-3 left-3 text-gray-400" />
            <input
              type="password"
              placeholder="Nhập mật khẩu"
              className="w-full pl-10 pr-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-400"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          {/* Forgot password */}
          <div className="flex justify-end mb-4">
            <a href="#" className="text-sm text-blue-600 hover:underline">
              Quên mật khẩu
            </a>
          </div>

          {/* Button */}
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 rounded font-semibold hover:bg-blue-700 transition"
          >
            Đăng nhập
          </button>
        </form>
      </div>
    </div>
  );
}
