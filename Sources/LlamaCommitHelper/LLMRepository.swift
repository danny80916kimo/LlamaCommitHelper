//
//  LLMRepository.swift
//  meepoo
//
//  Created by 劉家瑋 on 2025/5/29.
//



protocol LLMRepository {
    func generateMessage(token: String) async throws -> String
}

struct DefaultLLMRepository: LLMRepository {
    let service:LMStudioService
    
    init(service:LMStudioService){
        self.service = service
    }
    
    func generateMessage(token: String) async throws -> String {
        return try await service.generateMessage(prompt: token)
    }
}
