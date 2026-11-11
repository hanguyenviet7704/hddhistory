import React, { useEffect, useRef, useState } from "react";
import { Button, Skeleton, TextField } from "@mui/material";
import { SaveIcon, UploadIcon, XIcon } from "lucide-react";

import CommunityPageHeader from "../../components/community/CommunityPageHeader";
import { cloudflareService } from "../../services/cloudflareR2Service";
import { communityService } from "../../services/communityService";
import { useNotification } from "../../utils/hooks/useNotification";

/**
 * The team's face in the forum.
 *
 * This existed only in the source until now — `OFFICIAL_AUTHOR_NAME = 'HDDhistory'`,
 * no picture — so changing what readers see on an official post, or giving the
 * team an avatar at all, meant a deploy. It is brand, not code.
 *
 * Both fields are optional, and empty is a real choice rather than a missing
 * value: with no name the app keeps its own localised "Đội ngũ HDDhistory", and with
 * no picture it keeps drawing the violet "M" disc. The preview below shows
 * exactly what a reader will get, because the whole point of the page is that
 * nobody should have to open the app to find out.
 */
const CommunityOfficialProfilePage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [name, setName] = useState("");
  const [avatar, setAvatar] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    let alive = true;
    communityService
      .getOfficialProfile()
      .then((profile) => {
        if (!alive) return;
        setName(profile.name ?? "");
        setAvatar(profile.avatar ?? "");
      })
      .catch((err: any) =>
        showError(err?.response?.data?.message ?? "Không tải được profile")
      )
      .finally(() => alive && setLoading(false));

    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const upload = async (file: File) => {
    setUploading(true);
    try {
      const res = await cloudflareService.upload(file, {
        prefix: "",
        folder: "community-official",
      });
      const url = res?.data?.data?.url;
      if (!url) throw new Error("Không nhận được URL ảnh");
      setAvatar(url);
      showSuccess("Đã tải ảnh lên — bấm Lưu để áp dụng");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Tải ảnh thất bại");
    } finally {
      setUploading(false);
    }
  };

  const save = async () => {
    setSaving(true);
    try {
      await communityService.saveOfficialProfile({
        name: name.trim(),
        avatar: avatar.trim(),
      });
      showSuccess("Đã lưu profile Đội ngũ HDDhistory");
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không lưu được");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-4 p-6">
      <CommunityPageHeader
        title="Đội ngũ HDDhistory"
        subtitle="Tên và ảnh đại diện hiện trên mọi bài, bình luận và tin nhắn do đội ngũ đăng. Để trống thì app tự dùng tên đã dịch sẵn và ảnh chữ M."
      >
        <Button
          variant="contained"
          startIcon={<SaveIcon size={16} />}
          disabled={loading || saving || uploading}
          onClick={save}
        >
          Lưu
        </Button>
      </CommunityPageHeader>

      {loading ? (
        <Skeleton variant="rounded" height={260} />
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          <section className="space-y-4 rounded-[18px] border border-gray-200 bg-white p-5">
            <div>
              <h2 className="text-sm font-semibold text-gray-900">
                Ảnh đại diện
              </h2>
              <p className="mt-0.5 text-xs text-gray-500">
                Ảnh vuông, tối thiểu 256×256. App bo tròn nên đừng để chi tiết
                quan trọng ở góc.
              </p>
            </div>

            <div className="flex items-center gap-4">
              {avatar ? (
                <img
                  src={avatar}
                  alt=""
                  className="h-20 w-20 rounded-full border border-gray-200 object-cover"
                />
              ) : (
                // The disc the app draws when there is no picture, so "empty"
                // looks like what it will actually be.
                <div className="flex h-20 w-20 items-center justify-center rounded-full bg-[#EBEAFD] text-2xl font-bold text-[#4B44CA]">
                  M
                </div>
              )}
              <div className="flex flex-col gap-2">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  hidden
                  onChange={(event) => {
                    const file = event.target.files?.[0];
                    if (file) upload(file);
                    event.target.value = "";
                  }}
                />
                <Button
                  size="small"
                  variant="outlined"
                  startIcon={<UploadIcon size={14} />}
                  disabled={uploading}
                  onClick={() => fileInputRef.current?.click()}
                >
                  {uploading ? "Đang tải..." : "Chọn ảnh"}
                </Button>
                {!!avatar && (
                  <Button
                    size="small"
                    color="inherit"
                    startIcon={<XIcon size={14} />}
                    onClick={() => setAvatar("")}
                  >
                    Bỏ ảnh
                  </Button>
                )}
              </div>
            </div>

            <TextField
              label="URL ảnh"
              size="small"
              fullWidth
              value={avatar}
              onChange={(event) => setAvatar(event.target.value)}
              helperText="Tải ảnh lên là tự điền. Dán URL sẵn có cũng được."
            />

            <TextField
              label="Tên hiện cho người đọc"
              size="small"
              fullWidth
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Để trống = dùng tên app đã dịch"
              helperText='Một tên duy nhất cho cả 5 ngôn ngữ. Để trống thì mỗi ngôn ngữ hiện tên riêng đã dịch ("Đội ngũ HDDhistory" / "HDDhistory Team").'
            />
          </section>

          <section className="rounded-[18px] border border-gray-200 bg-gray-50 p-5">
            <h2 className="text-sm font-semibold text-gray-900">
              Người đọc sẽ thấy
            </h2>
            <p className="mt-0.5 text-xs text-gray-500">
              Đúng cách app vẽ dòng tác giả trên một bài của đội ngũ.
            </p>

            <div className="mt-4 rounded-[18px] border border-gray-200 bg-white p-4">
              <span className="mb-2 inline-block rounded-full bg-[#F4F3FD] px-2.5 py-1 text-[11px] font-bold text-[#7A69E8]">
                Sự nghiệp
              </span>
              <h3 className="mb-2 text-base font-bold leading-[1.3] text-gray-900">
                Nội quy trước khi đăng
              </h3>
              <div className="flex items-center gap-[7px]">
                {avatar ? (
                  <img
                    src={avatar}
                    alt=""
                    className="h-[30px] w-[30px] rounded-full object-cover"
                  />
                ) : (
                  <div className="flex h-[30px] w-[30px] items-center justify-center rounded-full bg-[#EBEAFD] text-xs font-bold text-[#4B44CA]">
                    M
                  </div>
                )}
                <span className="text-[13.5px] font-bold text-[#3A4250]">
                  {name.trim() || "Đội ngũ HDDhistory"}
                </span>
                <span className="text-[11px] font-semibold text-gray-400">
                  · 2 giờ trước
                </span>
                <span className="rounded bg-[#EBEAFD] px-1.5 py-0.5 text-[9px] font-bold tracking-wide text-[#4B44CA]">
                  HDDHISTORY
                </span>
              </div>
              <p className="mt-1 pl-[37px] text-sm leading-[1.55] text-gray-600">
                Không phán xét, không rao bán, và đừng tiết lộ danh tính của
                người khác.
              </p>
            </div>

            <p className="mt-4 text-xs text-gray-500">
              Thay đổi có hiệu lực trong vòng một phút — feed đọc profile này qua
              cache ngắn thay vì hỏi lại ở mỗi trang.
            </p>
          </section>
        </div>
      )}
    </div>
  );
};

export default CommunityOfficialProfilePage;
