├── app
│   ├── app.dart
│   └── view
│       ├── app.dart
│       └── imports.dart
├── bootstrap.dart
├── core
│   ├── constants
│   │   ├── api_endpoints.dart
│   │   ├── app_constant.dart
│   │   ├── environment_constant.dart
│   │   ├── image_constant.dart
│   │   └── storage_constants.dart
│   ├── error
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── mixins
│   │   └── auth_mixin.dart
│   ├── network
│   │   ├── cookie
│   │   │   └── secure_cookie_store.dart
│   │   ├── dio_network_service.dart
│   │   ├── failure
│   │   ├── get_parsed_data.dart
│   │   ├── i_network_service.dart
│   │   ├── interceptors
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── logging_interceptor.dart
│   │   │   └── secure_cookie_interceptor.dart
│   │   ├── models
│   │   │   └── api_error_response_model.dart
│   │   └── utils
│   ├── routes
│   │   ├── app_navigator.dart
│   │   ├── app_route_constant.dart
│   │   └── app_routes.dart
│   ├── theme
│   │   ├── app_theme.dart
│   │   ├── color_constant.dart
│   │   ├── cubit
│   │   │   └── theme_cubit.dart
│   │   └── design_tokens.dart
│   ├── utils
│   │   └── date_range_utils.dart
│   └── validators
│       ├── identifier_input.dart
│       └── password_input.dart
├── di
│   └── locator.dart
├── features
│   ├── agent_detail
│   │   └── presentation
│   │       ├── cubit
│   │       │   ├── agent_detail_cubit.dart
│   │       │   └── agent_detail_state.dart
│   │       ├── pages
│   │       │   └── agent_detail_page.dart
│   │       └── utils
│   │           └── agent_detail_date_range_logic.dart
│   ├── agent_list
│   │   ├── agent_list_import.dart
│   │   ├── domain
│   │   │   └── entities
│   │   │       └── agent_list_item_entity.dart
│   │   └── presentation
│   │       ├── cubit
│   │       │   ├── agent_list_cubit.dart
│   │       │   └── agent_list_state.dart
│   │       ├── pages
│   │       │   └── agent_list_page.dart
│   │       └── widgets
│   │           ├── agent_filter_chip.dart
│   │           ├── agent_list_empty_states.dart
│   │           ├── agent_list_item_card.dart
│   │           ├── agent_list_loading_shimmer.dart
│   │           ├── agent_list_screen.dart
│   │           └── agent_status_chip.dart
│   ├── authentication
│   │   ├── data
│   │   │   ├── models
│   │   │   ├── repositories
│   │   │   │   └── authentication_repository_impl.dart
│   │   │   └── sources
│   │   ├── domain
│   │   │   ├── entities
│   │   │   ├── repositories
│   │   │   │   └── authentication_repository.dart
│   │   │   └── usecases
│   │   │       ├── login_use_case.dart
│   │   │       └── restore_session_use_case.dart
│   │   └── presentation
│   │       ├── cubit
│   │       │   ├── login_cubit.dart
│   │       │   └── login_state.dart
│   │       ├── pages
│   │       │   └── login_page.dart
│   │       └── widgets
│   │           ├── login_header_section.dart
│   │           ├── login_identifier_field.dart
│   │           └── login_password_field.dart
│   ├── dashboard
│   │   ├── dashboard_import.dart
│   │   ├── data
│   │   │   ├── datasources
│   │   │   │   └── dashboard_remote_data_source.dart
│   │   │   ├── dummy
│   │   │   │   ├── dashboard_dummy_config.dart
│   │   │   │   └── dashboard_dummy_json.dart
│   │   │   ├── models
│   │   │   │   ├── dashboard_device_stats_model.dart
│   │   │   │   └── dashboard_filter_hierarchy_model.dart
│   │   │   └── repositories
│   │   │       └── dashboard_repository_impl.dart
│   │   ├── domain
│   │   │   ├── entities
│   │   │   │   ├── dashboard_device_stats_entity.dart
│   │   │   │   └── dashboard_filter_hierarchy_entity.dart
│   │   │   └── repositories
│   │   │       └── dashboard_repository.dart
│   │   └── presentation
│   │       ├── cubit
│   │       │   ├── dashboard_cubit.dart
│   │       │   ├── dashboard_filter_cubit.dart
│   │       │   ├── dashboard_filter_state.dart
│   │       │   └── dashboard_state.dart
│   │       └── view
│   │           ├── dashboard_base_view.dart
│   │           └── widgets
│   │               ├── app_filter_bottom_sheet.dart
│   │               ├── circular_icon_widget.dart
│   │               ├── dashboard_auto_refresh_wrapper.dart
│   │               ├── dashboard_ga_gc_metrics_card.dart
│   │               ├── dashboard_heartbeat_devices_card.dart
│   │               ├── dashboard_idle_devices_card.dart
│   │               ├── dashboard_loading_shimmer.dart
│   │               ├── dashboard_metric_pill.dart
│   │               ├── dashboard_procurement_card.dart
│   │               ├── dashboard_region_card.dart
│   │               ├── dashboard_shell_card.dart
│   │               ├── dashboard_single_metric_card.dart
│   │               ├── dashboard_time_card.dart
│   │               └── filter
│   │                   ├── filter_bottom_sheet_content.dart
│   │                   ├── filter_bottom_sheet_logic.dart
│   │                   ├── filter_bottom_sheet_models.dart
│   │                   ├── filter_multi_select_field.dart
│   │                   └── filter_single_select_dropdown_field.dart
│   ├── reset_password
│   │   ├── data
│   │   │   └── repositories
│   │   │       └── reset_password_repository_impl.dart
│   │   ├── domain
│   │   │   ├── repositories
│   │   │   │   └── reset_password_repository.dart
│   │   │   └── usecases
│   │   │       └── request_password_reset_use_case.dart
│   │   └── presentation
│   │       ├── cubit
│   │       │   ├── reset_password_cubit.dart
│   │       │   └── reset_password_state.dart
│   │       ├── pages
│   │       │   └── reset_password_page.dart
│   │       ├── validators
│   │       │   └── reset_password_email_input.dart
│   │       └── widgets
│   │           ├── reset_password_email_field.dart
│   │           └── reset_password_header_section.dart
│   └── splash
│       └── presentation
│           ├── controller
│           │   └── splash_controller.dart
│           ├── cubit
│           │   ├── splash_cubit.dart
│           │   └── splash_state.dart
│           └── pages
│               └── splash_page.dart
├── l10n
│   ├── arb
│   │   ├── app_en.arb
│   │   └── app_es.arb
│   ├── gen
│   │   ├── app_localizations_en.dart
│   │   ├── app_localizations_es.dart
│   │   └── app_localizations.dart
│   └── l10n.dart
├── main_development.dart
├── main_production.dart
├── main_staging.dart
├── start_up.dart
└── widgets
    ├── app_bottom_sheet.dart
    ├── app_button.dart
    ├── app_text_field.dart
    ├── build_text.dart
    ├── circular_right_arrow_button.dart
    └── filter
        ├── disabled_field_wrapper.dart
        └── filter_input_decoration.dart