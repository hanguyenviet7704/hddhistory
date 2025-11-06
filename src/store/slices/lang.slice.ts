import { createSlice, PayloadAction } from "@reduxjs/toolkit";
import { LangCode } from "../../types/enum/common.enum";

// Slice gọn nhẹ, chỉ để quản lý lang
const langSlice = createSlice({
  name: "lang",
  initialState: { code: LangCode.EN },
  reducers: {
    setLang: (state, action: PayloadAction<LangCode>) => {
      state.code = action.payload;
    },
  },
});

export const { setLang } = langSlice.actions;
export default langSlice.reducer;
