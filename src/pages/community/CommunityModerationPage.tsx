import React, { useState } from "react";
import { Button, Tab, Tabs } from "@mui/material";
import { MegaphoneIcon } from "lucide-react";
import { useSearchParams } from "react-router-dom";

import CommunityOfficialPostModal from "../../components/community/CommunityOfficialPostModal";
import ModerationChatTab from "../../components/community/ModerationChatTab";
import ModerationCommentsTab from "../../components/community/ModerationCommentsTab";
import ModerationPostsTab from "../../components/community/ModerationPostsTab";
import ModerationReportsTab from "../../components/community/ModerationReportsTab";
import { communityService } from "../../services/communityService";
import { ICommunityOfficialPostPayload } from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";

type TabKey = "reports" | "posts" | "comments" | "chat";

const CommunityModerationPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  // Tab and post filter live in the URL so the "xem bình luận của bài" jump
  // from the posts tab is a link, and a moderator can keep a queue open in
  // another window.
  const [params, setParams] = useSearchParams();
  const tab = (params.get("tab") as TabKey) || "reports";
  const postId = params.get("postId") ?? undefined;

  const [composeOpen, setComposeOpen] = useState(false);
  const [saving, setSaving] = useState(false);

  const setTab = (next: TabKey) => {
    const nextParams = new URLSearchParams(params);
    nextParams.set("tab", next);
    if (next !== "comments") nextParams.delete("postId");
    setParams(nextParams, { replace: true });
  };

  const clearPostFilter = () => {
    const nextParams = new URLSearchParams(params);
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
        <Tab value="comments" label="Bình luận" />
        <Tab value="chat" label="Chat nhóm" />
      </Tabs>

      {tab === "reports" && <ModerationReportsTab />}
      {tab === "posts" && (
        <ModerationPostsTab
          onViewComments={(postId) => {
            const nextParams = new URLSearchParams(params);
            nextParams.set("tab", "comments");
            nextParams.set("postId", postId);
            setParams(nextParams, { replace: true });
          }}
        />
      )}
      {tab === "comments" && (
        <ModerationCommentsTab
          postId={postId}
          onClearPostFilter={clearPostFilter}
        />
      )}
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
