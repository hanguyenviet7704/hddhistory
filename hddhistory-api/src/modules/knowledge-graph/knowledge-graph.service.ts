import { Injectable, NotFoundException } from '@nestjs/common';

import { GetRelatedEntityDto, SearchEntityDto } from './dto/search-entity.dto';
import {
  IKgEntityProfile,
  IKgEntitySummary,
  IKgOverview,
  IKgRelatedEntity,
} from './interface/entity-profile.interface';
import { KnowledgeGraphRepository } from './repository/knowledge-graph.repository';

@Injectable()
export class KnowledgeGraphService {
  constructor(
    private readonly knowledgeGraphRepository: KnowledgeGraphRepository,
  ) {}

  async search(dto: SearchEntityDto): Promise<IKgEntitySummary[]> {
    return this.knowledgeGraphRepository.search(dto.q ?? '', dto.limit ?? 20, {
      type: dto.type,
      periodId: dto.periodId,
    });
  }

  async getOverview(): Promise<IKgOverview> {
    return this.knowledgeGraphRepository.findOverview();
  }

  async getProfile(id: string): Promise<IKgEntityProfile> {
    const profile = await this.knowledgeGraphRepository.findProfile(id);
    if (!profile) {
      throw new NotFoundException(`Không tìm thấy thực thể có id '${id}'`);
    }
    return profile;
  }

  async getRelated(
    id: string,
    dto: GetRelatedEntityDto,
  ): Promise<IKgRelatedEntity[]> {
    // Phân biệt rõ hai trường hợp: thực thể không tồn tại (404) và thực thể
    // tồn tại nhưng chưa nối quan hệ nào (danh sách rỗng, vẫn là 200).
    const exists = await this.knowledgeGraphRepository.exists(id);
    if (!exists) {
      throw new NotFoundException(`Không tìm thấy thực thể có id '${id}'`);
    }
    return this.knowledgeGraphRepository.findRelated(
      id,
      dto.maxHops ?? 2,
      dto.limit ?? 20,
    );
  }
}
