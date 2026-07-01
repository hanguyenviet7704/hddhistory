import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Divider,
  LinearProgress,
  Paper,
  Snackbar,
  Typography,
} from "@mui/material";
import {
  ArrowPathIcon,
  PhotoIcon,
} from "@heroicons/react/24/outline";
import {
  thumbnailService,
  ThumbnailBackfillStatus,
} from "../../services/thumbnailService";

const POLL_INTERVAL_MS = 2000;

const formatDateTime = (value: string | null) => {
  if (!value) return "-";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "-";
  return d.toLocaleString("vi-VN", { hour12: false });
};

const progressPercent = (status: ThumbnailBackfillStatus): number => {
  if (!status.total || status.total === 0) return 0;
  return Math.min(100, Math.round((status.processed / status.total) * 100));
};

export default function ThumbnailsPage() {
  const [status, setStatus] = useState<ThumbnailBackfillStatus | null>(null);
  const [statusLoading, setStatusLoading] = useState(true);
  const [statusError, setStatusError] = useState<string | null>(null);

  const [starting, setStarting] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);

  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: "success" | "error" | "info";
  }>({ open: false, message: "", severity: "info" });

  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const stopPolling = useCallback(() => {
    if (pollRef.current !== null) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
  }, []);

  const fetchStatus = useCallback(async () => {
    try {
      const data = await thumbnailService.getBackfillStatus();
      setStatus(data);
      setStatusError(null);
      if (!data.running) {
        stopPolling();
      }
    } catch (err: any) {
      const msg =
        err?.response?.data?.message ??
        "Failed to fetch thumbnail job status.";
      setStatusError(msg);
      stopPolling();
    } finally {
      setStatusLoading(false);
    }
  }, [stopPolling]);

  const startPolling = useCallback(() => {
    stopPolling();
    pollRef.current = setInterval(() => {
      fetchStatus();
    }, POLL_INTERVAL_MS);
  }, [fetchStatus, stopPolling]);

  // Initial status fetch on mount
  useEffect(() => {
    fetchStatus();
    return () => stopPolling();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Start polling whenever status transitions to running
  useEffect(() => {
    if (status?.running && pollRef.current === null) {
      startPolling();
    }
  }, [status?.running, startPolling]);

  const handleStart = async (mode: "missing" | "all") => {
    setStarting(true);
    try {
      const res = await thumbnailService.startBackfill(mode);
      if (res.alreadyRunning) {
        setSnackbar({
          open: true,
          message:
            "A thumbnail job is already running. Monitoring the current job.",
          severity: "info",
        });
      } else {
        setSnackbar({
          open: true,
          message:
            mode === "missing"
              ? "Started generating missing thumbnails."
              : "Started regenerating all thumbnails.",
          severity: "success",
        });
      }
      // Immediately fetch status and begin polling
      setStatusLoading(true);
      await fetchStatus();
      startPolling();
    } catch (err: any) {
      const msg =
        err?.response?.data?.message ?? "Failed to start thumbnail job.";
      setSnackbar({ open: true, message: msg, severity: "error" });
    } finally {
      setStarting(false);
    }
  };

  const handleMissingClick = () => {
    handleStart("missing");
  };

  const handleRegenerateAllClick = () => {
    setConfirmOpen(true);
  };

  const handleConfirmRegenerateAll = () => {
    setConfirmOpen(false);
    handleStart("all");
  };

  const isJobRunning = status?.running === true;
  const buttonsDisabled = starting || isJobRunning;

  const pct = status ? progressPercent(status) : 0;

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Page header */}
        <div className="flex items-center gap-3">
          <PhotoIcon className="h-7 w-7 text-gray-600" />
          <Typography variant="h5" component="h1" className="font-bold">
            Thumbnail Management
          </Typography>
        </div>
        <Typography variant="body2" color="text.secondary">
          Run a background job to generate or regenerate image thumbnails stored
          in Cloudflare R2. Each job runs server-side; you can close this page
          while it runs and come back to check progress.
        </Typography>

        <Divider />

        {/* Action buttons */}
        <Paper className="p-6" elevation={2}>
          <Typography variant="subtitle1" className="font-semibold mb-4">
            Start a job
          </Typography>

          <div className="flex flex-col sm:flex-row gap-3">
            <Button
              variant="contained"
              color="primary"
              startIcon={
                starting && !confirmOpen ? (
                  <CircularProgress size={16} color="inherit" />
                ) : (
                  <ArrowPathIcon className="h-4 w-4" />
                )
              }
              disabled={buttonsDisabled}
              onClick={handleMissingClick}
              aria-label="Generate missing thumbnails — only creates thumbnails that do not yet exist"
              sx={{ minWidth: 220 }}
            >
              Generate missing thumbnails
            </Button>

            <Button
              variant="outlined"
              color="warning"
              startIcon={
                starting && confirmOpen ? (
                  <CircularProgress size={16} color="inherit" />
                ) : (
                  <ArrowPathIcon className="h-4 w-4" />
                )
              }
              disabled={buttonsDisabled}
              onClick={handleRegenerateAllClick}
              aria-label="Regenerate ALL thumbnails — overwrites every existing thumbnail"
              sx={{ minWidth: 220 }}
            >
              Regenerate ALL thumbnails
            </Button>
          </div>

          {isJobRunning && (
            <Typography
              variant="caption"
              color="text.secondary"
              className="mt-3 block"
            >
              Both buttons are disabled while a job is running.
            </Typography>
          )}
        </Paper>

        {/* Status panel */}
        <Paper className="p-6" elevation={2}>
          <div className="flex items-center justify-between mb-4">
            <Typography variant="subtitle1" className="font-semibold">
              Job status
            </Typography>
            <Button
              size="small"
              variant="outlined"
              startIcon={
                statusLoading ? (
                  <CircularProgress size={14} />
                ) : (
                  <ArrowPathIcon className="h-4 w-4" />
                )
              }
              onClick={() => {
                setStatusLoading(true);
                fetchStatus();
              }}
              disabled={statusLoading}
              aria-label="Refresh job status"
            >
              Refresh
            </Button>
          </div>

          {statusLoading && status === null ? (
            <Box className="flex flex-col gap-3">
              <LinearProgress />
              <Typography variant="body2" color="text.secondary">
                Loading status...
              </Typography>
            </Box>
          ) : statusError ? (
            <Box>
              <Alert
                severity="error"
                action={
                  <Button
                    size="small"
                    color="inherit"
                    onClick={() => {
                      setStatusLoading(true);
                      fetchStatus();
                    }}
                  >
                    Retry
                  </Button>
                }
              >
                {statusError}
              </Alert>
            </Box>
          ) : status ? (
            <Box className="space-y-4">
              {/* Running indicator */}
              <div className="flex items-center gap-2">
                <span
                  className={`inline-block w-2.5 h-2.5 rounded-full ${
                    status.running ? "bg-green-500 animate-pulse" : "bg-gray-300"
                  }`}
                  aria-hidden="true"
                />
                <Typography variant="body2" className="font-medium">
                  {status.running ? "Running" : "Idle"}
                </Typography>
                {status.mode && (
                  <span className="ml-1 px-2 py-0.5 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">
                    mode: {status.mode}
                  </span>
                )}
              </div>

              {/* Progress bar — only shown when there's a total to measure */}
              {(status.running || status.processed > 0) && status.total > 0 && (
                <Box>
                  <Box className="flex justify-between mb-1">
                    <Typography variant="caption" color="text.secondary">
                      Progress
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {status.processed} / {status.total} ({pct}%)
                    </Typography>
                  </Box>
                  <LinearProgress
                    variant="determinate"
                    value={pct}
                    aria-label={`Thumbnail job progress: ${pct}%`}
                  />
                </Box>
              )}

              {/* Stats grid */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {[
                  { label: "Processed", value: status.processed },
                  { label: "Created", value: status.created },
                  { label: "Skipped", value: status.skipped },
                  { label: "Failed", value: status.failed },
                ].map(({ label, value }) => (
                  <Paper
                    key={label}
                    variant="outlined"
                    className="p-3 text-center"
                  >
                    <Typography variant="h6" component="p" className="font-bold">
                      {value}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {label}
                    </Typography>
                  </Paper>
                ))}
              </div>

              {/* Timestamps */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm text-gray-600">
                <div>
                  <span className="font-medium text-gray-700">Started: </span>
                  {formatDateTime(status.startedAt)}
                </div>
                <div>
                  <span className="font-medium text-gray-700">Finished: </span>
                  {formatDateTime(status.finishedAt)}
                </div>
              </div>

              {/* Last error */}
              {status.lastError && (
                <Alert severity="warning" className="text-sm">
                  <span className="font-medium">Last error: </span>
                  {status.lastError}
                </Alert>
              )}

              {/* No job ever run */}
              {!status.running &&
                status.processed === 0 &&
                !status.startedAt && (
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    className="italic"
                  >
                    No thumbnail job has been run yet. Use the buttons above to
                    start one.
                  </Typography>
                )}
            </Box>
          ) : null}
        </Paper>
      </div>

      {/* Confirm dialog — Regenerate ALL */}
      <Dialog
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        aria-labelledby="confirm-regenerate-all-title"
        aria-describedby="confirm-regenerate-all-description"
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle id="confirm-regenerate-all-title">
          Regenerate ALL thumbnails?
        </DialogTitle>
        <DialogContent>
          <DialogContentText id="confirm-regenerate-all-description">
            This will overwrite every existing thumbnail. The job runs in the
            background and may take a long time depending on the number of files.
            Are you sure you want to continue?
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setConfirmOpen(false)}
            color="inherit"
            aria-label="Cancel regenerate all thumbnails"
          >
            Cancel
          </Button>
          <Button
            onClick={handleConfirmRegenerateAll}
            color="warning"
            variant="contained"
            aria-label="Confirm regenerate all thumbnails"
            autoFocus
          >
            Regenerate all
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={5000}
        onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert
          severity={snackbar.severity}
          onClose={() => setSnackbar((prev) => ({ ...prev, open: false }))}
          sx={{ width: "100%" }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </div>
  );
}
