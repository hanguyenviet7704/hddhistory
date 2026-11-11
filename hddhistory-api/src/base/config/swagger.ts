import { writeFileSync } from 'fs';
import { join } from 'path';

import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

const converter = require('openapi-to-postmanv2');

export function setupSwagger(app: INestApplication) {
  // Full decorator introspection (createDocument) + a synchronous
  // writeFileSync are costly on every process boot — skip them in
  // production, where nobody reads swagger-spec.json or hits /swagger.
  if (process.env.NODE_ENV === 'production') {
    return;
  }

  // 1️⃣ Cấu hình Swagger
  const config = new DocumentBuilder()
    .setTitle('HDDhistory API')
    .setDescription(
      'API documentation for HDDhistory project — build: perf-roadmap-optimization ✅',
    )
    .setVersion('1.1.0-perf')
    .addBearerAuth()
    .addGlobalParameters({
      name: 'lang',
      in: 'header',
      required: false,
    })
    .build();

  // 2️⃣ Sinh document và lưu ra file
  const document = SwaggerModule.createDocument(app, config);
  writeFileSync(
    join(process.cwd(), 'swagger-spec.json'),
    JSON.stringify(document, null, 2),
  );

  // 3️⃣ Thiết lập giao diện Swagger UI + nút Export Postman
  SwaggerModule.setup('swagger', app, document, {
    customCss: `
      .swagger-ui .topbar { justify-content: space-between; }
      .export-postman {
        background: #4CAF50;
        color: white;
        border: none;
        padding: 6px 12px;
        border-radius: 4px;
        cursor: pointer;
        font-size: 14px;
        margin-left: 10px;
      }
    `,
    swaggerOptions: {
      onComplete: function () {
        const topbar = window.document.querySelector('.swagger-ui .topbar');
        if (topbar && !window.document.querySelector('.export-postman')) {
          const btn = window.document.createElement('button');
          btn.innerText = 'Export to Postman';
          btn.className = 'export-postman';
          btn.onclick = () => {
            const link = window.document.createElement('a');
            link.href = '/swagger-postman';
            link.download = 'postman-collection.json';
            link.click();
          };
          topbar.appendChild(btn);
        }
      },
    },
  });

  // 4️⃣ Endpoint: /swagger-postman → sinh Postman Collection
  app.getHttpAdapter().get('/swagger-postman', (req, res) => {
    converter.convert(
      { type: 'json', data: JSON.stringify(document) },
      { folderStrategy: 'Tags', requestParametersResolution: 'Example' },
      (err: any, conversionResult: any) => {
        if (!conversionResult.result) {
          return res
            .status(500)
            .json({ error: 'Conversion failed', details: err });
        }

        const postmanCollection = conversionResult.output[0].data;

        // 🧩 Helper: lấy schema từ $ref
        function getSchemaByRef(ref: string): any | null {
          const schemaName = ref.replace('#/components/schemas/', '');
          return document.components?.schemas?.[schemaName] || null;
        }

        // 🧩 Helper: xây dựng JSON mô tả body
        function buildBodyDescriptionAsJson(
          schemaRef: string,
        ): Record<string, any> | null {
          if (!schemaRef) return null;

          const schema = getSchemaByRef(schemaRef);
          if (!schema) return null;

          if (schema.$ref) {
            return buildBodyDescriptionAsJson(schema.$ref);
          }

          if (!schema?.properties) return null;

          const jsonDesc: Record<string, any> = {};

          for (const [key, value] of Object.entries(
            schema.properties as Record<string, any>,
          )) {
            const prop = value as Record<string, any>;
            const field: Record<string, any> = {};

            if (prop.$ref) {
              const refFields = buildBodyDescriptionAsJson(prop.$ref);
              if (refFields) field.properties = refFields;
              field.type = 'object';
            } else {
              field.type = prop.type || 'unknown';
              if (prop.description) field.description = prop.description;
              if (prop.example !== undefined) field.example = prop.example;
              if (prop.enum) field.enum = prop.enum;
            }

            field.required = (schema.required || []).includes(key);
            jsonDesc[key] = field;
          }

          return jsonDesc;
        }

        // 🧩 Helper: lấy path string từ Postman request
        function getRequestPathString(request: any): string | null {
          if (!request || !request.url) return null;

          if (Array.isArray(request.url.path) && request.url.path.length) {
            return request.url.path.join('/').toLowerCase();
          }

          if (typeof request.url.raw === 'string' && request.url.raw.length) {
            try {
              const u = new URL(request.url.raw);
              return u.pathname.replace(/^\/+|\/+$/g, '').toLowerCase();
            } catch {
              return request.url.raw
                .replace(/^https?:\/\/[^/]+\/?/, '')
                .toLowerCase();
            }
          }

          if (typeof request.url.path === 'string') {
            return request.url.path.replace(/^\/+|\/+$/g, '').toLowerCase();
          }

          return null;
        }

        // 🆕 Helper: So khớp đường dẫn một cách chính xác
        // Hàm này thay thế cho logic `includes` bị lỗi
        function doPathsMatch(
          postmanPath: string,
          swaggerPath: string,
        ): boolean {
          const normalize = (p: string) =>
            p.replace(/^\/+|\/+$/g, '').toLowerCase();
          const pPath = normalize(postmanPath);
          const sPath = normalize(swaggerPath);

          const pSegments = pPath.split('/').filter(Boolean);
          const sSegments = sPath.split('/').filter(Boolean);

          // Số lượng phần tử phải giống nhau
          if (pSegments.length !== sSegments.length) {
            return false;
          }

          // So sánh từng phần tử
          for (let i = 0; i < sSegments.length; i++) {
            const swaggerSeg = sSegments[i];
            const postmanSeg = pSegments[i];

            // Nếu phần tử của Swagger là tham số (ví dụ: {id}), nó khớp với mọi giá trị
            if (swaggerSeg.startsWith('{') && swaggerSeg.endsWith('}')) {
              continue;
            }

            // Nếu không phải tham số, chúng phải giống hệt nhau
            if (swaggerSeg !== postmanSeg) {
              return false;
            }
          }

          return true;
        }

        // 🧩 Gắn JSON mô tả vào request tương ứng
        function attachJsonDescToMatchingRequests(
          items: any[],
          methodToMatch: string,
          swaggerPath: string,
          jsonDesc: Record<string, any>,
        ) {
          if (!Array.isArray(items) || !jsonDesc) return;

          items.forEach(it => {
            if (it.request) {
              const reqMethod = (it.request.method || '').toLowerCase();
              const reqPathStr = getRequestPathString(it.request);

              // Sử dụng hàm so khớp chính xác mới
              const methodMatches = reqMethod === methodToMatch.toLowerCase();
              const pathMatches =
                reqPathStr && doPathsMatch(reqPathStr, swaggerPath);

              if (methodMatches && pathMatches) {
                it.bodySchema = jsonDesc;
              }
            }

            if (it.item && Array.isArray(it.item)) {
              attachJsonDescToMatchingRequests(
                it.item,
                methodToMatch,
                swaggerPath,
                jsonDesc,
              );
            }
          });
        }

        // 🧩 Duyệt qua Swagger paths → chèn schema JSON
        // Logic này đã hỗ trợ PUT, POST, PATCH... miễn là có requestBody
        function addDescriptionsFromSwagger() {
          Object.entries(document.paths).forEach(
            ([path, methods]: [string, any]) => {
              Object.entries(methods).forEach(
                ([method, def]: [string, any]) => {
                  const schemaRef =
                    def.requestBody?.content?.['application/json']?.schema
                      ?.$ref ||
                    def.requestBody?.content?.['multipart/form-data']?.schema
                      ?.$ref;

                  if (!schemaRef) return;

                  const jsonDesc = buildBodyDescriptionAsJson(schemaRef);
                  if (!jsonDesc) return;

                  attachJsonDescToMatchingRequests(
                    postmanCollection.item,
                    method,
                    path,
                    jsonDesc,
                  );
                },
              );
            },
          );
        }

        addDescriptionsFromSwagger();

        // 🧩 Base URL
        postmanCollection.variable = [
          { key: 'baseUrl', value: 'http://localhost:3000' },
        ];

        // 🧩 Thay host bằng {{baseUrl}}
        function replaceHostRecursively(items: any[]) {
          if (!items) return;
          items.forEach(item => {
            if (item.request?.url) {
              item.request.url.host = ['{{baseUrl}}'];
            }
            if (item.item) replaceHostRecursively(item.item);
          });
        }

        replaceHostRecursively(postmanCollection.item);

        res.setHeader(
          'Content-Disposition',
          'attachment; filename=postman-collection.json',
        );
        res.json(postmanCollection);
      },
    );
  });
}
