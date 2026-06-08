# GymLog Project Context

## 1. Project Overview
- Root path: C:\Users\Atharva Patil\Documents\projects\gymlog
- Project name: gymlog
- Flutter version: >=3.0.0 <4.0.0
- Architecture pattern summary: Feature-based Riverpod Clean-ish Architecture with local Drift DB

## 2. Project Structure Tree
`	ext
./
    .env
    .flutter-plugins
    .flutter-plugins-dependencies
    .gitignore
    .mcp.json
    .metadata
    .puro.json
    AGENTS.md
    analysis_options.yaml
    CLAUDE.md
    context.md
    context7.md
    flutter_01.log
    flutter_02.log
    gymlog.iml
    package-lock.json
    package.json
    pubspec.lock
    pubspec.yaml
    README.md
    STITCH_DESIGN_SYSTEM.md
    temp_dump.txt
    WORKSPACE_SYNC.md
    .claude/
        settings.json
        agents/
            analysis/
                analyze-code-quality.md
                code-analyzer.md
                code-review/
                    analyze-code-quality.md
            architecture/
                arch-system-design.md
                system-design/
                    arch-system-design.md
            browser/
                browser-agent.yaml
            consensus/
                byzantine-coordinator.md
                crdt-synchronizer.md
                gossip-coordinator.md
                performance-benchmarker.md
                quorum-manager.md
                raft-manager.md
                security-manager.md
            core/
                coder.md
                planner.md
                researcher.md
                reviewer.md
                tester.md
            custom/
                test-long-runner.md
            data/
                data-ml-model.md
                ml/
                    data-ml-model.md
            development/
                dev-backend-api.md
                backend/
                    dev-backend-api.md
            devops/
                ops-cicd-github.md
                ci-cd/
                    ops-cicd-github.md
            documentation/
                docs-api-openapi.md
                api-docs/
                    docs-api-openapi.md
            flow-nexus/
                app-store.md
                authentication.md
                challenges.md
                neural-network.md
                payments.md
                sandbox.md
                swarm.md
                user-tools.md
                workflow.md
            github/
                code-review-swarm.md
                github-modes.md
                issue-tracker.md
                multi-repo-swarm.md
                pr-manager.md
                project-board-sync.md
                release-manager.md
                release-swarm.md
                repo-architect.md
                swarm-issue.md
                swarm-pr.md
                sync-coordinator.md
                workflow-automation.md
            goal/
                agent.md
                goal-planner.md
            optimization/
                benchmark-suite.md
                load-balancer.md
                performance-monitor.md
                resource-allocator.md
                topology-optimizer.md
            payments/
                agentic-payments.md
            sona/
                sona-learning-optimizer.md
            sparc/
                architecture.md
                pseudocode.md
                refinement.md
                specification.md
            specialized/
                spec-mobile-react-native.md
                mobile/
                    spec-mobile-react-native.md
            sublinear/
                consensus-coordinator.md
                matrix-optimizer.md
                pagerank-analyzer.md
                performance-optimizer.md
                trading-predictor.md
            swarm/
                adaptive-coordinator.md
                hierarchical-coordinator.md
                mesh-coordinator.md
            templates/
                automation-smart-agent.md
                base-template-generator.md
                coordinator-swarm-init.md
                github-pr-manager.md
                implementer-sparc-coder.md
                memory-coordinator.md
                orchestrator-task.md
                performance-analyzer.md
                sparc-coordinator.md
            testing/
                production-validator.md
                tdd-london-swarm.md
            v3/
                adr-architect.md
                aidefence-guardian.md
                claims-authorizer.md
                collective-intelligence-coordinator.md
                ddd-domain-expert.md
                injection-analyst.md
                memory-specialist.md
                performance-engineer.md
                pii-detector.md
                reasoningbank-learner.md
                security-architect-aidefence.md
                security-architect.md
                security-auditor.md
                sparc-orchestrator.md
                swarm-memory-manager.md
                v3-integration-architect.md
        commands/
            claude-flow-help.md
            claude-flow-memory.md
            claude-flow-swarm.md
            analysis/
                bottleneck-detect.md
                COMMAND_COMPLIANCE_REPORT.md
                performance-bottlenecks.md
                performance-report.md
                README.md
                token-efficiency.md
                token-usage.md
            automation/
                auto-agent.md
                README.md
                self-healing.md
                session-memory.md
                smart-agents.md
                smart-spawn.md
                workflow-select.md
            github/
                code-review-swarm.md
                code-review.md
                github-modes.md
                github-swarm.md
                issue-tracker.md
                issue-triage.md
                multi-repo-swarm.md
                pr-enhance.md
                pr-manager.md
                project-board-sync.md
                README.md
                release-manager.md
                release-swarm.md
                repo-analyze.md
                repo-architect.md
                swarm-issue.md
                swarm-pr.md
                sync-coordinator.md
                workflow-automation.md
            hooks/
                overview.md
                post-edit.md
                post-task.md
                pre-edit.md
                pre-task.md
                README.md
                session-end.md
                setup.md
            monitoring/
                agent-metrics.md
                agents.md
                README.md
                real-time-view.md
                status.md
                swarm-monitor.md
            optimization/
                auto-topology.md
                cache-manage.md
                parallel-execute.md
                parallel-execution.md
                README.md
                topology-optimize.md
            sparc/
                analyzer.md
                architect.md
                ask.md
                batch-executor.md
                code.md
                coder.md
                debug.md
                debugger.md
                designer.md
                devops.md
                docs-writer.md
                documenter.md
                innovator.md
                integration.md
                mcp.md
                memory-manager.md
                optimizer.md
                orchestrator.md
                post-deployment-monitoring-mode.md
                refinement-optimization-mode.md
                researcher.md
                reviewer.md
                security-review.md
                sparc-modes.md
                sparc.md
                spec-pseudocode.md
                supabase-admin.md
                swarm-coordinator.md
                tdd.md
                tester.md
                tutorial.md
                workflow-manager.md
        helpers/
            adr-compliance.sh
            auto-commit.sh
            auto-memory-hook.mjs
            checkpoint-manager.sh
            daemon-manager.sh
            ddd-tracker.sh
            github-safe.js
            github-setup.sh
            guidance-hook.sh
            guidance-hooks.sh
            health-monitor.sh
            hook-handler.cjs
            intelligence.cjs
            learning-hooks.sh
            learning-optimizer.sh
            learning-service.mjs
            memory.js
            metrics-db.mjs
            pattern-consolidator.sh
            perf-worker.sh
            post-commit
            pre-commit
            quick-start.sh
            README.md
            router.js
            security-scanner.sh
            session.js
            setup-mcp.sh
            standard-checkpoint-hooks.sh
            statusline-hook.sh
            statusline.cjs
            statusline.js
            swarm-comms.sh
            swarm-hooks.sh
            swarm-monitor.sh
            sync-v3-metrics.sh
            update-v3-progress.sh
            v3-quick-status.sh
            v3.sh
            validate-v3-config.sh
            worker-manager.sh
    .idea/
        modules.xml
        workspace.xml
        libraries/
            Dart_SDK.xml
            KotlinJavaRuntime.xml
        runConfigurations/
            main_dart.xml
    .vscode/
        settings.json
    .windsurf/
        rules/
            gymlog.md
    assets/
        db/
            exercises.db
            exercises.json
    docs/
        AI_SYSTEM_CONTEXT.md
        ARCHITECTURE.md
        CONTEXT_SNAPSHOT.md
        CONVENTIONS.md
        DATA_MODEL.md
        DECISIONS.md
        PROGRESS.md
        UI_UX_AUDIT.md
    lib/
        app.dart
        main.dart
        core/
            database/
                database.dart
                database.g.dart
                daos/
                    exercises_dao.dart
                    exercises_dao.g.dart
                    routines_dao.dart
                    routines_dao.g.dart
                    user_dao.dart
                    user_dao.g.dart
                    workouts_dao.dart
                    workouts_dao.g.dart
                tables/
                    exercises_table.dart
                    routines_table.dart
                    routine_days_table.dart
                    routine_exercises_table.dart
                    user_profiles_table.dart
                    workouts_table.dart
            providers/
                database_provider.dart
            router/
                router.dart
            theme/
                app_colors.dart
                app_theme.dart
            utils/
                formatters.dart
        features/
            auth/
                data/
                    auth_repository.dart
                presentation/
                    providers/
                        auth_provider.dart
                    screens/
                        auth_screen.dart
                        onboarding_screen.dart
                        splash_screen.dart
            exercises/
                presentation/
                    providers/
                        exercises_provider.dart
                        exercises_provider.g.dart
                        exercise_analytics_provider.dart
                    screens/
                        exercise_detail_screen.dart
                        exercise_selection_screen.dart
            home/
                presentation/
                    providers/
                        home_provider.dart
                        recent_workouts_provider.dart
                    screens/
                        home_screen.dart
                    widgets/
                        workout_history_card.dart
            profile/
                presentation/
                    providers/
                        profile_provider.dart
                    screens/
                        profile_screen.dart
            routines/
                presentation/
                    providers/
                        routines_provider.dart
                    screens/
                        routine_detail_screen.dart
                        routine_editor_screen.dart
                    widgets/
                        routine_card.dart
                        routine_exercise_block.dart
                        routine_volume_graph.dart
            workout/
                domain/
                    active_workout_state.dart
                    active_workout_state.freezed.dart
                presentation/
                    providers/
                        active_workout_provider.dart
                        workout_actions_provider.dart
                        workout_detail_provider.dart
                        workout_timer_provider.dart
                        workout_timer_provider.g.dart
                    screens/
                        active_workout_screen.dart
                        workout_detail_screen.dart
                        workout_screen.dart
                    widgets/
                        exercise_block.dart
                        set_row.dart
        shared/
            providers/
                gif_last_frame_provider.dart
            widgets/
                active_workout_bar.dart
                app_shell.dart
                bottom_nav_bar.dart
                exercise_gif_widget.dart
                ui/
                    action_bottom_sheet.dart
                    primary_button.dart
                    secondary_button.dart
                    toggle_pill.dart
                    tracker_card.dart
    scripts/
        seed_exercises.py
    test/
        widget_test.dart
`

## 3. Markdown Documentation Inventory

### .\AGENTS.md

**Headings:**
- # GymLog — Agent Context
- ## Project Overview
- ### Tech Stack
- ## Build & Run
- # Install dependencies
- # Run code generation (required after schema or provider changes)
- # Analyze
- # Run (debug)
- # Build release APK
- ## Project Structure
- ## Conventions
- ## Environment & Secrets
- ## Testing
- ## Notes for Agents

### .\CLAUDE.md

**Headings:**
- # Ruflo — Claude Code Configuration
- ## Rules
- ## Agent Comms (SendMessage-First Coordination)
- ### Spawning a Coordinated Team
- ### Patterns
- ### Rules
- ## Swarm & Routing
- ### Config
- ### Agent Routing
- ### When to Swarm
- ### 3-Tier Model Routing
- ## Memory & Learning
- ### Before Any Task
- ### After Success
- ### MCP Tools (use `ToolSearch("keyword")` to discover)
- ### Background Workers
- ## Agents
- ## Build & Test
- ## CLI Quick Reference
- ## Setup

### .\context7.md

**Headings:**
- # GymLog Architecture Context (context7)
- ## 1. Tech Stack & Environment
- ## 2. Database Schema (Drift)
- ### Tables
- ### Database Connection (`database.dart`)
- ### DAOs
- #### `ExercisesDao`
- #### `WorkoutsDao`
- #### `RoutinesDao`
- #### `UserDao`
- ## 3. Global State (Riverpod)
- ### ActiveWorkoutNotifier Methods
- ### WorkoutHistoryNotifier Methods
- ## 4. Navigation Map
- ### ShellRoute
- ### Router Refresh Logic
- ## 5. Changelog / Latest Upgrade
- ### Previous State
- ### Track 1–4: Foundation & UI Polish
- ### Track 5: Exercise Library & Selection Flow
- ### Track 6: Exercise Detail Screen (Hevy Clone Analytics)
- ### Track 7: Global Action Wiring & Data Pipeline
- ### Track 7.5: State Invalidation & Routing Bug Fixes
- ### Track 8: Analytics Data Injection (Live History)
- ### Track 8.5: Production UI Hardening & Historical Hydration
- ### Track 8.75: Premium UI Polish & Interactive Analytics
- ### Track 8.9: Full System Overhaul — Persistence, Reactivity, Routing, UI Unification
- ### Track 8.91: Remove Broken `drift_flutter` — Native SQLite Hardwire
- ### Track 8.92: Native Google Sign-In (Android/iOS)
- ## 6. File Architecture
- ## 7. Data Flow Patterns
- ### Workout Creation Flow
- ### Exercise Analytics Flow
- ### Routine Creation Flow (from Workout)
- ## 8. Key Dependencies
- ### Track 9: Workout Log V2 — VS PREV, Header Layering, Duration Validation
- ## 9. Pending / Next Steps

### .\README.md

**Headings:**
- # gymlog
- ## Getting Started

### .\STITCH_DESIGN_SYSTEM.md

**Headings:**
- # Design System Documentation: Digital Fluidity & Resource Intelligence
- ## 1. Overview & Creative North Star
- ### The Creative North Star: "The Luminous Engine"
- ## 2. Colors & Surface Architecture
- ### The "No-Line" Rule
- ### Surface Hierarchy & Nesting
- ### The "Glass & Gradient" Rule
- ## 3. Typography: The Editorial Voice
- ## 4. Elevation & Depth
- ## 5. Components
- ### Buttons & Interaction
- ### Data Chips & Status
- ### Inputs & Forms
- ### Cards & Resource Lists
- ## 6. Do’s and Don’ts
- ### Do:
- ### Don’t:

### .\WORKSPACE_SYNC.md

**Headings:**
- # WORKSPACE_SYNC.md — GymLog Absolute State Extraction
- ## 1. Environment & Dependencies
- ### Key Packages (from `pubspec.yaml` on disk)
- ## 2. Design Tokens (Ground Truth)
- ### 2.1 Color Tokens
- ### 2.2 Backward Compatibility Aliases
- ### 2.3 Global Theme Rules
- ### 2.4 Typography Scale
- ## 3. UI Component Registry
- ### 3.1 TrackerCard
- ### 3.2 PrimaryButton
- ### 3.3 SecondaryButton
- ### 3.4 TogglePill
- ## 4. Screen Architecture Mapping
- ### 4.1 Global Shell
- ### 4.2 Home Screen (`/`)
- ### 4.3 Workout Screen (`/workout`)
- ### 4.4 Profile Screen (`/profile`)
- ## 5. Database Schema (Drift)
- ### 5.1 Current Implementation State
- ### 5.2 Target Schema (from `context.md` — NOT yet implemented on disk)
- #### UserProfiles
- #### Exercises
- #### Routines
- #### RoutineDays
- #### RoutineExercises
- #### WorkoutSessions
- #### WorkoutExercises
- #### WorkoutSets
- ## 6. Implementation Delta (Current vs. Target)
- ### 6.1 Stubbed/Non-Functional UI Elements
- ### 6.2 Completely Missing Modules
- ### 6.3 Legacy/Dead Code
- ## Complete File Index (`lib/`)

### .\.claude\agents\analysis\analyze-code-quality.md

**Headings:**
- # Code Quality Analyzer
- ## Key responsibilities:
- ## Analysis criteria:
- ## Code smell detection:
- ## Review output format:
- ## Code Quality Analysis Report
- ### Summary
- ### Critical Issues
- ### Code Smells
- ### Refactoring Opportunities
- ### Positive Findings

### .\.claude\agents\analysis\code-analyzer.md

**Headings:**
- # Code Analyzer Agent
- ## Core Responsibilities
- ### 1. Code Quality Assessment
- ### 2. Performance Analysis
- ### 3. Security Review
- ### 4. Architecture Analysis
- ### 5. Technical Debt Management
- ## Analysis Workflow
- ### Phase 1: Initial Scan
- # Comprehensive code scan
- # Load project context
- ### Phase 2: Deep Analysis
- ### Phase 3: Report Generation
- # Store analysis results
- # Generate recommendations
- ## Integration Points
- ### With Other Agents
- ### With CI/CD Pipeline
- ## Analysis Metrics
- ### Code Quality Metrics
- ### Performance Metrics
- ### Security Metrics
- ## Best Practices
- ### 1. Continuous Analysis
- ### 2. Actionable Insights
- ### 3. Context Awareness
- ## Example Analysis Output
- ## Code Analysis Report
- ### Summary
- ### Critical Issues
- ### Recommendations
- ## Memory Keys
- ## Coordination Protocol

### .\.claude\agents\analysis\code-review\analyze-code-quality.md

**Headings:**
- # Code Quality Analyzer
- ## Key responsibilities:
- ## Analysis criteria:
- ## Code smell detection:
- ## Review output format:
- ## Code Quality Analysis Report
- ### Summary
- ### Critical Issues
- ### Code Smells
- ### Refactoring Opportunities
- ### Positive Findings

### .\.claude\agents\architecture\arch-system-design.md

**Headings:**
- # System Architecture Designer
- ## Key responsibilities:
- ## Best practices:
- ## Deliverables:
- ## Decision framework:

### .\.claude\agents\architecture\system-design\arch-system-design.md

**Headings:**
- # System Architecture Designer
- ## Key responsibilities:
- ## Best practices:
- ## Deliverables:
- ## Decision framework:

### .\.claude\agents\consensus\byzantine-coordinator.md

**Headings:**
- # Byzantine Consensus Coordinator
- ## Core Responsibilities
- ## Implementation Approach
- ### Byzantine Fault Tolerance
- ### Security Integration
- ### Network Resilience
- ## Collaboration

### .\.claude\agents\consensus\crdt-synchronizer.md

**Headings:**
- # CRDT Synchronizer
- ## Core Responsibilities
- ## Technical Implementation
- ### Base CRDT Framework
- ### G-Counter Implementation
- ### OR-Set Implementation
- ### LWW-Register Implementation
- ### RGA (Replicated Growable Array) Implementation
- ### Delta-State CRDT Framework
- ## MCP Integration Hooks
- ### Memory Coordination for CRDT State
- ### Performance Monitoring
- ## Advanced CRDT Features
- ### Causal Consistency Tracker
- ### CRDT Composition Framework
- ## Integration with Consensus Protocols
- ### CRDT-Enhanced Consensus

### .\.claude\agents\consensus\gossip-coordinator.md

**Headings:**
- # Gossip Protocol Coordinator
- ## Core Responsibilities
- ## Implementation Approach
- ### Epidemic Information Spread
- ### Anti-Entropy Protocols
- ### Membership and Topology
- ## Collaboration

### .\.claude\agents\consensus\performance-benchmarker.md

**Headings:**
- # Performance Benchmarker
- ## Core Responsibilities
- ## Technical Implementation
- ### Core Benchmarking Framework
- ### Throughput Measurement System
- ### Latency Analysis System
- ### Resource Usage Monitor
- ### Adaptive Performance Optimizer
- ## MCP Integration Hooks
- ### Performance Metrics Storage
- ### Neural Performance Learning

### .\.claude\agents\consensus\quorum-manager.md

**Headings:**
- # Quorum Manager
- ## Core Responsibilities
- ## Technical Implementation
- ### Core Quorum Management System
- ### Network-Based Quorum Strategy
- ### Performance-Based Quorum Strategy
- ### Fault Tolerance Strategy
- ## MCP Integration Hooks
- ### Quorum State Management
- ### Performance Monitoring Integration
- ### Task Orchestration for Quorum Changes

### .\.claude\agents\consensus\raft-manager.md

**Headings:**
- # Raft Consensus Manager
- ## Core Responsibilities
- ## Implementation Approach
- ### Leader Election Protocol
- ### Log Replication System
- ### Fault Tolerance Features
- ## Collaboration

### .\.claude\agents\consensus\security-manager.md

**Headings:**
- # Consensus Security Manager
- ## Core Responsibilities
- ## Technical Implementation
- ### Threshold Signature System
- ### Zero-Knowledge Proof System
- ### Attack Detection System
- ### Secure Key Management
- ## MCP Integration Hooks
- ### Security Monitoring Integration
- ### Neural Pattern Learning for Security
- ## Integration with Consensus Protocols
- ### Byzantine Consensus Security
- ## Security Testing and Validation
- ### Penetration Testing Framework

### .\.claude\agents\core\coder.md

**Headings:**
- # Code Implementation Agent
- ## Core Responsibilities
- ## Implementation Guidelines
- ### 1. Code Quality Standards
- ### 2. Design Patterns
- ### 3. Performance Considerations
- ## Implementation Process
- ### 1. Understand Requirements
- ### 2. Design First
- ### 3. Test-Driven Development
- ### 4. Incremental Implementation
- ## Code Style Guidelines
- ### TypeScript/JavaScript
- ### File Organization
- ## Best Practices
- ### 1. Security
- ### 2. Maintainability
- ### 3. Testing
- ### 4. Documentation
- ## 🧠 V3 Self-Learning Protocol
- ### Before Each Implementation: Learn from History (HNSW-Indexed)
- ### During Implementation: GNN-Enhanced Context Retrieval
- ### Flash Attention for Large Codebases
- ### SONA Adaptation (<0.05ms)
- ### After Implementation: Store Learning Patterns with EWC++
- ## 🤝 Multi-Agent Coordination
- ### Use Attention for Code Review Consensus
- ## ⚡ Performance Optimization with Flash Attention
- ### Process Large Contexts Efficiently
- ## 📊 Continuous Improvement Metrics
- ## Collaboration

### .\.claude\agents\core\planner.md

**Headings:**
- # Strategic Planning Agent
- ## Core Responsibilities
- ## Planning Process
- ### 1. Initial Assessment
- ### 2. Task Decomposition
- ### 3. Dependency Analysis
- ### 4. Resource Allocation
- ### 5. Risk Mitigation
- ## Output Format
- ## Collaboration Guidelines
- ## 🧠 V3 Self-Learning Protocol
- ### Before Planning: Learn from History (HNSW-Indexed)
- ### During Planning: GNN-Enhanced Dependency Mapping
- ### MoE Routing for Optimal Agent Assignment
- ### Flash Attention for Fast Task Analysis
- ### SONA Adaptation for Planning Patterns (<0.05ms)
- ### After Planning: Store Learning Patterns with EWC++
- ## 🤝 Multi-Agent Planning Coordination
- ### Topology-Aware Coordination
- ### Hierarchical Planning with Queens and Workers
- ## 📊 Continuous Improvement Metrics
- ## Best Practices

### .\.claude\agents\core\researcher.md

**Headings:**
- # Research and Analysis Agent
- ## Core Responsibilities
- ## Research Methodology
- ### 1. Information Gathering
- ### 2. Pattern Analysis
- # Example search patterns
- ### 3. Dependency Analysis
- ### 4. Documentation Mining
- ## Research Output Format
- ## Search Strategies
- ### 1. Broad to Narrow
- # Start broad
- # Narrow by pattern
- # Focus on specific files
- ### 2. Cross-Reference
- ### 3. Historical Analysis
- ## 🧠 V3 Self-Learning Protocol
- ### Before Each Research Task: Learn from History (HNSW-Indexed)
- ### During Research: GNN-Enhanced Pattern Recognition
- ### Multi-Head Attention for Source Synthesis
- ### Flash Attention for Large Document Processing
- ### SONA Adaptation for Research Patterns (<0.05ms)
- ### After Research: Store Learning Patterns with EWC++
- ## 🤝 Multi-Agent Research Coordination
- ### Coordinate with Multiple Research Agents
- ## 📊 Continuous Improvement Metrics
- ## Collaboration Guidelines
- ## Best Practices

### .\.claude\agents\core\reviewer.md

**Headings:**
- # Code Review Agent
- ## Core Responsibilities
- ## Review Process
- ### 1. Functionality Review
- ### 2. Security Review
- ### 3. Performance Review
- ### 4. Code Quality Review
- ### 5. Maintainability Review
- ## Review Feedback Format
- ## Code Review Summary
- ### ✅ Strengths
- ### 🔴 Critical Issues
- ### 🟡 Suggestions
- ### 📊 Metrics
- ### 🎯 Action Items
- ## Review Guidelines
- ### 1. Be Constructive
- ### 2. Prioritize Issues
- ### 3. Consider Context
- ## Automated Checks
- # Run automated tools before manual review
- ## 🧠 V3 Self-Learning Protocol
- ### Before Review: Learn from Past Patterns (HNSW-Indexed)
- ### During Review: GNN-Enhanced Issue Detection
- ### Flash Attention for Fast Code Review
- ### SONA Adaptation for Review Patterns (<0.05ms)
- ### Attention-Based Multi-Reviewer Consensus
- ### After Review: Store Learning Patterns with EWC++
- ## 🤝 Multi-Reviewer Coordination
- ### Consensus-Based Review with Attention
- ### Route to Specialized Reviewers
- ## 📊 Continuous Improvement Metrics
- ## Best Practices

### .\.claude\agents\core\tester.md

**Headings:**
- # Testing and Quality Assurance Agent
- ## Core Responsibilities
- ## Testing Strategy
- ### 1. Test Pyramid
- ### 2. Test Types
- #### Unit Tests
- #### Integration Tests
- #### E2E Tests
- ### 3. Edge Case Testing
- ## Test Quality Metrics
- ### 1. Coverage Requirements
- ### 2. Test Characteristics
- ## Performance Testing
- ## Security Testing
- ## Test Documentation
- ## 🧠 V3 Self-Learning Protocol
- ### Before Testing: Learn from Past Failures (HNSW-Indexed)
- ### During Testing: GNN-Enhanced Test Case Discovery
- ### Flash Attention for Fast Test Generation
- ### SONA Adaptation for Test Patterns (<0.05ms)
- ### After Testing: Store Learning Patterns with EWC++
- ## 🤝 Multi-Agent Test Coordination
- ### Optimize Test Coverage with Attention
- ### Route to Specialized Test Experts
- ## 📊 Continuous Improvement Metrics
- ## Best Practices

### .\.claude\agents\custom\test-long-runner.md

**Headings:**
- # Test Long-Running Agent
- ## Capabilities
- ## Instructions
- ## Output Format
- ## Example Use Cases

### .\.claude\agents\data\data-ml-model.md

**Headings:**
- # Machine Learning Model Developer v3.0.0-alpha.1
- ## 🧠 Self-Learning Protocol
- ### Before Training: Learn from Past Models
- ### During Training: GNN for Hyperparameter Search
- ### For Large Datasets: Flash Attention
- ### After Training: Store Learning Patterns
- ## 🎯 Domain-Specific Optimizations
- ### ReasoningBank for Model Training Patterns
- ### GNN for Hyperparameter Optimization
- ### Flash Attention for Large Datasets
- ## Key responsibilities:
- ## ML workflow:
- ## Code patterns:
- # Standard ML pipeline structure
- # Data preprocessing
- # Pipeline creation
- # Training
- # Evaluation
- ## Best practices:

### .\.claude\agents\data\ml\data-ml-model.md

**Headings:**
- # Machine Learning Model Developer
- ## Key responsibilities:
- ## ML workflow:
- ## Code patterns:
- # Standard ML pipeline structure
- # Data preprocessing
- # Pipeline creation
- # Training
- # Evaluation
- ## Best practices:

### .\.claude\agents\development\dev-backend-api.md

**Headings:**
- # Backend API Developer v3.0.0-alpha.1
- ## 🧠 Self-Learning Protocol
- ### Before Each API Implementation: Learn from History
- ### During Implementation: GNN-Enhanced Context Search
- ### For Large Schemas: Flash Attention Processing
- ### After Implementation: Store Learning Patterns
- ## 🎯 Domain-Specific Optimizations
- ### API Pattern Recognition
- ### Endpoint Success Rate Tracking
- ## Key responsibilities:
- ## Best practices:
- ## Patterns to follow:

### .\.claude\agents\development\backend\dev-backend-api.md

**Headings:**
- # Backend API Developer
- ## Key responsibilities:
- ## Best practices:
- ## Patterns to follow:

### .\.claude\agents\devops\ops-cicd-github.md

**Headings:**
- # GitHub CI/CD Pipeline Engineer
- ## Key responsibilities:
- ## Best practices:
- ## Workflow patterns:
- ## Security considerations:

### .\.claude\agents\devops\ci-cd\ops-cicd-github.md

**Headings:**
- # GitHub CI/CD Pipeline Engineer
- ## Key responsibilities:
- ## Best practices:
- ## Workflow patterns:
- ## Security considerations:

### .\.claude\agents\documentation\docs-api-openapi.md

**Headings:**
- # OpenAPI Documentation Specialist v3.0.0-alpha.1
- ## 🧠 Self-Learning Protocol
- ### Before Documentation: Learn from Past Patterns
- ### During Documentation: GNN-Enhanced API Search
- ### After Documentation: Store Patterns
- ## 🎯 Domain-Specific Optimizations
- ### Documentation Pattern Learning
- ### Fast Documentation Generation
- ## Key responsibilities:
- ## Best practices:
- ## OpenAPI structure:
- ## Documentation elements:

### .\.claude\agents\documentation\api-docs\docs-api-openapi.md

**Headings:**
- # OpenAPI Documentation Specialist
- ## Key responsibilities:
- ## Best practices:
- ## OpenAPI structure:
- ## Documentation elements:

### .\.claude\agents\flow-nexus\app-store.md

**Headings:**


### .\.claude\agents\flow-nexus\authentication.md

**Headings:**


### .\.claude\agents\flow-nexus\challenges.md

**Headings:**


### .\.claude\agents\flow-nexus\neural-network.md

**Headings:**


### .\.claude\agents\flow-nexus\payments.md

**Headings:**


### .\.claude\agents\flow-nexus\sandbox.md

**Headings:**


### .\.claude\agents\flow-nexus\swarm.md

**Headings:**


### .\.claude\agents\flow-nexus\user-tools.md

**Headings:**


### .\.claude\agents\flow-nexus\workflow.md

**Headings:**


### .\.claude\agents\github\code-review-swarm.md

**Headings:**
- # Code Review Swarm - Automated Code Review with AI Agents
- ## Overview
- ## 🧠 Self-Learning Protocol (v3.0.0-alpha.1)
- ### Before Each Review: Learn from Past Reviews
- ### During Review: GNN-Enhanced Code Analysis
- ### Multi-Agent Review Coordination with Attention
- ### After Review: Store Learning Patterns
- ## 🎯 GitHub-Specific Review Optimizations
- ### Pattern-Based Issue Detection
- ### GNN-Enhanced Similar Code Search
- ### Attention-Based Review Focus
- ## Core Features
- ### 1. Multi-Agent Review System
- # Initialize code review swarm with gh CLI
- # Get PR details
- # Initialize swarm with PR context
- # Post initial review status
- ### 2. Specialized Review Agents
- #### Security Agent
- # Security-focused review with gh CLI
- # Get changed files
- # Run security review
- # Post security findings
- ## 📈 Performance Targets
- ## 🔧 Implementation Examples
- ### Example: Security Review with Learning

### .\.claude\agents\github\github-modes.md

**Headings:**
- # GitHub Integration Modes
- ## Overview
- ## GitHub Workflow Modes
- ### gh-coordinator
- ### pr-manager
- ### issue-tracker
- ### release-manager
- ## Repository Management Modes
- ### repo-architect
- ### code-reviewer
- ### branch-manager
- ## Integration Commands
- ### sync-coordinator
- ### ci-orchestrator
- ### security-guardian
- ## Usage Examples
- ### Creating a coordinated pull request workflow:
- ### Managing repository synchronization:
- ### Setting up automated issue tracking:
- ## Batch Operations
- ### Parallel GitHub Operations Example:
- ## Integration with ruv-swarm

### .\.claude\agents\github\issue-tracker.md

**Headings:**
- # GitHub Issue Tracker
- ## Purpose
- ## Core Capabilities
- ## 🧠 Self-Learning Protocol (v3.0.0-alpha.1)
- ### Before Issue Triage: Learn from History
- ### During Triage: GNN-Enhanced Issue Search
- ### Multi-Agent Priority Ranking with Attention
- ### After Resolution: Store Learning Patterns
- ## 🎯 GitHub-Specific Optimizations
- ### Smart Issue Classification
- ### Attention-Based Priority Ranking
- ### GNN-Enhanced Duplicate Detection
- ## Tools Available
- ## Usage Patterns
- ### 1. Create Coordinated Issue with Swarm Tracking
- ### 2. Automated Progress Updates
- ### 3. Multi-Issue Project Coordination
- ## Batch Operations Example
- ### Complete Issue Management Workflow:
- ## Smart Issue Templates
- ### Integration Issue Template:
- ## 🔄 Integration Task
- ### Overview
- ### Objectives
- ### Integration Areas
- #### Dependencies
- #### Functionality  
- #### Testing
- ### Swarm Coordination
- ### Progress Tracking
- ### Bug Report Template:
- ## 🐛 Bug Report
- ### Problem Description
- ### Expected Behavior
- ### Actual Behavior  
- ### Reproduction Steps
- ### Environment
- ### Investigation Plan
- ### Swarm Assignment
- ## Best Practices
- ### 1. **Swarm-Coordinated Issue Management**
- ### 2. **Automated Progress Tracking**
- ### 3. **Smart Labeling and Organization**
- ### 4. **Batch Issue Operations**
- ## Integration with Other Modes
- ### Seamless integration with:
- ## Metrics and Analytics
- ### Automatic tracking of:
- ### Reporting features:

### .\.claude\agents\github\multi-repo-swarm.md

**Headings:**
- # Multi-Repo Swarm - Cross-Repository Swarm Orchestration
- ## Overview
- ## Core Features
- ### 1. Cross-Repo Initialization
- # Initialize multi-repo swarm with gh CLI
- # List organization repositories
- # Get repository details
- # Initialize swarm with repository context
- ### 2. Repository Discovery
- # Auto-discover related repositories with gh CLI
- # Search organization repositories
- # Analyze repository dependencies
- # Discover and analyze
- ### 3. Synchronized Operations
- # Execute synchronized changes across repos with gh CLI
- # Get matching repositories
- # Execute task and create PRs
- # Link related PRs
- ## Configuration
- ### Multi-Repo Config File
- # .swarm/multi-repo.yml
- ### Repository Roles
- ## Orchestration Commands
- ### Dependency Management
- # Update dependencies across all repos with gh CLI
- # Create tracking issue first
- # Get all repos with TypeScript
- # Update each repository
- ### Refactoring Operations
- # Coordinate large-scale refactoring
- ### Security Updates
- # Coordinate security patches
- ## Communication Strategies
- ### 1. Webhook-Based Coordination
- ### 2. GraphQL Federation
- # Federated schema for multi-repo queries
- ### 3. Event Streaming
- # Kafka configuration for real-time coordination
- ## Advanced Features
- ### 1. Distributed Task Queue
- # Create distributed task queue
- ### 2. Cross-Repo Testing
- # Run integration tests across repos
- ### 3. Monorepo Migration
- # Assist in monorepo migration
- ## Monitoring & Visualization
- ### Multi-Repo Dashboard
- # Launch monitoring dashboard
- ### Dependency Graph
- # Visualize repo dependencies
- ### Health Monitoring
- # Monitor swarm health across repos
- ## Synchronization Patterns
- ### 1. Eventually Consistent
- ### 2. Strong Consistency
- ### 3. Hybrid Approach
- ## Use Cases
- ### 1. Microservices Coordination
- # Coordinate microservices development
- ### 2. Library Updates
- # Update shared library across consumers
- ### 3. Organization-Wide Changes
- # Apply org-wide policy changes
- ## Best Practices
- ### 1. Repository Organization
- ### 2. Communication
- ### 3. Security
- ## Performance Optimization
- ### Caching Strategy
- # Implement cross-repo caching
- ### Parallel Execution
- # Optimize parallel operations
- ### Resource Pooling
- # Pool resources across repos
- ## Troubleshooting
- ### Connectivity Issues
- # Diagnose connectivity problems
- ### Memory Synchronization
- # Debug memory sync issues
- ### Performance Bottlenecks
- # Identify performance issues
- ## Examples
- ### Full-Stack Application Update
- # Update full-stack application
- ### Cross-Team Collaboration
- # Facilitate cross-team work

### .\.claude\agents\github\pr-manager.md

**Headings:**
- # GitHub PR Manager
- ## Purpose
- ## Core Capabilities
- ## 🧠 Self-Learning Protocol (v3.0.0-alpha.1)
- ### Before Each PR Task: Learn from History
- ### During PR Management: GNN-Enhanced Code Search
- ### Multi-Agent Coordination with Attention
- ### After PR Completion: Store Learning Patterns
- ## 🎯 GitHub-Specific Optimizations
- ### Smart Merge Decision Making
- ### Attention-Based Conflict Resolution
- ### GNN-Enhanced Review Coordination
- ## Usage Patterns
- ### 1. Create and Manage PR with Swarm Coordination
- ### 2. Automated Multi-File Review
- ### 3. Merge Coordination with Testing
- ## Batch Operations Example
- ### Complete PR Lifecycle in Parallel:
- ## Best Practices
- ### 1. **Always Use Swarm Coordination**
- ### 2. **Batch PR Operations**
- ### 3. **Intelligent Review Strategy**
- ### 4. **Progress Tracking**
- ## Integration with Other Modes
- ### Works seamlessly with:
- ## Error Handling
- ### Automatic retry logic for:
- ### Swarm coordination ensures:

### .\.claude\agents\github\project-board-sync.md

**Headings:**
- # Project Board Sync - GitHub Projects Integration
- ## Overview
- ## Core Features
- ### 1. Board Initialization
- # Connect swarm to GitHub Project using gh CLI
- # Get project details
- # Initialize swarm with project
- # Create project fields for swarm tracking
- ### 2. Task Synchronization
- # Sync swarm tasks with project cards
- ### 3. Real-time Updates
- # Enable real-time board updates
- ## Configuration
- ### Board Mapping Configuration
- # .github/board-sync.yml
- ### View Configuration
- ## Automation Features
- ### 1. Auto-Assignment
- # Automatically assign cards to agents
- ### 2. Progress Tracking
- # Track and visualize progress
- ### 3. Smart Card Movement
- # Intelligent card state transitions
- ## Board Commands
- ### Create Cards from Issues
- # Convert issues to project cards using gh CLI
- # List issues with label
- # Add issues to project
- # Process with swarm
- ### Bulk Operations
- # Bulk card operations
- ### Card Templates
- # Create cards from templates
- ## Advanced Synchronization
- ### 1. Multi-Board Sync
- # Sync across multiple boards
- ### 2. Cross-Organization Sync
- # Sync boards across organizations
- ### 3. External Tool Integration
- # Sync with external tools
- ## Visualization & Reporting
- ### Board Analytics
- # Generate board analytics using gh CLI data
- # Fetch project data
- # Get issue metrics
- # Generate analytics with swarm
- ### Custom Dashboards
- ### Reports
- # Generate reports
- ## Workflow Integration
- ### Sprint Management
- # Manage sprints with swarms
- ### Milestone Tracking
- # Track milestone progress
- ### Release Planning
- # Plan releases using board data
- ## Team Collaboration
- ### Work Distribution
- # Distribute work among team
- ### Standup Automation
- # Generate standup reports
- ### Review Coordination
- # Coordinate reviews via board
- ## Best Practices
- ### 1. Board Organization
- ### 2. Data Integrity
- ### 3. Team Adoption
- ## Troubleshooting
- ### Sync Issues
- # Diagnose sync problems
- ### Performance
- # Optimize board performance
- ### Data Recovery
- # Recover board data
- ## Examples
- ### Agile Development Board
- # Setup agile board
- ### Kanban Flow Board
- # Setup kanban board
- ### Research Project Board
- # Setup research board
- ## Metrics & KPIs
- ### Performance Metrics
- # Track board performance
- ### Team Metrics
- # Track team performance

### .\.claude\agents\github\release-manager.md

**Headings:**
- # GitHub Release Manager
- ## Purpose
- ## Core Capabilities
- ## 🧠 Self-Learning Protocol (v3.0.0-alpha.1)
- ### Before Release: Learn from Past Releases
- ### During Release: GNN-Enhanced Dependency Analysis
- ### Multi-Agent Go/No-Go Decision with Attention
- ### After Release: Store Learning Patterns
- ## 🎯 GitHub-Specific Optimizations
- ### Smart Deployment Strategy Selection
- ### Attention-Based Risk Assessment
- ### GNN-Enhanced Change Impact Analysis
- ## Usage Patterns
- ### 1. Coordinated Release Preparation
- ### 2. Multi-Package Version Coordination
- ## [1.0.72] - ${new Date().toISOString().split('T')[0]}
- ### Added
- ### Changed  
- ### Fixed
- ### 3. Automated Release Validation
- ### 🎯 Release Highlights
- ### 📦 Package Updates
- ### 🔧 Changes
- #### Added
- #### Changed
- #### Fixed
- ### ✅ Validation Results
- ### 🐝 Swarm Coordination
- ### 🎁 Ready for Deployment
- ## Batch Release Workflow
- ### Complete Release Pipeline:
- ## Release Strategies
- ### 1. **Semantic Versioning Strategy**
- ### 2. **Multi-Stage Validation**
- ### 3. **Rollback Strategy**
- ## Best Practices
- ### 1. **Comprehensive Testing**
- ### 2. **Documentation Management**
- ### 3. **Deployment Coordination**
- ### 4. **Version Management**
- ## Integration with CI/CD
- ### GitHub Actions Integration:
- ## Monitoring and Metrics
- ### Release Quality Metrics:
- ### Automated Monitoring:

### .\.claude\agents\github\release-swarm.md

**Headings:**
- # Release Swarm - Intelligent Release Automation
- ## Overview
- ## Core Features
- ### 1. Release Planning
- # Plan next release using gh CLI
- # Get commit history since last release
- # Get merged PRs
- # Plan release with commit analysis
- ### 2. Automated Versioning
- # Smart version bumping
- ### 3. Release Orchestration
- # Full release automation with gh CLI
- # Generate changelog from PRs and commits
- # Create release draft
- # Run release orchestration
- # Publish release after validation
- # Create announcement issue
- ## Release Configuration
- ### Release Config File
- # .github/release-swarm.yml
- ## Release Agents
- ### Changelog Agent
- # Generate intelligent changelog with gh CLI
- # Get all merged PRs between versions
- # Get contributors
- # Get commit messages
- # Generate categorized changelog
- # Save changelog
- # Create PR with changelog update
- ### Version Agent
- # Determine next version
- ### Build Agent
- # Coordinate multi-platform builds
- ### Test Agent
- # Pre-release testing
- ### Deploy Agent
- # Multi-target deployment
- ## Advanced Features
- ### 1. Progressive Deployment
- # Staged rollout configuration
- ### 2. Multi-Repo Releases
- # Coordinate releases across repos
- ### 3. Hotfix Automation
- # Emergency hotfix process
- ## Release Workflows
- ### Standard Release Flow
- # .github/workflows/release.yml
- ### Continuous Deployment
- # Automated deployment pipeline
- ## Release Validation
- ### Pre-Release Checks
- # Comprehensive validation
- ### Compatibility Testing
- # Test backward compatibility
- ### Security Scanning
- # Security validation
- ## Monitoring & Rollback
- ### Release Monitoring
- # Monitor release health
- ### Automated Rollback
- # Configure auto-rollback
- ### Release Analytics
- # Analyze release performance
- ## Documentation
- ### Auto-Generated Docs
- # Update documentation
- ### Release Notes
- # Release v2.0.0
- ## 🎉 Highlights
- ## 🚀 Features
- ### Feature Name (#PR)
- ## 🐛 Bug Fixes
- ### Fixed issue with... (#PR)
- ## 💥 Breaking Changes
- ### API endpoint renamed
- ## 📈 Performance Improvements
- ## 🔒 Security Updates
- ## 📚 Documentation
- ## 🙏 Contributors
- ## Best Practices
- ### 1. Release Planning
- ### 2. Automation
- ### 3. Documentation
- ## Integration Examples
- ### NPM Package Release
- # NPM package release
- ### Docker Image Release
- # Docker multi-arch release
- ### Mobile App Release
- # Mobile app store release
- ## Emergency Procedures
- ### Hotfix Process
- # Emergency hotfix
- ### Rollback Procedure
- # Immediate rollback

### .\.claude\agents\github\repo-architect.md

**Headings:**
- # GitHub Repository Architect
- ## Purpose
- ## Capabilities
- ## Usage Patterns
- ### 1. Repository Structure Analysis and Optimization
- ### 2. Multi-Repository Template Creation
- ## Quick Start
- ## Features
- ## Documentation
- ### 3. Cross-Repository Synchronization
- ## Batch Architecture Operations
- ### Complete Repository Architecture Optimization:
- ## Architecture Patterns
- ### 1. **Monorepo Structure Pattern**
- ### 2. **Command Structure Pattern**
- ### 3. **Integration Pattern**
- ## Best Practices
- ### 1. **Structure Optimization**
- ### 2. **Template Management**
- ### 3. **Multi-Repository Coordination**
- ### 4. **Documentation Architecture**
- ## Monitoring and Analysis
- ### Architecture Health Metrics:
- ### Automated Analysis:
- ## Integration with Development Workflow
- ### Seamless integration with:
- ### Workflow Enhancement:

### .\.claude\agents\github\swarm-issue.md

**Headings:**
- # Swarm Issue - Issue-Based Swarm Coordination
- ## Overview
- ## Core Features
- ### 1. Issue-to-Swarm Conversion
- # Create swarm from issue using gh CLI
- # Get issue details
- # Create swarm from issue
- # Batch process multiple issues
- # Update issues with swarm status
- ### 2. Issue Comment Commands
- ### 3. Issue Templates for Swarms
- ## Issue Label Automation
- ### Auto-Label Based on Content
- ### Dynamic Agent Assignment
- # Assign agents based on issue content
- ## Issue Swarm Commands
- ### Initialize from Issue
- # Create swarm with full issue context using gh CLI
- # Get complete issue data
- # Get referenced issues and PRs
- # Initialize swarm
- # Add swarm initialization comment
- ### Task Decomposition
- # Break down issue into subtasks with gh CLI
- # Get issue body
- # Decompose into subtasks
- # Update issue with checklist
- ## Subtasks
- # Create linked issues for major subtasks
- ### Progress Tracking
- # Update issue with swarm progress using gh CLI
- # Get current issue state
- # Get swarm progress
- # Update checklist in issue body
- # Edit issue with updated body
- # Post progress summary as comment
- ### Completed Tasks
- ### In Progress
- ### Remaining
- # Update labels based on progress
- ## Advanced Features
- ### 1. Issue Dependencies
- # Handle issue dependencies
- ### 2. Epic Management
- # Coordinate epic-level swarms
- ### 3. Issue Templates
- # Generate issue from swarm analysis
- ## Workflow Integration
- ### GitHub Actions for Issues
- # .github/workflows/issue-swarm.yml
- ### Issue Board Integration
- # Sync with project board
- ## Issue Types & Strategies
- ### Bug Reports
- # Specialized bug handling
- ### Feature Requests
- # Feature implementation swarm
- ### Technical Debt
- # Refactoring swarm
- ## Automation Examples
- ### Auto-Close Stale Issues
- # Process stale issues with swarm using gh CLI
- # Find stale issues
- # Analyze each stale issue
- # Close issues that have been stale for 37+ days
- ### Issue Triage
- # Automated triage system
- ### Duplicate Detection
- # Find duplicate issues
- ## Integration Patterns
- ### 1. Issue-PR Linking
- # Link issues to PRs automatically
- ### 2. Milestone Coordination
- # Coordinate milestone swarms
- ### 3. Cross-Repo Issues
- # Handle issues across repositories
- ## Metrics & Analytics
- ### Issue Resolution Time
- # Analyze swarm performance
- ### Swarm Effectiveness
- # Generate effectiveness report
- ## Best Practices
- ### 1. Issue Templates
- ### 2. Label Strategy
- ### 3. Comment Etiquette
- ## Security & Permissions
- ## Examples
- ### Complex Bug Investigation
- # Issue #789: Memory leak in production
- ### Feature Implementation
- # Issue #234: Add OAuth integration
- ### Documentation Update
- # Issue #567: Update API documentation
- ## Swarm Coordination Features
- ### Multi-Agent Issue Processing
- # Initialize issue-specific swarm with optimal topology
- # Store issue context in swarm memory
- # Orchestrate issue resolution workflow
- ### Automated Swarm Hooks Integration

### .\.claude\agents\github\swarm-pr.md

**Headings:**
- # Swarm PR - Managing Swarms through Pull Requests
- ## Overview
- ## Core Features
- ### 1. PR-Based Swarm Creation
- # Create swarm from PR description using gh CLI
- # Auto-spawn agents based on PR labels
- # Create swarm with PR context
- ### 2. PR Comment Commands
- ### 3. Automated PR Workflows
- # .github/workflows/swarm-pr.yml
- ## PR Label Integration
- ### Automatic Agent Assignment
- ### Label-Based Topology
- # Small PR (< 100 lines): ring topology
- # Medium PR (100-500 lines): mesh topology  
- # Large PR (> 500 lines): hierarchical topology
- ## PR Swarm Commands
- ### Initialize from PR
- # Create swarm with PR context using gh CLI
- ### Progress Updates
- # Post swarm progress to PR using gh CLI
- # Update PR labels based on progress
- ### Code Review Integration
- # Create review agents with gh CLI integration
- # Run swarm review
- # Post review comments using gh CLI
- ## Advanced Features
- ### 1. Multi-PR Swarm Coordination
- # Coordinate swarms across related PRs
- ### 2. PR Dependency Analysis
- # Analyze PR dependencies
- ### 3. Automated PR Fixes
- # Auto-fix PR issues
- ## Best Practices
- ### 1. PR Templates
- ## Swarm Configuration
- ## Tasks for Swarm
- ### 2. Status Checks
- # Require swarm completion before merge
- ### 3. PR Merge Automation
- # Auto-merge when swarm completes using gh CLI
- # Check swarm completion status
- ## Webhook Integration
- ### Setup Webhook Handler
- ## Examples
- ### Feature Development PR
- # PR #456: Add user authentication
- ### Bug Fix PR
- # PR #789: Fix memory leak
- ### Documentation PR
- # PR #321: Update API docs
- ## Metrics & Reporting
- ### PR Swarm Analytics
- # Generate PR swarm report
- ### Dashboard Integration
- # Export to GitHub Insights
- ## Security Considerations
- ## Integration with Claude Code
- ## Advanced Swarm PR Coordination
- ### Multi-Agent PR Analysis
- # Initialize PR-specific swarm with intelligent topology selection
- # Store PR context for swarm coordination
- # Orchestrate comprehensive PR workflow
- ### Swarm-Coordinated PR Lifecycle
- ### Intelligent PR Merge Coordination
- # Coordinate merge decision with swarm consensus
- # Analyze merge readiness with multiple agents
- # Store merge decision context

### .\.claude\agents\github\sync-coordinator.md

**Headings:**
- # GitHub Sync Coordinator
- ## Purpose
- ## Capabilities
- ## Tools Available
- ## Usage Patterns
- ### 1. Synchronize Package Dependencies
- ### 2. Documentation Synchronization
- ### 3. Cross-Package Feature Integration
- ### Features Added
- ### Integration Points
- ### Testing
- ### Swarm Coordination
- ## Batch Synchronization Example
- ### Complete Package Sync Workflow:
- ## Synchronization Strategies
- ### 1. **Version Alignment Strategy**
- ### 2. **Documentation Sync Pattern**
- ### 3. **Integration Testing Matrix**
- ## Best Practices
- ### 1. **Atomic Synchronization**
- ### 2. **Version Management**
- ### 3. **Documentation Consistency**
- ### 4. **Testing Integration**
- ## Monitoring and Metrics
- ### Sync Quality Metrics:
- ### Automated Reporting:
- ## Advanced Swarm Synchronization Features
- ### Multi-Agent Coordination Architecture
- # Initialize comprehensive synchronization swarm
- # Orchestrate complex synchronization workflow
- # Load balance synchronization tasks across agents
- ### Intelligent Conflict Resolution
- ### Comprehensive Synchronization Metrics
- # Store detailed synchronization metrics
- ## Error Handling and Recovery
- ### Swarm-Coordinated Error Recovery
- # Initialize error recovery swarm
- # Coordinate recovery procedures
- # Store recovery state
- ### Automatic handling of:
- ### Recovery procedures:

### .\.claude\agents\github\workflow-automation.md

**Headings:**
- # Workflow Automation - GitHub Actions Integration
- ## Overview
- ## 🧠 Self-Learning Protocol (v3.0.0-alpha.1)
- ### Before Workflow Creation: Learn from Past Workflows
- ### During Workflow Execution: GNN-Enhanced Optimization
- ### Multi-Agent Workflow Optimization with Attention
- ### After Workflow Run: Store Learning Patterns
- ## 🎯 GitHub-Specific Optimizations
- ### Pattern-Based Workflow Generation
- ### Attention-Based Job Prioritization
- ### GNN-Enhanced Failure Prediction
- ### Adaptive Workflow Learning
- ## Core Features
- ### 1. Swarm-Powered Actions
- # .github/workflows/swarm-ci.yml
- ### 2. Dynamic Workflow Generation
- # Generate workflows based on code analysis
- ### 3. Intelligent Test Selection
- # Smart test runner
- ## Workflow Templates
- ### Multi-Language Detection
- # .github/workflows/polyglot-swarm.yml
- ### Adaptive Security Scanning
- # .github/workflows/security-swarm.yml
- ## Action Commands
- ### Pipeline Optimization
- # Optimize existing workflows
- ### Failure Analysis
- # Analyze failed runs using gh CLI
- # Create issue for persistent failures
- ### Resource Management
- # Optimize resource usage
- ## Advanced Workflows
- ### 1. Self-Healing CI/CD
- # Auto-fix common CI failures
- ### 2. Progressive Deployment
- # Intelligent deployment strategy
- ### 3. Performance Regression Detection
- # Automatic performance testing
- ## Custom Actions
- ### Swarm Action Development
- ## Matrix Strategies
- ### Dynamic Test Matrix
- # Generate test matrix from code analysis
- ### Intelligent Parallelization
- # Determine optimal parallelization
- ## Monitoring & Insights
- ### Workflow Analytics
- # Analyze workflow performance
- ### Cost Optimization
- # Optimize GitHub Actions costs
- ### Failure Patterns
- # Identify failure patterns
- ## Integration Examples
- ### 1. PR Validation Swarm
- ### 2. Release Automation
- ### 3. Documentation Updates
- ## Best Practices
- ### 1. Workflow Organization
- ### 2. Security
- ### 3. Performance
- ## Advanced Features
- ### Predictive Failures
- # Predict potential failures
- ### Workflow Recommendations
- # Get workflow recommendations
- ### Automated Optimization
- # Continuously optimize workflows
- ## Debugging & Troubleshooting
- ### Debug Mode
- ### Performance Profiling
- # Profile workflow performance
- ## Advanced Swarm Workflow Automation
- ### Multi-Agent Pipeline Orchestration
- # Initialize comprehensive workflow automation swarm
- # Create intelligent workflow automation rules
- # Orchestrate adaptive workflow management
- ### Intelligent Performance Monitoring
- # Generate comprehensive workflow performance reports
- # Analyze workflow bottlenecks with swarm intelligence
- # Store performance insights in swarm memory
- ### Dynamic Workflow Generation
- ### Continuous Learning and Optimization
- # Implement continuous workflow learning
- # Generate workflow optimization recommendations

### .\.claude\agents\goal\agent.md

**Headings:**
- ## Core Capabilities
- ### 🧠 Dynamic Goal Decomposition
- ### ⚡ Sublinear Optimization
- ### 🎯 Intelligent Prioritization
- ### 🔮 Predictive Planning
- ### 🤝 Multi-Agent Coordination
- ## Primary Tools
- ### Sublinear-Time Solver Tools
- ### Claude Flow Integration Tools
- ## Workflow
- ### 1. State Space Modeling
- ### 2. Action Graph Construction
- ### 3. Goal Prioritization with PageRank
- ### 4. Temporal Advantage Planning
- ### 5. A* Search with Sublinear Optimization
- ## 🌐 Multi-Agent Coordination
- ### Swarm-Based Planning
- ### Consensus-Based Decision Making
- ## 🎯 Advanced Planning Workflows
- ### 1. Hierarchical Goal Decomposition
- ### 2. Dynamic Replanning
- ### 3. Learning from Execution
- ## 🎮 Gaming AI Integration
- ### Behavior Tree Implementation
- ### Utility-Based Action Selection
- ## Usage Examples
- ### Example 1: Complex Project Planning
- ### Example 2: Resource Allocation Optimization
- ### Example 3: Predictive Action Planning
- ### Example 4: Multi-Agent Goal Coordination
- ### Example 5: Adaptive Replanning
- ## Best Practices
- ### When to Use GOAP
- ### Goal Structure Optimization
- ### Integration with Other Agents
- ### Performance Optimization
- ### Error Handling & Resilience
- ### Monitoring & Adaptation
- ## 🔧 Advanced Configuration
- ### Customizing Planning Parameters
- ### Error Handling and Recovery
- ## Advanced Features
- ### Temporal Computational Advantage
- ### Matrix-Based Goal Modeling
- ### Creative Solution Discovery

### .\.claude\agents\goal\goal-planner.md

**Headings:**
- ## MCP Integration Examples

### .\.claude\agents\optimization\benchmark-suite.md

**Headings:**
- # Benchmark Suite Agent
- ## Agent Profile
- ## Core Capabilities
- ### 1. Comprehensive Benchmarking Framework
- ### 2. Performance Regression Detection
- ### 3. Automated Performance Testing
- ### 4. Performance Validation Framework
- ## MCP Integration Hooks
- ### Benchmark Execution Integration
- ## Operational Commands
- ### Benchmarking Commands
- # Run comprehensive benchmark suite
- # Execute specific benchmark
- # Compare with baseline
- # Quality assessment
- # Performance validation
- ### Regression Detection Commands
- # Detect performance regressions
- # Set up automated regression monitoring
- # Analyze error patterns
- ## Integration Points
- ### With Other Optimization Agents
- ### With CI/CD Pipeline
- ## Performance Benchmarks
- ### Standard Benchmark Suite

### .\.claude\agents\optimization\load-balancer.md

**Headings:**
- # Load Balancing Coordinator Agent
- ## Agent Profile
- ## Core Capabilities
- ### 1. Work-Stealing Algorithms
- ### 2. Dynamic Load Balancing
- ### 3. Queue Management & Prioritization
- ### 4. Resource Allocation Optimization
- ## MCP Integration Hooks
- ### Performance Monitoring Integration
- ## Advanced Scheduling Algorithms
- ### 1. Earliest Deadline First (EDF)
- ### 2. Completely Fair Scheduler (CFS)
- ## Performance Optimization Features
- ### Circuit Breaker Pattern
- ## Operational Commands
- ### Load Balancing Commands
- # Initialize load balancer
- # Start load balancing
- # Monitor load distribution
- # Adjust balancing parameters
- ### Performance Monitoring
- # Real-time load monitoring
- # Bottleneck analysis
- # Resource utilization tracking
- ## Integration Points
- ### With Other Optimization Agents
- ### With Swarm Infrastructure
- ## Performance Metrics
- ### Key Performance Indicators
- ### Benchmarking

### .\.claude\agents\optimization\performance-monitor.md

**Headings:**
- # Performance Monitor Agent
- ## Agent Profile
- ## Core Capabilities
- ### 1. Real-Time Metrics Collection
- ### 2. Bottleneck Detection & Analysis
- ### 3. SLA Monitoring & Alerting
- ### 4. Resource Utilization Tracking
- ## MCP Integration Hooks
- ### Performance Data Collection
- ### Anomaly Detection
- ## Dashboard Integration
- ### Real-Time Performance Dashboard
- ## Operational Commands
- ### Monitoring Commands
- # Start comprehensive monitoring
- # Real-time bottleneck analysis
- # Health check all components
- # Collect specific metrics
- # Monitor SLA compliance
- ### Alert Configuration
- # Configure performance alerts
- # Set up anomaly detection
- # Configure notification channels
- ## Integration Points
- ### With Other Optimization Agents
- ### With Swarm Infrastructure
- ## Performance Analytics
- ### Key Metrics Dashboard

### .\.claude\agents\optimization\resource-allocator.md

**Headings:**
- # Resource Allocator Agent
- ## Agent Profile
- ## Core Capabilities
- ### 1. Adaptive Resource Allocation
- ### 2. Predictive Scaling with Machine Learning
- ### 3. Circuit Breaker and Fault Tolerance
- ### 4. Performance Profiling and Optimization
- ## MCP Integration Hooks
- ### Resource Management Integration
- ## Operational Commands
- ### Resource Management Commands
- # Analyze resource usage
- # Optimize resource allocation
- # Predictive scaling
- # Performance profiling
- # Circuit breaker configuration
- ### Optimization Commands
- # Run performance optimization
- # Generate resource forecasts
- # Profile system performance
- # Analyze bottlenecks
- ## Integration Points
- ### With Other Optimization Agents
- ### With Swarm Infrastructure
- ## Performance Metrics
- ### Resource Allocation KPIs

### .\.claude\agents\optimization\topology-optimizer.md

**Headings:**
- # Topology Optimizer Agent
- ## Agent Profile
- ## Core Capabilities
- ### 1. Dynamic Topology Reconfiguration
- ### 2. Network Latency Optimization
- ### 3. Agent Placement Strategies
- ### 4. Communication Pattern Optimization
- ## MCP Integration Hooks
- ### Topology Management Integration
- ### Neural Network Integration
- ## Advanced Optimization Algorithms
- ### 1. Genetic Algorithm for Topology Evolution
- ### 2. Simulated Annealing for Topology Optimization
- ## Operational Commands
- ### Topology Optimization Commands
- # Analyze current topology
- # Optimize topology automatically
- # Compare topology configurations
- # Generate topology recommendations
- # Monitor topology performance
- ### Agent Placement Commands
- # Optimize agent placement
- # Analyze placement efficiency
- # Generate placement recommendations
- ## Integration Points
- ### With Other Optimization Agents
- ### With Swarm Infrastructure
- ## Performance Metrics
- ### Topology Performance Indicators

### .\.claude\agents\payments\agentic-payments.md

**Headings:**


### .\.claude\agents\sona\sona-learning-optimizer.md

**Headings:**
- # SONA Learning Optimizer
- ## Overview
- ## Core Capabilities
- ### 1. Adaptive Learning
- ### 2. Pattern Discovery
- ### 3. LoRA Fine-Tuning
- ### 4. LLM Routing
- ## Performance Characteristics
- ### Throughput
- ### Quality Improvements by Domain
- ## Hooks
- # Pre-task: Initialize trajectory
- # Post-task: Record outcome
- ## References

### .\.claude\agents\sparc\architecture.md

**Headings:**
- # SPARC Architecture Agent
- ## 🧠 Self-Learning Protocol for Architecture
- ### Before System Design: Learn from Past Architectures
- ### During Architecture Design: Flash Attention for Large Docs
- ### GNN Search for Similar System Designs
- ### After Architecture Design: Store Learning Patterns
- ## 🏗️ Architecture Pattern Library
- ### Learn Architecture Patterns by Scale
- ### Cross-Phase Coordination with Hierarchical Attention
- ## ⚡ Performance Optimization Examples
- ### Before: Typical architecture design (baseline)
- ### After: Self-learning architecture (v3.0.0-alpha.1)
- ## SPARC Architecture Phase
- ## System Architecture Design
- ### 1. High-Level Architecture
- ### 2. Component Architecture
- ### 3. Data Architecture
- ### 4. API Architecture
- ### 5. Infrastructure Architecture
- # Kubernetes Deployment Architecture
- ### 6. Security Architecture
- ### 7. Scalability Design
- ## Architecture Deliverables
- ## Best Practices

### .\.claude\agents\sparc\pseudocode.md

**Headings:**
- # SPARC Pseudocode Agent
- ## 🧠 Self-Learning Protocol for Algorithms
- ### Before Algorithm Design: Learn from Similar Implementations
- ### During Algorithm Design: GNN-Enhanced Pattern Search
- ### After Algorithm Design: Store Learning Patterns
- ## ⚡ Attention-Based Algorithm Selection
- ## 🎯 SPARC-Specific Algorithm Optimizations
- ### Learn Algorithm Patterns by Domain
- ### Cross-Phase Coordination
- ## SPARC Pseudocode Phase
- ## Pseudocode Standards
- ### 1. Structure and Syntax
- ### 2. Data Structure Selection
- ### 3. Algorithm Patterns
- ### 4. Complex Algorithm Design
- ### 5. Complexity Analysis
- ## Design Patterns in Pseudocode
- ### 1. Strategy Pattern
- ### 2. Observer Pattern
- ## Pseudocode Best Practices
- ## Deliverables

### .\.claude\agents\sparc\refinement.md

**Headings:**
- # SPARC Refinement Agent
- ## 🧠 Self-Learning Protocol for Refinement
- ### Before Refinement: Learn from Past Refactorings
- ### During Refinement: GNN-Enhanced Code Pattern Search
- ### After Refinement: Store Learning Patterns with Metrics
- ## 🧪 Test-Driven Refinement with Learning
- ### Red-Green-Refactor with Pattern Memory
- ### Performance Optimization with Flash Attention
- ## 📊 Continuous Improvement Metrics
- ### Track Refinement Progress Over Time
- ## ⚡ Performance Examples
- ### Before: Traditional refinement
- ### After: Self-learning refinement (v3.0.0-alpha.1)
- ## 🎯 SPARC-Specific Refinement Optimizations
- ### Cross-Phase Test Alignment
- ## SPARC Refinement Phase
- ## TDD Refinement Process
- ### 1. Red Phase - Write Failing Tests
- ### 2. Green Phase - Make Tests Pass
- ### 3. Refactor Phase - Improve Code Quality
- ## Performance Refinement
- ### 1. Identify Bottlenecks
- ### 2. Optimize Hot Paths
- ## Error Handling Refinement
- ### 1. Comprehensive Error Handling
- ### 2. Retry Logic and Circuit Breakers
- ## Quality Metrics
- ### 1. Code Coverage
- # Jest configuration for coverage
- ### 2. Complexity Analysis
- ## Best Practices

### .\.claude\agents\sparc\specification.md

**Headings:**
- # SPARC Specification Agent
- ## 🧠 Self-Learning Protocol for Specifications
- ### Before Each Specification: Learn from History
- ### During Specification: Enhanced Context Retrieval
- ### After Specification: Store Learning Patterns
- ## 📈 Specification Quality Metrics
- ## 🎯 SPARC-Specific Learning Optimizations
- ### Pattern-Based Requirement Analysis
- ### GNN Search for Similar Requirements
- ### Cross-Phase Coordination with Attention
- ## SPARC Specification Phase
- ## Specification Process
- ### 1. Requirements Gathering
- ### 2. Constraint Analysis
- ### 3. Use Case Definition
- ### 4. Acceptance Criteria
- ## Specification Deliverables
- ### 1. Requirements Document
- # System Requirements Specification
- ## 1. Introduction
- ### 1.1 Purpose
- ### 1.2 Scope
- ### 1.3 Definitions
- ## 2. Functional Requirements
- ### 2.1 Authentication
- ### 2.2 Authorization
- ## 3. Non-Functional Requirements
- ### 3.1 Performance
- ### 3.2 Security
- ### 2. Data Model Specification
- ### 3. API Specification
- ## Validation Checklist
- ## Best Practices

### .\.claude\agents\specialized\spec-mobile-react-native.md

**Headings:**
- # React Native Mobile Developer
- ## Key responsibilities:
- ## Best practices:
- ## Component patterns:
- ## Platform-specific considerations:

### .\.claude\agents\specialized\mobile\spec-mobile-react-native.md

**Headings:**
- # React Native Mobile Developer
- ## Key responsibilities:
- ## Best practices:
- ## Component patterns:
- ## Platform-specific considerations:

### .\.claude\agents\sublinear\consensus-coordinator.md

**Headings:**
- ## Core Capabilities
- ### Consensus Protocols
- ### Distributed Coordination
- ### Primary MCP Tools
- ## Usage Scenarios
- ### 1. Byzantine Fault Tolerant Consensus
- ### 2. Distributed Voting System
- ### 3. Multi-Agent Coordination
- ## Integration with Claude Flow
- ### Swarm Consensus Protocols
- ### Hierarchical Consensus
- ## Integration with Flow Nexus
- ### Distributed Consensus Infrastructure
- ### Blockchain Consensus Integration
- ## Advanced Consensus Algorithms
- ### Practical Byzantine Fault Tolerance (pBFT)
- ### Proof of Stake Consensus
- ### Hybrid Consensus Protocols
- ## Performance Optimization
- ### Scalability Techniques
- ### Latency Optimization
- ### Resource Optimization
- ## Fault Tolerance Mechanisms
- ### Byzantine Fault Tolerance
- ### Network Partition Tolerance
- ### Crash Fault Tolerance
- ## Integration Patterns
- ### With Matrix Optimizer
- ### With PageRank Analyzer
- ### With Performance Optimizer
- ## Example Workflows
- ### Enterprise Consensus Deployment
- ### Blockchain Network Setup
- ### Multi-Agent System Coordination

### .\.claude\agents\sublinear\matrix-optimizer.md

**Headings:**
- ## Core Capabilities
- ### Matrix Analysis
- ### Primary MCP Tools
- ## Usage Scenarios
- ### 1. Pre-Solver Matrix Analysis
- ### 2. Large-Scale System Optimization
- ### 3. Targeted Entry Estimation
- ## Integration with Claude Flow
- ### Swarm Coordination
- ### Performance Optimization
- ## Integration with Flow Nexus
- ### Sandbox Deployment
- ### Neural Network Integration
- ## Advanced Features
- ### Matrix Preprocessing
- ### Performance Monitoring
- ### Error Analysis
- ## Best Practices
- ### Matrix Preparation
- ### Performance Optimization
- ### Integration Guidelines
- ## Example Workflows
- ### Complete Matrix Optimization Pipeline
- ### Integration with Other Agents

### .\.claude\agents\sublinear\pagerank-analyzer.md

**Headings:**
- ## Core Capabilities
- ### Graph Analysis
- ### Network Optimization
- ### Primary MCP Tools
- ## Usage Scenarios
- ### 1. Large-Scale PageRank Computation
- ### 2. Personalized PageRank
- ### 3. Network Influence Analysis
- ## Integration with Claude Flow
- ### Swarm Topology Optimization
- ### Consensus Network Analysis
- ## Integration with Flow Nexus
- ### Distributed Graph Processing
- ### Neural Graph Networks
- ## Advanced Graph Algorithms
- ### Community Detection
- ### Network Dynamics
- ### Graph Machine Learning
- ## Performance Optimization
- ### Scalability Techniques
- ### Memory Optimization
- ### Computational Optimization
- ## Application Domains
- ### Social Network Analysis
- ### Web Search and Ranking
- ### Recommendation Systems
- ### Infrastructure Optimization
- ## Integration Patterns
- ### With Matrix Optimizer
- ### With Trading Predictor
- ### With Consensus Coordinator
- ## Example Workflows
- ### Social Media Influence Campaign
- ### Web Search Optimization
- ### Distributed System Design

### .\.claude\agents\sublinear\performance-optimizer.md

**Headings:**
- ## Core Capabilities
- ### Performance Analysis
- ### Optimization Strategies
- ### Primary MCP Tools
- ## Usage Scenarios
- ### 1. Resource Allocation Optimization
- ### 2. Load Balancing Optimization
- ### 3. Performance Bottleneck Analysis
- ## Integration with Claude Flow
- ### Swarm Performance Optimization
- ### Dynamic Performance Tuning
- ## Integration with Flow Nexus
- ### Cloud Performance Optimization
- ### Neural Performance Modeling
- ## Advanced Optimization Techniques
- ### Machine Learning-Based Optimization
- ### Multi-Objective Optimization
- ### Real-Time Optimization
- ## Performance Metrics and KPIs
- ### System Performance Metrics
- ### Application Performance Metrics
- ### Infrastructure Performance Metrics
- ## Optimization Strategies
- ### Algorithmic Optimization
- ### System-Level Optimization
- ### Application-Level Optimization
- ## Integration Patterns
- ### With Matrix Optimizer
- ### With Consensus Coordinator
- ### With Trading Predictor
- ## Example Workflows
- ### Cloud Infrastructure Optimization
- ### Application Performance Tuning
- ### System-Wide Performance Enhancement

### .\.claude\agents\sublinear\trading-predictor.md

**Headings:**
- ## Core Capabilities
- ### Temporal Advantage Trading
- ### Primary MCP Tools
- ## Usage Scenarios
- ### 1. High-Frequency Trading with Temporal Lead
- ### 2. Cross-Market Arbitrage
- ### 3. Real-Time Portfolio Optimization
- ## Integration with Claude Flow
- ### Multi-Agent Trading Swarms
- ### Consensus-Based Trading Decisions
- ## Integration with Flow Nexus
- ### Real-Time Trading Sandbox
- ### Neural Network Price Prediction
- ## Advanced Trading Strategies
- ### Latency Arbitrage
- ### Risk Management
- ### Market Making
- ## Performance Metrics
- ### Temporal Advantage Metrics
- ### Trading Performance
- ### System Performance
- ## Risk Management Framework
- ### Position Risk Controls
- ### Market Risk Controls
- ### Operational Risk Controls
- ## Integration Patterns
- ### With Matrix Optimizer
- ### With Performance Optimizer
- ### With Consensus Coordinator
- ## Example Trading Workflows
- ### Daily Trading Cycle
- ### Crisis Management

### .\.claude\agents\swarm\adaptive-coordinator.md

**Headings:**
- # Adaptive Swarm Coordinator
- ## Adaptive Architecture
- ## Core Intelligence Systems
- ### 1. Topology Adaptation Engine
- ### 2. Self-Organizing Coordination
- ### 3. Machine Learning Integration
- ## Topology Decision Matrix
- ### Workload Analysis Framework
- ### Topology Switching Conditions
- ## 🧠 Advanced Attention Mechanisms (v3.0.0-alpha.1)
- ### Dynamic Attention Mechanism Selection
- ### Usage Example: Adaptive Dynamic Coordination
- ### Self-Learning Integration (ReasoningBank)
- ## MCP Neural Integration
- ### Pattern Recognition & Learning
- # Analyze coordination patterns
- # Train adaptive models
- # Make predictions
- # Learn from outcomes
- ### Performance Optimization
- # Real-time performance monitoring
- # Bottleneck analysis
- # Automatic optimization
- # Load balancing optimization
- ### Predictive Scaling
- # Analyze usage trends
- # Predict resource needs
- # Auto-scale swarm
- ## Dynamic Adaptation Algorithms
- ### 1. Real-Time Topology Optimization
- ### 2. Intelligent Agent Allocation
- ### 3. Predictive Load Management
- ## Topology Transition Protocols
- ### Seamless Migration Process
- ### Rollback Mechanisms
- ## Performance Metrics & KPIs
- ### Adaptation Effectiveness
- ### System Efficiency
- ### Learning Progress
- ## Best Practices
- ### Adaptive Strategy Design
- ### Machine Learning Optimization
- ### System Monitoring

### .\.claude\agents\swarm\hierarchical-coordinator.md

**Headings:**
- # Hierarchical Swarm Coordinator
- ## Architecture Overview
- ## Core Responsibilities
- ### 1. Strategic Planning & Task Decomposition
- ### 2. Agent Supervision & Delegation
- ### 3. Coordination Protocol Management
- ## Specialized Worker Types
- ### Research Workers 🔬
- ### Code Workers 💻  
- ### Analyst Workers 📊
- ### Test Workers 🧪
- ## Coordination Workflow
- ### Phase 1: Planning & Strategy
- ### Phase 2: Execution & Monitoring
- ### Phase 3: Integration & Delivery
- ## 🧠 Advanced Attention Mechanisms (v3.0.0-alpha.1)
- ### Hyperbolic Attention for Hierarchical Coordination
- ### Usage Example: Hierarchical Coordination
- ### Self-Learning Integration (ReasoningBank)
- ## MCP Tool Integration
- ### Swarm Management
- # Initialize hierarchical swarm
- # Spawn specialized workers
- # Monitor swarm health
- ### Task Orchestration
- # Coordinate complex workflows
- # Load balance across workers
- # Sync coordination state
- ### Performance & Analytics
- # Generate performance reports
- # Analyze bottlenecks
- # Monitor resource usage
- ## Decision Making Framework
- ### Task Assignment Algorithm
- ### Escalation Protocols
- ## Communication Patterns
- ### Status Reporting
- ### Cross-Team Coordination
- ## Performance Metrics
- ### Coordination Effectiveness
- ### Quality Metrics
- ## Best Practices
- ### Efficient Delegation
- ### Performance Optimization

### .\.claude\agents\swarm\mesh-coordinator.md

**Headings:**
- # Mesh Network Swarm Coordinator
- ## Network Architecture
- ## Core Principles
- ### 1. Decentralized Coordination
- ### 2. Fault Tolerance & Resilience  
- ### 3. Collective Intelligence
- ## Network Communication Protocols
- ### Gossip Algorithm
- ### Consensus Building
- ### Peer Discovery
- ## Task Distribution Strategies
- ### 1. Work Stealing
- ### 2. Distributed Hash Table (DHT)
- ### 3. Auction-Based Assignment
- ## 🧠 Advanced Attention Mechanisms (v3.0.0-alpha.1)
- ### Multi-Head Attention for Peer-to-Peer Coordination
- ### Usage Example: Mesh Peer Coordination
- ### Self-Learning Integration (ReasoningBank)
- ## MCP Tool Integration
- ### Network Management
- # Initialize mesh network
- # Establish peer connections
- # Monitor network health
- ### Consensus Operations
- # Propose network-wide decision
- # Participate in voting
- # Monitor consensus status
- ### Fault Tolerance
- # Detect failed nodes
- # Trigger recovery procedures  
- # Update network topology
- ## Consensus Algorithms
- ### 1. Practical Byzantine Fault Tolerance (pBFT)
- ### 2. Raft Consensus
- ### 3. Gossip-Based Consensus
- ## Failure Detection & Recovery
- ### Heartbeat Monitoring
- ### Network Partitioning
- ## Load Balancing Strategies
- ### 1. Dynamic Work Distribution
- ### 2. Capability-Based Routing
- ## Performance Metrics
- ### Network Health
- ### Consensus Efficiency  
- ### Load Distribution
- ## Best Practices
- ### Network Design
- ### Consensus Optimization
- ### Fault Tolerance

### .\.claude\agents\templates\automation-smart-agent.md

**Headings:**
- # Smart Agent Coordinator
- ## Purpose
- ## Core Functionality
- ### 1. Intelligent Task Analysis
- ### 2. Capability Matching
- ### 3. Dynamic Agent Creation
- ### 4. Learning & Adaptation
- ## Automation Patterns
- ### 1. Task-Based Spawning
- ### 2. Workload-Based Scaling
- ### 3. Skill-Based Matching
- ## Intelligence Features
- ### 1. Predictive Spawning
- ### 2. Capability Learning
- ### 3. Resource Optimization
- ## Usage Examples
- ### Automatic Team Assembly
- ### Dynamic Scaling
- ### Intelligent Matching
- ## Integration Points
- ### With Task Orchestrator
- ### With Performance Analyzer
- ### With Memory Coordinator
- ## Machine Learning Integration
- ### 1. Task Classification
- ### 2. Agent Performance Prediction
- ### 3. Workload Forecasting
- ## Best Practices
- ### Effective Automation
- ### Common Pitfalls
- ## Advanced Features
- ### 1. Multi-Objective Optimization
- ### 2. Adaptive Strategies
- ### 3. Failure Recovery

### .\.claude\agents\templates\base-template-generator.md

**Headings:**
- ## 🧠 Self-Learning Protocol
- ### Before Generation: Learn from Successful Templates
- ### During Generation: GNN for Similar Project Search
- ### After Generation: Store Template Patterns
- ## 🎯 Domain-Specific Optimizations
- ### Pattern-Based Template Generation
- ### GNN-Enhanced Structure Search
- ## 🚀 Fast Template Generation

### .\.claude\agents\templates\coordinator-swarm-init.md

**Headings:**
- # Swarm Initializer Agent
- ## Purpose
- ## Core Functionality
- ### 1. Topology Selection
- ### 2. Resource Configuration
- ### 3. Communication Setup
- ## Usage Examples
- ### Basic Initialization
- ### Advanced Configuration
- ### Topology Optimization
- ## Integration Points
- ### Works With:
- ### Handoff Patterns:
- ## Best Practices
- ### Do:
- ### Don't:
- ## Error Handling

### .\.claude\agents\templates\github-pr-manager.md

**Headings:**
- # Pull Request Manager Agent
- ## Purpose
- ## Core Functionality
- ### 1. PR Creation & Management
- ### 2. Review Coordination
- ### 3. Merge Strategies
- ### 4. CI/CD Integration
- ## Usage Examples
- ### Simple PR Creation
- ### Complex Review Workflow
- ### Automated Merge
- ## Workflow Patterns
- ### 1. Standard Feature PR
- ### 2. Hotfix PR
- ### 3. Large Feature PR
- ## GitHub CLI Integration
- ### Common Commands
- # Create PR
- # Review PR
- # Check status
- # Merge PR
- ## Multi-Agent Coordination
- ### Review Swarm Setup
- ### Integration with Other Agents
- ## Best Practices
- ### PR Description Template
- ## Summary
- ## Motivation
- ## Changes
- ## Testing
- ## Checklist
- ### Review Coordination
- ## Error Handling
- ### Common Issues
- ### Recovery Strategies

### .\.claude\agents\templates\implementer-sparc-coder.md

**Headings:**
- # SPARC Implementation Specialist Agent
- ## Purpose
- ## Core Implementation Principles
- ### 1. Test-Driven Development (TDD)
- ### 2. Parallel Implementation
- ### 3. Code Quality Standards
- ## Implementation Workflow
- ### Phase 1: Test Creation (Red)
- ### Phase 2: Implementation (Green)
- ### Phase 3: Refinement (Refactor)
- ## Code Patterns
- ### 1. Service Implementation
- ### 2. API Route Pattern
- ### 3. Test Pattern
- ## Best Practices
- ### Code Organization
- ### Implementation Guidelines
- ## Integration Patterns
- ### With SPARC Coordinator
- ### With Testing Agents
- ### With Code Review Agents
- ## Performance Optimization
- ### 1. Algorithm Optimization
- ### 2. Database Optimization
- ### 3. API Optimization
- ## Error Handling Patterns
- ### 1. Graceful Degradation
- ### 2. Error Recovery
- ## Documentation Standards
- ### 1. Code Comments
- ### 2. README Updates

### .\.claude\agents\templates\memory-coordinator.md

**Headings:**
- # Memory Coordination Specialist Agent
- ## Purpose
- ## Core Functionality
- ### 1. Memory Operations
- ### 2. Namespace Management
- ### 3. Data Optimization
- ## Memory Patterns
- ### 1. Project Context
- ### 2. Agent Coordination
- ### 3. Learning & Patterns
- ## Usage Examples
- ### Storing Project Context
- ### Retrieving Past Decisions
- ### Cross-Session Continuity
- ## Integration Patterns
- ### With Task Orchestrator
- ### With SPARC Agents
- ### With Performance Analyzer
- ## Best Practices
- ### Effective Memory Usage
- ### Memory Hierarchies
- ## Advanced Features
- ### 1. Smart Retrieval
- ### 2. Memory Chains
- ### 3. Collaborative Memory
- ## Security & Privacy
- ### Data Protection
- ### Compliance
- ## Performance Optimization
- ### Caching Strategy
- ### Scalability

### .\.claude\agents\templates\orchestrator-task.md

**Headings:**
- # Task Orchestrator Agent
- ## Purpose
- ## Core Functionality
- ### 1. Task Decomposition
- ### 2. Execution Strategy
- ### 3. Progress Management
- ### 4. Result Synthesis
- ## Usage Examples
- ### Complex Feature Development
- ### Multi-Stage Processing
- ### Parallel Execution
- ## Task Patterns
- ### 1. Feature Development Pattern
- ### 2. Bug Fix Pattern
- ### 3. Refactoring Pattern
- ## Integration Points
- ### Upstream Agents:
- ### Downstream Agents:
- ### Monitoring Agents:
- ## Best Practices
- ### Effective Orchestration:
- ### Common Pitfalls:
- ## Advanced Features
- ### 1. Dynamic Re-planning
- ### 2. Multi-Level Orchestration
- ### 3. Intelligent Priority Management

### .\.claude\agents\templates\performance-analyzer.md

**Headings:**
- # Performance Bottleneck Analyzer Agent
- ## Purpose
- ## Analysis Capabilities
- ### 1. Bottleneck Types
- ### 2. Detection Methods
- ### 3. Optimization Strategies
- ## Analysis Workflow
- ### 1. Data Collection Phase
- ### 2. Analysis Phase
- ### 3. Recommendation Phase
- ## Common Bottleneck Patterns
- ### 1. Single Agent Overload
- ### 2. Sequential Task Chain
- ### 3. Resource Starvation
- ### 4. Communication Overhead
- ### 5. Inefficient Algorithms
- ## Integration Points
- ### With Orchestration Agents
- ### With Monitoring Agents
- ### With Optimization Agents
- ## Metrics and Reporting
- ### Key Performance Indicators
- ### Report Format
- ## Performance Analysis Report
- ### Executive Summary
- ### Detailed Findings
- ### Trend Analysis
- ## Optimization Examples
- ### Example 1: Slow Test Execution
- ### Example 2: Agent Coordination Delay
- ### Example 3: Memory Pressure
- ## Best Practices
- ### Continuous Monitoring
- ### Proactive Analysis
- ## Advanced Features
- ### 1. Predictive Analysis
- ### 2. Automated Optimization
- ### 3. A/B Testing

### .\.claude\agents\templates\sparc-coordinator.md

**Headings:**
- # SPARC Methodology Orchestrator Agent
- ## Purpose
- ## 🧠 Self-Learning Protocol for SPARC Coordination
- ### Before SPARC Cycle: Learn from Past Methodology Executions
- ### During SPARC Cycle: Hierarchical Coordination
- ### MoE Routing for Phase Specialist Selection
- ### After SPARC Cycle: Store Complete Methodology Learning
- ## 👑 Hierarchical SPARC Coordination Pattern
- ### Queen Level (Strategic Coordination)
- ### Worker Level (Phase Execution)
- ## 🎯 MoE Expert Routing for SPARC Phases
- ## ⚡ Cross-Phase Learning with Attention
- ## 📊 SPARC Cycle Improvement Tracking
- ## ⚡ Performance Benefits
- ### Before: Traditional SPARC coordination
- ### After: Self-learning SPARC coordination (v3.0.0-alpha.1)
- ## SPARC Phases Overview
- ### 1. Specification Phase
- ### 2. Pseudocode Phase
- ### 3. Architecture Phase
- ### 4. Refinement Phase
- ### 5. Completion Phase
- ## Orchestration Workflow
- ### Phase Transitions
- ### Quality Gates
- ## Agent Coordination
- ### Specialized SPARC Agents
- ### Parallel Execution Patterns
- ## Usage Examples
- ### Complete SPARC Cycle
- ### Specific Phase Focus
- ### Parallel Component Development
- ## Integration Patterns
- ### With Task Orchestrator
- ### With GitHub Agents
- ### With Testing Agents
- ## Best Practices
- ### Phase Execution
- ### Common Patterns
- ## Memory Integration
- ### Stored Artifacts
- ### Retrieval Patterns
- ## Success Metrics
- ### Phase Metrics
- ### Overall Metrics

### .\.claude\agents\testing\production-validator.md

**Headings:**
- # Production Validation Agent
- ## Core Responsibilities
- ## Validation Strategies
- ### 1. Implementation Completeness Check
- ### 2. Real Database Integration
- ### 3. External API Integration
- ### 4. Infrastructure Validation
- ### 5. Performance Under Load
- ## Validation Checklist
- ### 1. Code Quality Validation
- # No mock implementations in production code
- # No TODO/FIXME in critical paths
- # No hardcoded test data
- # No console.log statements
- ### 2. Environment Validation
- ### 3. Security Validation
- ### 4. Deployment Readiness
- ## Best Practices
- ### 1. Real Data Usage
- ### 2. Infrastructure Testing
- ### 3. Performance Validation
- ### 4. Security Testing

### .\.claude\agents\testing\tdd-london-swarm.md

**Headings:**
- # TDD London School Swarm Agent
- ## Core Responsibilities
- ## London School TDD Methodology
- ### 1. Outside-In Development Flow
- ### 2. Mock-First Approach
- ### 3. Behavior Verification Over State
- ## Swarm Coordination Patterns
- ### 1. Test Agent Collaboration
- ### 2. Contract Testing with Swarm
- ### 3. Mock Coordination
- ## Testing Strategies
- ### 1. Interaction Testing
- ### 2. Collaboration Patterns
- ### 3. Contract Evolution
- ## Swarm Integration
- ### 1. Test Coordination
- ### 2. Feedback Loops
- ### 3. Continuous Verification
- ## Best Practices
- ### 1. Mock Management
- ### 2. Contract Design
- ### 3. Swarm Collaboration

### .\.claude\agents\v3\adr-architect.md

**Headings:**
- # V3 ADR Architect Agent
- ## ADR Format (MADR 3.0)
- # ADR-{NUMBER}: {TITLE}
- ## Status
- ## Context
- ## Decision
- ## Consequences
- ### Positive
- ### Negative
- ### Neutral
- ## Options Considered
- ### Option 1: {Name}
- ### Option 2: {Name}
- ## Related Decisions
- ## References
- ## V3 Project ADRs
- ## Responsibilities
- ### 1. ADR Creation
- ### 2. Decision Tracking
- ### 3. Pattern Learning
- ### 4. Enforcement
- ## Commands
- # Create new ADR
- # List all ADRs
- # Search ADRs
- # Check ADR status
- # Supersede an ADR
- ## Memory Integration
- # Store ADR in memory
- # Search related ADRs
- # Get ADR details
- ## Decision Categories
- ## Workflow
- ## Integration with V3

### .\.claude\agents\v3\aidefence-guardian.md

**Headings:**
- # Dependencies
- # Auto-spawn configuration
- # AIDefence Guardian Agent
- ## Core Responsibilities
- ## Detection Capabilities
- ### Threat Types Detected
- ### Performance
- ## Usage
- ### Scanning Agent Input
- ### Multi-Agent Security Consensus
- ### Learning from Detections
- ## Integration Hooks
- ### Pre-Agent-Input Hook
- ### Swarm Coordination
- ## Escalation Protocol
- ## Collaboration
- ## Performance Metrics

### .\.claude\agents\v3\claims-authorizer.md

**Headings:**
- # V3 Claims Authorizer Agent
- ## Claims Architecture
- ## Claim Types
- ## Authorization Commands
- # Check if agent has permission
- # Grant claim to agent
- # Revoke claim
- # List agent claims
- ## Policy Definitions
- ### Role-Based Policies
- # coordinator-policy.yaml
- # worker-policy.yaml
- ### Attribute-Based Policies
- # security-agent-policy.yaml
- ## MCP Tool Authorization
- ## Hook Integration
- ## Audit Logging
- # Store authorization decision
- # Query audit log
- ## Default Policies
- ## Error Handling

### .\.claude\agents\v3\collective-intelligence-coordinator.md

**Headings:**
- # Collective Intelligence Coordinator
- ## Collective Architecture
- ## Core Responsibilities
- ### 1. Hive-Mind Collective Decision Making
- ### 2. Byzantine Fault-Tolerant Consensus
- ### 3. Attention-Based Agent Coordination
- ### 4. Memory Synchronization Protocols
- ## 🧠 Advanced Attention Mechanisms (V3)
- ### Collective Attention Framework
- ### Usage Example: Collective Intelligence Coordination
- ### Self-Learning Integration (ReasoningBank)
- ## MCP Tool Integration
- ### Collective Coordination Commands
- # Initialize hive-mind topology
- # Byzantine consensus protocol
- # CRDT synchronization
- # Attention-based coordination
- # Knowledge aggregation
- # Monitor collective health
- ### Memory Synchronization Commands
- # Initialize CRDT layer
- # Propagate deltas
- # Verify convergence
- # Backup collective state
- ### Neural Learning Commands
- # Train collective patterns
- # Pattern recognition
- # Predictive consensus
- # Learn from outcomes
- ## Consensus Mechanisms
- ### 1. Practical Byzantine Fault Tolerance (PBFT)
- ### 2. Attention-Weighted Voting
- ### 3. CRDT-Based Eventual Consistency
- ## Topology Integration
- ### Hierarchical-Mesh Hybrid
- ### Topology Switching
- ## Performance Metrics
- ### Collective Intelligence KPIs
- ### Health Monitoring
- # Collective health check
- # Performance report
- # Bottleneck analysis
- ## Best Practices
- ### 1. Consensus Building
- ### 2. Knowledge Aggregation
- ### 3. Memory Synchronization
- ### 4. Emergent Intelligence

### .\.claude\agents\v3\ddd-domain-expert.md

**Headings:**
- # V3 DDD Domain Expert Agent
- ## DDD Strategic Patterns
- ## Claude Flow V3 Bounded Contexts
- ## DDD Tactical Patterns
- ### Aggregate Design
- ### Domain Events
- ## Ubiquitous Language
- ## Context Mapping Patterns
- ## Event Storming Output
- ## Commands
- # Analyze domain model
- # Generate bounded context map
- # Validate aggregate design
- # Check ubiquitous language consistency
- ## Memory Integration
- # Store domain model
- # Search domain patterns

### .\.claude\agents\v3\injection-analyst.md

**Headings:**
- # Injection Analyst Agent
- ## Analysis Capabilities
- ### Attack Technique Classification
- ### Analysis Workflow
- ## Output Format
- ## Pattern Learning Integration
- ## Collaboration
- ## Reporting

### .\.claude\agents\v3\memory-specialist.md

**Headings:**
- # V3 Memory Specialist Agent
- ## Architecture Overview
- ## Core Responsibilities
- ### 1. HNSW Indexing Optimization (150x-12,500x Faster Search)
- ### 2. Hybrid Memory Backend (SQLite + AgentDB)
- ### 3. Vector Quantization (4-32x Memory Reduction)
- ### 4. Memory Consolidation and Cleanup
- ### 5. Cross-Session Persistence Patterns
- ### 6. Namespace Management and Isolation
- ### 7. Memory Sync Across Distributed Agents
- ### 8. EWC++ for Preventing Catastrophic Forgetting
- ### 9. Pattern Distillation and Compression
- ## MCP Tool Integration
- ### Memory Operations
- # Store with HNSW indexing
- # Semantic search with HNSW
- # Namespace management
- # Memory analytics
- # Memory compression
- # Cross-session persistence
- # Memory backup
- # Distributed sync
- ### CLI Commands
- # Initialize memory system
- # Memory health check
- # Search memories
- # Consolidate memories
- # Export/import namespaces
- # Memory statistics
- # Quantization
- ## Performance Targets
- ## Best Practices
- ### Memory Organization
- ### Memory Lifecycle
- ## Collaboration Points
- ## ADR References
- ### ADR-006: Unified Memory Service
- ### ADR-009: Hybrid Memory Backend

### .\.claude\agents\v3\performance-engineer.md

**Headings:**
- # V3 Performance Engineer Agent
- ## Overview
- ## V3 Performance Targets
- ## Core Capabilities
- ### 1. Flash Attention Optimization
- ### 2. WASM SIMD Acceleration
- ### 3. Performance Profiling & Bottleneck Detection
- ### 4. Token Usage Optimization (50-75% Reduction)
- ### 5. Latency Analysis & Optimization
- ### 6. Memory Footprint Reduction
- ### 7. Batch Processing Optimization
- ### 8. Parallel Execution Strategies
- ### 9. Benchmark Suite Integration
- ## MCP Integration
- ### Performance Monitoring via MCP
- ## CLI Integration
- ### Performance Commands
- # Run full benchmark suite
- # Profile specific component
- # Analyze bottlenecks
- # Generate performance report
- # Optimize specific area
- # Real-time metrics
- # WASM SIMD benchmark
- # Flash attention benchmark
- # Memory reduction analysis
- ## SONA Integration
- ### Adaptive Learning for Performance Optimization
- ## Best Practices
- ### Performance Optimization Checklist
- ## Integration Points
- ### With Other V3 Agents
- ### With Swarm Coordination

### .\.claude\agents\v3\pii-detector.md

**Headings:**
- # PII Detector Agent
- ## Detection Targets
- ### Personal Identifiable Information (PII)
- ### Credentials & Secrets
- ### Financial Data
- ## Usage
- ## Scanning Patterns
- ### API Key Patterns
- ### Password Patterns
- ## Remediation Recommendations
- ## Integration with Security Swarm
- ## Compliance Context

### .\.claude\agents\v3\reasoningbank-learner.md

**Headings:**
- # V3 ReasoningBank Learner Agent
- ## Intelligence Pipeline
- ## Pipeline Stages
- ### 1. RETRIEVE (HNSW Search)
- # Search patterns via HNSW
- # Get pattern statistics
- ### 2. JUDGE (Verdict Assignment)
- # Record trajectory step with outcome
- # End trajectory with final verdict
- ### 3. DISTILL (Pattern Extraction)
- # Store successful pattern
- # Search for patterns to distill
- ### 4. CONSOLIDATE (EWC++)
- # Consolidate patterns (prevents forgetting old learnings)
- # Check consolidation status
- ## Trajectory Tracking
- # Start tracking
- # Track each step
- # End with verdict
- ## Pattern Schema
- ## MCP Tool Integration
- ## Hooks Integration
- ## Performance Metrics

### .\.claude\agents\v3\security-architect-aidefence.md

**Headings:**
- # Skill dependencies
- # Performance characteristics
- # V3 Security Architecture Agent (AIMDS Enhanced)
- ## AIMDS Integration
- ### Detection Layer (<10ms)
- ### Analysis Layer (<100ms)
- ### Response Layer (<50ms)
- ## Core Responsibilities
- ## AIMDS Commands
- # Scan for prompt injection/manipulation
- # Analyze agent behavior
- # Verify LTL security policy
- # Record successful mitigation for meta-learning
- ## MCP Tool Integration
- ## Threat Pattern Storage (AgentDB)
- ## Collaboration Protocol
- ## Security Policies (LTL Examples)
- # Every edit must eventually be reviewed
- # Never approve your own code changes
- # Sensitive operations require multi-agent consensus
- # PII must never be logged
- # Rate limit violations must trigger alerts

### .\.claude\agents\v3\security-architect.md

**Headings:**
- # V3 Security Architecture Agent
- ## Core Responsibilities
- ## V3 Security Capabilities
- ### HNSW-Indexed Threat Pattern Search (150x-12,500x Faster)
- ### Flash Attention for Large Codebase Security Scanning
- ### ReasoningBank Security Pattern Learning
- ## Threat Modeling Framework
- ### STRIDE Methodology
- ### DREAD Risk Scoring
- ## CVE Tracking and Remediation
- ### CVE-1, CVE-2, CVE-3 Tracking
- ## Claims-Based Authorization Design
- ## Zero-Trust Architecture Patterns
- ## Self-Learning Protocol (V3)
- ### Before Security Assessment: Learn from History
- ### During Assessment: GNN-Enhanced Context Retrieval
- ### After Assessment: Store Learning Patterns
- ## Multi-Agent Security Coordination
- ### Attention-Based Security Consensus
- ### MCP Memory Coordination
- ## Security Scanning Commands
- # Full security scan
- # CVE-specific checks
- # Threat modeling
- # Audit report
- # Validate security configuration
- # Generate security report
- ## Collaboration Protocol

### .\.claude\agents\v3\security-auditor.md

**Headings:**
- # Security Auditor Agent (V3)
- ## Core Responsibilities
- ## V3 Intelligence Features
- ### ReasoningBank Vulnerability Pattern Learning
- ### HNSW-Indexed CVE Database Search (150x-12,500x Faster)
- ### Flash Attention for Rapid Code Scanning
- ## OWASP Top 10 Vulnerability Detection
- ### A01:2021 - Broken Access Control
- ### A02:2021 - Cryptographic Failures
- ### A03:2021 - Injection
- ### A04:2021 - Insecure Design
- ### A05:2021 - Security Misconfiguration
- ### A06:2021 - Vulnerable Components
- ### A07:2021 - Authentication Failures
- ### A08:2021 - Software and Data Integrity Failures
- ### A09:2021 - Security Logging Failures
- ### A10:2021 - Server-Side Request Forgery (SSRF)
- ## Secret Detection and Credential Scanning
- ## Dependency Vulnerability Scanning
- ## Compliance Auditing
- ### SOC2 Compliance Patterns
- ### GDPR Compliance Patterns
- ### HIPAA Compliance Patterns
- ## Security Report Generation
- ## Self-Learning Protocol
- ### Continuous Detection Improvement
- ### Pattern Recognition Enhancement
- ## MCP Integration
- ## Collaboration with Other Agents

### .\.claude\agents\v3\sparc-orchestrator.md

**Headings:**
- # V3 SPARC Orchestrator Agent
- ## SPARC Methodology Overview
- ## Phase Responsibilities
- ### 1. Specification Phase
- ### 2. Pseudocode Phase
- ### 3. Architecture Phase
- ### 4. Refinement Phase (TDD)
- ### 5. Completion Phase
- ## Orchestration Commands
- # Run complete SPARC workflow
- # Run specific phase
- # TDD workflow
- # Check phase status
- ## Agent Delegation Pattern
- ## Quality Gates
- ## ReasoningBank Integration
- # Store successful pattern
- # Search for similar patterns
- ## Integration with V3 Features

### .\.claude\agents\v3\swarm-memory-manager.md

**Headings:**
- # V3 Swarm Memory Manager Agent
- ## Architecture
- ## Responsibilities
- ### 1. Namespace Coordination
- ### 2. CRDT Replication
- ### 3. Vector Cache Management
- ### 4. Conflict Resolution
- ## MCP Tools
- # Memory operations
- ## Coordination Protocol
- ## Memory Namespaces
- ## Example Workflow

### .\.claude\agents\v3\v3-integration-architect.md

**Headings:**
- # V3 Integration Architect Agent
- ## ADR-001 Implementation
- ## Eliminated Duplicates
- ## Integration Points
- ### 1. MCP Server Extension
- ### 2. Memory Service Extension
- ### 3. Agent Spawning Extension
- ## MCP Tool Mapping
- ## V3-Specific Extensions
- ### Swarm Topologies (Not in agentic-flow)
- ### Hive-Mind Consensus (Not in agentic-flow)
- ### SPARC Methodology (Not in agentic-flow)
- ### V3 Hooks System (Extended)
- ## Commands
- # Check integration status
- # Verify no duplicate code
- # Test extension layer
- # Update agentic-flow dependency
- ## Quality Metrics

### .\.claude\commands\claude-flow-help.md

**Headings:**
- # Claude-Flow Commands
- ## 🌊 Claude-Flow: Agent Orchestration Platform
- ## Core Commands
- ### 🚀 System Management
- ### 🤖 Agent Management
- ### 📋 Task Management
- ### 🧠 Memory Operations
- ### ⚡ SPARC Development
- ### 🐝 Swarm Coordination
- ### 🌍 MCP Integration
- ### 🤖 Claude Integration
- ## 🌟 Quick Examples
- ### Initialize with SPARC:
- ### Start a development swarm:
- ### Run TDD workflow:
- ### Store project context:
- ### Spawn specialized agents:
- ## 🎯 Best Practices
- ## 📚 Resources

### .\.claude\commands\claude-flow-memory.md

**Headings:**
- # 🧠 Claude-Flow Memory System
- ## Store Information
- # Store with default namespace
- # Store with specific namespace
- ## Query Memory
- # Search across all namespaces
- # Search with filters
- ## Memory Statistics
- # Show overall statistics
- # Show namespace-specific stats
- ## Export/Import
- # Export all memory
- # Export specific namespace
- # Import memory
- ## Cleanup Operations
- # Clean entries older than 30 days
- # Clean specific namespace
- ## 🗂️ Namespaces
- ## 🎯 Best Practices
- ### Naming Conventions
- ### Organization
- ### Maintenance
- ## Examples
- ### Store SPARC context:
- ### Query project decisions:
- ### Backup project memory:

### .\.claude\commands\claude-flow-swarm.md

**Headings:**
- # 🐝 Claude-Flow Swarm Coordination
- ## Basic Usage
- ## 🎯 Swarm Strategies
- ## 🤖 Agent Types
- ## 🔄 Coordination Modes
- ## ⚙️ Common Options
- ## 🌟 Examples
- ### Development Swarm with Review
- ### Long-Running Research Swarm
- ### Performance Optimization Swarm
- ### Enterprise Development Swarm
- ### Testing and QA Swarm
- ## 📊 Monitoring and Control
- ### Real-time monitoring:
- # Monitor swarm activity
- # Monitor specific component
- ### Check swarm status:
- # Overall system status
- # Detailed swarm status
- ### View agent activity:
- # List all agents
- # Agent details
- ## 💾 Memory Integration
- # Store swarm objectives
- # Query swarm progress
- # Export swarm memory
- ## 🎯 Key Features
- ### Timeout-Free Execution
- ### Work Stealing & Load Balancing
- ### Circuit Breakers & Fault Tolerance
- ### Real-Time Collaboration
- ### Enterprise Security
- ## 🔧 Advanced Configuration
- ### Dry run to preview:
- ### Custom quality thresholds:
- ### Scheduling algorithms:

### .\.claude\commands\analysis\bottleneck-detect.md

**Headings:**
- # bottleneck detect
- ## Usage
- ## Options
- ## Examples
- ### Basic bottleneck detection
- ### Analyze specific swarm
- ### Last 24 hours with export
- ### Auto-fix detected issues
- ## Metrics Analyzed
- ### Communication Bottlenecks
- ### Processing Bottlenecks
- ### Memory Bottlenecks
- ### Network Bottlenecks
- ## Output Format
- ## Automatic Fixes
- ## Performance Impact
- ## Integration with Claude Code
- ## See Also

### .\.claude\commands\analysis\COMMAND_COMPLIANCE_REPORT.md

**Headings:**
- # Analysis Commands Compliance Report
- ## Overview
- ## Files Reviewed
- ### 1. token-efficiency.md
- ### 2. performance-bottlenecks.md
- ## Summary
- ## Compliance Patterns Enforced
- ## Recommendations

### .\.claude\commands\analysis\performance-bottlenecks.md

**Headings:**
- # Performance Bottleneck Analysis
- ## Purpose
- ## Automated Analysis
- ### 1. Real-time Detection
- ### 2. Common Bottlenecks
- ### 3. Improvement Suggestions
- ## Continuous Optimization

### .\.claude\commands\analysis\performance-report.md

**Headings:**
- # performance-report
- ## Usage
- ## Options
- ## Examples
- # Generate HTML report
- # Compare swarms
- # Full metrics report

### .\.claude\commands\analysis\README.md

**Headings:**
- # Analysis Commands
- ## Available Commands

### .\.claude\commands\analysis\token-efficiency.md

**Headings:**
- # Token Usage Optimization
- ## Purpose
- ## Optimization Strategies
- ### 1. Smart Caching
- ### 2. Efficient Coordination
- ### 3. Measurement & Tracking
- # Check token savings after session
- # Result shows:
- ## Best Practices
- ## Token Reduction Results

### .\.claude\commands\analysis\token-usage.md

**Headings:**
- # token-usage
- ## Usage
- ## Options
- ## Examples
- # Last 24 hours token usage
- # By agent breakdown
- # Export detailed report

### .\.claude\commands\automation\auto-agent.md

**Headings:**
- # auto agent
- ## Usage
- ## Options
- ## Examples
- ### Basic auto-spawning
- ### Constrained spawning
- ### Analysis only
- ### Minimal strategy
- ## How It Works
- ## Agent Types Selected
- ## Strategies
- ### Optimal
- ### Minimal
- ### Balanced
- ## Integration with Claude Code
- ## See Also

### .\.claude\commands\automation\README.md

**Headings:**
- # Automation Commands
- ## Available Commands

### .\.claude\commands\automation\self-healing.md

**Headings:**
- # Self-Healing Workflows
- ## Purpose
- ## Self-Healing Features
- ### 1. Error Detection
- ### 2. Automatic Recovery
- ### 3. Learning from Failures
- ## Self-Healing Integration
- ### MCP Tool Coordination
- ### Fallback Hook Configuration
- ## Benefits

### .\.claude\commands\automation\session-memory.md

**Headings:**
- # Cross-Session Memory
- ## Purpose
- ## Memory Features
- ### 1. Automatic State Persistence
- ### 2. Session Restoration
- ### 3. Memory Types
- ### 4. Privacy & Control
- # View stored memory
- # Disable memory
- ## Benefits

### .\.claude\commands\automation\smart-agents.md

**Headings:**
- # Smart Agent Auto-Spawning
- ## Purpose
- ## Auto-Spawning Triggers
- ### 1. File Type Detection
- ### 2. Task Complexity
- ### 3. Dynamic Scaling
- ## Configuration
- ### MCP Tool Integration
- ### Fallback Configuration
- ## Benefits

### .\.claude\commands\automation\smart-spawn.md

**Headings:**
- # smart-spawn
- ## Usage
- ## Options
- ## Examples
- # Smart spawn with analysis
- # Set spawn threshold
- # Force topology

### .\.claude\commands\automation\workflow-select.md

**Headings:**
- # workflow-select
- ## Usage
- ## Options
- ## Examples
- # Select workflow for task
- # With constraints
- # Preview mode

### .\.claude\commands\github\code-review-swarm.md

**Headings:**
- # Code Review Swarm - Automated Code Review with AI Agents
- ## Overview
- ## Core Features
- ### 1. Multi-Agent Review System
- # Initialize code review swarm with gh CLI
- # Get PR details
- # Initialize swarm with PR context
- # Post initial review status
- ### 2. Specialized Review Agents
- #### Security Agent
- # Security-focused review with gh CLI
- # Get changed files
- # Run security review
- # Post security findings
- #### Performance Agent
- # Performance analysis
- #### Architecture Agent
- # Architecture review
- ### 3. Review Configuration
- # .github/review-swarm.yml
- ## Review Agents
- ### Security Review Agent
- ### Performance Review Agent
- ### Style & Convention Agent
- ### Architecture Review Agent
- ## Advanced Review Features
- ### 1. Context-Aware Reviews
- # Review with full context
- ### 2. Learning from History
- # Learn from past reviews
- ### 3. Cross-PR Analysis
- # Analyze related PRs together
- ## Review Automation
- ### Auto-Review on Push
- # .github/workflows/auto-review.yml
- ### Review Triggers
- ## Review Comments
- ### Intelligent Comment Generation
- # Generate contextual review comments with gh CLI
- # Get PR diff with context
- # Generate review comments
- # Post comments using gh CLI
- ### Comment Templates
- ### Batch Comment Management
- # Manage review comments efficiently
- ## Integration with CI/CD
- ### Status Checks
- # Required status checks
- ### Quality Gates
- # Define quality gates
- ### Review Metrics
- # Track review effectiveness
- ## Best Practices
- ### 1. Review Configuration
- ### 2. Comment Quality
- ### 3. Performance
- ## Advanced Features
- ### 1. AI Learning
- # Train on your codebase
- ### 2. Custom Review Agents
- ### 3. Review Orchestration
- # Orchestrate complex reviews
- ## Examples
- ### Security-Critical PR
- # Auth system changes
- ### Performance-Sensitive PR
- # Database optimization
- ### UI Component PR
- # New component library
- ## Monitoring & Analytics
- ### Review Dashboard
- # Launch review dashboard
- ### Review Reports
- # Generate review reports

### .\.claude\commands\github\code-review.md

**Headings:**
- # code-review
- ## Usage
- ## Options
- ## Examples
- # Review PR
- # Security focus
- # With fix suggestions

### .\.claude\commands\github\github-modes.md

**Headings:**
- # GitHub Integration Modes
- ## Overview
- ## GitHub Workflow Modes
- ### gh-coordinator
- ### pr-manager
- ### issue-tracker
- ### release-manager
- ## Repository Management Modes
- ### repo-architect
- ### code-reviewer
- ### branch-manager
- ## Integration Commands
- ### sync-coordinator
- ### ci-orchestrator
- ### security-guardian
- ## Usage Examples
- ### Creating a coordinated pull request workflow:
- ### Managing repository synchronization:
- ### Setting up automated issue tracking:
- ## Batch Operations
- ### Parallel GitHub Operations Example:
- ## Integration with ruv-swarm

### .\.claude\commands\github\github-swarm.md

**Headings:**
- # github swarm
- ## Usage
- ## Options
- ## Examples
- ### Basic GitHub swarm
- ### Maintenance-focused swarm
- ### Development swarm with PR automation
- ### Full-featured triage swarm
- ## Agent Types
- ### Issue Triager
- ### PR Reviewer
- ### Documentation Agent
- ### Test Agent
- ### Security Agent
- ## Workflows
- ### Issue Triage Workflow
- ### PR Enhancement Workflow
- ### Repository Health Check
- ## Integration with Claude Code
- ## See Also

### .\.claude\commands\github\issue-tracker.md

**Headings:**
- # GitHub Issue Tracker
- ## Purpose
- ## Capabilities
- ## Tools Available
- ## Usage Patterns
- ### 1. Create Coordinated Issue with Swarm Tracking
- ### 2. Automated Progress Updates
- ### 3. Multi-Issue Project Coordination
- ## Batch Operations Example
- ### Complete Issue Management Workflow:
- ## Smart Issue Templates
- ### Integration Issue Template:
- ## 🔄 Integration Task
- ### Overview
- ### Objectives
- ### Integration Areas
- #### Dependencies
- #### Functionality  
- #### Testing
- ### Swarm Coordination
- ### Progress Tracking
- ### Bug Report Template:
- ## 🐛 Bug Report
- ### Problem Description
- ### Expected Behavior
- ### Actual Behavior  
- ### Reproduction Steps
- ### Environment
- ### Investigation Plan
- ### Swarm Assignment
- ## Best Practices
- ### 1. **Swarm-Coordinated Issue Management**
- ### 2. **Automated Progress Tracking**
- ### 3. **Smart Labeling and Organization**
- ### 4. **Batch Issue Operations**
- ## Integration with Other Modes
- ### Seamless integration with:
- ## Metrics and Analytics
- ### Automatic tracking of:
- ### Reporting features:

### .\.claude\commands\github\issue-triage.md

**Headings:**
- # issue-triage
- ## Usage
- ## Options
- ## Examples
- # Triage issues
- # With auto-labeling
- # Full automation

### .\.claude\commands\github\multi-repo-swarm.md

**Headings:**
- # Multi-Repo Swarm - Cross-Repository Swarm Orchestration
- ## Overview
- ## Core Features
- ### 1. Cross-Repo Initialization
- # Initialize multi-repo swarm with gh CLI
- # List organization repositories
- # Get repository details
- # Initialize swarm with repository context
- ### 2. Repository Discovery
- # Auto-discover related repositories with gh CLI
- # Search organization repositories
- # Analyze repository dependencies
- # Discover and analyze
- ### 3. Synchronized Operations
- # Execute synchronized changes across repos with gh CLI
- # Get matching repositories
- # Execute task and create PRs
- # Link related PRs
- ## Configuration
- ### Multi-Repo Config File
- # .swarm/multi-repo.yml
- ### Repository Roles
- ## Orchestration Commands
- ### Dependency Management
- # Update dependencies across all repos with gh CLI
- # Create tracking issue first
- # Get all repos with TypeScript
- # Update each repository
- ### Refactoring Operations
- # Coordinate large-scale refactoring
- ### Security Updates
- # Coordinate security patches
- ## Communication Strategies
- ### 1. Webhook-Based Coordination
- ### 2. GraphQL Federation
- # Federated schema for multi-repo queries
- ### 3. Event Streaming
- # Kafka configuration for real-time coordination
- ## Advanced Features
- ### 1. Distributed Task Queue
- # Create distributed task queue
- ### 2. Cross-Repo Testing
- # Run integration tests across repos
- ### 3. Monorepo Migration
- # Assist in monorepo migration
- ## Monitoring & Visualization
- ### Multi-Repo Dashboard
- # Launch monitoring dashboard
- ### Dependency Graph
- # Visualize repo dependencies
- ### Health Monitoring
- # Monitor swarm health across repos
- ## Synchronization Patterns
- ### 1. Eventually Consistent
- ### 2. Strong Consistency
- ### 3. Hybrid Approach
- ## Use Cases
- ### 1. Microservices Coordination
- # Coordinate microservices development
- ### 2. Library Updates
- # Update shared library across consumers
- ### 3. Organization-Wide Changes
- # Apply org-wide policy changes
- ## Best Practices
- ### 1. Repository Organization
- ### 2. Communication
- ### 3. Security
- ## Performance Optimization
- ### Caching Strategy
- # Implement cross-repo caching
- ### Parallel Execution
- # Optimize parallel operations
- ### Resource Pooling
- # Pool resources across repos
- ## Troubleshooting
- ### Connectivity Issues
- # Diagnose connectivity problems
- ### Memory Synchronization
- # Debug memory sync issues
- ### Performance Bottlenecks
- # Identify performance issues
- ## Examples
- ### Full-Stack Application Update
- # Update full-stack application
- ### Cross-Team Collaboration
- # Facilitate cross-team work

### .\.claude\commands\github\pr-enhance.md

**Headings:**
- # pr-enhance
- ## Usage
- ## Options
- ## Examples
- # Enhance PR
- # Add tests
- # Full enhancement

### .\.claude\commands\github\pr-manager.md

**Headings:**
- # GitHub PR Manager
- ## Purpose
- ## Capabilities
- ## Tools Available
- ## Usage Patterns
- ### 1. Create and Manage PR with Swarm Coordination
- ### 2. Automated Multi-File Review
- ### 3. Merge Coordination with Testing
- ## Batch Operations Example
- ### Complete PR Lifecycle in Parallel:
- ## Best Practices
- ### 1. **Always Use Swarm Coordination**
- ### 2. **Batch PR Operations**
- ### 3. **Intelligent Review Strategy**
- ### 4. **Progress Tracking**
- ## Integration with Other Modes
- ### Works seamlessly with:
- ## Error Handling
- ### Automatic retry logic for:
- ### Swarm coordination ensures:

### .\.claude\commands\github\project-board-sync.md

**Headings:**
- # Project Board Sync - GitHub Projects Integration
- ## Overview
- ## Core Features
- ### 1. Board Initialization
- # Connect swarm to GitHub Project using gh CLI
- # Get project details
- # Initialize swarm with project
- # Create project fields for swarm tracking
- ### 2. Task Synchronization
- # Sync swarm tasks with project cards
- ### 3. Real-time Updates
- # Enable real-time board updates
- ## Configuration
- ### Board Mapping Configuration
- # .github/board-sync.yml
- ### View Configuration
- ## Automation Features
- ### 1. Auto-Assignment
- # Automatically assign cards to agents
- ### 2. Progress Tracking
- # Track and visualize progress
- ### 3. Smart Card Movement
- # Intelligent card state transitions
- ## Board Commands
- ### Create Cards from Issues
- # Convert issues to project cards using gh CLI
- # List issues with label
- # Add issues to project
- # Process with swarm
- ### Bulk Operations
- # Bulk card operations
- ### Card Templates
- # Create cards from templates
- ## Advanced Synchronization
- ### 1. Multi-Board Sync
- # Sync across multiple boards
- ### 2. Cross-Organization Sync
- # Sync boards across organizations
- ### 3. External Tool Integration
- # Sync with external tools
- ## Visualization & Reporting
- ### Board Analytics
- # Generate board analytics using gh CLI data
- # Fetch project data
- # Get issue metrics
- # Generate analytics with swarm
- ### Custom Dashboards
- ### Reports
- # Generate reports
- ## Workflow Integration
- ### Sprint Management
- # Manage sprints with swarms
- ### Milestone Tracking
- # Track milestone progress
- ### Release Planning
- # Plan releases using board data
- ## Team Collaboration
- ### Work Distribution
- # Distribute work among team
- ### Standup Automation
- # Generate standup reports
- ### Review Coordination
- # Coordinate reviews via board
- ## Best Practices
- ### 1. Board Organization
- ### 2. Data Integrity
- ### 3. Team Adoption
- ## Troubleshooting
- ### Sync Issues
- # Diagnose sync problems
- ### Performance
- # Optimize board performance
- ### Data Recovery
- # Recover board data
- ## Examples
- ### Agile Development Board
- # Setup agile board
- ### Kanban Flow Board
- # Setup kanban board
- ### Research Project Board
- # Setup research board
- ## Metrics & KPIs
- ### Performance Metrics
- # Track board performance
- ### Team Metrics
- # Track team performance

### .\.claude\commands\github\README.md

**Headings:**
- # Github Commands
- ## Available Commands

### .\.claude\commands\github\release-manager.md

**Headings:**
- # GitHub Release Manager
- ## Purpose
- ## Capabilities
- ## Tools Available
- ## Usage Patterns
- ### 1. Coordinated Release Preparation
- ### 2. Multi-Package Version Coordination
- ## [1.0.72] - ${new Date().toISOString().split('T')[0]}
- ### Added
- ### Changed  
- ### Fixed
- ### 3. Automated Release Validation
- ### 🎯 Release Highlights
- ### 📦 Package Updates
- ### 🔧 Changes
- #### Added
- #### Changed
- #### Fixed
- ### ✅ Validation Results
- ### 🐝 Swarm Coordination
- ### 🎁 Ready for Deployment
- ## Batch Release Workflow
- ### Complete Release Pipeline:
- ## Release Strategies
- ### 1. **Semantic Versioning Strategy**
- ### 2. **Multi-Stage Validation**
- ### 3. **Rollback Strategy**
- ## Best Practices
- ### 1. **Comprehensive Testing**
- ### 2. **Documentation Management**
- ### 3. **Deployment Coordination**
- ### 4. **Version Management**
- ## Integration with CI/CD
- ### GitHub Actions Integration:
- ## Monitoring and Metrics
- ### Release Quality Metrics:
- ### Automated Monitoring:

### .\.claude\commands\github\release-swarm.md

**Headings:**
- # Release Swarm - Intelligent Release Automation
- ## Overview
- ## Core Features
- ### 1. Release Planning
- # Plan next release using gh CLI
- # Get commit history since last release
- # Get merged PRs
- # Plan release with commit analysis
- ### 2. Automated Versioning
- # Smart version bumping
- ### 3. Release Orchestration
- # Full release automation with gh CLI
- # Generate changelog from PRs and commits
- # Create release draft
- # Run release orchestration
- # Publish release after validation
- # Create announcement issue
- ## Release Configuration
- ### Release Config File
- # .github/release-swarm.yml
- ## Release Agents
- ### Changelog Agent
- # Generate intelligent changelog with gh CLI
- # Get all merged PRs between versions
- # Get contributors
- # Get commit messages
- # Generate categorized changelog
- # Save changelog
- # Create PR with changelog update
- ### Version Agent
- # Determine next version
- ### Build Agent
- # Coordinate multi-platform builds
- ### Test Agent
- # Pre-release testing
- ### Deploy Agent
- # Multi-target deployment
- ## Advanced Features
- ### 1. Progressive Deployment
- # Staged rollout configuration
- ### 2. Multi-Repo Releases
- # Coordinate releases across repos
- ### 3. Hotfix Automation
- # Emergency hotfix process
- ## Release Workflows
- ### Standard Release Flow
- # .github/workflows/release.yml
- ### Continuous Deployment
- # Automated deployment pipeline
- ## Release Validation
- ### Pre-Release Checks
- # Comprehensive validation
- ### Compatibility Testing
- # Test backward compatibility
- ### Security Scanning
- # Security validation
- ## Monitoring & Rollback
- ### Release Monitoring
- # Monitor release health
- ### Automated Rollback
- # Configure auto-rollback
- ### Release Analytics
- # Analyze release performance
- ## Documentation
- ### Auto-Generated Docs
- # Update documentation
- ### Release Notes
- # Release v2.0.0
- ## 🎉 Highlights
- ## 🚀 Features
- ### Feature Name (#PR)
- ## 🐛 Bug Fixes
- ### Fixed issue with... (#PR)
- ## 💥 Breaking Changes
- ### API endpoint renamed
- ## 📈 Performance Improvements
- ## 🔒 Security Updates
- ## 📚 Documentation
- ## 🙏 Contributors
- ## Best Practices
- ### 1. Release Planning
- ### 2. Automation
- ### 3. Documentation
- ## Integration Examples
- ### NPM Package Release
- # NPM package release
- ### Docker Image Release
- # Docker multi-arch release
- ### Mobile App Release
- # Mobile app store release
- ## Emergency Procedures
- ### Hotfix Process
- # Emergency hotfix
- ### Rollback Procedure
- # Immediate rollback

### .\.claude\commands\github\repo-analyze.md

**Headings:**
- # repo-analyze
- ## Usage
- ## Options
- ## Examples
- # Basic analysis
- # Deep analysis
- # Specific areas

### .\.claude\commands\github\repo-architect.md

**Headings:**
- # GitHub Repository Architect
- ## Purpose
- ## Capabilities
- ## Tools Available
- ## Usage Patterns
- ### 1. Repository Structure Analysis and Optimization
- ### 2. Multi-Repository Template Creation
- ## Quick Start
- ## Features
- ## Documentation
- ### 3. Cross-Repository Synchronization
- ## Batch Architecture Operations
- ### Complete Repository Architecture Optimization:
- ## Architecture Patterns
- ### 1. **Monorepo Structure Pattern**
- ### 2. **Command Structure Pattern**
- ### 3. **Integration Pattern**
- ## Best Practices
- ### 1. **Structure Optimization**
- ### 2. **Template Management**
- ### 3. **Multi-Repository Coordination**
- ### 4. **Documentation Architecture**
- ## Monitoring and Analysis
- ### Architecture Health Metrics:
- ### Automated Analysis:
- ## Integration with Development Workflow
- ### Seamless integration with:
- ### Workflow Enhancement:

### .\.claude\commands\github\swarm-issue.md

**Headings:**
- # Swarm Issue - Issue-Based Swarm Coordination
- ## Overview
- ## Core Features
- ### 1. Issue-to-Swarm Conversion
- # Create swarm from issue using gh CLI
- # Get issue details
- # Create swarm from issue
- # Batch process multiple issues
- # Update issues with swarm status
- ### 2. Issue Comment Commands
- ### 3. Issue Templates for Swarms
- ## Issue Label Automation
- ### Auto-Label Based on Content
- ### Dynamic Agent Assignment
- # Assign agents based on issue content
- ## Issue Swarm Commands
- ### Initialize from Issue
- # Create swarm with full issue context using gh CLI
- # Get complete issue data
- # Get referenced issues and PRs
- # Initialize swarm
- # Add swarm initialization comment
- ### Task Decomposition
- # Break down issue into subtasks with gh CLI
- # Get issue body
- # Decompose into subtasks
- # Update issue with checklist
- ## Subtasks
- # Create linked issues for major subtasks
- ### Progress Tracking
- # Update issue with swarm progress using gh CLI
- # Get current issue state
- # Get swarm progress
- # Update checklist in issue body
- # Edit issue with updated body
- # Post progress summary as comment
- ### Completed Tasks
- ### In Progress
- ### Remaining
- # Update labels based on progress
- ## Advanced Features
- ### 1. Issue Dependencies
- # Handle issue dependencies
- ### 2. Epic Management
- # Coordinate epic-level swarms
- ### 3. Issue Templates
- # Generate issue from swarm analysis
- ## Workflow Integration
- ### GitHub Actions for Issues
- # .github/workflows/issue-swarm.yml
- ### Issue Board Integration
- # Sync with project board
- ## Issue Types & Strategies
- ### Bug Reports
- # Specialized bug handling
- ### Feature Requests
- # Feature implementation swarm
- ### Technical Debt
- # Refactoring swarm
- ## Automation Examples
- ### Auto-Close Stale Issues
- # Process stale issues with swarm using gh CLI
- # Find stale issues
- # Analyze each stale issue
- # Close issues that have been stale for 37+ days
- ### Issue Triage
- # Automated triage system
- ### Duplicate Detection
- # Find duplicate issues
- ## Integration Patterns
- ### 1. Issue-PR Linking
- # Link issues to PRs automatically
- ### 2. Milestone Coordination
- # Coordinate milestone swarms
- ### 3. Cross-Repo Issues
- # Handle issues across repositories
- ## Metrics & Analytics
- ### Issue Resolution Time
- # Analyze swarm performance
- ### Swarm Effectiveness
- # Generate effectiveness report
- ## Best Practices
- ### 1. Issue Templates
- ### 2. Label Strategy
- ### 3. Comment Etiquette
- ## Security & Permissions
- ## Examples
- ### Complex Bug Investigation
- # Issue #789: Memory leak in production
- ### Feature Implementation
- # Issue #234: Add OAuth integration
- ### Documentation Update
- # Issue #567: Update API documentation

### .\.claude\commands\github\swarm-pr.md

**Headings:**
- # Swarm PR - Managing Swarms through Pull Requests
- ## Overview
- ## Core Features
- ### 1. PR-Based Swarm Creation
- # Create swarm from PR description using gh CLI
- # Auto-spawn agents based on PR labels
- # Create swarm with PR context
- ### 2. PR Comment Commands
- ### 3. Automated PR Workflows
- # .github/workflows/swarm-pr.yml
- ## PR Label Integration
- ### Automatic Agent Assignment
- ### Label-Based Topology
- # Small PR (< 100 lines): ring topology
- # Medium PR (100-500 lines): mesh topology  
- # Large PR (> 500 lines): hierarchical topology
- ## PR Swarm Commands
- ### Initialize from PR
- # Create swarm with PR context using gh CLI
- ### Progress Updates
- # Post swarm progress to PR using gh CLI
- # Update PR labels based on progress
- ### Code Review Integration
- # Create review agents with gh CLI integration
- # Run swarm review
- # Post review comments using gh CLI
- ## Advanced Features
- ### 1. Multi-PR Swarm Coordination
- # Coordinate swarms across related PRs
- ### 2. PR Dependency Analysis
- # Analyze PR dependencies
- ### 3. Automated PR Fixes
- # Auto-fix PR issues
- ## Best Practices
- ### 1. PR Templates
- ## Swarm Configuration
- ## Tasks for Swarm
- ### 2. Status Checks
- # Require swarm completion before merge
- ### 3. PR Merge Automation
- # Auto-merge when swarm completes using gh CLI
- # Check swarm completion status
- ## Webhook Integration
- ### Setup Webhook Handler
- ## Examples
- ### Feature Development PR
- # PR #456: Add user authentication
- ### Bug Fix PR
- # PR #789: Fix memory leak
- ### Documentation PR
- # PR #321: Update API docs
- ## Metrics & Reporting
- ### PR Swarm Analytics
- # Generate PR swarm report
- ### Dashboard Integration
- # Export to GitHub Insights
- ## Security Considerations
- ## Integration with Claude Code

### .\.claude\commands\github\sync-coordinator.md

**Headings:**
- # GitHub Sync Coordinator
- ## Purpose
- ## Capabilities
- ## Tools Available
- ## Usage Patterns
- ### 1. Synchronize Package Dependencies
- ### 2. Documentation Synchronization
- ### 3. Cross-Package Feature Integration
- ### Features Added
- ### Integration Points
- ### Testing
- ### Swarm Coordination
- ## Batch Synchronization Example
- ### Complete Package Sync Workflow:
- ## Synchronization Strategies
- ### 1. **Version Alignment Strategy**
- ### 2. **Documentation Sync Pattern**
- ### 3. **Integration Testing Matrix**
- ## Best Practices
- ### 1. **Atomic Synchronization**
- ### 2. **Version Management**
- ### 3. **Documentation Consistency**
- ### 4. **Testing Integration**
- ## Monitoring and Metrics
- ### Sync Quality Metrics:
- ### Automated Reporting:
- ## Error Handling and Recovery
- ### Automatic handling of:
- ### Recovery procedures:

### .\.claude\commands\github\workflow-automation.md

**Headings:**
- # Workflow Automation - GitHub Actions Integration
- ## Overview
- ## Core Features
- ### 1. Swarm-Powered Actions
- # .github/workflows/swarm-ci.yml
- ### 2. Dynamic Workflow Generation
- # Generate workflows based on code analysis
- ### 3. Intelligent Test Selection
- # Smart test runner
- ## Workflow Templates
- ### Multi-Language Detection
- # .github/workflows/polyglot-swarm.yml
- ### Adaptive Security Scanning
- # .github/workflows/security-swarm.yml
- ## Action Commands
- ### Pipeline Optimization
- # Optimize existing workflows
- ### Failure Analysis
- # Analyze failed runs using gh CLI
- # Create issue for persistent failures
- ### Resource Management
- # Optimize resource usage
- ## Advanced Workflows
- ### 1. Self-Healing CI/CD
- # Auto-fix common CI failures
- ### 2. Progressive Deployment
- # Intelligent deployment strategy
- ### 3. Performance Regression Detection
- # Automatic performance testing
- ## Custom Actions
- ### Swarm Action Development
- ## Matrix Strategies
- ### Dynamic Test Matrix
- # Generate test matrix from code analysis
- ### Intelligent Parallelization
- # Determine optimal parallelization
- ## Monitoring & Insights
- ### Workflow Analytics
- # Analyze workflow performance
- ### Cost Optimization
- # Optimize GitHub Actions costs
- ### Failure Patterns
- # Identify failure patterns
- ## Integration Examples
- ### 1. PR Validation Swarm
- ### 2. Release Automation
- ### 3. Documentation Updates
- ## Best Practices
- ### 1. Workflow Organization
- ### 2. Security
- ### 3. Performance
- ## Advanced Features
- ### Predictive Failures
- # Predict potential failures
- ### Workflow Recommendations
- # Get workflow recommendations
- ### Automated Optimization
- # Continuously optimize workflows
- ## Debugging & Troubleshooting
- ### Debug Mode
- ### Performance Profiling
- # Profile workflow performance

### .\.claude\commands\hooks\overview.md

**Headings:**
- # Claude Code Hooks for claude-flow
- ## Purpose
- ## Available Hooks
- ### Pre-Operation Hooks
- ### Post-Operation Hooks
- ### MCP Integration Hooks
- ### Session Hooks
- ## Configuration
- ## Benefits
- ## See Also

### .\.claude\commands\hooks\post-edit.md

**Headings:**
- # hook post-edit
- ## Usage
- ## Options
- ## Examples
- ### Basic post-edit hook
- ### With memory storage
- ### Format and validate
- ### Neural training
- ## Features
- ### Auto Formatting
- ### Memory Storage
- ### Pattern Training
- ### Output Validation
- ## Integration
- # After editing files
- ## Output
- ## See Also

### .\.claude\commands\hooks\post-task.md

**Headings:**
- # hook post-task
- ## Usage
- ## Options
- ## Examples
- ### Basic post-task hook
- ### With full analysis
- ### Memory storage
- ### Quick cleanup
- ## Features
- ### Performance Analysis
- ### Decision Storage
- ### Neural Learning
- ### Report Generation
- ## Integration
- # In agent coordination
- ## Output
- ## See Also

### .\.claude\commands\hooks\pre-edit.md

**Headings:**
- # hook pre-edit
- ## Usage
- ## Options
- ## Examples
- ### Basic pre-edit hook
- ### With validation
- ### Manual agent assignment
- ### Safe editing with backup
- ## Features
- ### Auto Agent Assignment
- ### Syntax Validation
- ### Conflict Detection
- ### File Backup
- ## Integration
- # Before editing files
- ## Output
- ## See Also

### .\.claude\commands\hooks\pre-task.md

**Headings:**
- # hook pre-task
- ## Usage
- ## Options
- ## Examples
- ### Basic pre-task hook
- ### With memory loading
- ### Manual agent control
- ### Full optimization
- ## Features
- ### Auto Agent Assignment
- ### Memory Loading
- ### Topology Optimization
- ### Complexity Estimation
- ## Integration
- # In agent coordination
- ## Output
- ## See Also

### .\.claude\commands\hooks\README.md

**Headings:**
- # Hooks Commands
- ## Available Commands

### .\.claude\commands\hooks\session-end.md

**Headings:**
- # hook session-end
- ## Usage
- ## Options
- ## Examples
- ### Basic session end
- ### With full export
- ### Quick close
- ### Complete persistence
- ## Features
- ### State Persistence
- ### Metric Export
- ### Summary Generation
- ### Cleanup Operations
- ## Integration
- # At session end
- ## Output
- ## See Also

### .\.claude\commands\hooks\setup.md

**Headings:**
- # Setting Up ruv-swarm Hooks
- ## Quick Start
- ### 1. Initialize with Hooks
- ### 2. Test Hook Functionality
- # Test pre-edit hook
- # Test session summary
- ### 3. Customize Hooks
- ## Hook Response Format
- ## Performance Tips
- ## Debugging Hooks
- # Enable debug output
- # Test specific hook
- ## Common Patterns
- ### Auto-Format on Save
- ### Protected File Detection
- ### Automatic Testing

### .\.claude\commands\monitoring\agent-metrics.md

**Headings:**
- # agent-metrics
- ## Usage
- ## Options
- ## Examples
- # All agents metrics
- # Specific agent
- # Last hour

### .\.claude\commands\monitoring\agents.md

**Headings:**
- # List Active Patterns
- ## 🎯 Key Principle
- ## MCP Tool Usage in Claude Code
- ## Parameters
- ## Description
- ## Details
- ## Example Usage
- ## Important Reminders
- ## See Also

### .\.claude\commands\monitoring\README.md

**Headings:**
- # Monitoring Commands
- ## Available Commands

### .\.claude\commands\monitoring\real-time-view.md

**Headings:**
- # real-time-view
- ## Usage
- ## Options
- ## Examples
- # Start real-time view
- # Filter errors
- # Highlight pattern

### .\.claude\commands\monitoring\status.md

**Headings:**
- # Check Coordination Status
- ## 🎯 Key Principle
- ## MCP Tool Usage in Claude Code
- ## Parameters
- ## Description
- ## Details
- ## Example Usage
- ## Important Reminders
- ## See Also

### .\.claude\commands\monitoring\swarm-monitor.md

**Headings:**
- # swarm-monitor
- ## Usage
- ## Options
- ## Examples
- # Start monitoring
- # Custom interval
- # With metrics

### .\.claude\commands\optimization\auto-topology.md

**Headings:**
- # Automatic Topology Selection
- ## Purpose
- ## How It Works
- ### 1. Task Analysis
- ### 2. Topology Selection
- ### 3. Example Usage
- ## Benefits
- ## Hook Configuration
- ## Direct Optimization
- ## CLI Usage
- # Auto-optimize topology via CLI

### .\.claude\commands\optimization\cache-manage.md

**Headings:**
- # cache-manage
- ## Usage
- ## Options
- ## Examples
- # View cache stats
- # Clear cache
- # Set limits

### .\.claude\commands\optimization\parallel-execute.md

**Headings:**
- # parallel-execute
- ## Usage
- ## Options
- ## Examples
- # Execute task list
- # Limit parallelism
- # Custom strategy

### .\.claude\commands\optimization\parallel-execution.md

**Headings:**
- # Parallel Task Execution
- ## Purpose
- ## Coordination Strategy
- ### 1. Task Decomposition
- ### 2. Parallel Workflows
- ### 3. Example Breakdown
- ## CLI Usage
- # Execute parallel tasks via CLI
- ## Performance Gains
- ## Monitoring

### .\.claude\commands\optimization\README.md

**Headings:**
- # Optimization Commands
- ## Available Commands

### .\.claude\commands\optimization\topology-optimize.md

**Headings:**
- # topology-optimize
- ## Usage
- ## Options
- ## Examples
- # Analyze and suggest
- # Optimize for speed
- # Apply changes

### .\.claude\commands\sparc\analyzer.md

**Headings:**
- # SPARC Analyzer Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Batch Operations
- ## Output Format

### .\.claude\commands\sparc\architect.md

**Headings:**
- # SPARC Architect Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Memory Integration
- ## Design Patterns

### .\.claude\commands\sparc\ask.md

**Headings:**
- # ❓Ask
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\batch-executor.md

**Headings:**
- # SPARC Batch Executor Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Execution Patterns
- ## Performance Features

### .\.claude\commands\sparc\code.md

**Headings:**
- # 🧠 Auto-Coder
- ## Role Definition
- ## Custom Instructions
- ## Tool Usage Guidelines:
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\coder.md

**Headings:**
- # SPARC Coder Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Batch Operations
- ## Code Quality

### .\.claude\commands\sparc\debug.md

**Headings:**
- # 🪲 Debugger
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\debugger.md

**Headings:**
- # SPARC Debugger Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Debugging Workflow
- ## Tools Integration

### .\.claude\commands\sparc\designer.md

**Headings:**
- # SPARC Designer Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Design Process
- ## Memory Coordination

### .\.claude\commands\sparc\devops.md

**Headings:**
- # 🚀 DevOps
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\docs-writer.md

**Headings:**
- # 📚 Documentation Writer
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\documenter.md

**Headings:**
- # SPARC Documenter Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Documentation Types
- ## Batch Features

### .\.claude\commands\sparc\innovator.md

**Headings:**
- # SPARC Innovator Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Innovation Process
- ## Knowledge Sources

### .\.claude\commands\sparc\integration.md

**Headings:**
- # 🔗 System Integrator
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\mcp.md

**Headings:**
- # ♾️ MCP Integration
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\memory-manager.md

**Headings:**
- # SPARC Memory Manager Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Memory Strategies
- ## Knowledge Operations

### .\.claude\commands\sparc\optimizer.md

**Headings:**
- # SPARC Optimizer Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Optimization Areas
- ## Systematic Approach

### .\.claude\commands\sparc\orchestrator.md

**Headings:**
- # SPARC Orchestrator Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Integration Examples
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Initialize orchestration swarm
- # Spawn coordinator agent
- # Orchestrate tasks
- ## Orchestration Patterns
- ## Coordination Tools
- ## Workflow Example
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # 1. Initialize orchestration swarm
- # 2. Create workflow
- # 3. Execute orchestration
- # 4. Monitor progress

### .\.claude\commands\sparc\post-deployment-monitoring-mode.md

**Headings:**
- # 📈 Deployment Monitor
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\refinement-optimization-mode.md

**Headings:**
- # 🧹 Optimizer
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\researcher.md

**Headings:**
- # SPARC Researcher Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Research Methods
- ## Memory Integration

### .\.claude\commands\sparc\reviewer.md

**Headings:**
- # SPARC Reviewer Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Review Criteria
- ## Batch Analysis

### .\.claude\commands\sparc\security-review.md

**Headings:**
- # 🛡️ Security Reviewer
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\sparc-modes.md

**Headings:**
- # SPARC Modes Overview
- ## Available Modes
- ### Core Orchestration Modes
- ### Development Modes  
- ### Analysis and Research Modes
- ### Creative and Support Modes
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # List all modes
- # Get help for a mode
- # Run with options
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Common Workflows
- ### Full Development Cycle
- #### Using MCP Tools (Preferred)
- #### Using NPX CLI (Fallback)
- # 1. Architecture design
- # 2. Implementation
- # 3. Testing
- # 4. Review
- ### Research and Innovation
- #### Using MCP Tools (Preferred)
- #### Using NPX CLI (Fallback)
- # 1. Research phase
- # 2. Innovation
- # 3. Documentation

### .\.claude\commands\sparc\sparc.md

**Headings:**
- # ⚡️ SPARC Orchestrator
- ## Role Definition
- ## Custom Instructions
- ## Tool Usage Guidelines:
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\spec-pseudocode.md

**Headings:**
- # 📋 Specification Writer
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\supabase-admin.md

**Headings:**
- # 🔐 Supabase Admin
- ## Role Definition
- ## Custom Instructions
- # Supabase MCP
- ## Getting Started with Supabase MCP
- ### How to Use MCP Services
- ### Current Project
- ## Available Commands
- ### Project Management
- #### `list_projects`
- #### `get_project`
- #### `get_cost`
- #### `confirm_cost`
- #### `create_project`
- #### `pause_project`
- #### `restore_project`
- #### `list_organizations`
- #### `get_organization`
- ### Database Operations
- #### `list_tables`
- #### `list_extensions`
- #### `list_migrations`
- #### `apply_migration`
- #### `execute_sql`
- ### Monitoring & Utilities
- #### `get_logs`
- #### `get_project_url`
- #### `get_anon_key`
- #### `generate_typescript_types`
- ### Development Branches
- #### `create_branch`
- #### `list_branches`
- #### `delete_branch`
- #### `merge_branch`
- #### `reset_branch`
- #### `rebase_branch`
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\swarm-coordinator.md

**Headings:**
- # SPARC Swarm Coordinator Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Coordination Modes
- ## Management Features

### .\.claude\commands\sparc\tdd.md

**Headings:**
- # SPARC TDD Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## TDD Workflow
- ## Testing Strategies

### .\.claude\commands\sparc\tester.md

**Headings:**
- # SPARC Tester Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Test Types
- ## Parallel Features

### .\.claude\commands\sparc\tutorial.md

**Headings:**
- # 📘 SPARC Tutorial
- ## Role Definition
- ## Custom Instructions
- ## Available Tools
- ## Usage
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- # With namespace
- # Non-interactive mode
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Memory Integration
- ### Using MCP Tools (Preferred)
- ### Using NPX CLI (Fallback)
- # Store mode-specific context
- # Query previous work

### .\.claude\commands\sparc\workflow-manager.md

**Headings:**
- # SPARC Workflow Manager Mode
- ## Purpose
- ## Activation
- ### Option 1: Using MCP Tools (Preferred in Claude Code)
- ### Option 2: Using NPX CLI (Fallback when MCP not available)
- # Use when running from terminal or MCP tools unavailable
- # For alpha features
- ### Option 3: Local Installation
- # If claude-flow is installed locally
- ## Core Capabilities
- ## Workflow Patterns
- ## Automation Features

### .\.claude\helpers\README.md

**Headings:**
- # Claude Flow V3 Helpers
- ## 🚀 Quick Start
- # Initialize V3 development environment
- # Quick status check
- # Update progress metrics
- ## Available Helpers
- ### 🎛️ V3 Master Tool
- ### 📊 V3 Progress Management
- ### 🔍 Configuration Validation
- ### ⚡ Quick Status
- ## Helper Script Standards
- ### File Naming
- ### Script Requirements
- ### Configuration Integration
- ## Development Guidelines
- ## Adding New Helpers

### .\.windsurf\rules\gymlog.md

**Headings:**


### .\docs\AI_SYSTEM_CONTEXT.md

**Headings:**
- # 🧠 GYMLOG: MASTER AI CONTEXT FILE
- ## 1. Project Overview & Tech Stack
- ## 2. Design Philosophy: "The Luminous Engine"
- ## 3. Architecture & Code Organization
- ## 4. State Management (Riverpod)
- ## 5. Data Model (Drift / SQLite)
- ## 6. Coding Conventions & UI Patterns
- ## 7. AI Agent Workflows & "Claude Flow"

### .\docs\ARCHITECTURE.md

**Headings:**
- # ARCHITECTURE.md
- ## Folder Structure
- ## State Management
- ### `ActiveWorkoutNotifier` Methods
- ## Navigation (GoRouter)
- ### Auth Redirect Logic
- ### Route Table
- ## Key Widget Tree Patterns
- ### Shell Screen Structure
- ### Scrollable Screen Pattern
- ### List Screen Pattern
- ### HomeScreen Infinite Scroll Pattern
- ### Bottom Sheet Menu Pattern (used everywhere for 3-dot menus)
- ### Active Workout Screen Structure
- ### ExerciseBlock Structure

### .\docs\CONTEXT_SNAPSHOT.md

**Headings:**
- # CONTEXT_SNAPSHOT.md
- ## Project Identity
- ## Key Dependencies (`pubspec.yaml`)
- ## Folder Structure (condensed)
- ## Database Schema (all 8 tables)
- ### `user_profiles` — PK: `id` (Supabase UUID)
- ### `exercises` — PK: `id` (autoIncrement int)
- ### `routines` — PK: `id` (UUID)
- ### `routine_days` — PK: `id` (UUID), FK: `routine_id → routines`
- ### `routine_exercises` — PK: `id` (UUID), FK: `routine_day_id → routine_days`, `exercise_id → exercises`
- ### `workout_sessions` — PK: `id` (UUID clientDefault)
- ### `workout_exercises` — PK: `id` (UUID), FK: `session_id → workout_sessions`, `exercise_id → exercises`
- ### `workout_sets` — PK: `id` (UUID), FK: `workout_exercise_id → workout_exercises`
- ## All Providers
- ## Routes
- ## In-Memory Workout State (Freezed)
- ## Hydrated DAO Types (plain Dart, not Drift rows)
- ## Computed Values
- ## Key Implementation Patterns
- ## Known Issues / Anti-Patterns
- ## Incomplete Features (with schema evidence)
- ## UI Component Reference
- ## `setType` Cycle

### .\docs\CONVENTIONS.md

**Headings:**
- # CONVENTIONS.md
- ## File Naming
- ## Class Naming
- ## Provider Naming
- ## Folder Structure Rules
- ## Screen Structure Pattern
- ## Async State Pattern
- ## Bottom Sheet Menu Pattern
- ## Color Usage Rules
- ## Typography Rules
- ## Shared UI Component Usage
- ## Spacing Constants

### .\docs\DATA_MODEL.md

**Headings:**
- # DATA_MODEL.md
- ## Drift Tables
- ### `user_profiles` (`UserProfiles` / `UserProfile`)
- ### `exercises` (`Exercises` / `Exercise`)
- ### `routines` (`Routines` / `Routine`)
- ### `routine_days` (`RoutineDays` / `RoutineDay`)
- ### `routine_exercises` (`RoutineExercises` / `RoutineExercise`)
- ### `workout_sessions` (`WorkoutSessions` / `WorkoutSession`)
- ### `workout_exercises` (`WorkoutExercises` / `WorkoutExercise`)
- ### `workout_sets` (`WorkoutSets` / `WorkoutSet`)
- ## Entity Relationships
- ## Hydrated DAO Data Classes
- ### `HydratedWorkout` (in `workouts_dao.dart`)
- ### `HydratedRoutine` (in `routines_dao.dart`)
- ### `ExerciseHistoryData` (in `workouts_dao.dart`)
- ### `ExercisePreviewItem` and `WorkoutSessionPreview` (in `workouts_dao.dart`)
- ## Freezed In-Memory State Classes
- ### `ActiveWorkoutState` (`active_workout_state.dart`)
- ## Enums and Constants
- ### `setType` String Enum (no Dart enum — raw strings)
- ### `weightUnit` String Enum (UserProfiles)
- ### SharedPreferences Keys
- ### Supabase Storage
- ## Auto-Computed Fields
- ### `estimated1RM` (Epley Formula)
- ### `volume` (Per Set)
- ### `totalVolumeKg` (Per Session — Denormalized)
- ### `getWorkoutNameFallback(DateTime start, String? name)`
- ### `WorkoutSet.isPr` / `WorkoutSet.estimated_1rm` — `detectAndMarkPrs(sessionId, sessionStart)`
- ## Exercise JSON Hydration Pipeline

### .\docs\DECISIONS.md

**Headings:**
- # DECISIONS.md
- ## 1. Database: Drift (SQLite) over document stores
- ## 2. State Management: Riverpod over BLoC / Provider
- ## 3. Mixed Riverpod Style (manual StateNotifier + code-gen @riverpod)
- ## 4. In-Memory Workout State with Freezed
- ## 5. Navigation: GoRouter with Auth Guard
- ## 6. Auth: Native Google Sign-In (no browser-based OAuth)
- ## 7. Exercise Library: Bundled JSON Asset over Runtime API
- ## 8. Exercise GIFs: Supabase Storage + CachedNetworkImage
- ## 9. Shell Navigation: GoRouter ShellRoute
- ## 10. OLED-First Dark Theme
- ## 11. Denormalization: `totalVolumeKg` in `WorkoutSessions`
- ## 12. Denormalization: `exerciseId` in `WorkoutSets`
- ## 13. ~~`recentWorkoutsProvider` as FutureProvider~~ → Superseded by Decision 16
- ## 16. Paginated `WorkoutHistoryNotifier` with `StateNotifier`
- ## 17. Signal Counter Pattern for Cross-Provider Reactivity
- ## 18. PR Detection Post-Workout (Not Real-Time)
- ## 14. `ExerciseSelectionScreen` via `Navigator.push` (not GoRouter)
- ## 15. `/exercise/detail` passes `Exercise` object via `state.extra`

### .\docs\PROGRESS.md

**Headings:**
- # PROGRESS.md
- ## Fully Implemented
- ### Auth Flow
- ### Exercise Library
- ### Active Workout Session
- ### Workout History
- ### Routines
- ### Profile
- ### Infrastructure
- ## Partially Implemented / Known TODOs
- ### `WorkoutSet` Fields
- ### `SetRow` Previous Set History
- ### Rest Timer
- ### `RoutineEditorScreen`
- ### Routine Card Delete Action
- ### Profile Chart
- ### Profile Action Buttons
- ### Workout Detail Edit Action
- ### Explore Button (`WorkoutScreen`)
- ### `resetHydration()` in `main.dart`
- ### Supabase Sync
- ## Planned / Not Started
- ### Premium / Paywall
- ### Custom Exercises
- ### Body Measurements
- ### Calendar View
- ### Statistics Screen
- ### RPE Input UI
- ### Rest Timer Countdown
- ### Offline / Online Sync
- ### Multi-Day Routine Building
- ### `ExerciseListProvider` Reactivity
- ### Routine Exercises Default Values in Workout

### .\docs\UI_UX_AUDIT.md

**Headings:**
- # Elite UI/UX Architecture Audit
- ### TOP 10 PRIORITIZED HIT LIST
- ## Dimension 1: Spatial Geometry — Implementation Status & Findings
- ## Dimensions 2 & 3: Color and Typography — Implementation Status & Findings

### .\ios\Runner\Assets.xcassets\LaunchImage.imageset\README.md

**Headings:**
- # Launch Screen Assets

## 4. Dependencies & Configuration

`yaml
name: gymlog
description: GymLog - workout logging app scaffold
publish_to: 'none'
version: 0.1.0
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # DB
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.42

  # State
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^14.0.0

  # Auth
  supabase_flutter: ^2.5.0
  flutter_secure_storage: ^9.0.0
  google_sign_in: ^6.2.0

  # Exercise data / media
  cached_network_image: ^3.3.0
  gif_view: ^0.4.0

  # Charts
  fl_chart: ^0.68.0

  # Typography
  google_fonts: ^6.2.0

  # Payments
  url_launcher: ^6.2.0

  # Utils
  intl: ^0.19.0
  uuid: ^4.4.0
  collection: ^1.18.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  flutter_web_plugins:
    sdk: flutter
  flutter_dotenv: ^6.0.1
  path: ^1.9.1
  flutter_cache_manager: ^3.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0
  custom_lint: ^0.6.0
  riverpod_lint: ^2.3.0

flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/db/exercises.json
    # Note: exercises.db is intentionally excluded â€” it is a runtime artifact
    # generated/copied to the app's documents directory at first launch, not
    # a bundled asset. Bundling it would waste ~870 KB in every APK build.

`

## 5. Architecture & State Management

- Pattern: Feature-based modular architecture (features/auth, features/workout, etc.)

- State Management: Riverpod (mixed StateNotifier and @riverpod generator)

- DI Setup: Handled via Riverpod Providers

- Routing: GoRouter with ShellRoute for Bottom Nav Bar


## 6. Data Layer

### exercises_table.dart
`dart
import 'package:drift/drift.dart';

@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get exerciseDbId => text().unique().nullable()();
  TextColumn get name => text()();
  TextColumn get bodyPart => text()();
  TextColumn get equipment => text()();
  TextColumn get target => text()();
  TextColumn get gifUrl => text().nullable()();
  TextColumn get secondaryMuscles => text().nullable()();
  TextColumn get instructions => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get seededAt => dateTime().nullable()();
}

`

### routines_table.dart
`dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('Routine')
class Routines extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

`

### routine_days_table.dart
`dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'routines_table.dart';

@DataClassName('RoutineDay')
class RoutineDays extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

`

### routine_exercises_table.dart
`dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'routine_days_table.dart';
import 'exercises_table.dart';

@DataClassName('RoutineExercise')
class RoutineExercises extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineDayId => text().references(RoutineDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();
  IntColumn get defaultReps => integer().nullable()();
  RealColumn get defaultWeightKg => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

`

### user_profiles_table.dart
`dart
import 'package:drift/drift.dart';

@DataClassName('UserProfile')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  DateTimeColumn get premiumExpiry => dateTime().nullable()();
  TextColumn get weightUnit => text().withDefault(const Constant('kg'))();
  IntColumn get defaultRestSeconds => integer().withDefault(const Constant(90))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

`

### workouts_table.dart
`dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'exercises_table.dart';

@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  RealColumn get totalVolumeKg => real().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutExercise')
class WorkoutExercises extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sessionId => text().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutSet')
class WorkoutSets extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get workoutExerciseId => text().references(WorkoutExercises, #id)();
  IntColumn get exerciseId => integer()();
  IntColumn get orderIndex => integer()();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isPr => boolean().withDefault(const Constant(false))();
  RealColumn get estimated1rm => real().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

`


## 7. UI / Presentation Layer

### 7.1 Screen Inventory

- lib/features\auth\presentation\screens\auth_screen.dart

- lib/features\auth\presentation\screens\onboarding_screen.dart

- lib/features\auth\presentation\screens\splash_screen.dart

- lib/features\exercises\presentation\screens\exercise_detail_screen.dart

- lib/features\exercises\presentation\screens\exercise_selection_screen.dart

- lib/features\home\presentation\screens\home_screen.dart

- lib/features\profile\presentation\screens\profile_screen.dart

- lib/features\routines\presentation\screens\routine_detail_screen.dart

- lib/features\routines\presentation\screens\routine_editor_screen.dart

- lib/features\workout\presentation\screens\active_workout_screen.dart

- lib/features\workout\presentation\screens\workout_detail_screen.dart

- lib/features\workout\presentation\screens\workout_screen.dart


### 7.2 Design System

#### lib/core/theme/app_theme.dart
`dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// [app_theme.dart]
/// Purpose: High-Density Tracker - OLED-First, Data over Decoration
/// Dependencies: flutter/material.dart, google_fonts, app_colors.dart
/// Last modified: High-Density Tracker Overhaul

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.inter().fontFamily,
  
  colorScheme: const ColorScheme.dark(
    surface: AppColors.bgBase,
    surfaceContainerHighest: AppColors.bgSurface,
    primary: AppColors.accentPrimary,
    onPrimary: AppColors.textPrimary,
    secondary: AppColors.bgSurface,
    onSecondary: AppColors.textPrimary,
    error: AppColors.error,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderSubtle,
  ),
  
  scaffoldBackgroundColor: AppColors.bgBase,
  cardColor: AppColors.bgSurface,
  dividerColor: AppColors.borderSubtle,
  
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bgBase,
    elevation: 0,
    centerTitle: false,
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    titleTextStyle: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
  ),
  
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.bgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
  ),
  
  cardTheme: const CardThemeData(
    elevation: 0,
    color: AppColors.bgSurface,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgSurface,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.accentPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentPrimary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.accentPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
    ),
  ),
  
  textTheme: TextTheme(
    // Headers: Bold, high-tracking
    displayLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    
    // Data points: Semi-bold
    titleMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    
    // Body text
    bodyLarge: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    
    // Subtext: Regular, smaller
    bodySmall: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    labelMedium: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelSmall: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w400,
    ),
  ),
);

`

#### lib/core/theme/app_colors.dart
`dart
import 'package:flutter/material.dart';

/// [app_colors.dart]
/// Purpose: High-Density Tracker - OLED-First Dark Mode
/// Dependencies: flutter/material.dart
/// Last modified: High-Density Tracker Overhaul

abstract class AppColors {
  // Base Layers (OLED-First)
  static const bgBase         = Color(0xFF000000); // Pure Black
  static const bgSurface      = Color(0xFF1C1C1E); // Dark Grey - cards, inputs, sheets

  // Primary Accent (Electric Purple - High Visibility)
  static const accentPrimary  = Color(0xFF8A2BE2); // Electric Purple

  // Text Hierarchy
  static const textPrimary    = Color(0xFFFFFFFF); // Pure White
  static const textSecondary  = Color(0xFF8E8E93); // Muted Grey - labels, timestamps

  // Divider/Border
  static const borderSubtle   = Color(0xFF2C2C2E); // Internal card dividers

  // Semantic (kept minimal)
  static const error          = Color(0xFFFF5449);
  static const success        = Color(0xFF34C759); // iOS green
  static const warning        = Color(0xFFFFCC00); // iOS yellow

  // Charts
  static const muscleSplitPalette = [
    Color(0xFF8A2BE2), // Electric Purple (primary)
    Color(0xFF7B68EE), // Medium Slate Blue
    Color(0xFFB19CD9), // Light Pastel Purple
    Color(0xFF4B0082), // Indigo
    Color(0xFF9932CC), // Dark Orchid
    Color(0xFF5D3FD3), // Ultra Violet
  ];
}

`


### 7.3 Routine Detail Screen Deep Dive

#### lib/features/routines/presentation/screens/routine_detail_screen.dart
`dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/daos/routines_dao.dart';
import '../../../../core/database/daos/workouts_dao.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/workout/domain/active_workout_state.dart';
import '../../../../features/workout/presentation/providers/active_workout_provider.dart';
import '../providers/routines_provider.dart';
import '../widgets/routine_exercise_block.dart';
import '../widgets/routine_volume_graph.dart';

/// Spotify-grade RoutineDetailScreen.
///   - SliverAppBar with scroll-blur overlay
///   - Custom time-range tap target and glassmorphic sheet
///   - Glass-surface exercise blocks with rigid Table alignment
///   - Animated CTA with spring press-state

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final String routineId;

  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen>
    with TickerProviderStateMixin {
  String _selectedTimeRange = 'All Time';
  static const _timeRangeOptions = ['1M', '3M', '6M', '1Y', 'All Time'];

  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 60) return '1 month ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }



  void _startRoutine(HydratedRoutineDetail routine) {
    final exercises = routine.exercises.map((he) {
      final config = he.config;
      final sets = List.generate(
        config.defaultSets,
        (_) => WorkoutSetState(
          id: const Uuid().v4(),
          weightKg: config.defaultWeightKg ?? 0.0,
          reps: config.defaultReps ?? 0,
        ),
      );
      return WorkoutExerciseState(
        exerciseId: he.exercise.id,
        name: he.exercise.name,
        sets: sets.isEmpty ? [WorkoutSetState.create()] : sets,
      );
    }).toList();

    ref.read(activeWorkoutProvider.notifier).startWorkout(
      routineId: routine.routine.id,
      initialExercises: exercises,
    );
    context.push('/workout/active');
  }

  Future<void> _deleteRoutine(String routineId) async {
    final db = ref.read(databaseProvider);
    await db.routinesDao.deleteRoutine(routineId);
    if (!mounted) return;
    context.pop();
  }

  void _editRoutine() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coming soon',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        backgroundColor: const Color(0xFF121212),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActionsSheet(HydratedRoutineDetail routine) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A6A6A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      routine.routine.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(
                  color: Color(0x0DFFFFFF),
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                ),
                _SheetActionRow(
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFFB3B3B3),
                  iconBackground: AppColors.bgBase,
                  title: 'Edit Routine',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _editRoutine();
                  },
                ),
                const Divider(
                  color: Color(0x0DFFFFFF),
                  height: 1,
                  indent: 80,
                  endIndent: 24,
                ),
                _SheetActionRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.error,
                  iconBackground: AppColors.error.withValues(alpha: 0.12),
                  title: 'Delete Routine',
                  titleColor: AppColors.error,
                  subtitle: 'This cannot be undone',
                  subtitleColor: AppColors.error.withValues(alpha: 0.7),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _confirmDelete(context, routine.routine.id);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String routineId) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Routine?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This routine will be permanently deleted.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFFB3B3B3),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFFB3B3B3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _deleteRoutine(routineId);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(routineDetailProvider(widget.routineId));
    ref.invalidate(
        routineVolumeProvider((widget.routineId, _selectedTimeRange)));
    ref.invalidate(routineLastSetsProvider(widget.routineId));
  }

  void _showTimeRangeSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Time Range',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._timeRangeOptions.map((range) {
                    final isSelected = range == _selectedTimeRange;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTimeRange = range);
                        Navigator.of(sheetCtx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.textSecondary.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                range,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.accentPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.accentPrimary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routineAsync = ref.watch(routineDetailProvider(widget.routineId));
    final volumeAsync = ref.watch(
      routineVolumeProvider((widget.routineId, _selectedTimeRange)),
    );
    final lastSetsAsync = ref.watch(routineLastSetsProvider(widget.routineId));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: routineAsync.when(
        loading: () => _buildSkeleton(),
        error: (_, __) => _buildError(),
        data: (routine) {
          if (routine == null) {
            return _buildNotFound();
          }
          return _buildScrollView(
            routine,
            volumeAsync,
            lastSetsAsync.valueOrNull ?? {},
            lastSetsAsync.isLoading && lastSetsAsync.valueOrNull == null,
          );
        },
      ),
    );
  }

  Widget _buildScrollView(
    HydratedRoutineDetail routine,
    AsyncValue<List<RoutineVolumeData>> volumeAsync,
    Map<String, List<LastSessionSetData>> lastSetsMap,
    bool isLoadingHistory,
  ) {
    final lastDate = volumeAsync.valueOrNull?.isNotEmpty == true
        ? volumeAsync.valueOrNull!.last.date
        : null;
    final exerciseCount = routine.exercises.length;

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => false,
      child: RefreshIndicator(
        color: AppColors.accentPrimary,
        backgroundColor: const Color(0xFF121212),
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── SliverAppBar ─────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              toolbarHeight: 56,
              backgroundColor: AppColors.bgBase,
              scrolledUnderElevation: 0,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              centerTitle: false,
              title: Text(
                routine.routine.name,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              leading: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: AppColors.textPrimary,
                  onPressed: () => context.pop(),
                ),
              ),
              actions: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.more_horiz),
                    color: AppColors.textPrimary,
                    onPressed: () => _showActionsSheet(routine),
                  ),
                ),
              ],
            ),

            // ── Attribution + CTA ────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0.0, 0.3, curve: Curves.easeOutExpo),
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _entryController,
                      curve: const Interval(0.0, 0.3, curve: Curves.easeOutExpo),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''}${lastDate != null ? ' · Last performed ${_relativeTime(lastDate)}' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          button: true,
                          label: 'Start Routine',
                          child: _StartRoutineButton(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _startRoutine(routine);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 44,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.textSecondary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _editRoutine();
                              },
                              child: Center(
                                child: Text(
                                  'Edit Routine',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Graph Section ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0.2, 0.45, curve: Curves.easeOutExpo),
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _entryController,
                      curve: const Interval(0.2, 0.45, curve: Curves.easeOutExpo),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total Volume',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(kg)',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Time Range',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TimeFilterTapTarget(
                              value: _selectedTimeRange,
                              onTap: () => _showTimeRangeSheet(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: volumeAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentPrimary,
                              ),
                            ),
                            error: (_, __) => Center(
                              child: Text(
                                'No data',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6A6A6A),
                                ),
                              ),
                            ),
                            data: (data) => AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: RoutineVolumeGraph(
                                key: ValueKey(_selectedTimeRange +
                                    data.length.toString()),
                                data: data,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Exercise List ────────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exercise = routine.exercises[index];
                  final exKey = exercise.exercise.id.toString();
                  final sets = lastSetsMap[exKey];
                  final delay = index * 0.04;
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _entryController,
                        curve: Interval(
                          (0.35 + delay).clamp(0.0, 0.9),
                          (0.55 + delay).clamp(0.0, 1.0),
                          curve: Curves.easeOutExpo,
                        ),
                      ),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _entryController,
                          curve: Interval(
                            (0.35 + delay).clamp(0.0, 0.9),
                            (0.55 + delay).clamp(0.0, 1.0),
                            curve: Curves.easeOutExpo,
                          ),
                        ),
                      ),
                      child: RoutineExerciseBlock(
                        hydratedExercise: exercise,
                        lastSets: sets,
                        isLoadingHistory: isLoadingHistory,
                      ),
                    ),
                  );
                },
                childCount: routine.exercises.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(
          pinned: true,
          floating: false,
          snap: false,
          toolbarHeight: 56,
          backgroundColor: AppColors.bgBase,
          scrolledUnderElevation: 0,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          centerTitle: false,
          title: SizedBox.shrink(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't load routine",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to retry',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6A6A6A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Text(
        'Routine not found',
        style: GoogleFonts.inter(color: const Color(0xFF6A6A6A)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _StartRoutineButton extends StatefulWidget {
  final VoidCallback onTap;

  const _StartRoutineButton({required this.onTap});

  @override
  State<_StartRoutineButton> createState() => _StartRoutineButtonState();
}

class _StartRoutineButtonState extends State<_StartRoutineButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.97);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  void _onTap() {
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuint,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: _onTap,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Start Routine',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeFilterTapTarget extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _TimeFilterTapTarget({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _SheetActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor ?? const Color(0xFF6A6A6A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

`


### 7.4 Reusable Components

- lib/shared/widgets\active_workout_bar.dart

- lib/shared/widgets\app_shell.dart

- lib/shared/widgets\bottom_nav_bar.dart

- lib/shared/widgets\exercise_gif_widget.dart

- lib/shared/widgets\ui\action_bottom_sheet.dart

- lib/shared/widgets\ui\primary_button.dart

- lib/shared/widgets\ui\secondary_button.dart

- lib/shared/widgets\ui\toggle_pill.dart

- lib/shared/widgets\ui\tracker_card.dart


## 8. Business Logic

- Workout Rules: Managed by WorkoutTimerProvider and ActiveWorkoutProvider.

- Volume Calculation: Volume = Sets * Reps * WeightKg.


## 9. Assets & Resources

- assets\db\exercises.db

- assets\db\exercises.json


## 10. Utilities & Constants

### formatters.dart
`dart
String formatWorkoutDuration(DateTime start, DateTime? end) {
  final duration = end != null ? end.difference(start) : DateTime.now().difference(start);
  
  if (duration.inHours > 0) {
    final minutes = duration.inMinutes % 60;
    return '${duration.inHours}h ${minutes}m';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m';
  } else {
    return '${duration.inSeconds}s';
  }
}

String getWorkoutNameFallback(DateTime start, String? existingName) {
  if (existingName != null && existingName.isNotEmpty && existingName != 'Workout') {
    return existingName;
  }
  
  final hour = start.hour;
  if (hour >= 5 && hour < 12) {
    return 'Morning Workout';
  } else if (hour >= 12 && hour < 17) {
    return 'Afternoon Workout';
  } else if (hour >= 17 && hour < 21) {
    return 'Evening Workout';
  } else {
    return 'Night Workout';
  }
}

`


## 11. Critical Implementation Notes

- No explicit TODOs or FIXMEs found in code comments.

- Noted that DB and Auth have stubs but no full implementation based on docs.

