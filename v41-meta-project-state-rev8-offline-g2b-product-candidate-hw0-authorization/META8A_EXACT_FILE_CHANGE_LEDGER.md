# META-8A exact file change ledger

Exactly 16 SSOT files change. UPDATE_POLICY.md, STATE_SCHEMA.md and META_UPDATE_TEMPLATE.md are unchanged. All other repository paths outside the new META-8A package are excluded.

| Path | Before SHA-256 | After SHA-256 | Reason / field |
|---|---|---|---|
| project-current-state/ACTIVE_BASELINES.md | E25125DB6866D306C7930C197459B6736DB1FF70FB18F1BD91F5D9EA7D1414FD | 42DB7FA4FA660848574877A4ED3FCC393E9378043638174BC5C6D8742A736497 | Inventory exact offline test candidate; retain R1i; revision; G2B baseline table; new accepted product test-candidate inventory |
| project-current-state/CHANGELOG.md | 682B1F9648B44D87A3BF812706624BBA68540158159EB6E7EDC321C2B164B2E7 | 917C4967E8E899632486791F40C0CB20AB4198EC7F91F0148AD9F80AD5B74662 | Append revision-8 transaction; append PROJECT_STATE_REV 8 only; preserve previous bytes |
| project-current-state/COMPATIBILITY_MATRIX.csv | 76D429FBB9C28589079E38817A96657FAB4DC64CDA47FE6B09BBEC9A30864058 | 4BE2FACBEC64760F1BFBF56F5D79E294F16ACD5C19C3376EFB6A99C9C8AC87F2 | Bind exact PRODUCT to ABI/MMIO and HW0; G2B/PRODUCT/host rows; new exact candidate compatibility row |
| project-current-state/CURRENT_ARCHITECTURE.md | 55F3C765BB7B7BDF8C4BBD1038F322B44480EA14529E2222E424CEC83DDA0549 | F918841D34061594A65EE7DBCDBA23F58A1090AD90322F330EEBF4E3439B0350 | Promote one-channel offline implementation and dual identity; revision; maturity matrix; MMIO/capture/DMA boundaries; Recovery-4 completion; new candidate binding |
| project-current-state/CURRENT_INTERFACES.md | FB391086FB448AFBFF0DC8766BF4FF9C7C89941B02F9A3C9D97ECBCA6219B72C | 94F11689011260F85349D01B61A4754343FEA8804D6699F6634B76D77A0FE8E8 | Record unchanged implemented ABI/MMIO and expected dual identity; revision; runtime identity table; implementation qualifiers; PRODUCT boundary |
| project-current-state/CURRENT_REQUIREMENTS.md | BC4820B32BB83E73F4879916AB42FCCEA1D84939833441D34190CDBFC1DB2684 | 2B5CC65328129A123829A96D1EAA161B2A2D4A443A6D30D6BF4D1A9B9C646627 | Record offline qualification and remaining hardware boundaries; revision; qualification cells; implementation target; profile/sign-off completion |
| project-current-state/CURRENT_RESOURCE_STATE.md | 271F53443B3F063BD1505BFBBD4FB95FB40B0ADED2A8F86DEB8BAA3D64368B0B | E1FD2BA9D02714EF3966A3075EAA65A759EA146A67A7C9F68D5AB6417239AF11 | Add actual PRODUCT utilization with unchanged thresholds; revision; PRODUCT measured result; pending/estimate qualifications |
| project-current-state/CURRENT_STATUS.md | BB3CF28F8E2AB06B8532838D6FAA2DE6408CBA0E10DACFDDCBE4516EDEC23164 | E9EDED945386B59B5CD0F695621A47778FC6A3CC1A64D44B2553A4673ADE7C83 | Accept offline gate and plan separate authorized HW0; revision; decision basis; gate/maturity tables; resource attainment |
| project-current-state/CURRENT_TRACKS.md | 5CB9898C95BD2E0BE7C137E147D5B0DFAA43DF6A76D4CDBF55E85F22F369A723 | 52AB4EC0E234346B6C524B561FA8C4CEA3C37B1ABDD3328568D0F89F4609B1B3 | Advance product last/next gate; revision; summary; G-track gates/next decision; META current task |
| project-current-state/EVIDENCE_MAP.md | 20C5E803E922B9056F40849EAE7A41F40DE14D97FD4BF089E5DF81B5BF8259F4 | 412E98C2B2F700034AD4542F61608D12D4A1AE0737B5290026E020461AF24788 | Bind source/DCP/bitstream and acceptance boundary; revision/current anchor; affected statement rows; Recovery-4 package |
| project-current-state/GOVERNANCE.md | BEA6E809FD76C2D08DCE30B507A58CE1E1F8B88C851B8D9D20E18D381A9E5474 | A5E4782C9C60FFF845D7EAFC8B040739D4FE91EED31E5FEC01B580BD8A39A958 | Synchronize governed revision only; Project-state revision governed 7 to 8; no policy/version change |
| project-current-state/OPEN_DECISIONS.md | 1A0E2F255A156A947E09880DD7FEED8F3A60489E5FC952C17D948871428C3950 | 57EC4A78C5214194D0642903BCD2C396BCD213C0DA124D826FA896DAE420A964 | Record unnumbered acceptance and remaining boundaries; revision; OD-05/11/12/13 evidence descriptions; new decision; historical labels |
| project-current-state/PROJECT_STATE.json | B800B561863202A34DA87EE6273F15F65FE1A4A716CDA82AEAC825C3A6AA872E | 9FEE5B8A2F9E2F0CB8D4CA730B087DA448E329524085FEBD1FF42CC41D0AD4AF | Apply exact offline candidate and next gate; revision/header; product/meta; implementation/profile/resource/sign-off maturity; candidate inventory; HW0; evidence refs |
| project-current-state/README.md | CDB53488D8F4BCA0BFF933F7593CB1CE5DC61548101E643F00EE717E567243C9 | 849ABF1C39CDCE93510F05B4A4FE691577DABF68584D852AA72B07DACCD52B12 | Update SSOT entry point; revision; snapshot; decision basis; sign-off completion |
| project-current-state/SHA256_MANIFEST.txt | DDC4FA16EDE2FDC350B0DCF2E38B7C29E5C05EF67557B8AEF51B5417B4726E7C | B935E05F75AC1357D29ACB91E08978BD9A6701CD06024F9E6E2C6EB071993EC6 | Seal 18 other SSOT files; recompute sorted SHA-256 entries; excludes itself |
| project-current-state/TRACK_STATUS.json | 92A6721670C214B5A178F309518B421412BA60974DA71BD85F6A7502BDBE2144 | 675BC71817D2C955BC296330D21EA846E227016BE0DCAE0BA38E61628F761C58 | Mirror schema-valid accepted offline and planned HW0; revision/header; product last/next/gates/source/sign-off; meta task |

## Exact changed JSON field paths


PROJECT_STATE.json

- `/acceptance_authorization`
- `/accepted_product_test_candidates`
- `/application_dma/application_c2h_payload/accepted_by_role`
- `/application_dma/application_c2h_payload/decision_source`
- `/application_dma/application_c2h_payload/evidence_directory`
- `/application_dma/application_c2h_payload/qualification`
- `/application_dma/application_c2h_payload/source_evidence_commit`
- `/application_dma/application_c2h_payload/status`
- `/application_dma/record_to_axi_stream_data_plane/accepted_by_role`
- `/application_dma/record_to_axi_stream_data_plane/accepted_gate`
- `/application_dma/record_to_axi_stream_data_plane/blocking_reason`
- `/application_dma/record_to_axi_stream_data_plane/decision_source`
- `/application_dma/record_to_axi_stream_data_plane/engineering_gate`
- `/application_dma/record_to_axi_stream_data_plane/evidence_directory`
- `/application_dma/record_to_axi_stream_data_plane/hardware_qualification`
- `/application_dma/record_to_axi_stream_data_plane/implementation_state`
- `/application_dma/record_to_axi_stream_data_plane/next_gate`
- `/application_dma/record_to_axi_stream_data_plane/offline_qualification_state`
- `/application_dma/record_to_axi_stream_data_plane/qualification_maturity`
- `/application_dma/record_to_axi_stream_data_plane/readiness`
- `/application_dma/record_to_axi_stream_data_plane/release_state`
- `/application_dma/record_to_axi_stream_data_plane/scope`
- `/application_dma/record_to_axi_stream_data_plane/source_evidence_commit`
- `/application_dma/record_to_axi_stream_data_plane/status`
- `/application_dma/record_to_axi_stream_data_plane/target_gate`
- `/application_dma/required_payload_288_mb_s/hardware_throughput_proven`
- `/application_dma/required_payload_288_mb_s/offline_analysis`
- `/application_dma/required_payload_288_mb_s/offline_evidence_commit`
- `/application_dma/required_payload_288_mb_s/qualification`
- `/build_profiles/implementation_authority/qualification_evidence_commit`
- `/build_profiles/implementation_authority/readiness`
- `/build_profiles/implementation_authority/selected_mechanism`
- `/build_profiles/implementation_authority/target_gate`
- `/build_profiles/implementation_state`
- `/build_profiles/product/accepted_by_role`
- `/build_profiles/product/actual_post_route_lut`
- `/build_profiles/product/actual_post_route_lut_percent`
- `/build_profiles/product/authorization_state`
- `/build_profiles/product/decision_source`
- `/build_profiles/product/evidence_directory`
- `/build_profiles/product/qualification_evidence_commit`
- `/build_profiles/product/qualification_maturity`
- `/build_profiles/product/source_evidence_commit`
- `/build_profiles/product/status`
- `/c2h_architecture/candidate_source_commit`
- `/c2h_architecture/implementation_state`
- `/c2h_architecture/qualification_evidence_commit`
- `/decided_decisions`
- `/diagnostic_reduction/implementation_state`
- `/diagnostic_reduction/qualification_evidence_commit`
- `/evidence_references`
- `/expected_previous_project_state_revision`
- `/g2b_diag0`
- `/g2b_hardware/accepted_by_role`
- `/g2b_hardware/bitstream_candidate`
- `/g2b_hardware/blocking_reason`
- `/g2b_hardware/decision_source`
- `/g2b_hardware/evidence_directory`
- `/g2b_hardware/execution_requires_fresh_operational_authorization`
- `/g2b_hardware/gate_contract`
- `/g2b_hardware/hardware_evidence_present`
- `/g2b_hardware/next_gate`
- `/g2b_hardware/readiness`
- `/g2b_hardware/scope`
- `/g2b_hardware/source_evidence_commit`
- `/g2b_hardware/status`
- `/g2b_implementation/accepted_by_role`
- `/g2b_implementation/accepted_gate`
- `/g2b_implementation/blocking_reason`
- `/g2b_implementation/decision_source`
- `/g2b_implementation/engineering_gate`
- `/g2b_implementation/evidence_directory`
- `/g2b_implementation/g2b_bitstream`
- `/g2b_implementation/hardware_qualification`
- `/g2b_implementation/implementation_state`
- `/g2b_implementation/next_engineering_source/commit`
- `/g2b_implementation/next_engineering_source/repository`
- `/g2b_implementation/next_engineering_source/scope`
- `/g2b_implementation/next_engineering_source/tree`
- `/g2b_implementation/next_gate`
- `/g2b_implementation/offline_qualification_state`
- `/g2b_implementation/one_channel_c2h_rtl`
- `/g2b_implementation/qualification_maturity`
- `/g2b_implementation/readiness`
- `/g2b_implementation/release_state`
- `/g2b_implementation/scope`
- `/g2b_implementation/source_evidence_commit`
- `/g2b_implementation/status`
- `/g2b_mmio/candidate_bitstream_sha256`
- `/g2b_mmio/candidate_source_commit`
- `/g2b_mmio/implementation_state`
- `/g2b_mmio/qualification_evidence_commit`
- `/g2b_resource_recovery/plan_state`
- `/g2b_resource_recovery/qualification_evidence_commit`
- `/g2b_resource_recovery/target_gate`
- `/groups15_17_release_slot_cdc_signoff/active_xdc_change`
- `/groups15_17_release_slot_cdc_signoff/active_xdc_change_at_promotion`
- `/groups15_17_release_slot_cdc_signoff/completed_offline_gate`
- `/groups15_17_release_slot_cdc_signoff/completed_offline_signoff_recipe`
- `/groups15_17_release_slot_cdc_signoff/future_signoff_recipe`
- `/groups15_17_release_slot_cdc_signoff/groups/0/active_xdc_change`
- `/groups15_17_release_slot_cdc_signoff/groups/0/active_xdc_change_at_promotion`
- `/groups15_17_release_slot_cdc_signoff/groups/0/qualification_evidence_commit`
- `/groups15_17_release_slot_cdc_signoff/groups/1/active_xdc_change`
- `/groups15_17_release_slot_cdc_signoff/groups/1/active_xdc_change_at_promotion`
- `/groups15_17_release_slot_cdc_signoff/groups/1/qualification_evidence_commit`
- `/groups15_17_release_slot_cdc_signoff/groups/2/active_xdc_change`
- `/groups15_17_release_slot_cdc_signoff/groups/2/active_xdc_change_at_promotion`
- `/groups15_17_release_slot_cdc_signoff/groups/2/qualification_evidence_commit`
- `/groups15_17_release_slot_cdc_signoff/next_gate`
- `/groups15_17_release_slot_cdc_signoff/qualification_evidence_commit`
- `/groups15_17_release_slot_cdc_signoff/recipe_completion`
- `/groups15_17_release_slot_cdc_signoff/remaining_methodology_warnings`
- `/interfaces/g2b_mmio/candidate_bitstream_sha256`
- `/interfaces/g2b_mmio/candidate_source_commit`
- `/interfaces/g2b_mmio/implementation_state`
- `/interfaces/g2b_mmio/qualification_evidence_commit`
- `/interfaces/transport_abi/candidate_bitstream_sha256`
- `/interfaces/transport_abi/candidate_source_commit`
- `/interfaces/transport_abi/implementation_state`
- `/interfaces/transport_abi/qualification_evidence_commit`
- `/linux_video/hw0_dependency`
- `/offline_product_qualification`
- `/ownership_cdc_signoff/completed_offline_gate`
- `/ownership_cdc_signoff/completed_offline_signoff_recipe`
- `/ownership_cdc_signoff/future_signoff_recipe`
- `/ownership_cdc_signoff/next_gate`
- `/ownership_cdc_signoff/qualification_evidence_commit`
- `/ownership_cdc_signoff/recipe_completion`
- `/pcie/hardware_throughput_proven`
- `/pcie/offline_evidence_commit`
- `/pcie/offline_throughput_analysis`
- `/project_state_revision`
- `/release`
- `/release_slot_cdc_signoff/completed_offline_gate`
- `/release_slot_cdc_signoff/next_gate`
- `/release_slot_cdc_signoff/structural_proof/fresh_global_cdc_closure`
- `/release_slot_cdc_signoff/structural_proof/qualification_evidence_commit`
- `/requirements/4/offline_analysis`
- `/requirements/4/offline_evidence_commit`
- `/requirements/4/qualification`
- `/requirements/8/implementation_state`
- `/requirements/8/implementation_state_at_promotion`
- `/requirements/8/qualification`
- `/requirements/8/qualification_evidence_commit`
- `/requirements/9/active_xdc_change`
- `/requirements/9/qualification`
- `/requirements/9/qualification_evidence_commit`
- `/requirements/10/active_xdc_change`
- `/requirements/10/qualification`
- `/requirements/10/qualification_evidence_commit`
- `/requirements/11/active_xdc_change`
- `/requirements/11/qualification`
- `/requirements/11/qualification_evidence_commit`
- `/reset_return_cdc_signoff/completed_offline_gate`
- `/reset_return_cdc_signoff/next_gate`
- `/reset_return_cdc_signoff/structural_proof/fresh_global_cdc_closure`
- `/reset_return_cdc_signoff/structural_proof/qualification_evidence_commit`
- `/resources/interpretation`
- `/resources/product_lut_target_achieved`
- `/resources/product_offline_result`
- `/source_evidence_commit`
- `/source_evidence_directory`
- `/tracks/meta/acceptance_basis`
- `/tracks/meta/accepted_by_role`
- `/tracks/meta/current_task`
- `/tracks/meta/decision_source`
- `/tracks/meta/evidence_directory`
- `/tracks/meta/source_evidence_commit`
- `/tracks/product/accepted_gates`
- `/tracks/product/g2b_hw0_product`
- `/tracks/product/g2b_lut1/accepted_gate`
- `/tracks/product/g2b_lut1/decision_source`
- `/tracks/product/g2b_lut1/engineering_gate`
- `/tracks/product/g2b_lut1/evidence_directory`
- `/tracks/product/g2b_lut1/hardware_qualification`
- `/tracks/product/g2b_lut1/implementation_state`
- `/tracks/product/g2b_lut1/next_gate`
- `/tracks/product/g2b_lut1/offline_qualification_state`
- `/tracks/product/g2b_lut1/qualification_maturity`
- `/tracks/product/g2b_lut1/readiness`
- `/tracks/product/g2b_lut1/release_state`
- `/tracks/product/g2b_lut1/scope`
- `/tracks/product/g2b_lut1/source_evidence_commit`
- `/tracks/product/g2b_lut1/status`
- `/tracks/product/last_accepted_gate`
- `/tracks/product/next_allowed_engineering_step`
- `/tracks/product/next_gate`
- `/transport_abi/candidate_bitstream_sha256`
- `/transport_abi/candidate_source_commit`
- `/transport_abi/implementation_state`
- `/transport_abi/qualification_evidence_commit`
- `/update_type`
- `/write_contract_receipt`

TRACK_STATUS.json

- `/acceptance_authorization`
- `/expected_previous_project_state_revision`
- `/meta_track/acceptance_basis`
- `/meta_track/current_task`
- `/meta_track/decision_source`
- `/meta_track/evidence_directory`
- `/meta_track/source_evidence_commit`
- `/product_track/accepted_product_test_candidate`
- `/product_track/gates`
- `/product_track/group13_reset_return_signoff/completed_offline_gate`
- `/product_track/group13_reset_return_signoff/next_gate`
- `/product_track/group14_release_slot_signoff/completed_offline_gate`
- `/product_track/group14_release_slot_signoff/next_gate`
- `/product_track/groups15_17_release_slot_signoff/active_xdc_change`
- `/product_track/groups15_17_release_slot_signoff/active_xdc_change_at_promotion`
- `/product_track/groups15_17_release_slot_signoff/completed_offline_gate`
- `/product_track/groups15_17_release_slot_signoff/completed_offline_signoff_recipe`
- `/product_track/groups15_17_release_slot_signoff/future_signoff_recipe`
- `/product_track/groups15_17_release_slot_signoff/groups/0/active_xdc_change`
- `/product_track/groups15_17_release_slot_signoff/groups/0/active_xdc_change_at_promotion`
- `/product_track/groups15_17_release_slot_signoff/groups/0/qualification_evidence_commit`
- `/product_track/groups15_17_release_slot_signoff/groups/1/active_xdc_change`
- `/product_track/groups15_17_release_slot_signoff/groups/1/active_xdc_change_at_promotion`
- `/product_track/groups15_17_release_slot_signoff/groups/1/qualification_evidence_commit`
- `/product_track/groups15_17_release_slot_signoff/groups/2/active_xdc_change`
- `/product_track/groups15_17_release_slot_signoff/groups/2/active_xdc_change_at_promotion`
- `/product_track/groups15_17_release_slot_signoff/groups/2/qualification_evidence_commit`
- `/product_track/groups15_17_release_slot_signoff/next_gate`
- `/product_track/groups15_17_release_slot_signoff/qualification_evidence_commit`
- `/product_track/groups15_17_release_slot_signoff/recipe_completion`
- `/product_track/groups15_17_release_slot_signoff/remaining_methodology_warnings`
- `/product_track/last_accepted_gate`
- `/product_track/next_allowed_engineering_step`
- `/product_track/next_engineering_source/commit`
- `/product_track/next_engineering_source/repository`
- `/product_track/next_engineering_source/scope`
- `/product_track/next_engineering_source/tree`
- `/product_track/next_gate`
- `/product_track/resource_recovery_state`
- `/project_state_revision`
- `/source_evidence_commit`
- `/source_evidence_directory`
- `/update_type`
- `/write_contract_receipt`
