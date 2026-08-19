import { PaywallConfig } from "../types/interface/paywall-config.interface";
import axiosClient from "./axiosClient";

// MySQL is now the source of truth for `paywall_config` -- there is no
// `environment` query param anymore. Each deployment's API only ever reads
// and writes its own database, so "dev" vs "prod" is the deployment itself,
// not something this client can (or needs to) switch between.
export const paywallConfigService = {
  async getConfig() {
    const res = await axiosClient.get("/paywall-config");
    return res.data;
  },

  async updateConfig(payload: PaywallConfig) {
    const res = await axiosClient.put("/paywall-config", payload);
    return res.data;
  },

  /** Full version history, newest first, for the version-history panel. */
  async getVersions() {
    const res = await axiosClient.get("/paywall-config/versions");
    return res.data;
  },

  /** Re-validates and republishes an earlier version as a new, later one. */
  async restoreVersion(version: number) {
    const res = await axiosClient.post(`/paywall-config/restore/${version}`);
    return res.data;
  },

  /**
   * Read-only order stats for one LogicSale, keyed by its stable attribution
   * id. On demand only (a refresh button on the row) — never fetched for the
   * whole `logicSales` list at once.
   */
  async getLogicSaleStats(id: string) {
    const res = await axiosClient.get(`/paywall-config/logic-sales/${id}/stats`);
    return res.data;
  },

  /**
   * Kết quả A/B thân paywall của đợt đang cấu hình: phễu đếm theo NGƯỜI từ
   * event của app, đơn + doanh thu từ purchase đã verify. Cửa sổ mặc định 30
   * ngày gần nhất, appEnv mặc định `prod` (do server quyết).
   */
  async getBodyExperimentStats(params?: {
    appEnv?: string;
    from?: string;
    to?: string;
  }) {
    const res = await axiosClient.get("/paywall-config/experiment/stats", {
      params,
    });
    return res.data;
  },
};
