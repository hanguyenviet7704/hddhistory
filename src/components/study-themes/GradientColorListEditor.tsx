// src/components/study-themes/GradientColorListEditor.tsx
//
// Small repeatable list of hex colour inputs for a "color" mode study theme,
// with a live gradient preview bar. One colour renders as a solid swatch;
// two or more render as a diagonal gradient, matching how the mobile app
// paints the background.
import { Box, IconButton, TextField, Typography, Button } from "@mui/material";
import { PlusIcon, TrashIcon } from "lucide-react";

const HEX_REGEX = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i;

interface Props {
  value: string[];
  onChange: (next: string[]) => void;
  error?: string;
  disabled?: boolean;
}

export default function GradientColorListEditor({
  value,
  onChange,
  error,
  disabled = false,
}: Props) {
  const setAt = (index: number, next: string) => {
    const copy = [...value];
    copy[index] = next;
    onChange(copy);
  };

  const removeAt = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
  };

  const addColor = () => {
    onChange([...value, "#FFFFFF"]);
  };

  const validColors = value.map((c) => c.trim()).filter((c) => HEX_REGEX.test(c));
  const previewBackground =
    validColors.length === 0
      ? undefined
      : validColors.length === 1
      ? validColors[0]
      : `linear-gradient(135deg, ${validColors.join(", ")})`;

  return (
    <Box>
      <Typography variant="body2" sx={{ fontWeight: 500, mb: 1 }}>
        Gradient colours
      </Typography>

      <Box
        sx={{
          height: 40,
          borderRadius: 1,
          border: "1px solid",
          borderColor: "divider",
          mb: 1.5,
          background: previewBackground,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        {!previewBackground && (
          <Typography variant="caption" color="text.secondary">
            Preview appears once you add a valid colour
          </Typography>
        )}
      </Box>

      <Box sx={{ display: "flex", flexDirection: "column", gap: 1 }}>
        {value.map((color, index) => {
          const trimmed = color.trim();
          const isValid = HEX_REGEX.test(trimmed);
          return (
            <Box key={index} sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              <Box
                component="input"
                type="color"
                value={isValid ? trimmed : "#ffffff"}
                onChange={(e) => setAt(index, e.target.value)}
                disabled={disabled}
                aria-label={`Pick colour ${index + 1}`}
                sx={{
                  width: 36,
                  height: 36,
                  padding: 0,
                  border: "1px solid",
                  borderColor: "divider",
                  borderRadius: 1,
                  cursor: disabled ? "default" : "pointer",
                  flexShrink: 0,
                }}
              />
              <TextField
                size="small"
                value={color}
                onChange={(e) => setAt(index, e.target.value)}
                placeholder="#RRGGBB"
                error={trimmed !== "" && !isValid}
                helperText={
                  trimmed !== "" && !isValid ? "Invalid hex colour" : undefined
                }
                disabled={disabled}
                fullWidth
              />
              <IconButton
                aria-label={`Remove colour ${index + 1}`}
                onClick={() => removeAt(index)}
                disabled={disabled}
                size="small"
              >
                <TrashIcon size={16} className="text-red-600" />
              </IconButton>
            </Box>
          );
        })}
      </Box>

      {error && (
        <Typography variant="caption" color="error" sx={{ display: "block", mt: 0.5 }}>
          {error}
        </Typography>
      )}

      <Button
        type="button"
        size="small"
        startIcon={<PlusIcon size={16} />}
        onClick={addColor}
        disabled={disabled}
        sx={{ mt: 1 }}
      >
        Add colour
      </Button>
    </Box>
  );
}
