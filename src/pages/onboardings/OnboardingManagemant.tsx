import {
  Container,
  Paper,
  Typography,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Box,
  CircularProgress,
} from "@mui/material";
import { Edit, Delete, Add, Save, Close } from "@mui/icons-material";
import { ILablel, LangCode } from "../../types/enum/common.enum";
import {
  IOnboardingIntro,
  IOnboarding,
  OnboardingPayload,
} from "../../types/interface/onboarding.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { onboardingService } from "../../services/onboardingService";
import { useCallback, useEffect, useState } from "react";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../../components/files/CloudflareFileUpload";

export interface ITranslation {
  [key: string]: string;
}

const IntroInput: React.FC<{
  item: IOnboardingIntro;
  onChange: (id: number, newIntro: IOnboardingIntro) => void;
  onDelete: (id: number) => void;
  onAdd: (id: number) => void;
  lang: LangCode;
}> = ({ item, onChange, onDelete, onAdd, lang }) => {
  const handleImageChange = useCallback(
    (newUrl: string) => {
      // Gọi onChange với ID của item hiện tại
      onChange(item.id, { ...item, image: newUrl });
    },
    [item.id, onChange]
  );

  return (
    <Box
      sx={{
        display: "flex",
        flexDirection: "column",
        mb: 3,
        p: 2,
        borderRadius: 1,
        bgcolor: "grey.100",
        boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
        transition: "all 0.3s ease",
        "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
      }}
    >
      <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
        <Box sx={{ mr: 2, flex: 1 }}>
          <TextField
            label="Title"
            value={(item.title as ITranslation)[lang] || ""}
            onChange={(e) =>
              onChange(item.id, {
                ...item,
                title: { ...item.title, [lang]: e.target.value },
              })
            }
            fullWidth
            size="small"
            variant="outlined"
          />
        </Box>
        <Box sx={{ display: "flex" }}>
          <IconButton
            onClick={() => onDelete(item.id)}
            color="error"
            size="small"
          >
            <Delete />
          </IconButton>
          <IconButton
            onClick={() => onAdd(item.id)}
            color="primary"
            size="small"
          >
            <Add />
          </IconButton>
        </Box>
      </Box>

      <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
        <Box sx={{ mr: 2 }}>
          <CloudflareFileUpload
            initialUrl={item.image || ""}
            onUrlChange={handleImageChange}
            label="Image URL"
            uploadPayload={{
              prefix: "",
              folder: "onboarding",
            }}
          />
        </Box>
      </Box>

      <Box sx={{ display: "flex", alignItems: "center" }}>
        <Box sx={{ flex: 1 }}>
          <TextField
            label={lang}
            value={(item.content as ITranslation)[lang] || ""}
            onChange={(e) => {
              const newContent = { ...item.content, [lang]: e.target.value };
              onChange(item.id, { ...item, content: newContent });
            }}
            fullWidth
            multiline
            rows={3}
            size="small"
            variant="outlined"
          />
        </Box>
      </Box>
    </Box>
  );
};

const LabelInput: React.FC<{
  item: ILablel;
  onChange: (id: number, newLabel: ILablel) => void;
  onDelete: (id: number) => void;
  onAdd: (id: number) => void;
  lang: LangCode;
  showTitle?: boolean;
}> = ({ item, onChange, onDelete, onAdd, lang, showTitle = false }) => (
  <Box
    sx={{
      display: "flex",
      flexDirection: "column",
      mb: 3,
      p: 2,
      borderRadius: 1,
      bgcolor: "grey.100",
      boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
      transition: "all 0.3s ease",
      "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
    }}
  >
    <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
      <Box sx={{ mr: 2, minWidth: 120 }}>
        <CloudflareFileUpload
          initialUrl={item.icon || ""}
          onUrlChange={(newUrl) => onChange(item.id, { ...item, icon: newUrl })}
          label="Icon"
          uploadPayload={{ prefix: "", folder: "onboarding" }}
        />
      </Box>
      <Box sx={{ display: "flex" }}>
        <IconButton
          onClick={() => onDelete(item.id)}
          color="error"
          size="small"
        >
          <Delete />
        </IconButton>
        <IconButton onClick={() => onAdd(item.id)} color="primary" size="small">
          <Add />
        </IconButton>
      </Box>
    </Box>

    {showTitle && (
      <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
        <Box sx={{ flex: 1 }}>
          <TextField
            label="Title"
            value={(item.title as ITranslation)[lang] || ""}
            onChange={(e) =>
              onChange(item.id, {
                ...item,
                title: { ...item.title, [lang]: e.target.value },
              })
            }
            fullWidth
            size="small"
            variant="outlined"
          />
        </Box>
      </Box>
    )}

    <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
      <Box sx={{ flex: 1 }}>
        <TextField
          label="Label"
          value={(item.label as ITranslation)[lang] || ""}
          onChange={(e) =>
            onChange(item.id, {
              ...item,
              label: { ...item.label, [lang]: e.target.value },
            })
          }
          fullWidth
          size="small"
          variant="outlined"
        />
      </Box>
    </Box>
  </Box>
);

// --- Component Cha: OnboardingManagement ---
const OnboardingManagement: React.FC = () => {
  const lang = useSelector((state: RootState) => state.lang.code);
  const { showSuccess, showError } = useNotification();

  const [onboarding, setOnboarding] = useState<IOnboarding | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<string>("intro");
  const [loading, setLoading] = useState<boolean>(false);

  const [nextIds, setNextIds] = useState({
    intro: 1,
    age: 1,
    gender: 1,
    skillsetWantToMaster: 1,
    seemLikeYou: 1,
    strugglesWhenSpeaking: 1,
    comfortableLearningTime: 1,
    dailyLearningGoal: 1,
    timeToBecomeSkilled: 1,
  });

  const createNewIntro = (): IOnboardingIntro => {
    const newId = nextIds.intro;
    setNextIds((prev) => ({ ...prev, intro: newId + 1 }));
    return {
      id: newId,
      title: { [lang]: "" },
      image: "",
      content: { [lang]: "" },
    };
  };

  const createNewLabel = (field: keyof IOnboarding): ILablel => {
    const newId = nextIds[field as keyof typeof nextIds];
    setNextIds((prev) => ({ ...prev, [field]: newId + 1 }));
    return {
      id: newId,
      icon: "",
      title: { [lang]: "" },
      label: { [lang]: "" },
    };
  };

  const calculateNextIds = (data: IOnboarding) => {
    const fields: (keyof IOnboarding)[] = [
      "intro",
      "age",
      "gender",
      "skillsetWantToMaster",
      "seemLikeYou",
      "strugglesWhenSpeaking",
      "comfortableLearningTime",
      "dailyLearningGoal",
      "timeToBecomeSkilled",
    ];

    const newIds = { ...nextIds };

    fields.forEach((field) => {
      if (Array.isArray(data[field]) && data[field].length > 0) {
        const maxId = Math.max(
          ...(data[field] as any[]).map((item) => item.id)
        );
        newIds[field as keyof typeof newIds] = maxId + 1;
      }
    });

    setNextIds(newIds);
  };

  useEffect(() => {
    const fetchOnboarding = async () => {
      setLoading(true);
      try {
        const res = await onboardingService.getOne();
        setOnboarding(res.data);
        calculateNextIds(res.data);
      } catch (err) {
        showError("Failed to fetch onboarding data");
      } finally {
        setLoading(false);
      }
    };

    fetchOnboarding();
  }, []); // ĐÃ SỬA: Chỉ chạy 1 lần

  const handleEdit = (tab: string): void => {
    setActiveTab(tab);
    setIsDialogOpen(true);
  };

  const handleSave = async (): Promise<void> => {
    if (!onboarding) return;

    setLoading(true);
    try {
      const payload: OnboardingPayload = {
        intro: onboarding.intro.map((intro) => ({
          id: intro.id,
          image: intro.image,
          title: (intro.title as ITranslation)[lang] || "",
          content: (intro.content as ITranslation)[lang] || "",
        })),
        age: onboarding.age.map((l) => ({
          id: l.id,
          icon: l.icon,
          title: (l.title as ITranslation | undefined)?.[lang] ?? "",
          label: (l.label as ITranslation)[lang] || "",
        })),
        gender: onboarding.gender.map((l) => ({
          id: l.id,
          icon: l.icon,
          title: (l.title as ITranslation | undefined)?.[lang] ?? "",
          label: (l.label as ITranslation)[lang] || "",
        })),
        skillsetWantToMaster: onboarding.skillsetWantToMaster.map((l) => ({
          id: l.id,
          icon: l.icon,
          title: (l.title as ITranslation | undefined)?.[lang] ?? "",
          label: (l.label as ITranslation)[lang] || "",
        })),
        seemLikeYou: onboarding.seemLikeYou.map((l) => ({
          id: l.id,
          icon: l.icon,
          title: (l.title as ITranslation | undefined)?.[lang] ?? "",
          label: (l.label as ITranslation)[lang] || "",
        })),
        strugglesWhenSpeaking: onboarding.strugglesWhenSpeaking.map((l) => ({
          id: l.id,
          icon: l.icon,
          title: (l.title as ITranslation | undefined)?.[lang] ?? "",
          label: (l.label as ITranslation)[lang] || "",
        })),
        comfortableLearningTime: onboarding.comfortableLearningTime.map(
          (l) => ({
            id: l.id,
            icon: l.icon,
            title: (l.title as ITranslation | undefined)?.[lang] ?? "",
            label: (l.label as ITranslation)[lang] || "",
          })
        ),
        dailyLearningGoal: onboarding.dailyLearningGoal.map((l) => ({
          id: l.id,
          icon: l.icon,
          title: (l.title as ITranslation | undefined)?.[lang] ?? "",
          label: (l.label as ITranslation)[lang] || "",
        })),
        timeToBecomeSkilled: onboarding.timeToBecomeSkilled.map((l) => ({
          id: l.id,
          icon: l.icon,
          title: (l.title as ITranslation | undefined)?.[lang] ?? "",
          label: (l.label as ITranslation)[lang] || "",
        })),
      };

      await onboardingService.update(onboarding._id, payload);
      setIsDialogOpen(false);
      showSuccess("Saved onboarding successfully");
    } catch (err) {
      console.error("Update error:", err);
      showError("Failed to save onboarding");
    } finally {
      setLoading(false);
    }
  };

  // ĐÃ SỬA: Nhận `id` thay vì `index`
  const handleArrayChange = useCallback(
    (field: keyof IOnboarding, id: number, value: any): void => {
      if (!onboarding) return;
      const currentValue = onboarding[field] as any[];
      // Tìm index bằng id
      const index = currentValue.findIndex((item) => item.id === id);
      if (index === -1) return;

      const newArray = [...currentValue];
      newArray[index] = value;
      setOnboarding({ ...onboarding, [field]: newArray });
    },
    [onboarding]
  );

  const addToArray = (field: keyof IOnboarding): void => {
    if (!onboarding) return;

    if (field === "intro") {
      const newIntro = createNewIntro();
      const newArray = [...(onboarding[field] as IOnboardingIntro[]), newIntro];
      setOnboarding({ ...onboarding, [field]: newArray });
    } else {
      const newLabel = createNewLabel(field);
      const newArray = [...(onboarding[field] as ILablel[]), newLabel];
      setOnboarding({ ...onboarding, [field]: newArray });
    }
  };

  // ĐÃ SỬA: Nhận `id` thay vì `index`
  const addToArrayAtIndex = (field: keyof IOnboarding, id: number): void => {
    if (!onboarding) return;
    const currentValue = onboarding[field] as any[];
    // Tìm index bằng id
    const index = currentValue.findIndex((item) => item.id === id);
    if (index === -1) return;

    if (field === "intro") {
      const newIntro = createNewIntro();
      const newArray = [...currentValue];
      newArray.splice(index + 1, 0, newIntro);
      setOnboarding({ ...onboarding, [field]: newArray });
    } else {
      const newLabel = createNewLabel(field);
      const newArray = [...currentValue];
      newArray.splice(index + 1, 0, newLabel);
      setOnboarding({ ...onboarding, [field]: newArray });
    }
  };

  // ĐÃ SỬA: Nhận `id` thay vì `index`
  const removeFromArray = (field: keyof IOnboarding, id: number): void => {
    if (!onboarding) return;
    const currentValue = onboarding[field] as any[];
    // Tìm index bằng id
    const index = currentValue.findIndex((item) => item.id === id);
    if (index === -1) return;

    const newArray = [...currentValue];
    newArray.splice(index, 1);
    setOnboarding({ ...onboarding, [field]: newArray });
  };

  const renderIntroTab = (): React.ReactNode => (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>
        Introduction Steps
      </Typography>
      <Box sx={{ mt: 2 }}>
        {onboarding?.intro.map((intro) => (
          <IntroInput
            // Nếu ID của bạn không duy nhất, hãy dùng key={`${intro.id}-${index}`
            key={intro.id}
            item={intro}
            onChange={(id, newIntro) =>
              handleArrayChange("intro", id, newIntro)
            }
            onDelete={(id) => removeFromArray("intro", id)}
            onAdd={(id) => addToArrayAtIndex("intro", id)}
            lang={lang}
          />
        ))}
        <Button
          onClick={() => addToArray("intro")}
          variant="outlined"
          startIcon={<Add />}
          sx={{ mt: 1 }}
        >
          Add Intro Step
        </Button>
      </Box>
    </Box>
  );

  const renderDailyGoalTab = (): React.ReactNode => (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>
        Daily Learning Goal
      </Typography>
      <Box sx={{ mt: 2 }}>
        {Array.isArray(onboarding?.dailyLearningGoal) &&
          (onboarding?.dailyLearningGoal as ILablel[]).map((item: ILablel) => (
            <LabelInput
              key={item.id}
              item={item}
              onChange={(id, newLabel) =>
                handleArrayChange("dailyLearningGoal", id, newLabel)
              }
              onDelete={(id) => removeFromArray("dailyLearningGoal", id)}
              onAdd={(id) => addToArrayAtIndex("dailyLearningGoal", id)}
              lang={lang}
            />
          ))}
        <Button
          onClick={() => addToArray("dailyLearningGoal")}
          variant="outlined"
          startIcon={<Add />}
          sx={{ mt: 1 }}
        >
          Add Daily Goal
        </Button>
      </Box>
    </Box>
  );

  const renderTimeframeTab = (): React.ReactNode => (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>
        Time to Become Skilled
      </Typography>
      <Box sx={{ mt: 2 }}>
        {Array.isArray(onboarding?.timeToBecomeSkilled) &&
          (onboarding?.timeToBecomeSkilled as ILablel[]).map(
            (item: ILablel) => (
              <LabelInput
                key={item.id}
                item={item}
                onChange={(id, newLabel) =>
                  handleArrayChange("timeToBecomeSkilled", id, newLabel)
                }
                onDelete={(id) => removeFromArray("timeToBecomeSkilled", id)}
                onAdd={(id) => addToArrayAtIndex("timeToBecomeSkilled", id)}
                lang={lang}
              />
            )
          )}
        <Button
          onClick={() => addToArray("timeToBecomeSkilled")}
          variant="outlined"
          startIcon={<Add />}
          sx={{ mt: 1 }}
        >
          Add Timeframe
        </Button>
      </Box>
    </Box>
  );

  const renderLabelsTab = (
    field: keyof IOnboarding,
    title: string,
    showTitle?: boolean
  ): React.ReactNode => (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>
        {title}
      </Typography>
      <Box sx={{ mt: 2 }}>
        {Array.isArray(onboarding?.[field]) &&
          (onboarding?.[field] as ILablel[]).map((item: ILablel) => (
            <LabelInput
              key={item.id}
              item={item}
              onChange={(id, newLabel) =>
                handleArrayChange(field, id, newLabel)
              }
              onDelete={(id) => removeFromArray(field, id)}
              onAdd={(id) => addToArrayAtIndex(field, id)}
              lang={lang}
              showTitle={showTitle}
            />
          ))}
        <Button
          onClick={() => addToArray(field)}
          variant="outlined"
          startIcon={<Add />}
          sx={{ mt: 1 }}
        >
          Add {title}
        </Button>
      </Box>
    </Box>
  );

  const renderChipWithIcon = (item: ILablel) => {
    if (item.icon && item.icon.startsWith("http")) {
      return (
        <Box
          key={item.id}
          sx={{
            display: "flex",
            alignItems: "center",
            mb: 2,
            p: 1,
            borderRadius: 1,
            bgcolor: "white",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            transition: "all 0.3s ease",
            "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
          }}
        >
          <img
            src={item.icon}
            alt={(item.label as ITranslation)[lang]}
            style={{
              width: 32,
              height: 32,
              objectFit: "contain",
              marginRight: 8,
              display: "block",
            }}
          />
          <Typography variant="body1" sx={{ fontWeight: "medium" }}>
            {(item.label as ITranslation)[lang]}
          </Typography>
        </Box>
      );
    }

    return (
      <Box
        key={item.id}
        sx={{
          display: "flex",
          alignItems: "center",
          mb: 2,
          p: 1,
          borderRadius: 1,
          bgcolor: "white",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          transition: "all 0.3s ease",
          "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
        }}
      >
        <Typography variant="body1" sx={{ mr: 1 }}>
          {item.icon}
        </Typography>
        <Typography variant="body1" sx={{ fontWeight: "medium" }}>
          {(item.label as ITranslation)[lang]}
        </Typography>
      </Box>
    );
  };

  const renderChipWithIconAndTitle = (item: ILablel) => {
    if (item.icon && item.icon.startsWith("http")) {
      return (
        <Box
          key={item.id}
          sx={{
            display: "flex",
            alignItems: "center",
            mb: 2,
            p: 1,
            borderRadius: 1,
            bgcolor: "white",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            transition: "all 0.3s ease",
            "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
          }}
        >
          <img
            src={item.icon}
            alt={(item.label as ITranslation)[lang]}
            style={{
              width: 32,
              height: 32,
              objectFit: "contain",
              marginRight: 8,
              display: "block",
            }}
          />
          {(item.title as ITranslation)[lang] && (
            <Typography variant="body1" sx={{ mr: 1, fontWeight: "medium" }}>
              {(item.title as ITranslation)[lang]}
            </Typography>
          )}
          <Typography variant="body1" sx={{ fontWeight: "medium" }}>
            {(item.label as ITranslation)[lang]}
          </Typography>
        </Box>
      );
    }

    return (
      <Box
        key={item.id}
        sx={{
          display: "flex",
          alignItems: "center",
          mb: 2,
          p: 1,
          borderRadius: 1,
          bgcolor: "white",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          transition: "all 0.3s ease",
          "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
        }}
      >
        <Typography variant="body1" sx={{ mr: 1 }}>
          {item.icon}
        </Typography>
        {(item.title as ITranslation)[lang] && (
          <Typography variant="body1" sx={{ mr: 1, fontWeight: "medium" }}>
            {(item.title as ITranslation)[lang]}
          </Typography>
        )}
        <Typography variant="body1" sx={{ fontWeight: "medium" }}>
          {(item.label as ITranslation)[lang]}
        </Typography>
      </Box>
    );
  };

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Paper
        sx={{
          p: 3,
          boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
          transition: "all 0.3s ease",
          "&:hover": { boxShadow: "0 6px 16px rgba(0,0,0,0.15)" },
        }}
      >
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            mb: 4,
          }}
        >
          <Typography variant="h4" sx={{ fontWeight: "bold" }}>
            Onboarding Management
          </Typography>
        </Box>

        {loading ? (
          <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
            <CircularProgress />
          </Box>
        ) : onboarding ? (
          <Box>
            {/* Intro Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Introduction Steps
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("intro")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 3 }}>
                {onboarding.intro.map((intro) => (
                  <Box
                    key={intro.id}
                    sx={{
                      p: 3,
                      borderRadius: 2,
                      bgcolor: "white",
                      boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                      transition: "all 0.3s ease",
                      "&:hover": { boxShadow: "0 4px 8px rgba(0,0,0,0.15)" },
                    }}
                  >
                    <Box sx={{ display: "flex", gap: 3 }}>
                      <Box sx={{ flex: 1 }}>
                        {intro.image && (
                          <img
                            src={intro.image}
                            alt={(intro.title as ITranslation)[lang]}
                            style={{
                              width: "100%",
                              height: 200,
                              objectFit: "cover",
                              borderRadius: 4,
                            }}
                          />
                        )}
                      </Box>
                      <Box sx={{ flex: 2 }}>
                        <Typography gutterBottom sx={{ fontWeight: "bold" }}>
                          {(intro.title as ITranslation)[lang]}
                        </Typography>
                        <Typography
                          sx={{ lineHeight: 1.6, whiteSpace: "pre-wrap" }}
                        >
                          {(intro.content as ITranslation)[lang]}
                        </Typography>
                      </Box>
                    </Box>
                  </Box>
                ))}
              </Box>
            </Box>

            {/* Age Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Age Options
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("age")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.age.map((item) => renderChipWithIcon(item))}
              </Box>
            </Box>

            {/* Gender Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Gender Options
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("gender")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.gender.map((item) => renderChipWithIcon(item))}
              </Box>
            </Box>

            {/* Topics Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Skillset to Master
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("skillsetWantToMaster")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.skillsetWantToMaster.map((item) =>
                  renderChipWithIconAndTitle(item)
                )}
              </Box>
            </Box>

            {/* Profile Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Seem like You
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("seemLikeYou")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.seemLikeYou.map((item) => renderChipWithIcon(item))}
              </Box>
            </Box>

            {/* Struggles Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Speaking Struggles
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("strugglesWhenSpeaking")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.strugglesWhenSpeaking.map((item) =>
                  renderChipWithIcon(item)
                )}
              </Box>
            </Box>

            {/* Schedule Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Comfortable Learning Time
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("comfortableLearningTime")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.comfortableLearningTime.map((item) =>
                  renderChipWithIcon(item)
                )}
              </Box>
            </Box>

            {/* Goals Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Daily Learning Goals
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("dailyLearningGoal")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.dailyLearningGoal.map((item) =>
                  renderChipWithIcon(item)
                )}
              </Box>
            </Box>

            {/* Timeframe Section */}
            <Box
              sx={{
                mb: 6,
                p: 3,
                borderRadius: 2,
                bgcolor: "grey.50",
                boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                transition: "all 0.3s ease",
                "&:hover": { boxShadow: "0 4px 12px rgba(0,0,0,0.12)" },
              }}
            >
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Typography variant="h5" sx={{ fontWeight: "bold" }}>
                  Time to Become Skilled
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<Edit />}
                  onClick={() => handleEdit("timeToBecomeSkilled")}
                  sx={{
                    transition: "all 0.3s ease",
                    "&:hover": { bgcolor: "primary.main", color: "white" },
                  }}
                >
                  Edit
                </Button>
              </Box>
              <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
                {onboarding.timeToBecomeSkilled.map((item) =>
                  renderChipWithIcon(item)
                )}
              </Box>
            </Box>
          </Box>
        ) : (
          <Typography>No onboarding data found</Typography>
        )}
      </Paper>

      <Dialog
        open={isDialogOpen}
        onClose={() => setIsDialogOpen(false)}
        maxWidth="md"
        fullWidth
        PaperProps={{
          sx: {
            minHeight: "70vh",
            borderRadius: 2,
            boxShadow: "0 8px 24px rgba(0,0,0,0.15)",
          },
        }}
      >
        <DialogTitle>
          <Box
            sx={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <Typography variant="h6" sx={{ fontWeight: "bold" }}>
              {activeTab === "intro" && "Edit Introduction Steps"}
              {activeTab === "age" && "Edit Age Options"}
              {activeTab === "gender" && "Edit Gender Options"}
              {activeTab === "skillsetWantToMaster" &&
                "Edit Skillset to Master"}
              {activeTab === "seemLikeYou" && "Edit Profile Types"}
              {activeTab === "strugglesWhenSpeaking" &&
                "Edit Speaking Struggles"}
              {activeTab === "comfortableLearningTime" && "Edit Learning Times"}
              {activeTab === "dailyLearningGoal" && "Edit Daily Goals"}
              {activeTab === "timeToBecomeSkilled" &&
                "Edit Time to Become Skilled"}
            </Typography>
            <IconButton onClick={() => setIsDialogOpen(false)}>
              <Close />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          {activeTab === "intro" && renderIntroTab()}
          {activeTab === "age" && renderLabelsTab("age", "Age Options")}
          {activeTab === "gender" &&
            renderLabelsTab("gender", "Gender Options")}
          {activeTab === "skillsetWantToMaster" &&
            renderLabelsTab("skillsetWantToMaster", "Skillset to Master", true)}
          {activeTab === "seemLikeYou" &&
            renderLabelsTab("seemLikeYou", "Profile Types")}
          {activeTab === "strugglesWhenSpeaking" &&
            renderLabelsTab("strugglesWhenSpeaking", "Speaking Struggles")}
          {activeTab === "comfortableLearningTime" &&
            renderLabelsTab("comfortableLearningTime", "Learning Times")}
          {activeTab === "dailyLearningGoal" && renderDailyGoalTab()}
          {activeTab === "timeToBecomeSkilled" && renderTimeframeTab()}
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setIsDialogOpen(false)}
            sx={{
              transition: "all 0.3s ease",
              "&:hover": { bgcolor: "grey.200" },
            }}
          >
            Cancel
          </Button>
          <Button
            onClick={handleSave}
            variant="contained"
            startIcon={<Save />}
            disabled={loading}
            sx={{
              transition: "all 0.3s ease",
              "&:hover": { transform: "translateY(-2px)" },
            }}
          >
            {loading ? "Saving..." : "Save"}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default OnboardingManagement;
