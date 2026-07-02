import React, { useCallback, useRef, useState } from "react";
import {
  Alert,
  Button,
  Chip,
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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import {
  ArrowsPointingInIcon,
  MagnifyingGlassIcon,
  PhotoIcon,
  StopIcon,
} from "@heroicons/react/24/outline";
import {
  CompressImageResult,
  imageCompressionService,
} from "../../services/imageCompressionService";

const MAX_LOG_ROWS = 300;

interface Aggregate {
  scanned: number;
  candidates: number;
  compressed: number;
  skipped: number;
  errors: number;
  bytesBefore: number;
  bytesAfter: number;
}

const EMPTY_AGGREGATE: Aggregate = {
  scanned: 0,
  candidates: 0,
  compressed: 0,
  skipped: 0,
  errors: 0,
  bytesBefore: 0,
  bytesAfter: 0,
};

const formatBytes = (bytes: number): string => {
  if (!bytes) return "0 B";
  const units = ["B", "KB", "MB", "GB"];
  const i = Math.min(
    units.length - 1,
    Math.floor(Math.log(Math.abs(bytes)) / Math.log(1024))
  );
  return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${units[i]}`;
};

const actionLabel: Record<CompressImageResult["action"], string> = {
  compressed: "Compressed",
  "skipped-not-smaller": "Skipped (not smaller)",
  "skipped-type": "Skipped (type)",
  "skipped-small": "Skipped (too small)",
  error: "Error",
};

export default function ImageCompressionPage() {
  const [prefix, setPrefix] = useState("images/");
  const [maxEdge, setMaxEdge] = useState(1080);
  const [quality, setQuality] = useState(80);
  const [minKb, setMinKb] = useState(20);
  const [backupPrefix, setBackupPrefix] = useState("originals-backup");

  const [running, setRunning] = useState(false);
  const [lastRunApply, setLastRunApply] = useState<boolean | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);

  const [aggregate, setAggregate] = useState<Aggregate>(EMPTY_AGGREGATE);
  const [log, setLog] = useState<CompressImageResult[]>([]);
  const [totalLogged, setTotalLogged] = useState(0);

  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: "success" | "error" | "info";
  }>({ open: false, message: "", severity: "info" });

  const stopRef = useRef(false);

  const runJob = useCallback(
    async (apply: boolean) => {
      stopRef.current = false;
      setRunning(true);
      setLastRunApply(apply);
      setAggregate(EMPTY_AGGREGATE);
      setLog([]);
      setTotalLogged(0);

      let token: string | undefined;
      let stoppedEarly = false;

      try {
        // eslint-disable-next-line no-constant-condition
        while (true) {
          if (stopRef.current) {
            stoppedEarly = true;
            break;
          }

          const report = await imageCompressionService.compressBatch({
            prefix: prefix.trim() || undefined,
            apply,
            maxEdge,
            quality,
            minBytes: Math.max(0, minKb) * 1024,
            batchSize: 100,
            continuationToken: token,
            backupPrefix: backupPrefix.trim() || undefined,
          });

          setAggregate((prev) => ({
            scanned: prev.scanned + report.scanned,
            candidates: prev.candidates + report.candidates,
            compressed: prev.compressed + report.compressed,
            skipped: prev.skipped + report.skipped,
            errors: prev.errors + report.errors,
            bytesBefore: prev.bytesBefore + report.bytesBefore,
            bytesAfter: prev.bytesAfter + report.bytesAfter,
          }));

          const notable = report.results.filter(
            (r) => r.action !== "skipped-type"
          );
          setTotalLogged((prev) => prev + notable.length);
          setLog((prev) => [...notable, ...prev].slice(0, MAX_LOG_ROWS));

          token = report.nextContinuationToken;
          if (!report.isTruncated || !token) break;
        }
      } catch (err: any) {
        const msg =
          err?.response?.data?.message ?? "Image compression batch failed.";
        setSnackbar({ open: true, message: msg, severity: "error" });
        setRunning(false);
        return;
      }

      setRunning(false);
      setSnackbar({
        open: true,
        message: stoppedEarly
          ? "Stopped."
          : apply
          ? "Compression finished and applied."
          : "Preview finished — no files were modified.",
        severity: stoppedEarly ? "info" : "success",
      });
    },
    [prefix, maxEdge, quality, minKb, backupPrefix]
  );

  const handlePreview = () => runJob(false);
  const handleApplyClick = () => setConfirmOpen(true);
  const handleConfirmApply = () => {
    setConfirmOpen(false);
    runJob(true);
  };
  const handleStop = () => {
    stopRef.current = true;
  };

  const bytesSaved = aggregate.bytesBefore - aggregate.bytesAfter;
  const savedPercent =
    aggregate.bytesBefore > 0
      ? Math.round((bytesSaved / aggregate.bytesBefore) * 100)
      : 0;
  const hasRun = lastRunApply !== null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-3">
          <PhotoIcon className="h-7 w-7 text-gray-600" />
          <Typography variant="h5" component="h1" className="font-bold">
            Compress Images
          </Typography>
        </div>
        <Typography variant="body2" color="text.secondary">
          Re-encodes existing images in Cloudflare R2 as WebP (only when
          smaller) and downscales anything larger than the max edge. The
          original key/URL is kept — no other content needs to change. Before
          any overwrite, the original is copied once to the backup prefix
          below, so it can be restored if needed.
        </Typography>

        <Divider />

        <Paper className="p-6" elevation={2}>
          <Typography variant="subtitle1" className="font-semibold mb-4">
            Settings
          </Typography>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
            <TextField
              label="Prefix"
              size="small"
              value={prefix}
              onChange={(e) => setPrefix(e.target.value)}
              disabled={running}
              helperText="Only objects under this key prefix"
            />
            <TextField
              label="Max edge (px)"
              size="small"
              type="number"
              value={maxEdge}
              onChange={(e) => setMaxEdge(Number(e.target.value) || 0)}
              disabled={running}
            />
            <TextField
              label="WebP quality"
              size="small"
              type="number"
              value={quality}
              onChange={(e) => setQuality(Number(e.target.value) || 0)}
              disabled={running}
            />
            <TextField
              label="Skip files smaller than (KB)"
              size="small"
              type="number"
              value={minKb}
              onChange={(e) => setMinKb(Number(e.target.value) || 0)}
              disabled={running}
            />
            <TextField
              label="Backup prefix"
              size="small"
              value={backupPrefix}
              onChange={(e) => setBackupPrefix(e.target.value)}
              disabled={running}
              helperText="Originals are copied here before overwrite"
            />
          </div>

          <div className="flex flex-col sm:flex-row gap-3 mt-6">
            <Button
              variant="outlined"
              startIcon={
                running && lastRunApply === false ? (
                  <CircularProgress size={16} color="inherit" />
                ) : (
                  <MagnifyingGlassIcon className="h-4 w-4" />
                )
              }
              disabled={running}
              onClick={handlePreview}
              sx={{ minWidth: 220 }}
            >
              Preview (dry-run)
            </Button>

            <Button
              variant="contained"
              color="warning"
              startIcon={
                running && lastRunApply === true ? (
                  <CircularProgress size={16} color="inherit" />
                ) : (
                  <ArrowsPointingInIcon className="h-4 w-4" />
                )
              }
              disabled={running}
              onClick={handleApplyClick}
              sx={{ minWidth: 220 }}
            >
              Compress &amp; Apply
            </Button>

            {running && (
              <Button
                variant="text"
                color="inherit"
                startIcon={<StopIcon className="h-4 w-4" />}
                onClick={handleStop}
              >
                Stop
              </Button>
            )}
          </div>
        </Paper>

        {(running || hasRun) && (
          <Paper className="p-6" elevation={2}>
            <div className="flex items-center justify-between mb-4">
              <Typography variant="subtitle1" className="font-semibold">
                {lastRunApply ? "Apply run" : "Preview run"}
              </Typography>
              {running && (
                <Chip
                  size="small"
                  color="primary"
                  label="Running…"
                  className="animate-pulse"
                />
              )}
            </div>

            {running && <LinearProgress className="mb-4" />}

            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-4">
              {[
                { label: "Scanned", value: aggregate.scanned },
                { label: "Candidates", value: aggregate.candidates },
                { label: "Compressed", value: aggregate.compressed },
                { label: "Skipped", value: aggregate.skipped },
                { label: "Errors", value: aggregate.errors },
              ].map(({ label, value }) => (
                <Paper key={label} variant="outlined" className="p-3 text-center">
                  <Typography variant="h6" component="p" className="font-bold">
                    {value}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {label}
                  </Typography>
                </Paper>
              ))}
            </div>

            <Alert severity={lastRunApply ? "warning" : "info"} className="mb-2">
              {formatBytes(aggregate.bytesBefore)} →{" "}
              {formatBytes(aggregate.bytesAfter)} ({savedPercent}% saved
              {lastRunApply ? "" : " if applied"}).{" "}
              {lastRunApply
                ? "Cloudflare's CDN may keep serving cached originals until their cache TTL expires — purge the cache to see the new sizes immediately."
                : "Nothing was modified — re-run with Compress & Apply to write changes."}
            </Alert>

            <TableContainer sx={{ maxHeight: 420, mt: 2 }}>
              <Table size="small" stickyHeader>
                <TableHead>
                  <TableRow>
                    <TableCell>Key</TableCell>
                    <TableCell>Action</TableCell>
                    <TableCell align="right">Before</TableCell>
                    <TableCell align="right">After</TableCell>
                    <TableCell align="right">Saved</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {log.map((r, idx) => (
                    <TableRow key={`${r.key}-${idx}`} hover>
                      <TableCell sx={{ fontFamily: "monospace", fontSize: 12 }}>
                        <div>{r.key}</div>
                        {r.action === "error" && r.error && (
                          <Typography
                            variant="caption"
                            color="error"
                            sx={{ display: "block", fontFamily: "inherit" }}
                          >
                            {r.error}
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell>
                        <Chip
                          size="small"
                          label={actionLabel[r.action]}
                          color={
                            r.action === "compressed"
                              ? "success"
                              : r.action === "error"
                              ? "error"
                              : "default"
                          }
                        />
                      </TableCell>
                      <TableCell align="right">
                        {formatBytes(r.originalBytes)}
                      </TableCell>
                      <TableCell align="right">
                        {r.newBytes !== undefined
                          ? formatBytes(r.newBytes)
                          : "-"}
                      </TableCell>
                      <TableCell align="right">
                        {r.savedBytes > 0 ? formatBytes(r.savedBytes) : "-"}
                      </TableCell>
                    </TableRow>
                  ))}
                  {log.length === 0 && !running && (
                    <TableRow>
                      <TableCell colSpan={5}>
                        <Typography
                          variant="body2"
                          color="text.secondary"
                          className="italic py-4 text-center"
                        >
                          No candidate images found under this prefix.
                        </Typography>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
            {totalLogged > MAX_LOG_ROWS && (
              <Typography
                variant="caption"
                color="text.secondary"
                className="block mt-2"
              >
                Showing the latest {MAX_LOG_ROWS} of {totalLogged} logged rows.
                Aggregate stats above cover every file processed.
              </Typography>
            )}
          </Paper>
        )}
      </div>

      <Dialog
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>Overwrite originals with compressed WebP?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            This copies every original under <code>{prefix || "(root)"}</code>{" "}
            to <code>{backupPrefix || "(none)"}</code> once, then overwrites
            files that get smaller. Run a preview first if you haven't. Are you
            sure you want to continue?
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmOpen(false)} color="inherit">
            Cancel
          </Button>
          <Button
            onClick={handleConfirmApply}
            color="warning"
            variant="contained"
            autoFocus
          >
            Compress &amp; Apply
          </Button>
        </DialogActions>
      </Dialog>

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
