import React, { useState } from "react";
import { Button, Tab, Tabs } from "@mui/material";
import { MegaphoneIcon } from "lucide-react";
import { useSearchParams } from "react-router-dom";

import CommunityOfficialPostModal from "../../components/community/CommunityOfficialPostModal";
import ModerationChatTab from "../../components/community/ModerationChatTab";
import ModerationPostsTab from "../../components/community/ModerationPostsTab";
import ModerationReportsTab from "../../components/community/ModerationReportsTab";
import { communityService } from "../../services/communityService";
import { ICommunityOfficialPostPayload } from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";

// No comments tab: a comment is judged inside the thread it belongs to, so it
// opens under its post on the "Bài đăng" tab instead of being a list of its own.
type TabKey = "reports" | "posts" | "chat";

const CommunityModerationPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  // The tab lives in the URL so a moderator can keep a queue open in another
  // window.
  const [params, setParams] = useSearchParams();
  const tab = (params.get("tab") as TabKey) || "reports";

  const [composeOpen, setComposeOpen] = useState(false);
  const [saving, setSaving] = useState(false);

  const setTab = (next: TabKey) => {
    const nextParams = new URLSearchParams(params);
    nextParams.set("tab", next);
    // Left over from the comments tab's per-post filter; dropped so an old
    // bookmark does not carry a parameter nothing reads any more.
    nextParams.delete("postId");
    setParams(nextParams, { replace: true });
  };

  const handleOfficialPost = async (
    payload: ICommunityOfficialPostPayload
  ) => {
    setSaving(true);
    try {
      await communityService.createOfficialPost(payload);
      showSuccess("Đã đăng bài với tư cách Đội ngũ MeUp");
      setComposeOpen(false);
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Đăng bài thất bại");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-6 space-y-4">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Kiểm duyệt cộng đồng</h1>
          <p className="text-sm text-gray-500">
            Hậu kiểm: nội dung hiện ngay khi đăng. Hàng đợi báo cáo là việc cần
            xử lý trước.
          </p>
        </div>
        <Button
          variant="contained"
          startIcon={<MegaphoneIcon size={16} />}
          onClick={() => setComposeOpen(true)}
        >
          Đăng bài Đội ngũ MeUp
        </Button>
      </div>

      <Tabs
        value={tab}
        onChange={(_, next: TabKey) => setTab(next)}
        className="border-b border-gray-200"
      >
        <Tab value="reports" label="Báo cáo" />
        <Tab value="posts" label="Bài đăng" />
        <Tab value="chat" label="Chat nhóm" />
      </Tabs>

      {tab === "reports" && <ModerationReportsTab />}
      {tab === "posts" && <ModerationPostsTab />}
      {tab === "chat" && <ModerationChatTab />}

      <CommunityOfficialPostModal
        open={composeOpen}
        saving={saving}
        onClose={() => setComposeOpen(false)}
        onSubmit={handleOfficialPost}
      />
    </div>
  );
};

export default CommunityModerationPage;
