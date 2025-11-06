import { useState } from "react";
import { useSelector, useDispatch } from "react-redux";
import { RootState } from "../../store";
import { UserCircleIcon, ArrowLeftIcon } from "@heroicons/react/24/solid";
import ReactCountryFlag from "react-country-flag";
import { LangCode } from "../../types/enum/common.enum";
import { LangOption } from "../../utils/interface/lang.interface";
import { authService } from "../../services/authService";
import { getClientInfo } from "../../utils/device";
import { useNavigate } from "react-router-dom";
import { setLang } from "../../store/slices/lang.slice";

const langs: LangOption[] = [
  { code: LangCode.EN, label: "English", countryCode: "GB" },
  { code: LangCode.VI, label: "Tiếng Việt", countryCode: "VN" },
];

export default function Header() {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [langOpen, setLangOpen] = useState(false);

  const dispatch = useDispatch();
  const lang = useSelector((state: RootState) => state.lang.code);
  const device = getClientInfo();

  const handleLogout = async () => {
    try {
      // 1. Gọi API logout
      await authService.logout({
        device: {
          deviceId: device.userAgent,
          deviceName: device.platform,
        },
      });

      // 2. Xoá toàn bộ localStorage
      localStorage.clear();

      // 3. Redirect về trang login
      navigate("/login", { replace: true });
    } catch (error) {
      console.error("Error during logout:", error);
      // Dù lỗi thì vẫn đảm bảo xóa local và redirect
      localStorage.clear();
      navigate("/login", { replace: true });
    }
  };

  const handleProfile = () => {
    setOpen(!open);
  };

  const handleChangeLang = (code: LangCode) => {
    dispatch(setLang(code));
    setLangOpen(false);
  };

  const current = langs.find((l) => l.code === lang) || langs[0];

  const handleBack = () => {
    navigate(-1); // Quay lại trang trước đó
  };

  return (
    <header className="w-full bg-white shadow px-6 py-3 flex items-center relative">
      {/* Left section - Nút quay lại */}
      <div className="flex items-center">
        <button
          onClick={handleBack}
          className="flex items-center justify-center w-10 h-10 rounded-full bg-gray-100 hover:bg-gray-200 hover:shadow transition-all"
        >
          <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
        </button>
      </div>

      {/* Spacer */}
      <div className="flex-1"></div>

      {/* Right section - Các nút cũ */}
      <div className="flex items-center gap-6">
        {/* Language switcher */}
        <div className="relative">
          <button
            onClick={() => setLangOpen(!langOpen)}
            className="flex items-center gap-2 border rounded px-2 py-1 hover:bg-gray-50"
          >
            <ReactCountryFlag
              countryCode={current.countryCode}
              svg
              style={{ width: "1.2em", height: "1.2em" }}
            />
            <span>{current.code.toUpperCase()}</span>
          </button>

          {langOpen && (
            <div className="absolute right-0 mt-2 w-32 bg-white shadow-lg rounded z-10">
              {langs.map((l) => (
                <button
                  key={l.code}
                  onClick={() => handleChangeLang(l.code)}
                  className={`flex items-center gap-2 px-3 py-2 w-full hover:bg-gray-100 ${
                    lang === l.code ? "bg-gray-200 font-medium" : ""
                  }`}
                >
                  <ReactCountryFlag
                    countryCode={l.countryCode}
                    svg
                    style={{ width: "1.2em", height: "1.2em" }}
                  />
                  <span>{l.label}</span>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Profile dropdown */}
        <div className="relative">
          <button
            onClick={() => setOpen(!open)}
            className="flex items-center justify-center w-10 h-10 rounded-full bg-gray-100 hover:shadow"
          >
            <UserCircleIcon className="h-6 w-6 text-gray-600" />
          </button>

          {open && (
            <div className="absolute right-0 mt-2 w-40 bg-white text-gray-700 rounded shadow-lg z-10">
              <button
                onClick={handleProfile}
                className="w-full text-left px-4 py-2 hover:bg-gray-100"
              >
                Profile
              </button>
              <button
                onClick={handleLogout}
                className="w-full text-left px-4 py-2 hover:bg-gray-100"
              >
                Logout
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
