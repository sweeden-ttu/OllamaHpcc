# PMBOK Project Management Plan

This document outlines the project management approach following PMBOK (Project Management Body of Knowledge) best practices.

## Project Overview

| Attribute | Value |
|-----------|-------|
| Project Name | OllamaHpcc |
| Description | Ollama server and client for HPCC RedRaider GPU clusters |
| Repository | github.com/sweeden-ttu/OllamaHpcc |
| Owner | sweeden-ttu |

## Project Phases (PMBOK)

### 1. Initiating Phase
- [x] Define project charter
- [x] Identify stakeholders
- [x] Define initial scope
- [x] Base image research (slurm-openssh-container)

### 2. Planning Phase
- [x] Create WBS
- [x] Define schedule milestones
- [ ] Plan budget/resources (HPCC allocation)
- [x] Identify risks
- [ ] Define quality standards

### 3. Executing Phase
- [x] Container deployment scripts
- [x] Client library development
- [ ] HPCC integration testing
- [ ] LangChain integration

### 4. Monitoring & Controlling Phase
- [ ] Monitor container health
- [ ] Performance benchmarking
- [ ] Monitor resource usage

### 5. Closing Phase
- [ ] Release v1.0
- [ ] Document lessons learned

## Milestones

### Phase 1: Foundation (Week 1-2)
| Milestone | Target | Status |
|-----------|--------|--------|
| Project charter approved | Week 1 | ✅ Complete |
| Repository created | Week 1 | ✅ Complete |
| Base image research | Week 1 | ✅ Complete |
| Container deployment scripts | Week 2 | ✅ Complete |

### Phase 2: Core Development (Week 3-6)
| Milestone | Target | Status |
|-----------|--------|--------|
| granite4 container (port 55077) | Week 3 | 🔄 In Progress |
| qwen-coder container (port 66044) | Week 4 | ⏳ Pending |
| Python client library | Week 5 | ⏳ Pending |
| HPCC job submission scripts | Week 6 | ⏳ Pending |

### Phase 3: Integration (Week 7-10)
| Milestone | Target | Status |
|-----------|--------|--------|
| LangChain integration | Week 7 | ⏳ Pending |
| GlobPretect tunnel integration | Week 8 | ⏳ Pending |
| data-structures integration | Week 9 | ⏳ Pending |
| Performance benchmarking | Week 10 | ⏳ Pending |

### Phase 4: Polish & Release (Week 11-12)
| Milestone | Target | Status |
|-----------|--------|--------|
| Beta testing | Week 11 | ⏳ Pending |
| Release v1.0 | Week 12 | ⏳ Pending |

## Work Breakdown Structure (WBS)

```
OllamaHpcc
├── 1. Project Management
│   ├── 1.1 Project Charter
│   ├── 1.2 Planning
│   └── 1.3 Closing
├── 2. Container Infrastructure
│   ├── 2.1 Base Image (slurm-openssh-container)
│   ├── 2.2 granite4 Container (55077)
│   └── 2.3 qwen-coder Container (66044)
├── 3. HPCC Integration
│   ├── 3.1 Slurm Job Templates
│   ├── 3.2 GPU Allocation
│   └── 3.3 Job Monitoring
├── 4. Client Library
│   ├── 4.1 Connection Management
│   ├── 4.2 Model Selection
│   └── 4.3 Streaming Responses
├── 5. LangChain Integration
│   ├── 5.1 Ollama LLM Wrapper
│   ├── 5.2 Tool Definitions
│   └── 5.3 Agent Templates
├── 6. Dependencies
│   ├── 6.1 GlobPretect (tunnels)
│   └── 6.2 data-structures (Graph, Queue)
└── 7. Testing & Deployment
    ├── 7.1 Unit Tests
    ├── 7.2 Integration Tests
    └── 7.3 Release Package
```

## Risk Register

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R1 | GPU availability on HPCC | High | High | Queue monitoring, job scheduling |
| R2 | Container networking issues | Medium | High | Host network mode, port validation |
| R3 | Model loading failures | Medium | Medium | Health checks, auto-restart |
| R4 | HPCC maintenance downtime | Medium | Medium | Graceful degradation, local fallback |
| R5 | Memory constraints | Medium | Medium | Resource limits, model swapping |

## Port Configuration

| Port | Model | Purpose | Status |
|------|-------|---------|--------|
| 55077 | granite4 | Agentic tasks | 🔄 In Progress |
| 66044 | qwen2.5-coder | Code generation | ⏳ Pending |

## Success Criteria

1. Ollama containers running on HPCC GPU nodes
2. Fixed ports 55077 and 66044 accessible via SSH tunnels
3. Python client library functional
4. LangChain integration complete
5. Daily GitHub sync operational
6. Integration with data-structures and GlobPretect

## Dependencies

- **GlobPretect**: SSH tunnel management for port forwarding
- **data-structures**: Graph for model dependency tracking, Queue for request management

## Lessons Learned

*(To be updated throughout the project)*
