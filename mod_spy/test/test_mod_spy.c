#include <test/switch_test.h>

FST_CORE_BEGIN("conf")
{
  FST_MODULE_BEGIN(mod_spy, mod_spy_test)
    {
      FST_SETUP_BEGIN()
        {
          fst_requires_module("mod_spy");
        }
      FST_SETUP_END();

      FST_TEST_BEGIN(dump_hash)
        {
          switch_stream_handle_t stream = { 0 };

          SWITCH_STANDARD_STREAM(stream);

          fst_check(switch_api_execute("userspy_show", "userspy_show", NULL, &stream) == SWITCH_STATUS_SUCCESS);

          fst_check_string_has(stream.data, "total spy");
        }
      FST_TEST_END();


      FST_SESSION_BEGIN(spy_a_user)
        {
          fst_check(switch_core_session_execute_application(fst_session, "userspy", "12346") == SWITCH_STATUS_SUCCESS);
        }
      FST_SESSION_END();

      FST_SESSION_BEGIN(function_event_handler)
        {
          switch_event_t *event;
          fst_check(switch_event_create(&event, SWITCH_EVENT_CHANNEL_BRIDGE) == SWITCH_STATUS_SUCCESS);
          switch_event_fire(&event);
          sleep(1);
          // TODO: how to check changes in function `event_handler`?
        }
      FST_SESSION_END();

      FST_SESSION_BEGIN(process_event_variable_dialed_user_and_variable_dialed_domain)
        {
          fst_check(switch_core_session_execute_application(fst_session, "userspy", "1000@test.org") == SWITCH_STATUS_SUCCESS);

          switch_event_t *event;
          const char *my_uuid = switch_channel_get_variable(fst_channel, "uuid");

          fst_check(switch_event_create(&event, SWITCH_EVENT_CHANNEL_BRIDGE) == SWITCH_STATUS_SUCCESS);
          switch_event_add_header_string(event, SWITCH_STACK_BOTTOM, "variable_dialed_user", "1000");
          switch_event_add_header_string(event, SWITCH_STACK_BOTTOM, "variable_dialed_domain", "test.org");

          switch_event_fire(&event);
          sleep(1);
          fst_check_string_has(switch_channel_get_variable(fst_channel, "spy_uuid"), my_uuid);
        }
      FST_SESSION_END();

      FST_TEARDOWN_BEGIN()
        {
        }
      FST_TEARDOWN_END();
    }
  FST_MODULE_END();
}
FST_CORE_END();
