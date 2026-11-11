import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports: [
    MongooseModule.forRootAsync({
      useFactory: (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI'),
        // Keep a warm pool of connections so requests never pay the
        // cold-connection penalty (handshake + TLS to Atlas) that caused the
        // ~590ms slow cluster and multi-second cold spikes.
        minPoolSize: 10,
        maxPoolSize: 100,
        maxIdleTimeMS: 0,
      }),
      inject: [ConfigService],
    }),
  ],
})
export class MongoDbModule {}
