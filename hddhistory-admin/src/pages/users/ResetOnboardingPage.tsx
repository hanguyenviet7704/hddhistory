import { useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  TextField,
  Typography,
} from "@mui/material";
import { BugAntIcon } from "@heroicons/react/24/outline";
import { userService } from "../../services/userService";
import { IResetOnboardingResult } from "../../types/interface/user.interface";
import { useNotification } from "../../utils/hooks/useNotification";

// Internal QA utility: reset a user's onboarding flag so a tester can go
// through the onboarding flow again without needing a fresh account.
export default function ResetOnboardingPage() {
  const { showError } = useNotification();

  const [identifier, setIdentifier] = useState("");
  const [touched, setTouched] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<IResetOnboardingResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const trimmed = identifier.trim();
  const inputError = touched && !trimmed ? "Enter an email or user ID" : null;

  const openConfirm = () => {
    setTouched(true);
    if (!trimmed) return;
    setError(null);
    setResult(null);
    setConfirmOpen(true);
  };

  const handleConfirm = async () => {
    setSubmitting(true);
    setError(null);
    try {
      const payload = trimmed.includes("@")
        ? { email: trimmed }
        : { userId: trimmed };
      const data = await userService.resetOnboarding(payload);
      setResult(data);
      setConfirmOpen(false);
    } catch (err: any) {
      const message =
        err?.response?.data?.message ??
        "Failed to reset onboarding — check the email/user ID and try again";
      setError(message);
      showError(message);
      setConfirmOpen(false);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Box className="p-6 flex justify-center">
      <Box className="w-full max-w-lg">
        <Box className="mb-4 flex items-center gap-2">
          <BugAntIcon className="h-6 w-6 text-gray-500" />
          <Typography variant="h5">Reset Onboarding</Typography>
        </Box>
        <Typography variant="body2" color="text.secondary" className="mb-6">
          QA tool — reset a user's onboarding state so they can re-test the
          onboarding flow from scratch.
        </Typography>

        <Card>
          <CardContent className="p-6">
            <TextField
              fullWidth
              label="Email or User ID"
              placeholder="tester@example.com or 64f1c2..."
              value={identifier}
              onChange={(e) => {
                setIdentifier(e.target.value);
                if (error) setError(null);
              }}
              onBlur={() => setTouched(true)}
              error={!!inputError}
              helperText={
                inputError ??
                "Enter the tester's email (contains @) or Mongo user ID."
              }
              size="small"
              className="mb-4"
            />

            <Button
              variant="contained"
              color="warning"
              onClick={openConfirm}
              disabled={submitting}
              startIcon={
                submitting ? (
                  <CircularProgress size={18} color="inherit" />
                ) : undefined
              }
            >
              {submitting ? "Resetting..." : "Reset onboarding"}
            </Button>

            {error && (
              <Alert severity="error" className="mt-4">
                {error}
              </Alert>
            )}

            {result && (
              <Alert severity="success" className="mt-4">
                <Typography variant="body2" className="font-medium">
                  Onboarding reset for {result.name || result.email} (
                  {result.email}, id: {result.id}).
                </Typography>
                <Typography variant="body2" className="mt-1">
                  Ask the tester to log out & back in — or reinstall — so the
                  app re-fetches the reset state.
                </Typography>
              </Alert>
            )}
          </CardContent>
        </Card>
      </Box>

      <Dialog
        open={confirmOpen}
        onClose={() => !submitting && setConfirmOpen(false)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>Reset onboarding</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Reset onboarding for <strong>{trimmed}</strong>? They'll see the
            onboarding flow again on next login.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={() => setConfirmOpen(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button
            onClick={handleConfirm}
            color="warning"
            variant="contained"
            disabled={submitting}
            startIcon={
              submitting ? (
                <CircularProgress size={16} color="inherit" />
              ) : undefined
            }
          >
            Reset
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
