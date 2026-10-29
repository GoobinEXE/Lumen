# Graph Report - TDAH  (2026-10-29)

## Corpus Check
- 241 files · ~154,077 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 61 file(s) not represented in the graph (top: .xml 10, .plist 8, .xcconfig 8)

## Summary
- 3477 nodes · 5191 edges · 182 communities (159 shown, 23 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 73 edges (avg confidence: 0.86)
- Token cost: 629,555 input · 0 output

## Community Hubs (Navigation)
- Shell Navigation Imports
- App Icons
- Fase 0 Feedback Plans
- Android Platform Bridges
- Localization & Shell Tests
- Agent Rules & GDD Core
- Routine Export Copy
- Lumen Glass Style
- Medication Reminder Service
- Domain Unit Tests
- Dashboard Card Widgets
- App Colors
- Task Reminder Service
- Glass Nav Bar
- Liquid Glass Chrome
- Settings Screen
- First Launch Onboarding
- Dose Reminder Schedule
- Correlation Engine
- Pubspec Dependencies
- Glass Surface
- Core Providers
- Medication Repository
- Glass Chips & Buttons
- Medication Providers
- Add Medication Sheet
- Toast & Skeletons
- Task Editor Sheet
- Correlation Copy
- Facade Health Service
- Home Ficha Screen
- Check-in Form
- Des-Trava Sheet
- Health Plugin Store
- Clinical Folder Screen
- Correlation Engine Tests
- Onboarding Profile Draft
- HealthKit Bridge (Dart)
- Health Mirror Idempotency
- Profile Screen
- Locale & Theme Providers
- Routine Providers
- Async Placeholders
- Care Contact Repository
- Profile & Check-in Tests
- Profile Feed Providers
- HealthKit Bridge (Swift)
- Period Export Stats
- Local Notifications Host
- Medication Model
- Task Repository
- Samsung Health Connector
- Stateful Sheets & Shell
- Weekly Summary Card
- State of Mind Editor
- Routine Repository
- Health Connect Connector
- Task Period Logic
- Apple HealthKit Connector
- Mood Repository
- Onboarding Profile Form
- HealthService Interface
- HealthAppConnector Contract
- Spacing & Radii
- Health Sync Prefs
- TaskItem Model
- Task Export
- Task Reminder Schedule
- App Theme
- Routine Calendar Screen
- Routine Snapshot
- User Profile Repository
- Sleep Record
- Samsung Health Bridge
- Background Notifications
- Local Data Export
- Profile Sheet Card
- GDD Docx Generator
- Onboarding Widget Tests
- Mood Entry Labels
- Daily Routine Screen Imports
- Task Providers
- Glass App Bar
- Notification Buses
- Care Contact Editor
- Health Connector Selector
- Therapist Report Screen
- iOS Runner Bridges
- Daily Recovery Snapshot
- Routine Export Model
- Medication Log
- Health Demographics
- App Bootstrap
- Routine Health Mirror
- Day Digest Providers
- PDF KPI Styling
- Home Data Providers
- Health Consent Sheet
- UserProfile Model
- DailyRoutineState Model
- macOS & Runner Tests
- Day Digest Model
- Medications Screen
- Des-Trava Prototype (New)
- Insights & Med Window Cards
- Daily Routine Screen
- State of Mind Entry
- Task Tests
- Sync Ledger
- Tasks Hub Screen
- Profile Feed Item
- Async Mutex Locks
- CareContact Model
- Environment Snapshot
- Soft Liquid Glass Design
- Device Calendar
- Calendar Bridge (Swift)
- Sleep & Health Sync UI
- Theme Mode Provider
- System Time Picker
- Task Quiet Hours
- Início Ficha Prototype
- macOS Plugin Registrant
- PDF Style Prefs
- iOS AppDelegate
- Feedback & Privacy Config
- State of Mind Labels
- Sleep Night Intervals
- Connector Selector Tests
- GDD PDF Generator
- Stored JSON Persistence
- Efficacy Window
- Smaller-Step Escape
- Pasta Clínica Prototype
- Profile Demographics
- Responsive Helpers
- Riverpod Notifiers
- Glass Surface Tests
- Check-in Prototype
- Clinical Hub Prototype
- Home Meds Card Prototype
- Dia Tab Prototype
- Safety & Privacy Claims
- Onboarding Bootstrap
- Civil Day Helpers
- Onboarding Prefs
- Voice Tone Profile
- Reminder Permission Banners
- Rotina Prototype
- Des-Trava Prototype (Old)
- Home Hub Prototype
- Remédios Prototype
- Quiet Hours Prefs
- Micro-habits Prefs
- PDF Report Style
- Care Contact Labels
- Profile Labels
- Apple Health Service
- L10n Labels
- macOS AppDelegate
- Demographics Mapper
- Shell Navigation Doors
- Care Contacts Section
- Analyzer Options
- Zero-Guilt Micro-habits
- Deprecated APIs
- Shell Page KeepAlive
- Four-Tab Bottom Nav
- Correlation Copy Interface
- Next Dose Test
- Shell Scope
- Shell Stack Observer
- HealthAppSource
- HealthCapability
- Flutter Web Shell
- Launch Image README

## God Nodes (most connected - your core abstractions)
1. `appLocalizationsProvider` - 63 edges
2. `Fase 0 Feedback plan (FASE_0_FEEDBACK.md)` - 48 edges
3. `Lumen GDD (Game Design Document)` - 41 edges
4. `Soft Liquid Glass Design System` - 22 edges
5. `dependencies` - 19 edges
6. `HealthKitBridge` - 17 edges
7. `userProfileProvider` - 16 edges
8. `tasksListProvider` - 15 edges
9. `_ClinicalFolderScreenState` - 13 edges
10. `SettingsScreen` - 12 edges

## Surprising Connections (you probably didn't know these)
- `No-guilt, humanized copy principle` --semantically_similar_to--> `Forbidden code patterns (Timer dose reminder, guilt copy)`  [INFERRED] [semantically similar]
  docs/GDD.md → AGENTS.md
- `EKReminder / app Lembretes fora de escopo` --semantically_similar_to--> `Princípio: funcionamento pessoal antes de SDK`  [INFERRED] [semantically similar]
  .cursor/plans/fase_0_7_alarmes_tarefas.plan.md → docs/FASE_0_FEEDBACK.md
- `Uma porta principal por job` --semantically_similar_to--> `Uma porta principal por job`  [INFERRED] [semantically similar]
  .cursor/plans/fase_0_8_navegacao.plan.md → docs/FASE_0_FEEDBACK.md
- `Ocultar Notas Íntimas Toggle` --semantically_similar_to--> `User Privacy Controls (revoke, delete, export, hide intimate notes)`  [INFERRED] [semantically similar]
  Design/Stitch/new/pasta_cl_nica_exporta_o_consulta/code.html → site/index.html
- `User-Initiated Sharing (PDF, WhatsApp, card via system share)` --semantically_similar_to--> `Enviar via WhatsApp (primary export)`  [INFERRED] [semantically similar]
  site/index.html → Design/Stitch/new/pasta_cl_nica_exporta_o_consulta/code.html

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Check-in write flow (MoodEntry + SoM snapshot + Health mirror)** — docs_gdd_checkin, docs_gdd_moodentry, docs_gdd_dailyroutinestate, docs_gdd_state_of_mind, docs_gdd_healthkit_bridge [EXTRACTED 1.00]
- **Health integration stack under parity rule** — docs_gdd_health_parity_rule, docs_gdd_health_service, docs_gdd_healthkit_bridge, docs_gdd_health_connect, docs_gdd_hrv_sdnn_rmssd [EXTRACTED 1.00]
- **i18n pipeline (arb → doloc → gen-l10n)** — docs_i18n_app_pt_arb, docs_i18n_doloc, docs_i18n_app_localizations [EXTRACTED 1.00]
- **Fase 0 Feedback subphases 0.1–0.8** — docs_fase_0_feedback_fase_0_1, docs_fase_0_feedback_fase_0_2, docs_fase_0_feedback_fase_0_3, docs_fase_0_feedback_fase_0_4, docs_fase_0_feedback_fase_0_5, docs_fase_0_feedback_fase_0_6, docs_fase_0_feedback_fase_0_7, docs_fase_0_feedback_fase_0_8 [EXTRACTED 1.00]
- **Canonical navigation doors with pop-to-root** — docs_fase_0_feedback_showtab_poptoroot, docs_fase_0_feedback_opentaskshub, docs_fase_0_feedback_openroutinecalendarscreen, docs_fase_0_feedback_openclinicalfolderscreen, docs_fase_0_feedback_one_door_per_job [EXTRACTED 1.00]
- **Dose log integrity fixes (0.2/0.6)** — docs_fase_0_feedback_alignday_logs, docs_fase_0_feedback_medicationrepository_synchronized, docs_fase_0_feedback_ensuredoselog, docs_fase_0_feedback_multidose_slots [INFERRED 0.85]
- **Des-Trava three-step anti-paralysis flow** — design_stitch_lumen_des_trava_anti_paralisia_code_micro_acao_fisica, design_stitch_lumen_des_trava_anti_paralisia_code_palavra_unica, design_stitch_lumen_des_trava_anti_paralisia_code_timer_60s, design_stitch_lumen_des_trava_anti_paralisia_code_pacto_parar_ok [EXTRACTED 1.00]
- **Lumen brand color triad** — design_stitch_soft_liquid_glass_design_primary_mint_teal, design_stitch_soft_liquid_glass_design_secondary_calming_lavender, design_stitch_soft_liquid_glass_design_tertiary_gentle_coral, design_stitch_lumen_minimalist_mark_code [INFERRED 0.85]
- **Check-in rápido field set** — design_stitch_lumen_check_in_r_pido_code_valencia_emocional, design_stitch_lumen_check_in_r_pido_code_matriz_de_foco, design_stitch_lumen_check_in_r_pido_code_nivel_de_energia, design_stitch_lumen_check_in_r_pido_code_sinais_fisiologicos, design_stitch_lumen_check_in_r_pido_code_nuvem_state_of_mind, design_stitch_lumen_check_in_r_pido_code_nota_opcional [EXTRACTED 1.00]
- **Stitch four-tab shell screens (Início · Dia · Remédios · Pasta clínica)** — design_stitch_new_in_cio_hub_pessoal_ficha_viva_code_inicio_ficha_viva, design_stitch_new_dia_execu_o_rotina_code_dia_tab_screen, design_stitch_new_rem_dios_posologia_alarmes_code_remedios_screen, design_stitch_new_pasta_cl_nica_exporta_o_consulta_code_pasta_clinica_screen, design_stitch_new_dia_execu_o_rotina_code_bottom_nav_four_tabs [EXTRACTED 1.00]
- **Stitch prototypes built on Soft Liquid Glass tokens** — design_stitch_new_lumen_soft_liquid_glass_design_lumen_soft_liquid_glass, design_stitch_new_des_trava_resgate_anti_paralisia_code_des_trava_rescue_sheet, design_stitch_new_dia_execu_o_rotina_code_dia_tab_screen, design_stitch_new_in_cio_hub_pessoal_ficha_viva_code_inicio_ficha_viva, design_stitch_new_pasta_cl_nica_exporta_o_consulta_code_pasta_clinica_screen, design_stitch_new_rem_dios_posologia_alarmes_code_remedios_screen [INFERRED 0.95]
- **Anti-paralysis micro-step pattern** — design_stitch_new_lumen_soft_liquid_glass_design_micro_passo_component, design_stitch_new_dia_execu_o_rotina_code_micro_passo_imediato, design_stitch_new_des_trava_resgate_anti_paralisia_code_three_micro_steps, design_stitch_new_des_trava_resgate_anti_paralisia_code_cyclesmallerstep [INFERRED 0.85]

## Communities (182 total, 23 thin omitted)

### Community 0 - "Shell Navigation Imports"
Cohesion: 0.02
Nodes (64): _activeCanPopNotifier, _buildPageView, _buildTabBar, child, _clinicalFolderRoute, createState, _destinations, didPop (+56 more)

### Community 1 - "App Icons"
Cohesion: 0.03
Nodes (66): add, anchor, AppIcons, back, block, brain, calendar, chat (+58 more)

### Community 2 - "Fase 0 Feedback Plans"
Cohesion: 0.06
Nodes (58): Plano Fase 0.6 — Multi-dose, Dependência da Fase 0.2 (realign não reseta status), Plano Fase 0.7 — Clareza dos alarmes de tarefas, Plano Fase 0.8 — Navegação mais intuitiva, Uma porta principal por job, Samsung Health Data SDK libs README, Health Connect fallback, Samsung Health Data SDK AAR (+50 more)

### Community 3 - "Android Platform Bridges"
Cohesion: 0.05
Nodes (14): CalendarBridge, MainActivity, SamsungHealthBridge, SystemSettingsBridge, background_color, description, display, icons (+6 more)

### Community 4 - "Localization & Shell Tests"
Cohesion: 0.06
Nodes (30): code, lookupAppLocalizations, resolveSupportedLocale, l10n, main, openSheet, l10n, main (+22 more)

### Community 5 - "Agent Rules & GDD Core"
Cohesion: 0.06
Nodes (48): AGENTS.md Flutter engineer instructions, Riverpod for persisted state, showLumenSheet + GlassSheet (useRootNavigator), Lumen GDD (Game Design Document), Calendário & Raio-X do Dia (DayDigest), Check-in (CheckInForm), Pasta clínica (ClinicalFolderScreen), Acompanhamento Clínico pillar (+40 more)

### Community 6 - "Routine Export Copy"
Cohesion: 0.04
Nodes (39): anchor, describeRoutineExportLine, languageCode, som, somLabels, when, accent, accentSoft (+31 more)

### Community 7 - "Lumen Glass Style"
Cohesion: 0.04
Nodes (40): alpha, baseAlpha, blur, blurRadius, build, child, cornerRadius, debugLumenForceFakeGlass (+32 more)

### Community 8 - "Medication Reminder Service"
Cohesion: 0.04
Nodes (46): _androidMode, _apply, applyResponse, body, cancelSnooze, code, copyWith, _details (+38 more)

### Community 9 - "Domain Unit Tests"
Cohesion: 0.07
Nodes (15): day, main, main, main, main, main, main, main (+7 more)

### Community 10 - "Dashboard Card Widgets"
Cohesion: 0.06
Nodes (26): build, durationHours, log, build, _busySnooze, _busyTaken, createState, log (+18 more)

### Community 11 - "App Colors"
Cohesion: 0.05
Nodes (42): accent, accentSoft, AppColors, backgroundDark, backgroundLight, cardBorderDark, cardBorderLight, cardDark (+34 more)

### Community 12 - "Task Reminder Service"
Cohesion: 0.05
Nodes (35): _androidMode, _apply, applyResponse, body, details, empty, _ensureTimeZone, exactAlarmsAllowed (+27 more)

### Community 13 - "Glass Nav Bar"
Cohesion: 0.05
Nodes (36): barHeight, bottomGap, build, child, color, contentGap, createState, destination (+28 more)

### Community 14 - "Liquid Glass Chrome"
Cohesion: 0.06
Nodes (34): LumenGlass, LumenGlassLite, GlassNavBar, _NavDockChrome, _NavSlot, associations, _CheckInTile, child (+26 more)

### Community 15 - "Settings Screen"
Cohesion: 0.06
Nodes (26): _exportLocal, feedbackFormLauncherProvider, icon, localDataExportProvider, _localeLabel, onTap, _openPrivacyPolicy, _openSystem (+18 more)

### Community 16 - "First Launch Onboarding"
Cohesion: 0.05
Nodes (33): _back, body, build, _busy, _calendar, choice, createState, _demographics (+25 more)

### Community 17 - "Dose Reminder Schedule"
Cohesion: 0.06
Nodes (35): action, at, decode, decoded, doseNotificationId, DoseOccurrence, encode, hasAction (+27 more)

### Community 18 - "Correlation Engine"
Cohesion: 0.06
Nodes (34): actionableAdvice, analyze, CorrelationEngine, CorrelationInsight, correlationPercentage, description, iconKey, insightCollectingAdvice (+26 more)

### Community 19 - "Pubspec Dependencies"
Cohesion: 0.06
Nodes (35): dependencies, cupertino_icons, fl_chart, flutter, flutter_local_notifications, flutter_localizations, flutter_riverpod, flutter_timezone (+27 more)

### Community 20 - "Glass Surface"
Cohesion: 0.06
Nodes (28): borderRadius, build, child, defaultPadding, enableDrag, expandChild, fraction, glassInkOverlay (+20 more)

### Community 21 - "Core Providers"
Cohesion: 0.06
Nodes (25): addEntry, analyze, appleStateOfMindHistoryProvider, environmentHistoryProvider, getEnvironmentHistory, getRecoveryHistory, getSleepHistory, getStateOfMindHistory (+17 more)

### Community 22 - "Medication Repository"
Cohesion: 0.06
Nodes (33): addExternalLog, alignDayLogs, deleteMedication, ensureDoseLog, getAllLogs, getLogsForDate, getLogsForDateReadOnly, getMedications (+25 more)

### Community 23 - "Glass Chips & Buttons"
Cohesion: 0.08
Nodes (23): avatar, build, GlassActionChip, GlassChip, icon, label, onTap, selected (+15 more)

### Community 24 - "Medication Providers"
Cohesion: 0.06
Nodes (28): MedicationRepository, _checkedSchedule, deleteMedication, dispose, getMedications, health, importFromAppleHealth, initialize (+20 more)

### Community 25 - "Add Medication Sheet"
Cohesion: 0.06
Nodes (29): _applyPreset, build, createState, dispose, _dosageController, _dosageFocus, _durationHours, _editTime (+21 more)

### Community 26 - "Toast & Skeletons"
Cohesion: 0.08
Nodes (22): PulseSkeletonBar, _PulseSkeletonBarState, build, _controller, createState, _dismiss, dispose, duration (+14 more)

### Community 27 - "Task Editor Sheet"
Cohesion: 0.07
Nodes (27): actionLabel, _alertHint, _alertLabel, _alertStyle, body, createState, _dayOfMonth, dispose (+19 more)

### Community 28 - "Correlation Copy"
Cohesion: 0.07
Nodes (26): insightCollectingAdvice, insightCollectingDescGeneric, insightCollectingDescHealth, insightCollectingTitle, insightDaylightAdvice, insightDaylightDesc, insightDaylightTitle, insightHrvAdvice (+18 more)

### Community 29 - "Facade Health Service"
Cohesion: 0.07
Nodes (25): activeSource, _ensureResolved, _fallback, _forCapability, getEnvironmentHistory, getLastNightSleep, getRecoveryHistory, getSleepHistory (+17 more)

### Community 30 - "Home Ficha Screen"
Cohesion: 0.07
Nodes (20): _call, child, contact, displayName, _greeting, highlighted, icon, l10n (+12 more)

### Community 31 - "Check-in Form"
Cohesion: 0.07
Nodes (27): _buildValenceButton, CheckInDraft, CheckInHalo, copyWith, createState, dispose, draft, emotionLabels (+19 more)

### Community 32 - "Des-Trava Sheet"
Cohesion: 0.07
Nodes (24): _advance, _AssistantOrb, build, controller, createState, _currentStep, didChangeDependencies, dispose (+16 more)

### Community 33 - "Health Plugin Store"
Cohesion: 0.07
Nodes (22): allPermissions, allTypes, _averageNumericInRange, configure, demographicsReadTypes, getRecoveryHistory, getSleepHistory, hasPermissions (+14 more)

### Community 34 - "Clinical Folder Screen"
Cohesion: 0.07
Nodes (22): busy, _busyShareCard, _busySharePdf, _busyWhatsApp, buttonLabel, _cardKey, _ClinicalFolderActionTone, createState (+14 more)

### Community 35 - "Correlation Engine Tests"
Cohesion: 0.07
Nodes (26): insightCollectingAdvice, insightCollectingDescGeneric, insightCollectingDescHealth, insightCollectingTitle, insightDaylightAdvice, insightDaylightDesc, insightDaylightTitle, insightHrvAdvice (+18 more)

### Community 36 - "Onboarding Profile Draft"
Cohesion: 0.08
Nodes (22): alwaysRequired, applyTo, biologicalSex, birthDate, copyWith, fromProfile, hasInvalidMetrics, healthFilled (+14 more)

### Community 37 - "HealthKit Bridge (Dart)"
Cohesion: 0.08
Nodes (24): appleConceptId, _channel, form, HealthKitBridge, HealthKitDoseEvent, healthKitMedicationId, HealthKitMedicationInfo, isActive (+16 more)

### Community 38 - "Health Mirror Idempotency"
Cohesion: 0.08
Nodes (23): activeSource, getEnvironmentHistory, getLastNightSleep, getRecoveryHistory, getSleepHistory, getStateOfMindHistory, hasPermissions, initialize (+15 more)

### Community 39 - "Profile Screen"
Cohesion: 0.08
Nodes (19): UserProfileNotifier, UserProfile, createState, _draft, _FeedTile, _HealthBadge, icon, _iconFor (+11 more)

### Community 40 - "Locale & Theme Providers"
Cohesion: 0.14
Nodes (24): activeLocaleProvider, appLocalizationsProvider, lastRecoveryProvider, themeModeProvider, build, dayDigestProvider, build, DayDigestSheet (+16 more)

### Community 41 - "Routine Providers"
Cohesion: 0.08
Nodes (20): countAppleHealthStateOfMind, getSnapshotsForDate, l10n, markedDays, markedRoutineDaysProvider, mergeTodayStateOfMind, mirror, mirrorIfEnabled (+12 more)

### Community 42 - "Async Placeholders"
Cohesion: 0.08
Nodes (23): bars, _BlockSkeleton, borderRadius, build, busy, BusyButtonChild, child, _controller (+15 more)

### Community 43 - "Care Contact Repository"
Cohesion: 0.08
Nodes (24): contactsKey, currentKey, _decodeContacts, _decodeJsonList, delete, _encodeContacts, legacyKey, legacyPhoneKey (+16 more)

### Community 44 - "Profile & Check-in Tests"
Cohesion: 0.09
Nodes (6): main, main, build, l10n, main, main

### Community 45 - "Profile Feed Providers"
Cohesion: 0.08
Nodes (20): allMedLogs, buildProfileFeed, cappedMood, cappedSnapshots, day, items, kProfileFeedMaxItems, l10n (+12 more)

### Community 47 - "Period Export Stats"
Cohesion: 0.08
Nodes (22): _avg, avgDaylightMinutes, avgExerciseMinutes, avgHrv, avgNoiseDb, _avgNullable, avgRemHours, avgRestingHeartRate (+14 more)

### Community 48 - "Local Notifications Host"
Cohesion: 0.08
Nodes (16): _background, bindBackground, _configure, consumeLaunch, dispatch, ensureInitialized, _initializing, kindFromPayload (+8 more)

### Community 49 - "Medication Model"
Cohesion: 0.08
Nodes (23): active, appleConceptId, copyWith, daysOfWeek, dosage, durationHours, fromMap, healthKitMedicationId (+15 more)

### Community 50 - "Task Repository"
Cohesion: 0.08
Nodes (22): _cache, completedTitles, delete, getById, getTasks, loadOrSeed, markComplete, markIncomplete (+14 more)

### Community 51 - "Samsung Health Connector"
Cohesion: 0.08
Nodes (20): _bridge, _capabilities, getEnvironmentHistory, getRecoveryHistory, getSleepHistory, getStateOfMindHistory, hasPermissions, initialize (+12 more)

### Community 52 - "Stateful Sheets & Shell"
Cohesion: 0.11
Nodes (20): LumenShell, _LumenShellState, AddMedicationSheet, _AddMedicationSheetState, MedicationCard, _MedicationCardState, _ProfileEditSheet, _ProfileEditSheetState (+12 more)

### Community 53 - "Weekly Summary Card"
Cohesion: 0.09
Nodes (18): border, build, icon, ink, isDark, label, _MetricTile, moodEntries (+10 more)

### Community 54 - "State of Mind Editor"
Cohesion: 0.09
Nodes (18): _associations, build, _collapsedLabelCount, createState, _emit, initial, initState, _kind (+10 more)

### Community 55 - "Routine Repository"
Cohesion: 0.09
Nodes (17): appendSnapshot, _blockedKeys, countAppleHealthStateOfMind, _decode, _getKey, getSnapshotsForDate, _keyPattern, markedDays (+9 more)

### Community 56 - "Health Connect Connector"
Cohesion: 0.09
Nodes (20): _capabilities, getEnvironmentHistory, getRecoveryHistory, getSleepHistory, getStateOfMindHistory, hasPermissions, initialize, isAvailable (+12 more)

### Community 57 - "Task Period Logic"
Cohesion: 0.09
Nodes (19): anchorFireAt, appliesOn, biweeklyEpoch, _biweeklyStart, contains, _dayKey, _daysInMonth, end (+11 more)

### Community 58 - "Apple HealthKit Connector"
Cohesion: 0.09
Nodes (21): _capabilities, getEnvironmentHistory, getRecoveryHistory, getSleepHistory, getStateOfMindHistory, hasPermissions, initialize, isAvailable (+13 more)

### Community 59 - "Mood Repository"
Cohesion: 0.09
Nodes (16): addEntry, _byDayCache, _cache, getAllEntries, getEntriesForCivilDay, getEntriesForDays, getLatestEntry, _indexByDay (+8 more)

### Community 60 - "Onboarding Profile Form"
Cohesion: 0.09
Nodes (18): OnboardingProfileDraft, build, createState, dispose, draft, _FieldLabel, fromHealth, _HealthTag (+10 more)

### Community 61 - "HealthService Interface"
Cohesion: 0.09
Nodes (19): activeSource, getEnvironmentHistory, getLastNightSleep, getRecoveryHistory, getSleepHistory, getStateOfMindHistory, hasPermissions, initialize (+11 more)

### Community 62 - "HealthAppConnector Contract"
Cohesion: 0.09
Nodes (19): getEnvironmentHistory, getRecoveryHistory, getSleepHistory, getStateOfMindHistory, hasPermissions, initialize, isAvailable, isMedicationsApiAvailable (+11 more)

### Community 63 - "Spacing & Radii"
Cohesion: 0.09
Nodes (21): AppRadii, AppSheetHandle, AppSpacing, button, buttonMaterial, card, chip, handle (+13 more)

### Community 64 - "Health Sync Prefs"
Cohesion: 0.09
Nodes (20): contains, _dayKey, getBool, getInt, getSyncedStateOfMindMs, getSyncedWaterGlasses, healthSyncEnabledKey, isBreathingMindfulnessHabit (+12 more)

### Community 65 - "TaskItem Model"
Cohesion: 0.09
Nodes (21): active, alertStyle, alertStyleFrom, completedPeriodKey, copyWith, _dateOnly, dayOfMonth, fromMap (+13 more)

### Community 66 - "Task Export"
Cohesion: 0.09
Nodes (18): TaskRecurrence, _appliesInWindow, completed, completedMarker, day, describeTaskExportLines, false, last (+10 more)

### Community 67 - "Task Reminder Schedule"
Cohesion: 0.09
Nodes (21): action, alertStyle, decode, decoded, encode, hasAction, hash, kind (+13 more)

### Community 68 - "App Theme"
Cohesion: 0.10
Nodes (15): androidTheme, AppTheme, _cupertinoTransitions, _darkScheme, darkTheme, _elevatedStyle, iosEngineTheme, _lightScheme (+7 more)

### Community 69 - "Routine Calendar Screen"
Cohesion: 0.11
Nodes (16): markedHistoryDaysProvider, build, createState, initState, isDark, localeName, marked, _month (+8 more)

### Community 70 - "Routine Snapshot"
Cohesion: 0.10
Nodes (19): calendarEventId, capture, completedHabits, copyWith, day, eveningReflection, fromLegacy, fromMap (+11 more)

### Community 71 - "User Profile Repository"
Cohesion: 0.10
Nodes (16): applyDemographicsGaps, fallback, _prefs, prefsKey, profileDisplayName, read, _repository, save (+8 more)

### Community 72 - "Sleep Record"
Cohesion: 0.10
Nodes (18): averageHeartRate, awakeDuration, bedtime, date, deepHours, deepSleep, formatDuration, fromMap (+10 more)

### Community 73 - "Samsung Health Bridge"
Cohesion: 0.10
Nodes (16): _channel, _channelName, connect, hasPermissions, isAvailable, isSdkLinked, isSupported, readDemographics (+8 more)

### Community 74 - "Background Notifications"
Cohesion: 0.11
Nodes (6): ensureTimeZone, LocalNotificationScheduler, _timeZoneReady, zonedSchedule, _handle, localNotificationsBackground

### Community 75 - "Local Data Export"
Cohesion: 0.11
Nodes (11): buildPayload, collectKeys, LocalDataExport, shareBackup, captureAndShare, ShareCardExporter, apiToken, main (+3 more)

### Community 76 - "Profile Sheet Card"
Cohesion: 0.10
Nodes (16): build, displayName, icon, _InfoRow, ink, label, medications, moodEntries (+8 more)

### Community 77 - "GDD Docx Generator"
Cohesion: 0.16
Nodes (8): add_styled_heading(), build_docx(), convert_docx_to_pages(), format_inline_text(), main(), set_cell_background(), set_cell_borders(), set_cell_margins()

### Community 78 - "Onboarding Widget Tests"
Cohesion: 0.13
Nodes (6): l10n, main, tapButton, wrap, main, main

### Community 79 - "Mood Entry Labels"
Cohesion: 0.10
Nodes (18): EnergyLevelLabels, FocusStateLabels, MoodEntryLabels, emotionLabels, emotionSource, energy, EnergyLevel, focus (+10 more)

### Community 80 - "Daily Routine Screen Imports"
Cohesion: 0.11
Nodes (12): _anchorTaskId, _anchorTitleFromTasks, _buildSectionCard, _checkInKey, createState, dispose, _eveningController, _initFromState (+4 more)

### Community 81 - "Task Providers"
Cohesion: 0.11
Nodes (13): _checkedSchedule, delete, dispose, load, _onExternal, ref, save, syncReminders (+5 more)

### Community 82 - "Glass App Bar"
Cohesion: 0.11
Nodes (15): actions, appBar, automaticallyImplyLeading, body, build, capsuleHeight, extendBodyBehindAppBar, floatingActionButton (+7 more)

### Community 83 - "Notification Buses"
Cohesion: 0.11
Nodes (13): doseChanged, MedicationNotificationBus, notifyDoseChanged, openMedications, requestOpenMedications, notifyTasksChanged, openRoutine, openTasks (+5 more)

### Community 84 - "Care Contact Editor"
Cohesion: 0.11
Nodes (14): build, createState, _decoration, dispose, _editing, existing, initState, _nameController (+6 more)

### Community 85 - "Health Connector Selector"
Cohesion: 0.13
Nodes (13): AppleHealthKitConnector, HealthConnectConnector, SamsungHealthConnector, HealthAppConnector, HealthAppConnectorX, _apple, fallback, _healthConnect (+5 more)

### Community 86 - "Therapist Report Screen"
Cohesion: 0.11
Nodes (7): _buildPdf, _cachedBytes, createState, hideIntimateNotes, periodDays, _shareFromAppBar, _sharing

### Community 87 - "iOS Runner Bridges"
Cohesion: 0.14
Nodes (7): EventKit, Flutter, flutter_local_notifications, HealthKit, SceneDelegate, SystemSettingsBridge, UIKit

### Community 88 - "Daily Recovery Snapshot"
Cohesion: 0.11
Nodes (16): avgEnvironmentalDb, avgHeadphoneDb, copyWith, DailyRecoverySnapshot, date, exerciseMinutes, fromMap, hasHighNoise (+8 more)

### Community 89 - "Routine Export Model"
Cohesion: 0.11
Nodes (16): StateOfMindEntryLabels, anchor, completedHabits, eveningReflection, filtered, RoutineExportLine, routineExportLines, savedAt (+8 more)

### Community 90 - "Medication Log"
Cohesion: 0.11
Nodes (17): copyWith, fromMap, id, isPending, isSnoozed, isTaken, medicationId, MedicationLog (+9 more)

### Community 91 - "Health Demographics"
Cohesion: 0.11
Nodes (16): biologicalSex, birthDate, birthDateFromEpochSeconds, code, copyWith, empty, fromCode, fromMap (+8 more)

### Community 92 - "App Bootstrap"
Cohesion: 0.12
Nodes (11): consumeLaunch, createState, didChangeLocales, didChangePlatformBrightness, dispose, initState, _localizationsDelegates, main (+3 more)

### Community 93 - "Routine Health Mirror"
Cohesion: 0.12
Nodes (10): litersPerGlass, mergeStateOfMindFromHealth, mindfulnessDuration, mirrorCheckInIfEnabled, mirrorIfEnabled, _mirrorMindfulness, _mirrorStateOfMind, mirrorStateOfMindEntry (+2 more)

### Community 94 - "Day Digest Providers"
Cohesion: 0.12
Nodes (12): checkIns, civil, completed, dayKey, logs, medRepo, moodDays, moodRepo (+4 more)

### Community 95 - "PDF KPI Styling"
Cohesion: 0.12
Nodes (11): accent, cardBorder, cardFill, fontBold, fontRegular, ink, kpiRadius, muted (+3 more)

### Community 96 - "Home Data Providers"
Cohesion: 0.28
Nodes (16): moodEntriesProvider, recoveryHistoryProvider, sleepHistoryProvider, HomeFichaScreen, _goTo, userProfileProvider, _save, _editName (+8 more)

### Community 97 - "Health Consent Sheet"
Cohesion: 0.13
Nodes (11): body, createState, icon, _InfoBlock, _isAndroid, _isConnecting, isDark, _openHealthConnect (+3 more)

### Community 98 - "UserProfile Model"
Cohesion: 0.13
Nodes (13): applyDemographicsGaps, biologicalSex, birthDate, copyWith, fromMap, heightCm, id, importedFromHealth (+5 more)

### Community 99 - "DailyRoutineState Model"
Cohesion: 0.13
Nodes (13): completedHabits, copyWith, DailyRoutineState, date, eveningReflection, fromMap, mainFocusAnchor, microHabits (+5 more)

### Community 100 - "macOS & Runner Tests"
Cohesion: 0.18
Nodes (6): Cocoa, FlutterMacOS, RunnerTests, MainFlutterWindow, RunnerTests, XCTest

### Community 101 - "Day Digest Model"
Cohesion: 0.14
Nodes (9): checkIns, civilDay, completedTaskTitles, day, DayDigest, isEmpty, medicationLogs, sameCivilDay (+1 more)

### Community 102 - "Medications Screen"
Cohesion: 0.14
Nodes (10): createState, _DoseCurveCard, _importing, log, logs, meds, paint, progress (+2 more)

### Community 103 - "Des-Trava Prototype (New)"
Cohesion: 0.18
Nodes (12): 4-7-8 Breathing Exercise Box, Des-Trava Rescue Sheet (Stitch prototype), 60-Second Start Timer with Pulsing Orb, Button Specs (Primary 52px teal, Descongelar pill, Ghost), Material Color Tokens (primary #006c53, primary-container #1faf8a), Lumen Soft Liquid Glass Design System, Micro-Checkbox Spec (28px, haptic on check), Plus Jakarta Sans Typography Scale (+4 more)

### Community 104 - "Insights & Med Window Cards"
Cohesion: 0.18
Nodes (14): correlationInsightsProvider, didChangeAppLifecycleState, build, _InsightsCard, _MedWindowCard, build, _importFromHealth, initState (+6 more)

### Community 105 - "Daily Routine Screen"
Cohesion: 0.19
Nodes (14): _AnchorCard, build, DailyRoutineScreen, _DailyRoutineScreenState, _saveRoutine, routineHealthMirrorProvider, todayRoutineDraftProvider, todaySnapshotsProvider (+6 more)

### Community 106 - "State of Mind Entry"
Cohesion: 0.14
Nodes (13): associations, checkinScaleToValence, copyWith, fromMap, kind, labels, mergePreferNewest, source (+5 more)

### Community 107 - "Task Tests"
Cohesion: 0.15
Nodes (5): daily, main, now, main, main

### Community 108 - "Sync Ledger"
Cohesion: 0.15
Nodes (9): calendarSnapshots, contains, maxIds, _memory, _read, remember, stateOfMindMs, SyncLedger (+1 more)

### Community 109 - "Tasks Hub Screen"
Cohesion: 0.15
Nodes (6): empty, isDark, now, task, tasks, title

### Community 110 - "Profile Feed Item"
Cohesion: 0.15
Nodes (11): civilDay, detail, id, isFromHealth, kind, ProfileFeedItem, ProfileFeedKind, ProfileFeedSource (+3 more)

### Community 111 - "Async Mutex Locks"
Cohesion: 0.15
Nodes (9): AsyncMutex, careContacts, medications, mood, PersistenceLocks, routine, syncLedger, _tail (+1 more)

### Community 112 - "CareContact Model"
Cohesion: 0.17
Nodes (12): CareContact, CareContactRole, CareContactRoleCodec, copyWith, displayName, fromCode, fromMap, id (+4 more)

### Community 113 - "Environment Snapshot"
Cohesion: 0.15
Nodes (12): copyWith, DailyEnvironmentSnapshot, date, daylightMinutes, envAudioDb, fromMap, hasData, hasHighEnvNoise (+4 more)

### Community 114 - "Soft Liquid Glass Design"
Cohesion: 0.23
Nodes (11): Lumen Minimalist Mark (SVG logo), Soft Liquid Glass Design System, Ambient Diffusion Elevation, Ambient Pastel Orbs Background, Frosted Glass Input Fields, Layout & Spacing Tokens (margin-mobile 20px, max 540px), Organic Rounded Shapes (16-24px radii, nested proportionality), Primary Mint Teal #1FAF8A (+3 more)

### Community 115 - "Device Calendar"
Cohesion: 0.17
Nodes (10): anchor, calendarAccessPromptedKey, _calendarChannel, createRoutineEvent, DeviceCalendar, join, lines, requestAccess (+2 more)

### Community 117 - "Sleep & Health Sync UI"
Cohesion: 0.23
Nodes (12): healthServiceProvider, lastNightSleepProvider, healthSyncEnabledProvider, build, _confirm, HealthSyncConsentSheet, _HealthSyncConsentSheetState, initState (+4 more)

### Community 118 - "Theme Mode Provider"
Cohesion: 0.17
Nodes (8): cycle, _fromStorage, _loadPreference, _ref, setThemeMode, ThemeModeNotifier, _themeModePrefKey, _toStorage

### Community 119 - "System Time Picker"
Cohesion: 0.17
Nodes (9): context, initialTime, material, platform, selected, _showAppleTimePicker, showSystemTimePicker, showTimePicker (+1 more)

### Community 120 - "Task Quiet Hours"
Cohesion: 0.17
Nodes (11): contains, defaults, endHour, endMinute, fromMap, nextAllowed, startHour, startMinute (+3 more)

### Community 121 - "Início Ficha Prototype"
Cohesion: 0.18
Nodes (11): Identity & Personal Record Block (age, height, weight chips), Início Ficha Viva Prototype (personal hub), Observação Prática Insight Card, Meus Dias Week Teaser, Meus Profissionais (care contacts, WhatsApp/call), Recuperação & Vitais Card (HRV, RHR, steps), Sono Reparador Card, Voice Tone Chip (Tom: Acolhedor e Direto) (+3 more)

### Community 122 - "macOS Plugin Registrant"
Cohesion: 0.18
Nodes (8): device_info_plus, flutter_timezone, Foundation, RegisterGeneratedPlugins(), printing, share_plus, shared_preferences_foundation, url_launcher_macos

### Community 123 - "PDF Style Prefs"
Cohesion: 0.20
Nodes (7): fromStorage, getPdfReportStyle, pdfReportStyleKey, _ref, setPdfReportStyle, setString, setStyle

### Community 125 - "Feedback & Privacy Config"
Cohesion: 0.22
Nodes (8): _, FeedbackFormConfig, uri, url, _, PrivacyPolicyConfig, uri, url

### Community 126 - "State of Mind Labels"
Cohesion: 0.20
Nodes (7): ids, label, StateOfMindAssociations, ids, label, sortedIds, StateOfMindLabels

### Community 127 - "Sleep Night Intervals"
Cohesion: 0.20
Nodes (8): aggregate, end, kind, SleepInterval, SleepIntervalKind, SleepNight, start, wakeDay

### Community 129 - "GDD PDF Generator"
Cohesion: 0.20
Nodes (4): fs, main(), path, { spawn, execSync }

### Community 130 - "Stored JSON Persistence"
Cohesion: 0.22
Nodes (7): encodeStoredJsonList, hadCorruptItems, isEmpty, items, storedJsonListIsReadable, StoredJsonListRead, unreadable

### Community 131 - "Efficacy Window"
Cohesion: 0.22
Nodes (7): crashTime, EfficacyWindow, isInPeak, ofDose, peakEnd, peakStart, takenAt

### Community 132 - "Smaller-Step Escape"
Cohesion: 0.22
Nodes (6): cycleSmallerStep(), Three Sequential Micro-Steps (reduce, remove friction, 60s pact), Âncora do Dia Card (One Thing at a Time), Micro-passo Imediato + Dividir em menores, Âncora do Dia Summary Card, Micro-Passo Component (bite-sized task breakdown)

### Community 133 - "Pasta Clínica Prototype"
Cohesion: 0.25
Nodes (9): O Que Entra no Relatório Checklist, Ocultar Notas Íntimas Toggle, Pasta Clínica Prototype (export for consultation), Baixar PDF Action, Period Chips (7 / 14 / 30 days), Privacy Toggle ↔ Free-Notes Checkbox Sync Script, Cartão Visual Modal, Weekly Share Preview Card (adherence, sleep, patterns) (+1 more)

### Community 134 - "Profile Demographics"
Cohesion: 0.22
Nodes (7): biologicalSex, birthDate, fromMap, heightCm, isEmpty, ProfileDemographics, weightKg

### Community 135 - "Responsive Helpers"
Cohesion: 0.22
Nodes (6): ensureMinTapTarget, isNarrow, kMinBodySecondary, kMinTapTarget, kNarrowBreakpoint, main

### Community 136 - "Riverpod Notifiers"
Cohesion: 0.36
Nodes (6): MoodEntriesNotifier, HealthSyncEnabledNotifier, TodayMedicationLogsNotifier, RoutineHealthMirrorNotifier, TasksListNotifier, CareContactsNotifier

### Community 138 - "Check-in Prototype"
Cohesion: 0.25
Nodes (7): Stitch Prototype: Check-in Rápido, Matriz de Foco (Focado/Hiperfoco/Disperso/Paralisado), Nível de Energia, Nota Opcional, Sinais Fisiológicos Rápidos (medicação, sobrecarga sensorial), Valência Emocional (5 níveis), CTA Check-in Rápido

### Community 139 - "Clinical Hub Prototype"
Cohesion: 0.25
Nodes (8): Stitch Prototype: Hub Clínico & Terapeuta, Contato profissional (Dra. Camila Ramos, próxima consulta), Janela do Resumo (7/14/30 dias), Toggle Ocultar notas íntimas, Relatório clínico em PDF, Síntese Estruturada (adesão, sono, estado neuroemocional, bloqueios, correlação), Enviar resumo via WhatsApp, Notas para a Terapia

### Community 140 - "Home Meds Card Prototype"
Cohesion: 0.29
Nodes (8): Bottom nav: Início · Rotina · Remédios · Clínico, Card Medicação & Foco (platô, próxima dose), Stitch Prototype: Medicações & Janela de Eficácia, Curva plasmática & janela de eficácia (Lisdexanfetamina 30mg), Doses de Hoje (tomar / +15m / pular), Estoque baixo + solicitar receita ao médico, Aviso de prevenção do rebote (lanche + água), Medication Efficacy Window Cards

### Community 141 - "Dia Tab Prototype"
Cohesion: 0.25
Nodes (8): Check-in do Momento CTA, Abrir Des-Trava Discreet Entry Row, Dia Tab Prototype (routine execution), Fluxo dos Turnos (Manhã/Tarde/Noite checklist), Hidratação Tactile Cups Tracker, Lixeira Mental (quick thought dump), Check-ins Recentes List, Tarefas Planejadas Card

### Community 142 - "Safety & Privacy Claims"
Cohesion: 0.29
Nodes (5): Local Offline Encryption Footer Claim, Health Connect / Apple Health Read-Write Scope, Local Data Inventory Table (noa_* prefs keys), docs/PRIVACY.md Canonical Source Reference, Lumen Privacy Policy Page

### Community 143 - "Onboarding Bootstrap"
Cohesion: 0.29
Nodes (8): sharedPreferencesProvider, _finish, FirstLaunchOnboarding, _FirstLaunchOnboardingState, maybeShow, _requestPermissions, deviceCalendarProvider, _requestCalendar

### Community 144 - "Civil Day Helpers"
Cohesion: 0.25
Nodes (7): civilDay, civilDayKey, d, day, isSameCivilDay, m, y

### Community 145 - "Onboarding Prefs"
Cohesion: 0.25
Nodes (6): alreadyUsing, markOnboardingDone, onboardingDoneKey, setBool, shouldShowFirstLaunchOnboarding, true

### Community 146 - "Voice Tone Profile"
Cohesion: 0.25
Nodes (5): boyYouth, fallback, fromMap, toMap, VoiceToneProfile

### Community 147 - "Reminder Permission Banners"
Cohesion: 0.29
Nodes (8): build, initState, _openSystemSettings, _ReminderPermissionBanners, taskExactAlarmsAllowedProvider, taskNotificationsEnabledProvider, taskQuietHoursProvider, taskSystemSettingsProvider

### Community 148 - "Rotina Prototype"
Cohesion: 0.33
Nodes (7): Nuvem de Sensações (State of Mind), Card Âncora do Dia + Micro-rituais, Stitch Prototype: Rotina & Foco do Dia, Foco Único Inegociável (Âncora), Hidratação Gentil (ml, copos 250ml), State of Mind slider + contexto de energia, State of Mind & Neuro-Energy Chips

### Community 149 - "Des-Trava Prototype (Old)"
Cohesion: 0.29
Nodes (6): Stitch Prototype: Des-Trava (Sessão Descongelar), Passo 1: Micro-ação física (corpo), Passo 2: Uma palavra da tarefa, Passo 3: Timer 60s sem compromisso, CTA Desempacar, Inter Typography Scale

### Community 150 - "Home Hub Prototype"
Cohesion: 0.29
Nodes (7): Stitch Prototype: Início Home Hub, CTA Des-Trava (SOS), Micro Check-ins Recentes, Card Padrão Cognitivo Revelado (insight REM × foco), Ver Resumo para Consulta Terapêutica, Card Sono & Recuperação (Apple Health), Unstick (Anti-Paralysis) Action Button

### Community 151 - "Remédios Prototype"
Cohesion: 0.38
Nodes (7): Remédios de Hoje Card, Progresso Gentil Daily Dose Card, Janelas Posológicas (per-slot dose cards), Prescription Validity Notice, Remédios Prototype (posology & alarms), Calm Stock / Refill Alert, Marcar como Tomado / Adiar 15 min Actions

### Community 152 - "Quiet Hours Prefs"
Cohesion: 0.29
Nodes (5): getTaskQuietHours, raw, setString, setTaskQuietHours, taskQuietHoursKey

### Community 153 - "Micro-habits Prefs"
Cohesion: 0.29
Nodes (6): defaultMicroHabits, getMicroHabitsTemplate, microHabitsTemplateKey, raw, setMicroHabitsTemplate, setString

### Community 154 - "PDF Report Style"
Cohesion: 0.33
Nodes (5): PdfReportStyleNotifier, fromStorage, PdfReportStyle, PdfReportStyleStorage, storageValue

### Community 155 - "Care Contact Labels"
Cohesion: 0.33
Nodes (4): careContactDisplayName, careContactRoleLabel, l10n, name

### Community 156 - "Profile Labels"
Cohesion: 0.33
Nodes (3): biologicalSexCodes, biologicalSexLabel, voiceToneLabel

### Community 157 - "Apple Health Service"
Cohesion: 0.33
Nodes (4): AppleHealthService, FacadeHealthService, HealthService, _RecordingHealth

### Community 158 - "L10n Labels"
Cohesion: 0.33
Nodes (3): description, label, valenceLabel

### Community 160 - "Demographics Mapper"
Cohesion: 0.33
Nodes (3): HealthDemographicsMapper, toProfileDemographics, HealthDemographics

### Community 161 - "Shell Navigation Doors"
Cohesion: 0.33
Nodes (5): openProfileScreen, openRoutineCalendarScreen, openSettingsScreen, _openTasksFromAlarm, openTasksHub

### Community 162 - "Care Contacts Section"
Cohesion: 0.40
Nodes (5): _CareContactsSection, careContactsProvider, _delete, _save, _sendWhatsApp

### Community 163 - "Analyzer Options"
Cohesion: 0.50
Nodes (3): include, linter, rules

### Community 169 - "Correlation Copy Interface"
Cohesion: 0.67
Nodes (3): L10nCorrelationCopy, CorrelationCopy, _Copy

## Ambiguous Edges - Review These
- `Meus Dias Week Teaser` → `Gentle pt-BR Copy & Tone (no shame idioms)`  [AMBIGUOUS]
  Design/Stitch/new/in_cio_hub_pessoal_ficha_viva/code.html · relation: conceptually_related_to
- `Local Offline Encryption Footer Claim` → `Offline-First, No Account, No Lumen Cloud`  [AMBIGUOUS]
  Design/Stitch/new/pasta_cl_nica_exporta_o_consulta/code.html · relation: conceptually_related_to

## Knowledge Gaps
- **2121 isolated node(s):** `EventKit`, `HealthKit`, `AppIcons`, `checkin`, `unstuck` (+2116 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2438 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `UserProfile` connect `Profile Screen` to `UserProfile Model`, `Profile Sheet Card`, `Home Ficha Screen`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `EventKit`, `HealthKit`, `AppIcons` to the rest of the system?**
  _2121 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Shell Navigation Imports` be split into smaller, more focused modules?**
  _Cohesion score 0.024390243902439025 - nodes in this community are weakly interconnected._
- **Why does `appLocalizationsProvider` connect `Locale & Theme Providers` to `Home Data Providers`, `Health Consent Sheet`, `Localization & Shell Tests`, `Routine Calendar Screen`, `Insights & Med Window Cards`, `Daily Routine Screen`, `Dashboard Card Widgets`, `Onboarding Bootstrap`, `First Launch Onboarding`, `Reminder Permission Banners`, `Stateful Sheets & Shell`, `Sleep & Health Sync UI`, `Care Contact Editor`, `Add Medication Sheet`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Should `App Icons` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Meus Dias Week Teaser` and `Gentle pt-BR Copy & Tone (no shame idioms)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Local Offline Encryption Footer Claim` and `Offline-First, No Account, No Lumen Cloud`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._