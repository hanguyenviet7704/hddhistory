# Báo cáo đồ án tốt nghiệp — HDDhistory

File kết quả: **`bao-cao-do-an.docx`** (sinh tự động, đừng sửa trực tiếp nếu còn muốn sinh lại).

## Sinh lại file

```bash
cd bao-cao
npm install        # chỉ cần chạy lần đầu
node build.js
```

## Cấu trúc mã nguồn

| Tệp | Nội dung |
|---|---|
| `build.js` | Lắp ráp các chương, cấu hình trang/đầu trang/chân trang, xuất .docx |
| `lib/helpers.js` | Hàm dựng đoạn văn, tiêu đề, bảng, khối mã, công thức, chú thích hình |
| `content/frontmatter.js` | Bìa, lời cảm ơn, trang nhận xét, mục lục, danh mục viết tắt |
| `content/ch1.js` … `ch6.js` | Nội dung sáu chương |

## Việc cần làm sau khi mở file trong Word

1. **Điền thông tin cá nhân** — tìm các chỗ trong dấu ngoặc vuông:
   - `[Học hàm, học vị và họ tên GVHD]`
   - `[Họ và tên] - [Mã sinh viên]`
   - `[Lớp]`, `[Khóa học, ví dụ 2021 – 2026]`
   - `[Họ tên GVHD]` trong Lời cảm ơn

2. **Cập nhật mục lục** — nhấp chuột phải vào bảng mục lục → *Update Field* → *Update entire table*.
   Mục lục chỉ hiện ra sau bước này (Word cần tự dựng lại từ các tiêu đề).

3. **Chèn hình minh hoạ** — các vị trí cần hình được đánh dấu bằng khung nét đứt ghi rõ
   nội dung hình cần chèn. Có 6 vị trí:
   - Hình 1.1: Sơ đồ tổng quan năm tầng xử lý
   - Hình 3.1: Biểu đồ use case tổng quan
   - Hình 3.2: Sơ đồ kiến trúc tổng thể
   - Hình 3.3: Minh hoạ một phần đồ thị tri thức (có thể chụp từ Neo4j Browser)
   - Hình 4.1: Sơ đồ luồng dữ liệu của pipeline
   - Hình 4.2: Phân bố thực thể trong không gian nhúng — **đã có sẵn** tại
     `knowledge-graph/reports/embedding_plot.png`
   - Hình 5.1: Biểu đồ so sánh MRR/Hits@10 giữa các cấu hình (vẽ từ số liệu Bảng 5.4)

4. **Sau khi chèn hình**, dùng *Insert → Table of Figures* để sinh danh mục hình.

## Nguồn số liệu trong báo cáo

Mọi số liệu đều lấy từ mã nguồn hoặc lần chạy thật, không ước lượng:

- Số liệu codebase (số tệp, số dòng, phiên bản thư viện): khảo sát trực tiếp
  `hddhistory-api`, `hddhistory-admin`, `hddhistory-flutter`
- Số liệu bộ dữ liệu: `knowledge-graph/data/vn_history/vn_history_seed.json`
- Số liệu MRR/Hits@k: các lần chạy `src/step3_train_kge.py` trên từng cấu hình dữ liệu
- Số ca kiểm thử: `knowledge-graph/tests/`
