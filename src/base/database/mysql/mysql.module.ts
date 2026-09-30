import { join } from 'path';

import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'mysql',
        host: configService.get<string>('MYSQL_HOST'),
        port: Number(configService.get<string>('MYSQL_PORT')) || 3306,
        username: configService.get<string>('MYSQL_USERNAME'),
        password: configService.get<string>('MYSQL_PASSWORD'),
        database: configService.get<string>('MYSQL_DB'),
        autoLoadEntities: true,
        // Stays off: schema changes go through migrations below, never through
        // TypeORM diffing entities against a live database.
        synchronize: false,
        // Until now this repo had no migration system and every table was
        // provisioned by hand, which meant code could deploy ahead of its
        // schema (TypeORM lists all columns explicitly, so a missing one breaks
        // every read of that table). Migrations run at boot so the two can
        // never drift apart. Resolved from __dirname, i.e. dist/migrations at
        // runtime; `dist` is in .dockerignore, so the image only ever contains
        // migrations compiled from src in the build stage.
        migrations: [join(__dirname, '..', '..', '..', 'migrations', '*.{ts,js}')],
        migrationsRun: true,
        migrationsTableName: 'typeorm_migrations',
        logging: false,
        // giúp app restart/hot-reload không tạo thêm kết nối lộn xộn
        keepConnectionAlive: true,

        // retry khi DB/proxy reset kết nối thoáng qua
        retryAttempts: 10,
        retryDelay: 2000,

        // pool + keepalive ở mức driver
        extra: {
          connectionLimit: 10,
          enableKeepAlive: true,
          keepAliveInitialDelay: 0,
          // (tuỳ chọn) giới hạn thời gian chờ connect/queue để tránh treo
          connectTimeout: 10000,
          queueLimit: 0,
        },
      }),
    }),
  ],
})
export class MysqlModule {}
